library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module generates an IPFIX header for an incoming stream of IPFIX sets.

The sequence number is kept track of.
For the length field the length field of the set header is used.

Multiple sets in a single message are not supported.
A new header is prefixed for every set.
The whole IPFIX message is forwarded.

configuration in:
* `ipfix_observation_domain_id`
* `timestamp`
 */
entity ipfix_header is
	generic(
		g_ip_version : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_ipfix_config : in t_ipfix_config;
		cpu_timestamp    : in t_timestamp
	);
end entity;

architecture arch of ipfix_header is
begin
end architecture;
