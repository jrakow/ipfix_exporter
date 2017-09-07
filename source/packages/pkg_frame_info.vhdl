library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_common_subtypes.all;

package pkg_frame_info is
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

	function get_ip_version_from_frame_info_width(width : natural) return positive;
end;

package body pkg_frame_info is
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

	function get_ip_version_from_frame_info_width(width : natural) return positive is
	begin
		if width = c_ipv6_frame_info_width then
			return 6;
		else
			return 4;
		end if;
	end function;
end;
