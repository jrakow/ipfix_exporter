library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module drops the Ethernet header.

Up to three VLAN tags are supported.
The output IP packet starts at the IP header.
MAC addresses, VLAN tags and the Ethertype field are dropped.
 */
entity ethernet_dropping is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of ethernet_dropping is
begin
end architecture;
