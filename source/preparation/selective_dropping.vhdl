library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
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
begin
end architecture;
