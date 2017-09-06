library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_common_subtypes.all;
use ipfix_exporter.pkg_ipfix_data_record.all;
use ipfix_exporter.pkg_protocol_types.all;

--! data types and conversion functions
package pkg_types is
	constant c_reset_active       : std_ulogic := '1';

	constant c_number_of_counters_preparation : natural := 3;
	constant c_number_of_counters_collect     : natural := 5;
	constant c_number_of_counters_export      : natural := 6;
	constant c_number_of_counters             : natural := c_number_of_counters_preparation
	                                                       + 2 * (c_number_of_counters_collect + c_number_of_counters_export)
	                                                       + 1; -- combined output frames

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

	/**
	 * output of @ref information_extraction
	 *
	 * This type contains most of the fields of an @ref t_ipfix_ipv6_data_record.
	 * As not all fields of it are used, this type is used instead.
	 */
	type t_ipv6_frame_info is record
		src_ip_addr   : t_ipv6_addr;
		dest_ip_addr  : t_ipv6_addr;
		src_port      : t_transport_port;
		dest_port     : t_transport_port;
		timestamp     : t_timestamp;
		octet_count   : t_small_octet_count;
		next_header   : t_next_header;
		traffic_class : t_ip_traffic_class;
		tcp_flags     : t_tcp_flags;
	end record;
	constant c_ipv6_frame_info_width : natural := 2 * 128 + 2 * 16 + 32 + 16 + 3 * 8;
	function to_std_ulogic_vector(fi : t_ipv6_frame_info) return std_ulogic_vector;
	function to_ipv6_frame_info(slv : std_ulogic_vector) return t_ipv6_frame_info;
	constant c_ipv6_frame_info_default : t_ipv6_frame_info := (
		src_ip_addr   => (others => '0'),
		dest_ip_addr  => (others => '0'),
		src_port      => (others => '0'),
		dest_port     => (others => '0'),
		timestamp     => (others => '0'),
		octet_count   => (others => '0'),
		next_header   => (others => '0'),
		traffic_class => (others => '0'),
		tcp_flags     => (others => '0')
	);

	/**
	 * output of @ref information_extraction
	 *
	 * This type contains most of the fields of an @ref t_ipfix_ipv4_data_record.
	 * As not all fields of it are used, this type is used instead.
	 */
	type t_ipv4_frame_info is record
		src_ip_addr   : t_ipv4_addr;
		dest_ip_addr  : t_ipv4_addr;
		src_port      : t_transport_port;
		dest_port     : t_transport_port;
		timestamp     : t_timestamp;
		octet_count   : t_small_octet_count;
		next_header   : t_next_header;
		traffic_class : t_ip_traffic_class;
		tcp_flags     : t_tcp_flags;
	end record;
	constant c_ipv4_frame_info_width : natural := 2 * 32 + 2 * 16 + 32 + 16 + 3 * 8;
	function to_std_ulogic_vector(fi : t_ipv4_frame_info) return std_ulogic_vector;
	function to_ipv4_frame_info(slv : std_ulogic_vector) return t_ipv4_frame_info;
	constant c_ipv4_frame_info_default : t_ipv4_frame_info := (
		src_ip_addr   => (others => '0'),
		dest_ip_addr  => (others => '0'),
		src_port      => (others => '0'),
		dest_port     => (others => '0'),
		timestamp     => (others => '0'),
		octet_count   => (others => '0'),
		next_header   => (others => '0'),
		traffic_class => (others => '0'),
		tcp_flags     => (others => '0')
	);

	/**
	 * check a condition like `assert`
	 *
	 * This is equivalent to normal `assert`.
	 * However this procedure may be called with a static condition.
	 * Failing is delayed until run.
	 */
	procedure static_assert(b : in boolean; s : in string; f : in severity_level);

	-- safe IP packet total length : 1500 bytes
	constant c_ipfix_message_max_length  : natural := 1500 - 40 - 8;
	constant c_ipv6_ipfix_records_per_message : natural := (c_ipfix_message_max_length - 20) * 8 / c_ipfix_ipv6_data_record_width;
	constant c_ipv4_ipfix_records_per_message : natural := (c_ipfix_message_max_length - 20) * 8 / c_ipfix_ipv4_data_record_width;
end package;

package body pkg_types is
	function to_std_ulogic_vector(fi : t_ipv6_frame_info) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipv6_frame_info_width - 1 downto 0) := (others => '0');
	begin
		ret(359 downto 232) := fi.src_ip_addr  ;
		ret(231 downto 104) := fi.dest_ip_addr ;
		ret(103 downto  88) := fi.src_port     ;
		ret( 87 downto  72) := fi.dest_port    ;
		ret( 71 downto  40) := std_ulogic_vector(fi.timestamp  );
		ret( 39 downto  24) := std_ulogic_vector(fi.octet_count);
		ret( 23 downto  16) := fi.next_header  ;
		ret( 15 downto   8) := fi.traffic_class;
		ret(  7 downto   0) := fi.tcp_flags    ;
		return ret;
	end;

	function to_ipv6_frame_info(slv : std_ulogic_vector) return t_ipv6_frame_info is
		variable ret : t_ipv6_frame_info := c_ipv6_frame_info_default;
	begin
		ret.src_ip_addr   := slv(359 downto 232);
		ret.dest_ip_addr  := slv(231 downto 104);
		ret.src_port      := slv(103 downto  88);
		ret.dest_port     := slv( 87 downto  72);
		ret.timestamp     := unsigned(slv( 71 downto  40));
		ret.octet_count   := unsigned(slv( 39 downto  24));
		ret.next_header   := slv( 23 downto  16);
		ret.traffic_class := slv( 15 downto   8);
		ret.tcp_flags     := slv(  7 downto   0);
		return ret;
	end;

	function to_std_ulogic_vector(fi : t_ipv4_frame_info) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipv4_frame_info_width - 1 downto 0) := (others => '0');
	begin
		ret(167 downto 136) := fi.src_ip_addr  ;
		ret(135 downto 104) := fi.dest_ip_addr ;
		ret(103 downto  88) := fi.src_port     ;
		ret( 87 downto  72) := fi.dest_port    ;
		ret( 71 downto  40) := std_ulogic_vector(fi.timestamp  );
		ret( 39 downto  24) := std_ulogic_vector(fi.octet_count);
		ret( 23 downto  16) := fi.next_header  ;
		ret( 15 downto   8) := fi.traffic_class;
		ret(  7 downto   0) := fi.tcp_flags    ;
		return ret;
	end;

	function to_ipv4_frame_info(slv : std_ulogic_vector) return t_ipv4_frame_info is
		variable ret : t_ipv4_frame_info := c_ipv4_frame_info_default;
	begin
		ret.src_ip_addr   := slv(167 downto 136);
		ret.dest_ip_addr  := slv(135 downto 104);
		ret.src_port      := slv(103 downto  88);
		ret.dest_port     := slv( 87 downto  72);
		ret.timestamp     := unsigned(slv( 71 downto  40));
		ret.octet_count   := unsigned(slv( 39 downto  24));
		ret.next_header   := slv( 23 downto  16);
		ret.traffic_class := slv( 15 downto   8);
		ret.tcp_flags     := slv(  7 downto   0);
		return ret;
	end;

	procedure static_assert(b : in boolean; s : in string; f : in severity_level) is
	begin
		assert b
			report s
			severity f;
	end procedure;
end package body;
