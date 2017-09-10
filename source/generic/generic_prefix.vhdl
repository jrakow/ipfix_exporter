library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/**
 * This module prefixes a stream with a given prefix.
 * The prefix must be held just as tdata on when tvalid is first set after tlast was set.
 */
entity generic_prefix is
	generic(
		g_prefix_width : natural
	);
	port(
		clk           : in  std_ulogic;
		rst           : in  std_ulogic;
		if_axis_in_m  : in  t_if_axis_frame_m;
		if_axis_in_s  : out t_if_axis_s;
		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;
		prefix        : in  std_ulogic_vector(g_prefix_width - 1 downto 0)
	);
end entity;

architecture arch of generic_prefix is
	constant c_zeros : std_ulogic_vector(127 downto 0) := (others => '0');
	type t_fsm is (prefix_frames, receive, wait_read, send_last);

	constant c_prefix_frames          : natural := g_prefix_width / 128;
	constant c_prefix_remainder_width : natural := g_prefix_width mod 128;

	type t_reg is record
		fsm                   : t_fsm;
		prefix_frames_counter : natural range 0 to c_prefix_frames;
		prefix_remainder      : std_ulogic_vector(c_prefix_remainder_width - 1 downto 0);
		prev_bytes            : std_ulogic_vector(c_prefix_remainder_width - 1 downto 0);
		first_frame           : std_ulogic;
		last_tkeep            : std_ulogic_vector(15 downto 0);

		-- output
		if_axis_in_s  : t_if_axis_s;
		if_axis_out_m : t_if_axis_frame_m;
	end record;
	constant c_reg_default : t_reg := (
		fsm                   => prefix_frames,
		prefix_frames_counter => 0,
		prefix_remainder      => (others => '0'),
		prev_bytes            => (others => '0'),
		first_frame           => '1',
		last_tkeep            => (others => '0'),
		if_axis_in_s          => c_if_axis_s_default,
		if_axis_out_m         => c_if_axis_frame_m_default
	);
	signal r, r_nxt        : t_reg := c_reg_default;
begin
	p_seq : process(clk)
	begin
		if rising_edge(clk) then
			if rst = c_reset_active then
				r <= c_reg_default;
			else
				r <= r_nxt;
			end if;
		end if;
	end process;

	p_comb : process(if_axis_in_m, if_axis_in_s,
			if_axis_out_m, if_axis_out_s,
			prefix, r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			-- only used if the prefix is more than one frame
			when prefix_frames =>
				v.if_axis_in_s.tready := '0';
				if c_prefix_frames = 0 then
					-- this state is ignored
					v.fsm := receive;
				elsif if_axis_in_m.tvalid then
					-- master starts sending
					v.if_axis_out_m.tvalid := '1';
					v.if_axis_out_m.tkeep  := (others => '1');
					v.if_axis_out_m.tlast  := '0';

					-- sample prefix frames containing in data
					v.prefix_remainder := prefix(c_prefix_remainder_width - 1 downto 0);

					if if_axis_out_m.tvalid and if_axis_out_s.tready then
						v.prefix_frames_counter := v.prefix_frames_counter + 1;
						if v.prefix_frames_counter = c_prefix_frames then
							-- reset counter
							v.prefix_frames_counter := c_reg_default.prefix_frames_counter;

							v.if_axis_out_m.tvalid := '0';
							v.if_axis_in_s.tready  := '1';
							v.fsm := receive;
						end if;
					end if;

					v.if_axis_out_m.tdata  := prefix(g_prefix_width - v.prefix_frames_counter * 128 - 1 downto g_prefix_width - (v.prefix_frames_counter + 1) * 128);
				end if;

			when receive =>
				v.if_axis_in_s.tready := '1';

				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					v.if_axis_in_s.tready := '0';

					if v.first_frame then
						v.prefix_remainder    := prefix(c_prefix_remainder_width - 1 downto 0);
						v.if_axis_out_m.tdata := v.prefix_remainder(c_prefix_remainder_width - 1 downto 0) & if_axis_in_m.tdata(127 downto c_prefix_remainder_width);
						v.first_frame         := '0';
					else
						v.if_axis_out_m.tdata := v.prev_bytes & if_axis_in_m.tdata(127 downto c_prefix_remainder_width);
					end if;
					v.prev_bytes := if_axis_in_m.tdata(c_prefix_remainder_width - 1 downto 0);

					-- defaults
					v.if_axis_out_m.tvalid := '1';
					v.if_axis_out_m.tkeep  := (others => '1');
					v.if_axis_out_m.tlast  := '0';
					v.fsm                  := wait_read;

					if if_axis_in_m.tlast then
						if tkeep_to_integer(if_axis_in_m.tkeep) + c_prefix_remainder_width / 8 <= 16 then
							-- prefix and incoming fit into single frame
							v.if_axis_out_m.tkeep := to_tkeep(tkeep_to_integer(if_axis_in_m.tkeep) + c_prefix_remainder_width / 8, 16);
							v.if_axis_out_m.tlast := '1';
							v.first_frame         := '1';
							v.fsm                 := wait_read;
						else
							-- full frame and one more
							v.last_tkeep := to_tkeep(tkeep_to_integer(if_axis_in_m.tkeep) + c_prefix_remainder_width / 8 - 16, 16);
							v.fsm        := send_last;
						end if;
					end if;
				end if;

			when wait_read =>
				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_out_m.tvalid := '0';
					if if_axis_out_m.tlast then
						v.fsm := prefix_frames;
					else
						v.if_axis_in_s.tready  := '1';
						v.fsm := receive;
					end if;
				end if;

			when send_last =>
				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_out_m.tkeep := v.last_tkeep;
					v.if_axis_out_m.tdata := v.prev_bytes & c_zeros(127 - c_prefix_remainder_width downto 0);
					v.if_axis_out_m.tlast := '1';

					v.last_tkeep  := (others => '0');
					v.first_frame := '1';
					v.fsm         := wait_read;
				end if;
		end case;

		r_nxt <= v;
	end process;

	if_axis_in_s  <= r.if_axis_in_s ;
	if_axis_out_m <= r.if_axis_out_m;
end architecture;
