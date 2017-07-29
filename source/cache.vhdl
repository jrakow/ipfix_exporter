library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module is a generic block RAM used as cache for active flows.
 */
entity cache is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic
	);
end entity;

architecture arch of cache is
begin
end architecture;
