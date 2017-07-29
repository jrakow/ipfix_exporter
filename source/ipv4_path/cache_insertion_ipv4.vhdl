library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

entity cache_insertion_ipv4 is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_ipv4_m;
		if_axis_in_s : out t_if_axis_s
	);
end entity;

architecture arch of cache_insertion_ipv4 is
begin
end architecture;
