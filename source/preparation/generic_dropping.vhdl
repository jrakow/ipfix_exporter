library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module drops a configurable part of the first frame of a given AXI stream.
All but the specified width will be dropped from the first part of the first frame.
All bytes are shifted to the front.

Incoming frames are expected to consist of more than the first frame.
 */
entity generic_dropping is
	generic(
		g_kept_bytes : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of generic_dropping is
	type t_fsm is (drop_first, forward, send_last, wait_read);
	type t_reg is record
		fsm        : t_fsm;
		-- last frame controls if wait_read goes to drop_first or forward
		last_frame : boolean;

		prev_tdata_part : std_ulogic_vector(g_kept_bytes * 8 - 1 downto 0);
		prev_tkeep      : std_ulogic_vector(15 downto 0);

		-- output
		if_axis_in_s  : t_if_axis_s;
		if_axis_out_m : t_if_axis_frame_m;
	end record;
	constant c_reg_default : t_reg := (
		fsm             => drop_first,
		last_frame      => false,
		prev_tdata_part => (others => '0'),
		prev_tkeep      => (others => '0'),
		if_axis_in_s    => c_if_axis_s_default,
		if_axis_out_m   => c_if_axis_frame_m_default
	);
	signal r, r_nxt : t_reg := c_reg_default;
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
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when drop_first =>
				-- read not write
				assert r.if_axis_in_s.tready  = '1';
				assert r.if_axis_out_m.tvalid = '0';
				v.if_axis_in_s.tready := '1';

				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					-- the first frame may not be the last frame
					v.prev_tdata_part := if_axis_in_m.tdata(g_kept_bytes * 8 - 1 downto 0);

					v.fsm                 := forward;
				end if;

			when forward =>
				-- read not write
				assert r.if_axis_in_s.tready  = '1';
				assert r.if_axis_out_m.tvalid = '0';

				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					v.if_axis_out_m.tvalid := '1';
					v.if_axis_out_m.tdata  := r.prev_tdata_part & if_axis_in_m.tdata(127 downto g_kept_bytes * 8);
					v.if_axis_out_m.tkeep  := (others => '1');
					v.if_axis_out_m.tlast  := '0';
					v.prev_tdata_part      := if_axis_in_m.tdata(g_kept_bytes * 8 - 1 downto 0);

					v.if_axis_in_s.tready := '0';

					if if_axis_in_m.tlast then
						if tkeep_to_integer(if_axis_in_m.tkeep) <= 16 - g_kept_bytes then
							-- this frame is the last
							-- add tkeep for last part from previous frame
							v.if_axis_out_m.tkeep := to_tkeep(g_kept_bytes + tkeep_to_integer(if_axis_in_m.tkeep), 16);
							v.if_axis_out_m.tlast := '1';

							v.fsm        := wait_read;
							v.last_frame := true;
						else
							-- this is a full frame
							-- the next frame is the last
							-- next frame contains up to g_kept_bytes byte
							-- prev_tdata is already set
							v.prev_tkeep := if_axis_in_m.tkeep;
							v.fsm        := send_last;
						end if;
					else
						v.fsm        := wait_read;
						v.last_frame := false;
					end if;
				end if;

			when send_last =>
				-- write not read
				assert r.if_axis_out_m.tvalid;
				assert r.if_axis_in_s.tready = '0';

				assert tkeep_to_integer(r.prev_tkeep) > 16 - g_kept_bytes;

				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_out_m.tdata(127 downto 128 - g_kept_bytes * 8) := r.prev_tdata_part;
					-- subtract 16 - g_kept_bytes from last frame
					v.if_axis_out_m.tkeep := to_tkeep(tkeep_to_integer(r.prev_tkeep) - 16 + g_kept_bytes, 16);
					v.if_axis_out_m.tlast := '1';

					v.fsm        := wait_read;
					v.last_frame := true;
				end if;

			when wait_read =>
				-- write not read
				assert r.if_axis_out_m.tvalid;
				assert r.if_axis_in_s.tready = '0';

				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_out_m.tvalid := '0';
					v.if_axis_in_s.tready  := '1';

					if r.last_frame then
						v.fsm := drop_first;
					else
						v.fsm := forward;
					end if;
				end if;
			end case;

		r_nxt <= v;
	end process;

	if_axis_in_s  <= r.if_axis_in_s;
	if_axis_out_m <= r.if_axis_out_m;
end architecture;
