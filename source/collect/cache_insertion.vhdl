library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/*!
This module inserts new flows into the cache.

Incoming information is used to update existing IPFIX data records.
The quintuple of incoming frames is hashed and used as the address of the cache, which is a hash table.
A cache slot is read.
If the cache slot is empty, a new flow is created.
If the cache slot is used and the quintuples do not match, a collision occured and the collision counter is incremented.
If the matching flow was found, it is updated with the new frame length and a new timestamp.

configuration out:
* `collision_event`
 */
entity cache_insertion is
	generic(
		g_addr_width : natural;
		g_record_width : natural;
		g_frame_info_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m_tdata  : in  std_ulogic_vector(g_frame_info_width - 1 downto 0);
		if_axis_in_m_tvalid : in  std_ulogic;
		if_axis_in_s        : out t_if_axis_s;

		enable       : out std_ulogic;
		write_enable : out std_ulogic;
		addr         : out std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in      : out std_ulogic_vector(g_record_width - 1 downto 0);
		data_out     : in  std_ulogic_vector(g_record_width - 1 downto 0);

		cpu_collision_event : out std_ulogic
	);
end entity;

architecture arch of cache_insertion is
begin
end architecture;
