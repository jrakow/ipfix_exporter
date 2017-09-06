library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module drops frames originating from `ipfix_exporter`.

This opens the possibility to insert IPFIX messages in front of the collector without them being measured.

Incoming Ethernet frames are expected to start at the destination MAC address and end with transport layer payload. Network byte order is used.
Frames to be dropped are recognized by the source MAC address.
This module can be enabled / disabled by setting a flag in the configuration register.
If this module is disabled, all Ethernet frames are forwarded.

configuration in:
* `drop_source_mac_enable`
* `source_mac_address`
*/
entity selective_dropping is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_drop_source_mac_enable : in std_ulogic;
		cpu_ethernet_config        : in t_ethernet_config
	);
end entity;

architecture arch of selective_dropping is
	type t_fsm is (idle, dropping, forwarding);
	type t_reg is record
		fsm : t_fsm;

		-- output
		if_axis_in_s  : t_if_axis_s;
		if_axis_out_m : t_if_axis_frame_m;
	end record;
	constant c_reg_default : t_reg := (
		fsm             => idle,
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
	                 cpu_drop_source_mac_enable, cpu_ethernet_config,
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when idle =>
				v.if_axis_in_s.tready  := '1';
				v.if_axis_out_m.tvalid := '0';

				-- master may not change after tvalid
				if if_axis_in_m.tvalid then
					if cpu_drop_source_mac_enable = '1' and if_axis_in_m.tdata(79 downto 32) = cpu_ethernet_config.source then
						v.fsm := dropping;
					else
						-- forward ongoing transaction
						-- forwarding needs to start with either in ready or out valid
						-- start with out valid
						if if_axis_in_s.tready then
							v.if_axis_out_m := if_axis_in_m;
						end if;
						v.if_axis_in_s.tready := '0';
						v.fsm := forwarding;
					end if;
				end if;
			when dropping =>
				-- accept everything
				v.if_axis_in_s.tready  := '1';
				v.if_axis_out_m.tvalid := '0';

				-- until tlast
				if if_axis_in_m.tvalid and if_axis_in_m.tlast then
					v.fsm := idle;
				end if;

			when forwarding =>
				-- in transaction
				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					v.if_axis_in_s.tready := '0';
					-- especially out.valid := '1'
					v.if_axis_out_m       := if_axis_in_m;
				end if;

				-- out transaction
				if if_axis_out_m.tvalid and if_axis_out_s.tready then
					v.if_axis_in_s.tready  := '1';
					v.if_axis_out_m.tvalid := '0';

					-- end on tlast
					if if_axis_out_m.tlast then
						v.fsm := idle;
					end if;
				end if;
			end case;

		r_nxt <= v;
	end process;

	if_axis_in_s  <= r.if_axis_in_s;
	if_axis_out_m <= r.if_axis_out_m;
end architecture;
