library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module prefixes an IPv6 or IPv4 header.

The IP version may be set at runtime.

configuration in:
* `ip_version`
* `ip_traffic_class`
* `ipv6_flow_label`
* `ipv4_identification`
* `hop_limit`
* `ipv6_source_address`
* `ipv6_destination_address`
* `ipv4_source_address`
* `ipv4_destination_address`
 */
entity ip_header is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_ip_config : in t_ip_config
	);
end entity;

architecture arch of ip_header is
begin
end architecture;
