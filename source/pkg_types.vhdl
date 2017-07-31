library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_protocol_types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! data types and conversion functions
package pkg_types is
	constant c_reset_active       : std_ulogic := '1';

	constant c_number_of_counters_preparation : natural := 3;
	constant c_number_of_counters_collect     : natural := 4;
	constant c_number_of_counters_export      : natural := 7;
	constant c_number_of_counters             : natural := c_number_of_counters_preparation
	                                                       + 2 * (c_number_of_counters_collect + c_number_of_counters_export)
	                                                       + 1; -- combined output frames

	subtype t_timeout is unsigned(15 downto 0);

	subtype t_timestamp         is unsigned(31 downto 0);
	subtype t_packet_count      is unsigned(31 downto 0);
	subtype t_octet_count       is unsigned(31 downto 0);
	subtype t_small_octet_count is unsigned(15 downto 0);

	constant c_number_of_vlans_width : natural := 2;
	subtype t_number_of_vlans is unsigned(c_number_of_vlans_width - 1 downto 0);
	subtype t_vlan_tag is std_ulogic_vector(31 downto 0);

	/**
	 * IPFIX data record with information about an IPv6 flow
	 *
	 * | element ID | length | name                     |
	 * | ---------: | -----: | ------------------------ |
	 * |         27 |     16 | sourceIPv6Address        |
	 * |         28 |     16 | destinationIPv6Address   |
	 * |          7 |      2 | sourceTransportPort      |
	 * |         11 |      2 | destinationTransportPort |
	 * |        150 |      4 | flowStartSeconds         |
	 * |        151 |      4 | flowEndSeconds           |
	 * |          1 |      4 | octetDeltaCount          |
	 * |          2 |      4 | packetDeltaCount         |
	 * |          4 |      1 | protocolIdentifier       |
	 * |          5 |      1 | ipClassOfService         |
	 * |          6 |      1 | tcpControlBits           |
	 * |        210 |      9 | paddingOctets            |
	 * |            |     64 | *total*                  |
	 */
	type t_ipfix_ipv6_data_record is record
		src_ip_addr   : t_ipv6_addr;
		dest_ip_addr  : t_ipv6_addr;
		src_port      : t_transport_port;
		dest_port     : t_transport_port;
		start_time    : t_timestamp;
		end_time      : t_timestamp;
		octet_count   : t_octet_count;
		packet_count  : t_packet_count;
		next_header   : t_next_header;
		traffic_class : t_ip_traffic_class;
		tcp_flags     : t_tcp_flags;
		padding       : std_ulogic_vector(71 downto 0);
	end record;
	constant c_ipfix_ipv6_data_record_width : natural := 2 * 128 + 2 * 16 + 2 * 32 + 2 * 32 + 8 + 8 + 8 + 72;
	function to_std_ulogic_vector(dr : t_ipfix_ipv6_data_record) return std_ulogic_vector;
	function to_ipfix_ipv6_data_record(slv : std_ulogic_vector(c_ipfix_ipv6_data_record_width - 1 downto 0)) return t_ipfix_ipv6_data_record;
	constant c_ipfix_ipv6_data_record_default : t_ipfix_ipv6_data_record := (
		src_ip_addr   => (others => '0'),
		dest_ip_addr  => (others => '0'),
		src_port      => (others => '0'),
		dest_port     => (others => '0'),
		start_time    => (others => '0'),
		end_time      => (others => '0'),
		octet_count   => (others => '0'),
		packet_count  => (others => '0'),
		next_header   => (others => '0'),
		traffic_class => (others => '0'),
		tcp_flags     => (others => '0'),
		padding       => (others => '0')
	);

	/**
	 * IPFIX data record with information about an IPv4 flow
	 *
	 * | element ID | length | name                     |
	 * | ---------: | -----: | ------------------------ |
	 * |          8 |      4 | sourceIPv4Address        |
	 * |         12 |      4 | destinationIPv4Address   |
	 * |          7 |      2 | sourceTransportPort      |
	 * |         11 |      2 | destinationTransportPort |
	 * |        150 |      4 | flowStartSeconds         |
	 * |        151 |      4 | flowEndSeconds           |
	 * |          1 |      4 | octetDeltaCount          |
	 * |          2 |      4 | packetDeltaCount         |
	 * |          4 |      1 | protocolIdentifier       |
	 * |          5 |      1 | ipClassOfService         |
	 * |          6 |      1 | tcpControlBits           |
	 * |        210 |      1 | paddingOctets            |
	 * |            |     32 | *total*                  |
	*/
	type t_ipfix_ipv4_data_record is record
		src_ip_addr   : t_ipv4_addr;
		dest_ip_addr  : t_ipv4_addr;
		src_port      : t_transport_port;
		dest_port     : t_transport_port;
		start_time    : t_timestamp;
		end_time      : t_timestamp;
		octet_count   : t_octet_count;
		packet_count  : t_packet_count;
		next_header   : t_next_header;
		traffic_class : t_ip_traffic_class;
		tcp_flags     : t_tcp_flags;
		padding       : std_ulogic_vector(7 downto 0);
	end record;
	constant c_ipfix_ipv4_data_record_width   : natural := 2 * 32 + 2 * 16 + 2 * 32 + 2 * 32 + 8 + 8 + 8 + 8;
	function to_std_ulogic_vector(v4 : t_ipfix_ipv4_data_record) return std_ulogic_vector;
	function to_ipfix_ipv4_data_record(slv : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0)) return t_ipfix_ipv4_data_record;
	constant c_ipfix_ipv4_data_record_default : t_ipfix_ipv4_data_record := (
		src_ip_addr   => (others => '0'),
		dest_ip_addr  => (others => '0'),
		src_port      => (others => '0'),
		dest_port     => (others => '0'),
		next_header   => (others => '0'),
		start_time    => (others => '0'),
		end_time      => (others => '0'),
		packet_count  => (others => '0'),
		octet_count   => (others => '0'),
		tcp_flags     => (others => '0'),
		traffic_class => (others => '0'),
		padding       => (others => '0')
	);

	--! AXI stream master interface
	type t_if_axis_frame_m is record
		tvalid : std_ulogic;
		tdata  : std_ulogic_vector(127 downto 0);
		tkeep  : std_ulogic_vector(15  downto 0);
		tlast  : std_ulogic;
	end record;
	constant c_if_axis_frame_m_default : t_if_axis_frame_m := (
		tvalid => '0',
		tdata  => (others => '0'),
		tkeep  => (others => '0'),
		tlast  => '0'
	);

	--! AXI stream slave interface
	type t_if_axis_s is record
		tready : std_ulogic;
	end record;
	constant c_if_axis_s_default : t_if_axis_s := (
		tready => '0'
	);

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
	 * convert a number of bytes to a std_ulogic_vector
	 *
	 * @param number of valid bytes in tdata
	 * @param tkeep_width width of return tkeep std_ulogic_vector
	 * @return filled with n `'1'`s from the left
	 */
	function to_tkeep(n : positive; tkeep_width : natural) return std_ulogic_vector;

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
	function to_std_ulogic_vector(dr : t_ipfix_ipv6_data_record) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipfix_ipv6_data_record_width - 1 downto 0) := (others => '0');
	begin
		ret(511 downto 384) :=                   dr.src_ip_addr  ;
		ret(383 downto 256) :=                   dr.dest_ip_addr ;
		ret(255 downto 240) :=                   dr.src_port     ;
		ret(239 downto 224) :=                   dr.dest_port    ;
		ret(223 downto 192) := std_ulogic_vector(dr.start_time  );
		ret(191 downto 160) := std_ulogic_vector(dr.end_time    );
		ret(159 downto 128) := std_ulogic_vector(dr.octet_count );
		ret(127 downto  96) := std_ulogic_vector(dr.packet_count);
		ret( 95 downto  88) :=                   dr.next_header  ;
		ret( 87 downto  80) :=                   dr.traffic_class;
		ret( 79 downto  72) :=                   dr.tcp_flags    ;
		ret( 71 downto   0) :=                   (others => '0') ;
		return ret;
	end;

	function to_ipfix_ipv6_data_record(slv : std_ulogic_vector(c_ipfix_ipv6_data_record_width - 1 downto 0)) return t_ipfix_ipv6_data_record is
		variable ret : t_ipfix_ipv6_data_record := c_ipfix_ipv6_data_record_default;
	begin
		ret.src_ip_addr   :=          slv(511 downto 384);
		ret.dest_ip_addr  :=          slv(383 downto 256);
		ret.src_port      :=          slv(255 downto 240);
		ret.dest_port     :=          slv(239 downto 224);
		ret.start_time    := unsigned(slv(223 downto 192));
		ret.end_time      := unsigned(slv(191 downto 160));
		ret.octet_count   := unsigned(slv(159 downto 128));
		ret.packet_count  := unsigned(slv(127 downto  96));
		ret.next_header   :=          slv( 95 downto  88);
		ret.traffic_class :=          slv( 87 downto  80);
		ret.tcp_flags     :=          slv( 79 downto  72);
		ret.padding       :=          slv( 71 downto   0);
		return ret;
	end;

	function to_std_ulogic_vector(v4 : t_ipfix_ipv4_data_record) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0) := (others => '0');
	begin
		ret(255 downto 224) :=                   v4.src_ip_addr  ;
		ret(223 downto 192) :=                   v4.dest_ip_addr ;
		ret(191 downto 176) :=                   v4.src_port     ;
		ret(175 downto 160) :=                   v4.dest_port    ;
		ret(159 downto 128) := std_ulogic_vector(v4.start_time   );
		ret(127 downto  96) := std_ulogic_vector(v4.end_time     );
		ret( 95 downto  64) := std_ulogic_vector(v4.octet_count  );
		ret( 63 downto  32) := std_ulogic_vector(v4.packet_count );
		ret( 31 downto  24) :=                   v4.next_header  ;
		ret( 23 downto  16) :=                   v4.traffic_class;
		ret( 15 downto   8) :=                   v4.tcp_flags    ;
		ret(  7 downto   0) :=                   v4.padding      ;
		return ret;
	end;
	function to_ipfix_ipv4_data_record(slv : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0)) return t_ipfix_ipv4_data_record is
		variable ret : t_ipfix_ipv4_data_record := c_ipfix_ipv4_data_record_default;
	begin
		ret.src_ip_addr   :=          slv(255 downto 224);
		ret.dest_ip_addr  :=          slv(223 downto 192);
		ret.src_port      :=          slv(191 downto 176);
		ret.dest_port     :=          slv(175 downto 160);
		ret.start_time    := unsigned(slv(159 downto 128));
		ret.end_time      := unsigned(slv(127 downto  96));
		ret.octet_count   := unsigned(slv( 95 downto  64));
		ret.packet_count  := unsigned(slv( 63 downto  32));
		ret.next_header   :=          slv( 31 downto  24);
		ret.traffic_class :=          slv( 23 downto  16);
		ret.tcp_flags     :=          slv( 15 downto   8);
		ret.padding       :=          slv(  7 downto   0);
		return ret;
	end;

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

	function to_tkeep(n : positive; tkeep_width : natural) return std_ulogic_vector is
		variable ret : std_ulogic_vector(tkeep_width - 1 downto 0) := (others => '0');
	begin
		assert n <= tkeep_width;
		for i in 0 to tkeep_width - 1 loop
			ret(tkeep_width - i - 1) := '1';
			if i >= n then
				return ret;
			end if;
		end loop;
		return ret;
	end;

	procedure static_assert(b : in boolean; s : in string; f : in severity_level) is
	begin
		assert b
			report s
			severity f;
	end procedure;
end package body;
