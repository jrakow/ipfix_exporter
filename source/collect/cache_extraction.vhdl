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

configuration in:
* `cache_active_timeout`
* `cache_inactive_timeout`
* `timestamp`
 */
entity cache_extraction is
	generic(
		g_addr_width  : natural;
		g_record_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		enable       : in  std_ulogic;
		write_enable : in  std_ulogic;
		addr         : in  std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in      : in  std_ulogic_vector(g_record_width - 1 downto 0);
		data_out     : out std_ulogic_vector(g_record_width - 1 downto 0);

		if_axis_out_m_tdata  : out std_ulogic_vector(g_record_width - 1 downto 0);
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s        : in  t_if_axis_s;

		cpu_cache_active_timeout   : in t_timeout;
		cpu_cache_inactive_timeout : in t_timeout;
		cpu_timestamp              : in t_timestamp
	);
end entity;

architecture arch of cache_extraction is
begin
	static_assert(g_record_width = c_ipfix_ipv6_data_record_width or g_record_width = c_ipfix_ipv4_data_record_width, "g_record_width is not a record width", failure);
end architecture;
