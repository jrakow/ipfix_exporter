library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

entity ip_version_split is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_ipv6_m : out t_if_axis_frame_m;
		if_axis_out_ipv6_s : in  t_if_axis_s;

		if_axis_out_ipv4_m : out t_if_axis_frame_m;
		if_axis_out_ipv4_s : in  t_if_axis_s
	);
end entity;

architecture arch of ip_version_split is
begin
end architecture;
