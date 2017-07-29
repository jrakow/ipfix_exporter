library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module combines the separate Ethernet frames from the IPv6 and the IPv4 data path into a single one.
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
begin
end architecture;
