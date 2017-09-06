library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module combines the frames from two AXI streams into a single one.
 */
entity axis_combiner is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m_0 : in  t_if_axis_frame_m;
		if_axis_in_s_0 : out t_if_axis_s;

		if_axis_in_m_1 : in  t_if_axis_frame_m;
		if_axis_in_s_1 : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of axis_combiner is
	type t_switch is (in_0, in_1);
	type t_fsm is (init, forward);
	type t_reg is record
		switch : t_switch;
		fsm    : t_fsm;
	end record;
	constant c_reg_default : t_reg := (
		switch => in_0,
		fsm    => init
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

	p_comb : process(if_axis_in_m_0, if_axis_in_m_1, if_axis_out_s, r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when init =>
				if if_axis_in_m_0.tvalid then
					v.switch := in_0;
					v.fsm := forward;
				elsif if_axis_in_m_1.tvalid then
					v.switch := in_1;
					v.fsm := forward;
				end if;

			when forward =>
				if r.switch = in_0 and if_axis_in_m_0.tvalid = '1' and if_axis_in_m_0.tlast = '1' and if_axis_in_s_0.tready = '1' then
					-- last frame on in_0
					-- switch if other is valid
					if if_axis_in_m_1.tvalid then
						v.switch := in_1;
					end if;
				elsif r.switch = in_1 and if_axis_in_m_1.tvalid = '1' and if_axis_in_m_1.tlast = '1' and if_axis_in_s_1.tready = '1' then
					-- last frame on in_1
					-- switch if other is valid
					if if_axis_in_m_0.tvalid then
						v.switch := in_1;
					end if;
				end if;
			end case;

		r_nxt <= v;
	end process;

	-- switch outputs directly
	if_axis_in_s_0.tready <= if_axis_out_s.tready when r.switch = in_0 else '0';
	if_axis_in_s_1.tready <= if_axis_out_s.tready when r.switch = in_1 else '0';
	if_axis_out_m         <= if_axis_in_m_0       when r.switch = in_0 else if_axis_in_m_1;

end architecture;
