library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module provides a CPU interface to the `ipfix_exporter`.

The CPU interface is a simple memory mapping with a single data channel.
For a write transaction the CPU sets the `address` and `write_enable` signals as well as the data to be written on `data_out`.
For a read transaction the `address`, `read_enable` and `data_in` signals are considered.
If the CPU reads from a valid address, the `read_valid` signal is set.
Else it is reset.

See [CPU interface](doc/cpu_interface.md) for the registers provided.
 */
entity cpu_interface is
	generic(
		g_cpu_data_width : natural := 32;
		g_cpu_addr_width : natural := 32
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		read_enable  : in  std_ulogic;
		write_enable : in  std_ulogic_vector;
		data_in      : in  std_ulogic_vector;
		data_out     : out std_ulogic_vector;
		address      : in  std_ulogic_vector;
		read_valid   : out std_ulogic;

		drop_source_mac_enable : std_ulogic;
		timestamp              : t_timestamp;
		collision_event_ipv6   : std_ulogic;
		collision_event_ipv4   : std_ulogic;
		cache_active_timeout   : t_timeout;
		cache_inactive_timeout : t_timeout;
		ipfix_message_timeout  : t_timeout;
		ipfix_config_ipv6      : t_ipfix_config;
		ipfix_config_ipv4      : t_ipfix_config;
		udp_config             : t_udp_config;
		ip_config              : t_ip_config;
		vlan_config            : t_vlan_config;
		ethernet_config        : t_ethernet_config
	);
end entity;

architecture arch of cpu_interface is
begin

end architecture;
