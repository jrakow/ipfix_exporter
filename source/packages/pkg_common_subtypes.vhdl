library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_common_subtypes is
	subtype t_ip_version          is std_ulogic_vector(  3 downto 0);
	subtype t_ipv6_addr           is std_ulogic_vector(127 downto 0);
	subtype t_ipv4_addr           is std_ulogic_vector( 31 downto 0);
	subtype t_ip_traffic_class    is std_ulogic_vector(  7 downto 0);
	subtype t_next_header         is std_ulogic_vector(  7 downto 0);
	subtype t_ipv6_flow_label     is std_ulogic_vector(19 downto 0);
	subtype t_ipv4_identification is std_ulogic_vector(15 downto 0);
	subtype t_ip_hop_limit        is std_ulogic_vector( 7 downto 0);

	subtype t_transport_port is std_ulogic_vector(15 downto 0);
	subtype t_tcp_flags      is std_ulogic_vector( 7 downto 0);
	subtype t_mac_addr       is std_ulogic_vector(47 downto 0);

	subtype t_udp_checksum is std_ulogic_vector(15 downto 0);

	subtype t_ip_length is unsigned(15 downto 0);

	subtype t_ipfix_version_number        is std_ulogic_vector(15 downto 0);
	subtype t_ipfix_export_time           is unsigned(31 downto 0);
	subtype t_ipfix_sequence_number       is unsigned(31 downto 0);
	subtype t_ipfix_observation_domain_id is std_ulogic_vector(31 downto 0);
	subtype t_ipfix_set_id                is std_ulogic_vector(15 downto 0);
	subtype t_ipfix_length                is unsigned(15 downto 0);

	subtype t_timeout is unsigned(15 downto 0);

	subtype t_timestamp         is unsigned(31 downto 0);
	subtype t_packet_count      is unsigned(31 downto 0);
	subtype t_octet_count       is unsigned(31 downto 0);
	subtype t_small_octet_count is unsigned(15 downto 0);

	constant c_number_of_vlans_width : natural := 2;
	subtype t_number_of_vlans is unsigned(c_number_of_vlans_width - 1 downto 0);
	subtype t_vlan_tag is std_ulogic_vector(31 downto 0);
end;
