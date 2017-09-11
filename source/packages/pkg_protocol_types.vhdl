library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_common_subtypes.all;
use ipfix_exporter.pkg_config.all;

package pkg_protocol_types is
	constant c_protocol_udp : t_next_header := x"11";
	constant c_protocol_tcp : t_next_header := x"06";

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

	type t_ipfix_header is record
		version_number        : t_ipfix_version_number;
		length                : t_ipfix_length;
		export_time           : t_ipfix_export_time;
		sequence_number       : t_ipfix_sequence_number;
		observation_domain_id : t_ipfix_observation_domain_id;
	end record;
	constant c_ipfix_header_width : natural := 128;
	function to_std_ulogic_vector(ih : t_ipfix_header) return std_ulogic_vector;
	constant c_ipfix_header_default : t_ipfix_header := (
		version_number        => x"000A",
		length                => (others => '0'),
		export_time           => (others => '0'),
		sequence_number       => (others => '0'),
		observation_domain_id => (others => '0')
	);

	type t_ipfix_set_header is record
		set_id : t_ipfix_set_id;
		length : t_ipfix_length;
	end record;
	constant c_ipfix_set_header_width : natural := 32;
	function to_std_ulogic_vector(ih : t_ipfix_set_header) return std_ulogic_vector;
	constant c_ipfix_set_header_default : t_ipfix_set_header := (
		set_id => (others => '0'),
		length => (others => '0')
	);

	subtype t_partial_checksum is unsigned(15 downto 0);
	subtype t_checksum is std_ulogic_vector(15 downto 0);
	function partial_checksum(slv : std_ulogic_vector) return t_partial_checksum;
	function ipv4_header_checksum(ih : t_ipv4_header) return std_ulogic_vector;
	function udp_checksum(udp : t_udp_header;  partial : t_partial_checksum; cpu_ip_config : t_ip_config) return t_checksum;
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

	function to_std_ulogic_vector(ih : t_ipfix_header) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipfix_header_width - 1 downto 0) := (others => '0');
	begin
		ret(127 downto 112) := ih.version_number       ;
		ret(111 downto  96) := std_ulogic_vector(ih.length         );
		ret( 95 downto  64) := std_ulogic_vector(ih.export_time    );
		ret( 63 downto  32) := std_ulogic_vector(ih.sequence_number);
		ret( 31 downto   0) := ih.observation_domain_id;
		return ret;
	end;
	function to_std_ulogic_vector(ih : t_ipfix_set_header) return std_ulogic_vector is
		variable ret : std_ulogic_vector(c_ipfix_set_header_width - 1 downto 0) := (others => '0');
	begin
		ret(31 downto 16) := ih.set_id;
		ret(15 downto  0) := std_ulogic_vector(ih.length);
		return ret;
	end;

	function partial_checksum(slv : std_ulogic_vector) return t_partial_checksum is
		function carry_around_add(lhs, rhs: t_partial_checksum) return t_partial_checksum is
			-- additional carry bit
			variable ret : unsigned(16 downto 0) := (others => '0');
		begin
			assert lhs'length  = 16;
			assert rhs'length = 16;
			-- pad to get 17 bit result
			ret := ("0" & lhs) + rhs;
			-- add all carries
			while ret(16) loop
				ret := ("0" & ret(15 downto 0)) + ret(16);
			end loop;

			return ret(15 downto 0);
		end;

		alias    slv_rev  : std_ulogic_vector(slv'reverse_range) is slv;
		variable slv_copy : std_ulogic_vector(slv'length - 1 downto 0);

		variable ret : t_partial_checksum := (others => '0');
	begin
		-- slv'length is a multiple of 16
		assert (slv'length / 16) * 16 = slv'length;

		if slv'ascending then
			slv_copy := slv_rev;
		else
			slv_copy := slv;
		end if;

		for i in 0 to slv_copy'length / 16 - 1 loop
			ret := carry_around_add(ret, t_partial_checksum(slv_copy((i + 1) * 16 - 1 downto i * 16)));
		end loop;
		return ret;
	end;

	function ipv4_header_checksum(ih : t_ipv4_header) return std_ulogic_vector is
		variable copy : t_ipv4_header := ih;
	begin
		copy.header_checksum := (others => '0');
		return not std_ulogic_vector(partial_checksum(to_std_ulogic_vector(copy)));
	end;

	function udp_checksum(udp : t_udp_header;  partial : t_partial_checksum; cpu_ip_config : t_ip_config) return t_checksum is
		variable copy : t_udp_header := udp;
		variable full_checksum : t_partial_checksum := (others => '0');
	begin
		copy.checksum := (others => '0');
		if cpu_ip_config.version = x"6" then
			-- pseudo header
			full_checksum := partial_checksum(
				cpu_ip_config.ipv6_source_address
				& cpu_ip_config.ipv6_destination_address
				& std_ulogic_vector(udp.length)
				& x"00" & c_protocol_udp
				& to_std_ulogic_vector(copy)
				& std_ulogic_vector(partial));
		else
			full_checksum := partial_checksum(
				cpu_ip_config.ipv4_source_address
				& cpu_ip_config.ipv4_destination_address
				& x"00" & c_protocol_udp
				& std_ulogic_vector(udp.length)
				& to_std_ulogic_vector(copy)
				& std_ulogic_vector(partial));
		end if;
		if full_checksum = x"1111" then
			return std_ulogic_vector(full_checksum);
		else
			return not std_ulogic_vector(full_checksum);
		end if;
	end;
end package body;
