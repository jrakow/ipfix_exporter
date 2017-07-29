library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module extracts flow information from the incoming Ethernet frame and fills an IPFIX data record.

The extracted information includes the quintuple use for identifying the flow and additional information (see [data types](doc/data_types.md)).
The output format is the IPFIX data record data type for the IP version six.
See also @ref information_extraction_ipv4 which is equivalent.

@todo configuration in: `timestamp`
 */
entity information_extraction_ipv6 is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_ipv6_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of information_extraction_ipv6 is
begin
end architecture;
