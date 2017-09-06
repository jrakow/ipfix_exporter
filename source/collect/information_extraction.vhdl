library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module extracts flow information from the incoming Ethernet frame and fills an IPFIX data record.

The extracted information includes the quintuple use for identifying the flow and additional information (see [data types](doc/data_types.md)).
The output format is @ref t_ipv6_frame_info or @ref t_ipv4_frame_info for the IP version.

configuration in:
* `timestamp`
 */
entity information_extraction is
	generic(
		g_frame_info_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m_tdata  : out std_ulogic_vector(g_frame_info_width - 1 downto 0);
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s        : in  t_if_axis_s;

		cpu_timestamp : in t_timestamp
	);
end entity;

architecture arch of information_extraction is
begin
end architecture;
