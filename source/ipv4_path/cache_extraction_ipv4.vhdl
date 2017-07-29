library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module searches the cache for expired flows and exports these.

The cache, which is a hash table, is searched in linear order for expired flows.
A flows is expired, if the last frame is older than the inactive timeout or if the first frame is older than the active timeout.
Expired flows are put directly onto the AXIS interface.
`tkeep` and `tlast` are not used, because a whole data record is transported with each transaction.

This module is equivalent to @ref cache_extraction_ipv6.

@todo configuration in: `cache_active_timeout`, `cache_inactive_timeout`, `timestamp`
 */
entity cache_extraction_ipv4 is
	generic(
		g_addr_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		enable       : in  std_ulogic;
		write_enable : in  std_ulogic;
		addr         : in  std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in      : in  std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0);
		data_out     : out std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0);

		if_axis_out_m : out t_if_axis_ipv4_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of cache_extraction_ipv4 is
begin
end architecture;
