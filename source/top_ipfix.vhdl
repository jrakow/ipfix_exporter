library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the complete `ipfix_exporter`.

It instantiates and connects the @ref top_preparation, @ref top_collect and @ref axis_combiner modules.
 */
entity top_ipfix is
	generic(
		g_ipv6_cache_addr_width : natural;
		g_ipv4_cache_addr_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		read_enable  : in  std_ulogic;
		write_enable : in  std_ulogic;
		data_in      : out std_ulogic_vector(31 downto 0);
		data_out     : in  std_ulogic_vector(31 downto 0);
		address      : in  std_ulogic_vector(31 downto 0);
		read_valid   : out std_ulogic
	);
end entity;

architecture arch of top_ipfix is
	signal s_if_axis_ipv6_m_0 : t_if_axis_frame_m;
	signal s_if_axis_ipv6_s_0 : t_if_axis_s;
	signal s_if_axis_ipv6_m_1 : t_if_axis_frame_m;
	signal s_if_axis_ipv6_s_1 : t_if_axis_s;
	signal s_if_axis_ipv6_m_2 : t_if_axis_frame_m;
	signal s_if_axis_ipv6_s_2 : t_if_axis_s;

	signal s_if_axis_ipv4_m_0 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_0 : t_if_axis_s;
	signal s_if_axis_ipv4_m_1 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_1 : t_if_axis_s;
	signal s_if_axis_ipv4_m_2 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_2 : t_if_axis_s;

	signal s_cpu_drop_source_mac_enable : std_ulogic;
	signal s_cpu_timestamp              : t_timestamp;
	signal s_cpu_cache_active_timeout   : t_timeout;
	signal s_cpu_cache_inactive_timeout : t_timeout;
	signal s_cpu_ipfix_message_timeout  : t_timeout;
	signal s_cpu_ipfix_config_ipv6      : t_ipfix_config;
	signal s_cpu_ipfix_config_ipv4      : t_ipfix_config;
	signal s_cpu_udp_config             : t_udp_config;
	signal s_cpu_ip_config              : t_ip_config;
	signal s_cpu_vlan_config            : t_vlan_config;
	signal s_cpu_ethernet_config        : t_ethernet_config;

	signal s_events : std_logic_vector(c_number_of_counters - 1 downto 0);
begin
	s_events(3) <= if_axis_out_m.tvalid and if_axis_out_m.tlast and if_axis_out_s.tready;

	i_top_preparation : entity ipfix_exporter.top_preparation
		port map(
			clk                => clk,
			rst                => rst,

			if_axis_in_m       => if_axis_in_m,
			if_axis_in_s       => if_axis_in_s,

			if_axis_out_ipv6_m => s_if_axis_ipv6_m_0,
			if_axis_out_ipv6_s => s_if_axis_ipv6_s_0,

			if_axis_out_ipv4_m => s_if_axis_ipv4_m_0,
			if_axis_out_ipv4_s => s_if_axis_ipv4_s_0,

			cpu_drop_source_mac_enable => s_cpu_drop_source_mac_enable,
			cpu_ethernet_config        => s_cpu_ethernet_config,

			events => s_events(2 downto 0)
		);

	i_top_collect_ipv6 : entity ipfix_exporter.top_collect
		generic map(
			g_addr_width => g_ipv6_cache_addr_width,
			g_ip_version => 6
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv6_m_0,
			if_axis_in_s  => s_if_axis_ipv6_s_0,

			if_axis_out_m => s_if_axis_ipv6_m_1,
			if_axis_out_s => s_if_axis_ipv6_s_1,

			cpu_timestamp              => s_cpu_timestamp,
			cpu_cache_active_timeout   => s_cpu_cache_active_timeout,
			cpu_cache_inactive_timeout => s_cpu_cache_inactive_timeout,
			cpu_ipfix_message_timeout  => s_cpu_ipfix_message_timeout,
			cpu_ipfix_config           => s_cpu_ipfix_config_ipv6,

			events => s_events(8 downto 4)
		);

	i_top_collect_ipv4 : entity ipfix_exporter.top_collect
		generic map(
			g_addr_width => g_ipv4_cache_addr_width,
			g_ip_version => 4
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv4_m_0,
			if_axis_in_s  => s_if_axis_ipv4_s_0,

			if_axis_out_m => s_if_axis_ipv4_m_1,
			if_axis_out_s => s_if_axis_ipv4_s_1,

			cpu_timestamp              => s_cpu_timestamp,
			cpu_cache_active_timeout   => s_cpu_cache_active_timeout,
			cpu_cache_inactive_timeout => s_cpu_cache_inactive_timeout,
			cpu_ipfix_message_timeout  => s_cpu_ipfix_message_timeout,
			cpu_ipfix_config           => s_cpu_ipfix_config_ipv4,

			events => s_events(19 downto 15)
		);

	i_top_export_ipv6 : entity ipfix_exporter.top_export
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv6_m_1,
			if_axis_in_s  => s_if_axis_ipv6_s_1,

			if_axis_out_m => s_if_axis_ipv6_m_2,
			if_axis_out_s => s_if_axis_ipv6_s_2,

			cpu_udp_config      => s_cpu_udp_config,
			cpu_ip_config       => s_cpu_ip_config,
			cpu_vlan_config     => s_cpu_vlan_config,
			cpu_ethernet_config => s_cpu_ethernet_config,

			events => s_events(14 downto 9)
		);

	i_top_export_ipv4 : entity ipfix_exporter.top_export
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv4_m_1,
			if_axis_in_s  => s_if_axis_ipv4_s_1,

			if_axis_out_m => s_if_axis_ipv4_m_2,
			if_axis_out_s => s_if_axis_ipv4_s_2,

			cpu_udp_config      => s_cpu_udp_config,
			cpu_ip_config       => s_cpu_ip_config,
			cpu_vlan_config     => s_cpu_vlan_config,
			cpu_ethernet_config => s_cpu_ethernet_config,

			events => s_events(25 downto 20)
		);

	i_axis_combiner : entity ipfix_exporter.axis_combiner
		port map(
			clk            => clk,
			rst            => rst,

			if_axis_in_m_0 => s_if_axis_ipv6_m_2,
			if_axis_in_s_0 => s_if_axis_ipv6_s_2,

			if_axis_in_m_1 => s_if_axis_ipv4_m_2,
			if_axis_in_s_1 => s_if_axis_ipv4_s_2,

			if_axis_out_m  => if_axis_out_m,
			if_axis_out_s  => if_axis_out_s
		);

	i_cpu_interface : entity ipfix_exporter.cpu_interface
		port map(
			clk                    => clk,
			rst                    => rst,

			read_enable            => read_enable,
			write_enable           => write_enable,
			data_in                => data_in,
			data_out               => data_out,
			address                => address,
			read_valid             => read_valid,

			drop_source_mac_enable => s_cpu_drop_source_mac_enable,
			timestamp              => s_cpu_timestamp,
			cache_active_timeout   => s_cpu_cache_active_timeout,
			cache_inactive_timeout => s_cpu_cache_inactive_timeout,
			ipfix_message_timeout  => s_cpu_ipfix_message_timeout,
			ipfix_config_ipv6      => s_cpu_ipfix_config_ipv6,
			ipfix_config_ipv4      => s_cpu_ipfix_config_ipv4,
			udp_config             => s_cpu_udp_config,
			ip_config              => s_cpu_ip_config,
			vlan_config            => s_cpu_vlan_config,
			ethernet_config        => s_cpu_ethernet_config,
			events                 => s_events
		);
end architecture;
