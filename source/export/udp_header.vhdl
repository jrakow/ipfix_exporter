library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module prefixes an arbitrary payload with an UDP header.

This module buffers a whole packet.
While buffering the length and checksum are computed.
This module does not use information from the payload.

The IP version may be set at runtime.

configuration in:
* `ip_version`
* `ipvN_source_address`
* `ipvN_destination_address`
* `source_port`
* `destination_port`
 */
entity udp_header is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_udp_config : in t_udp_config;
		cpu_ip_config  : in t_ip_config
	);
end entity;

architecture arch of udp_header is
begin
end architecture;
