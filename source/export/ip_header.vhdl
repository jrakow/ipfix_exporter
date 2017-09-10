library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module prefixes an IPv6 or IPv4 header.

The IP version may be set at runtime.

configuration in:
* `ip_version`
* `ip_traffic_class`
* `ipv6_flow_label`
* `ipv4_identification`
* `hop_limit`
* `ipv6_source_address`
* `ipv6_destination_address`
* `ipv4_source_address`
* `ipv4_destination_address`
 */
entity ip_header is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_ip_config : in t_ip_config
	);
end entity;

architecture arch of ip_header is
	signal s_if_axis_ipv6_m_0 : t_if_axis_frame_m;
	signal s_if_axis_ipv6_s_0 : t_if_axis_s      ;
	signal s_if_axis_ipv6_m_1 : t_if_axis_frame_m;
	signal s_if_axis_ipv6_s_1 : t_if_axis_s      ;
	signal s_if_axis_ipv4_m_0 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_0 : t_if_axis_s      ;
	signal s_if_axis_ipv4_m_1 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_1 : t_if_axis_s      ;

	-- stream is ipv6 else ipv4
	signal s_ipv6_not_ipv4 : std_ulogic;

	signal s_ipv6_header   : t_ipv6_header := c_ipv6_header_default;
	signal s_ipv4_header   : t_ipv4_header := c_ipv4_header_default;

	signal s_hold_ipv6_header : std_ulogic;
	signal s_hold_ipv4_header : std_ulogic;

	signal s_udp_header_ipv6_path : t_udp_header;
	signal s_udp_header_ipv4_path : t_udp_header;
begin
	s_ipv6_not_ipv4 <= '1' when cpu_ip_config.version = x"6" else '0';

	process(clk)
	begin
		if rising_edge(clk) then
			s_hold_ipv6_header <= s_if_axis_ipv6_m_0.tvalid and not s_if_axis_ipv6_m_0.tlast;
			s_hold_ipv4_header <= s_if_axis_ipv4_m_0.tvalid and not s_if_axis_ipv4_m_0.tlast;
		end if;
	end process;

	p_ipv6_header : process(all)
	begin
		s_udp_header_ipv6_path <= to_udp_header(s_if_axis_ipv6_m_0.tdata(127 downto 64));
		-- do not change if used by generic_prefix
		if not s_hold_ipv6_header then
			s_ipv6_header.traffic_class  <= cpu_ip_config.traffic_class;
			s_ipv6_header.flow_label     <= cpu_ip_config.ipv6_flow_label;
			s_ipv6_header.payload_length <= s_udp_header_ipv6_path.length;
			s_ipv6_header.next_header    <= c_protocol_udp;
			s_ipv6_header.hop_limit      <= cpu_ip_config.hop_limit;
			s_ipv6_header.source         <= cpu_ip_config.ipv6_source_address;
			s_ipv6_header.destination    <= cpu_ip_config.ipv6_destination_address;
		end if;
	end process;

	p_ipv4_header : process(all)
	begin
		s_udp_header_ipv4_path <= to_udp_header(s_if_axis_ipv4_m_0.tdata(127 downto 64));
		-- do not change if used by generic_prefix
		if not s_hold_ipv4_header then
			s_ipv4_header.traffic_class   <= cpu_ip_config.traffic_class;
			s_ipv4_header.total_length    <= s_udp_header_ipv4_path.length + c_ipv4_header_width / 8;
			s_ipv4_header.identification  <= cpu_ip_config.ipv4_identification;
			s_ipv4_header.time_to_live    <= cpu_ip_config.hop_limit;
			s_ipv4_header.protocol        <= c_protocol_udp;
			s_ipv4_header.header_checksum <= ipv4_header_checksum(s_ipv4_header);
			s_ipv4_header.source          <= cpu_ip_config.ipv4_source_address;
			s_ipv4_header.destination     <= cpu_ip_config.ipv4_destination_address;
		end if;
	end process;

	i_conditional_split : entity ipfix_exporter.conditional_split
		port map(
			clk             => clk,
			rst             => rst,

			target_1_not_0  => s_ipv6_not_ipv4,

			if_axis_in_m    => if_axis_in_m,
			if_axis_in_s    => if_axis_in_s,

			if_axis_out_0_m => s_if_axis_ipv4_m_0,
			if_axis_out_0_s => s_if_axis_ipv4_s_0,

			if_axis_out_1_m => s_if_axis_ipv6_m_0,
			if_axis_out_1_s => s_if_axis_ipv6_s_0
		);
	i_ipv6_prefix : entity ipfix_exporter.generic_prefix
		generic map(
			g_prefix_width => c_ipv6_header_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv6_m_0,
			if_axis_in_s  => s_if_axis_ipv6_s_0,

			if_axis_out_m => s_if_axis_ipv6_m_1,
			if_axis_out_s => s_if_axis_ipv6_s_1,

			prefix        => to_std_ulogic_vector(s_ipv6_header)
		);
	i_ipv4_prefix : entity ipfix_exporter.generic_prefix
		generic map(
			g_prefix_width => c_ipv4_header_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv4_m_0,
			if_axis_in_s  => s_if_axis_ipv4_s_0,

			if_axis_out_m => s_if_axis_ipv4_m_1,
			if_axis_out_s => s_if_axis_ipv4_s_1,

			prefix        => to_std_ulogic_vector(s_ipv4_header)
		);
	i_axis_combiner : entity ipfix_exporter.axis_combiner
		port map(
			clk            => clk,
			rst            => rst,

			if_axis_in_m_0 => s_if_axis_ipv4_m_1,
			if_axis_in_s_0 => s_if_axis_ipv4_s_1,

			if_axis_in_m_1 => s_if_axis_ipv6_m_1,
			if_axis_in_s_1 => s_if_axis_ipv6_s_1,

			if_axis_out_m  => if_axis_out_m,
			if_axis_out_s  => if_axis_out_s
		);
end architecture;
