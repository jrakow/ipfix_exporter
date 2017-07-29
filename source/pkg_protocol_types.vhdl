library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_protocol_types is
	subtype t_ipv6_addr           is std_ulogic_vector(127 downto 0);
	subtype t_ipv4_addr           is std_ulogic_vector( 31 downto 0);
	subtype t_ip_traffic_class    is std_ulogic_vector(  7 downto 0);
	subtype t_next_header         is std_ulogic_vector(  7 downto 0);
	subtype t_ipv6_flow_label     is std_ulogic_vector(19 downto 0);
	subtype t_ipv4_identification is std_ulogic_vector(15 downto 0);
	subtype t_ip_hop_limit        is std_ulogic_vector( 7 downto 0);
	constant c_protocol_udp : t_next_header := x"11";
	constant c_protocol_tcp : t_next_header := x"06";

	subtype t_transport_port is std_ulogic_vector(15 downto 0);
	subtype t_tcp_flags      is std_ulogic_vector( 7 downto 0);
	subtype t_mac_addr       is std_ulogic_vector(47 downto 0);

	subtype t_udp_checksum is std_ulogic_vector(15 downto 0);
	type t_udp_header is record
		source      : t_transport_port;
		destination : t_transport_port;
		length      : unsigned(15 downto 0);
		checksum    : t_udp_checksum;
	end record;
	constant c_udp_header_width : natural := 64;
	function to_udp_header(slv : std_ulogic_vector(c_udp_header_width - 1 downto 0)) return t_udp_header;
	function to_std_ulogic_vector(uh : t_udp_header) return std_ulogic_vector;
	constant c_udp_header_default : t_udp_header := (
		source      => (others => '0'),
		destination => (others => '0'),
		length      => (others => '0'),
		checksum    => (others => '0')
	);

	subtype t_ip_length is unsigned(15 downto 0);
	type t_ipv6_header is record
		version        : std_ulogic_vector(3 downto 0);
		traffic_class  : t_ip_traffic_class;
		flow_label     : t_ipv6_flow_label;
		payload_length : t_ip_length;
		next_header    : t_next_header;
		hop_limit      : t_ip_hop_limit;
		source         : t_ipv6_addr;
		destination    : t_ipv6_addr;
	end record;
	constant c_ipv6_header_width : natural := 320;
	function to_ipv6_header(slv : std_ulogic_vector(c_ipv6_header_width - 1 downto 0)) return t_ipv6_header;
	function to_std_ulogic_vector(ih : t_ipv6_header) return std_ulogic_vector;
	constant c_ipv6_header_default : t_ipv6_header := (
		version        => x"6",
		traffic_class  => (others => '0'),
		flow_label     => (others => '0'),
		payload_length => (others => '0'),
		next_header    => (others => '0'),
		hop_limit      => (others => '0'),
		source         => (others => '0'),
		destination    => (others => '0')
	);

	type t_ipv4_header is record
		version         : std_ulogic_vector(3 downto 0);
		ihl             : std_ulogic_vector(3 downto 0);
		traffic_class   : t_ip_traffic_class;
		total_length    : t_ip_length;
		identification  : t_ipv4_identification;
		flags           : std_ulogic_vector( 2 downto 0);
		fragment_offset : std_ulogic_vector(12 downto 0);
		time_to_live    : t_ip_hop_limit;
		protocol        : t_next_header;
		header_checksum : std_ulogic_vector(15 downto 0);
		source          : t_ipv4_addr;
		destination     : t_ipv4_addr;
	end record;
	constant c_ipv4_header_width : natural := 160;
	function to_ipv4_header(slv : std_ulogic_vector(c_ipv4_header_width - 1 downto 0)) return t_ipv4_header;
	function to_std_ulogic_vector(ih : t_ipv4_header) return std_ulogic_vector;
	constant c_ipv4_header_default : t_ipv4_header := (
		version         => x"4",
		ihl             => x"5",
		traffic_class   => (others => '0'),
		total_length    => (others => '0'),
		identification  => (others => '0'),
		flags           => (others => '0'),
		fragment_offset => (others => '0'),
		time_to_live    => (others => '0'),
		protocol        => (others => '0'),
		header_checksum => (others => '0'),
		source          => (others => '0'),
		destination     => (others => '0')
	);
end package;

package body pkg_protocol_types is
	function to_udp_header(slv : std_ulogic_vector(c_udp_header_width - 1 downto 0)) return t_udp_header is
		variable ret : t_udp_header := c_udp_header_default;
	begin
		ret.source      := slv(63 downto 48);
		ret.destination := slv(47 downto 32);
		ret.length      := unsigned(slv(31 downto 16));
		ret.checksum    := slv(15 downto  0);
		return ret;
	end;
	function to_std_ulogic_vector(uh : t_udp_header) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_udp_header_width - 1 downto 0) := (others => '0');
	begin
		ret(63 downto 48) := uh.source     ;
		ret(47 downto 32) := uh.destination;
		ret(31 downto 16) := std_ulogic_vector(uh.length);
		ret(15 downto  0) := uh.checksum   ;
		return ret;
	end;

	function to_ipv6_header(slv : std_ulogic_vector(c_ipv6_header_width - 1 downto 0)) return t_ipv6_header is
		variable ret : t_ipv6_header := c_ipv6_header_default;
	begin
		ret.version        := slv(319 downto 316);
		ret.traffic_class  := slv(315 downto 308);
		ret.flow_label     := slv(307 downto 288);
		ret.payload_length := unsigned(slv(287 downto 272));
		ret.next_header    := slv(271 downto 264);
		ret.hop_limit      := slv(263 downto 256);
		ret.source         := slv(255 downto 128);
		ret.destination    := slv(127 downto   0);
		return ret;
	end;
	function to_std_ulogic_vector(ih : t_ipv6_header) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipv6_header_width - 1 downto 0) := (others => '0');
	begin
		ret(319 downto 316) := ih.version       ;
		ret(315 downto 308) := ih.traffic_class ;
		ret(307 downto 288) := ih.flow_label    ;
		ret(287 downto 272) := std_ulogic_vector(ih.payload_length);
		ret(271 downto 264) := ih.next_header   ;
		ret(263 downto 256) := ih.hop_limit     ;
		ret(255 downto 128) := ih.source        ;
		ret(127 downto   0) := ih.destination   ;
		return ret;
	end;

	function to_ipv4_header(slv : std_ulogic_vector(c_ipv4_header_width - 1 downto 0)) return t_ipv4_header is
		variable ret : t_ipv4_header := c_ipv4_header_default;
	begin
		ret.version         := slv(159 downto 156);
		ret.ihl             := slv(155 downto 152);
		ret.traffic_class   := slv(151 downto 144);
		ret.total_length    := unsigned(slv(143 downto 128));
		ret.identification  := slv(127 downto 112);
		ret.flags           := slv(111 downto 109);
		ret.fragment_offset := slv(108 downto  96);
		ret.time_to_live    := slv( 95 downto  88);
		ret.protocol        := slv( 87 downto  80);
		ret.header_checksum := slv( 79 downto  64);
		ret.source          := slv( 63 downto  32);
		ret.destination     := slv( 31 downto   0);
		return ret;
	end;
	function to_std_ulogic_vector(ih : t_ipv4_header) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipv4_header_width - 1 downto 0) := (others => '0');
	begin
		ret(159 downto 156) := ih.version        ;
		ret(155 downto 152) := ih.ihl            ;
		ret(151 downto 144) := ih.traffic_class  ;
		ret(143 downto 128) := std_ulogic_vector(ih.total_length);
		ret(127 downto 112) := ih.identification ;
		ret(111 downto 109) := ih.flags          ;
		ret(108 downto  96) := ih.fragment_offset;
		ret( 95 downto  88) := ih.time_to_live   ;
		ret( 87 downto  80) := ih.protocol       ;
		ret( 79 downto  64) := ih.header_checksum;
		ret( 63 downto  32) := ih.source         ;
		ret( 31 downto   0) := ih.destination    ;
		return ret;
	end;
end package body;
