library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
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
		if_axis_out_s : in  t_if_axis_s
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
	signal s_cpu_collision_event_ipv6   : std_ulogic;
	signal s_cpu_collision_event_ipv4   : std_ulogic;
	signal s_cpu_cache_active_timeout   : t_timeout;
	signal s_cpu_cache_inactive_timeout : t_timeout;
	signal s_cpu_ipfix_message_timeout  : t_timeout;
	signal s_cpu_ipfix_config_ipv6      : t_ipfix_config;
	signal s_cpu_ipfix_config_ipv4      : t_ipfix_config;
	signal s_cpu_udp_config             : t_udp_config;
	signal s_cpu_ip_config              : t_ip_config;
	signal s_cpu_vlan_config            : t_vlan_config;
	signal s_cpu_ethernet_config        : t_ethernet_config;
begin
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
			cpu_ethernet_config        => s_cpu_ethernet_config
		);

	i_top_collect_ipv6 : entity ipfix_exporter.top_collect
		generic map(
			g_addr_width   => g_ipv6_cache_addr_width,
			g_record_width => c_ipfix_ipv6_data_record_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv6_m_0,
			if_axis_in_s  => s_if_axis_ipv6_s_0,

			if_axis_out_m => s_if_axis_ipv6_m_1,
			if_axis_out_s => s_if_axis_ipv6_s_1,

			cpu_timestamp              => s_cpu_timestamp,
			cpu_collision_event        => s_cpu_collision_event_ipv6,
			cpu_cache_active_timeout   => s_cpu_cache_active_timeout,
			cpu_cache_inactive_timeout => s_cpu_cache_inactive_timeout,
			cpu_ipfix_message_timeout  => s_cpu_ipfix_message_timeout
		);

	i_top_collect_ipv4 : entity ipfix_exporter.top_collect
		generic map(
			g_addr_width   => g_ipv4_cache_addr_width,
			g_record_width => c_ipfix_ipv4_data_record_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv4_m_0,
			if_axis_in_s  => s_if_axis_ipv4_s_0,

			if_axis_out_m => s_if_axis_ipv4_m_1,
			if_axis_out_s => s_if_axis_ipv4_s_1,

			cpu_timestamp              => s_cpu_timestamp,
			cpu_collision_event        => s_cpu_collision_event_ipv4,
			cpu_cache_active_timeout   => s_cpu_cache_active_timeout,
			cpu_cache_inactive_timeout => s_cpu_cache_inactive_timeout,
			cpu_ipfix_message_timeout  => s_cpu_ipfix_message_timeout
		);

	i_top_export_ipv6 : entity ipfix_exporter.top_export
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv6_m_1,
			if_axis_in_s  => s_if_axis_ipv6_s_1,

			if_axis_out_m => s_if_axis_ipv6_m_2,
			if_axis_out_s => s_if_axis_ipv6_s_2,

			cpu_timestamp       => s_cpu_timestamp,
			cpu_ipfix_config    => s_cpu_ipfix_config_ipv6,
			cpu_udp_config      => s_cpu_udp_config,
			cpu_ip_config       => s_cpu_ip_config,
			cpu_vlan_config     => s_cpu_vlan_config,
			cpu_ethernet_config => s_cpu_ethernet_config
		);

	i_top_export_ipv4 : entity ipfix_exporter.top_export
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_ipv4_m_1,
			if_axis_in_s  => s_if_axis_ipv4_s_1,

			if_axis_out_m => s_if_axis_ipv4_m_2,
			if_axis_out_s => s_if_axis_ipv4_s_2,

			cpu_timestamp       => s_cpu_timestamp,
			cpu_ipfix_config    => s_cpu_ipfix_config_ipv4,
			cpu_udp_config      => s_cpu_udp_config,
			cpu_ip_config       => s_cpu_ip_config,
			cpu_vlan_config     => s_cpu_vlan_config,
			cpu_ethernet_config => s_cpu_ethernet_config
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
end architecture;
