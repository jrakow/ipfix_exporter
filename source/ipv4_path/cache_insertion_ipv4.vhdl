library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module inserts new flows into the cache.

The quintuple of incoming frames is hashed and used as the address of the cache, which is a hash table.
A cache slot is read.
If the cache slot is empty, a new flow is created.
If the cache slot is used and the quintuples do not match, a collision occured and the collision counter is incremented.
If the matching flow was found, it is updated with the new frame length and a new timestamp.

This is equivalent to @ref cache_insertion_ipv6.

@todo configuration out: `collision_counter`
 */
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
