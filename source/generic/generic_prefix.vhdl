library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/**
 * This module prefixes a stream with a given prefix.
 * The prefix is sampled at the first incoming handshake after an incoming handshake with tlast, i. e. the first transaction.
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
	type t_fsm is (receive, wait_read, send_last);

	type t_reg is record
		fsm           : t_fsm;
		prev_bytes    : std_ulogic_vector(g_prefix_width - 1 downto 0);
		first_frame   : std_ulogic;
		last_tkeep    : std_ulogic_vector(15 downto 0);

		-- output
		if_axis_in_s  : t_if_axis_s;
		if_axis_out_m : t_if_axis_frame_m;
	end record;
	constant c_reg_default : t_reg := (
		fsm           => receive,
		prev_bytes    => (others => '0'),
		first_frame   => '1',
		last_tkeep    => (others => '0'),
		if_axis_in_s  => c_if_axis_s_default,
		if_axis_out_m => c_if_axis_frame_m_default
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
			when receive =>
				v.if_axis_in_s.tready := '1';

				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					v.if_axis_in_s.tready := '0';

					if v.first_frame then
						v.if_axis_out_m.tdata := prefix & if_axis_in_m.tdata(127 downto g_prefix_width);
						v.first_frame         := '0';
					else
						v.if_axis_out_m.tdata := v.prev_bytes & if_axis_in_m.tdata(127 downto g_prefix_width);
					end if;
					v.prev_bytes := if_axis_in_m.tdata(g_prefix_width - 1 downto 0);

					-- defaults
					v.if_axis_out_m.tvalid := '1';
					v.if_axis_out_m.tkeep  := (others => '1');
					v.if_axis_out_m.tlast  := '0';
					v.fsm                  := wait_read;

					if if_axis_in_m.tlast then
						if tkeep_to_integer(if_axis_in_m.tkeep) + g_prefix_width / 8 <= 16 then
							-- prefix and incoming fit into single frame
							v.if_axis_out_m.tkeep := to_tkeep(tkeep_to_integer(if_axis_in_m.tkeep) + g_prefix_width / 8, 16);
							v.if_axis_out_m.tlast := '1';
							v.first_frame         := '1';
							v.fsm                 := wait_read;
						else
							-- full frame and one more
							v.last_tkeep := to_tkeep(tkeep_to_integer(if_axis_in_m.tkeep) + g_prefix_width / 8 - 16, 16);
							v.fsm        := send_last;
						end if;
					end if;
				end if;

			when wait_read =>
				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_out_m.tvalid := '0';
					v.if_axis_in_s.tready  := '1';
					v.fsm                  := receive;
				end if;

			when send_last =>
				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_out_m.tkeep := v.last_tkeep;
					v.if_axis_out_m.tdata := v.prev_bytes & c_zeros(127 - g_prefix_width downto 0);
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
