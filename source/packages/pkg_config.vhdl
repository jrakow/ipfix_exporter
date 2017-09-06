library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_common_subtypes.all;

package pkg_config is
	type t_ipfix_config is record
		template_id           : t_ipfix_set_id;
		observation_domain_id : t_ipfix_observation_domain_id;
	end record;
	constant c_ipfix_config_default : t_ipfix_config := (
		template_id           => (others => '0'),
		observation_domain_id => (others => '0')
	);

	type t_udp_config is record
		source      : t_transport_port;
		destination : t_transport_port;
	end record;
	constant c_udp_config_default : t_udp_config := (
		source      => (others => '0'),
		destination => (others => '0')
	);

	type t_ip_config is record
		version                  : t_ip_version;
		ipv6_source_address      : t_ipv6_addr;
		ipv6_destination_address : t_ipv6_addr;
		ipv4_source_address      : t_ipv4_addr;
		ipv4_destination_address : t_ipv4_addr;
		traffic_class            : t_ip_traffic_class;
		ipv6_flow_label          : t_ipv6_flow_label;
		ipv4_identification      : t_ipv4_identification;
		hop_limit                : t_ip_hop_limit;
	end record;
	constant c_ip_config_default : t_ip_config := (
		version                  => x"6",
		ipv6_source_address      => (others => '0'),
		ipv6_destination_address => (others => '0'),
		ipv4_source_address      => (others => '0'),
		ipv4_destination_address => (others => '0'),
		traffic_class            => (others => '0'),
		ipv6_flow_label          => (others => '0'),
		ipv4_identification      => (others => '0'),
		hop_limit                => (others => '0')
	);

	type t_vlan_config is record
		number_of_vlans : t_number_of_vlans;
		tag_0           : t_vlan_tag;
		tag_1           : t_vlan_tag;
	end record;
	constant c_vlan_config_default : t_vlan_config := (
		number_of_vlans => (others => '0'),
		tag_0           => (others => '0'),
		tag_1           => (others => '0')
	);

	type t_ethernet_config is record
		destination : t_mac_addr;
		source      : t_mac_addr;
	end record;
	constant c_ethernet_config_default : t_ethernet_config := (
		destination => (others => '0'),
		source      => (others => '0')
	);
end;
