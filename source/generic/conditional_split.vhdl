library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/**
 * This module forwards incoming frames to one of two sinks.
 *
 * The sink is selected by the target port.
 * The target port is expected to be set in the same clock cycle in which a frame comes in.
 */
entity conditional_split is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		target_1_not_0 : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_0_m : out t_if_axis_frame_m;
		if_axis_out_0_s : in  t_if_axis_s;

		if_axis_out_1_m : out t_if_axis_frame_m;
		if_axis_out_1_s : in  t_if_axis_s
	);
end entity;

architecture arch of conditional_split is
	type t_fsm is (first, forward, wait_read);
	type t_target is (out_0, out_1);
	type t_reg is record
		fsm : t_fsm;

		target : t_target;

		-- output
		if_axis_in_s    : t_if_axis_s;
		if_axis_out_0_m : t_if_axis_frame_m;
		if_axis_out_1_m : t_if_axis_frame_m;
	end record;
	constant c_reg_default : t_reg := (
		fsm             => first,
		target          => out_0,
		if_axis_in_s    => c_if_axis_s_default,
		if_axis_out_0_m => c_if_axis_frame_m_default,
		if_axis_out_1_m => c_if_axis_frame_m_default
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
	                 if_axis_out_0_m, if_axis_out_0_s,
	                 if_axis_out_1_m, if_axis_out_1_s,
	                 target_1_not_0,
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when first =>
				-- read not write
				assert if_axis_in_s.tready    = '0';
				assert if_axis_out_0_m.tvalid = '0';
				assert if_axis_out_1_m.tvalid = '0';

				if if_axis_in_m.tvalid then
					v.if_axis_in_s.tready := '1';
					if target_1_not_0 then
						v.target := out_1;
					else
						v.target := out_0;
					end if;
					v.fsm := forward;
				end if;

			when forward =>
				-- read not write
				assert if_axis_in_s.tready    = '1';
				assert if_axis_out_0_m.tvalid = '0';
				assert if_axis_out_1_m.tvalid = '0';

				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					if r.target = out_0 then
						v.if_axis_out_0_m := if_axis_in_m;
						v.if_axis_out_1_m := c_if_axis_frame_m_default;
					else
						v.if_axis_out_0_m := c_if_axis_frame_m_default;
						v.if_axis_out_1_m := if_axis_in_m;
					end if;
					v.if_axis_in_s.tready := '0';
					v.fsm                 := wait_read;
				end if;

			when wait_read =>
				-- write not read
				if r.target = out_0 then
					assert     if_axis_out_0_m.tvalid;
					assert not if_axis_out_1_m.tvalid;
				else
					assert not if_axis_out_0_m.tvalid;
					assert     if_axis_out_1_m.tvalid;
				end if;
				assert r.if_axis_in_s.tready = '0';

				if    (r.target = out_0 and if_axis_out_0_m.tvalid = '1' and if_axis_out_0_s.tready = '1')
				   or (r.target = out_1 and if_axis_out_1_m.tvalid = '1' and if_axis_out_1_s.tready = '1') then

					if r.target = out_0 then
						v.if_axis_out_0_m.tvalid := '0';
					else
						v.if_axis_out_1_m.tvalid := '0';
					end if;

					if    (r.target = out_0 and r.if_axis_out_0_m.tlast = '1')
					   or (r.target = out_1 and r.if_axis_out_1_m.tlast = '1') then
						v.if_axis_in_s.tready := '0';
						v.fsm := first;
					else
						v.if_axis_in_s.tready := '1';
						v.fsm := forward;
					end if;
				end if;
		end case;

		r_nxt <= v;
	end process;

	if_axis_in_s    <= r.if_axis_in_s;
	if_axis_out_0_m <= r.if_axis_out_0_m;
	if_axis_out_1_m <= r.if_axis_out_1_m;
end architecture;
