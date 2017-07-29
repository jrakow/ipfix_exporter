library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

entity cache_extraction_ipv6 is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_out_m : out t_if_axis_ipv6_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of cache_extraction_ipv6 is
begin
end architecture;
