library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
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
	signal s_frame_is_dropped : std_ulogic;
begin
	p_condition : process(all)
	begin
		if cpu_drop_source_mac_enable = '1' and if_axis_in_m.tdata(79 downto 32) = cpu_ethernet_config.source then
			s_frame_is_dropped <= '1';
		else
			s_frame_is_dropped <= '0';
		end if;
	end process;

	i_conditional_split : entity ipfix_exporter.conditional_split
		port map(
			clk             => clk,
			rst             => rst,

			target_1_not_0  => s_frame_is_dropped,

			if_axis_in_m    => if_axis_in_m,
			if_axis_in_s    => if_axis_in_s,

			if_axis_out_0_m => if_axis_out_m,
			if_axis_out_0_s => if_axis_out_s,

			-- all those frames are dropped
			if_axis_out_1_m => open,
			if_axis_out_1_s => ( tready => '1' )
		);
end architecture;
