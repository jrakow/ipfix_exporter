library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the preparational modules.

It instantiates and connects the @ref selective_dropping, @ref ethernet_dropping, @ref vlan_dropping, @ref ethertype_dropping and @ref ip_version_split modules.

@dot
digraph overview
	{
	node [shape=box];
	input  [ label="input"  shape=circle ];
	output_ipv6 [ label="output_ipv6" shape=circle ];
	output_ipv4 [ label="output_ipv4" shape=circle ];

	selective_dropping [ label="selective_dropping" URL="@ref selective_dropping" ];
	ethernet_dropping  [ label="ethernet_dropping"  URL="@ref ethernet_dropping"  ];
	vlan_dropping_0    [ label="vlan_dropping 0"    URL="@ref vlan_dropping"      ];
	vlan_dropping_1    [ label="vlan_dropping 1"    URL="@ref vlan_dropping"      ];
	ethertype_dropping [ label="ethertype_dropping" URL="@ref ethertype_dropping" ];
	ip_version_split   [ label="ip_version_split"   URL="@ref ip_version_split"   ];

	input -> selective_dropping -> ethernet_dropping -> vlan_dropping_0 -> vlan_dropping_1 -> ip_version_split;
	ip_version_split -> output_ipv6;
	ip_version_split -> output_ipv4;
	}
@enddot
 */
entity top_preparation is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_ipv6_m : out t_if_axis_frame_m;
		if_axis_out_ipv6_s : in  t_if_axis_s;

		if_axis_out_ipv4_m : out t_if_axis_frame_m;
		if_axis_out_ipv4_s : in  t_if_axis_s;

		cpu_drop_source_mac_enable : in std_ulogic;
		cpu_ethernet_config        : in t_ethernet_config;

		events : out std_ulogic_vector(c_number_of_counters_preparation - 1 downto 0)
	);
end entity;

architecture arch of top_preparation is
	signal s_if_axis_m_0 : t_if_axis_frame_m;
	signal s_if_axis_s_0 : t_if_axis_s;

	signal s_if_axis_m_1 : t_if_axis_frame_m;
	signal s_if_axis_s_1 : t_if_axis_s;

	signal s_if_axis_m_2 : t_if_axis_frame_m;
	signal s_if_axis_s_2 : t_if_axis_s;

	signal s_if_axis_m_3 : t_if_axis_frame_m;
	signal s_if_axis_s_3 : t_if_axis_s;

	signal s_if_axis_m_4 : t_if_axis_frame_m;
	signal s_if_axis_s_4 : t_if_axis_s;
begin
	events(0) <= if_axis_in_m.tvalid and if_axis_in_m.tlast and if_axis_in_s.tready;
	events(1) <= s_if_axis_m_0.tvalid and s_if_axis_m_0.tlast and s_if_axis_s_0.tready;
	events(2) <= s_if_axis_m_1.tvalid and s_if_axis_m_1.tlast and s_if_axis_s_1.tready;

	i_selective_dropping : entity ipfix_exporter.selective_dropping
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m => s_if_axis_m_0,
			if_axis_out_s => s_if_axis_s_0,

			cpu_drop_source_mac_enable => cpu_drop_source_mac_enable,
			cpu_ethernet_config        => cpu_ethernet_config
		);

	i_ethernet_dropping : entity ipfix_exporter.ethernet_dropping
		port map(
			clk           => clk,
			rst           => rst,
			if_axis_in_m  => s_if_axis_m_0,
			if_axis_in_s  => s_if_axis_s_0,
			if_axis_out_m => s_if_axis_m_1,
			if_axis_out_s => s_if_axis_s_1
		);

	i_vlan_dropping_0 : entity ipfix_exporter.vlan_dropping
		port map(
			clk           => clk,
			rst           => rst,
			if_axis_in_m  => s_if_axis_m_1,
			if_axis_in_s  => s_if_axis_s_1,
			if_axis_out_m => s_if_axis_m_2,
			if_axis_out_s => s_if_axis_s_2
		);

	i_vlan_dropping_1 : entity ipfix_exporter.vlan_dropping
		port map(
			clk           => clk,
			rst           => rst,
			if_axis_in_m  => s_if_axis_m_2,
			if_axis_in_s  => s_if_axis_s_2,
			if_axis_out_m => s_if_axis_m_3,
			if_axis_out_s => s_if_axis_s_3
		);

	i_ethertype_dropping : entity ipfix_exporter.ethertype_dropping
		port map(
			clk           => clk,
			rst           => rst,
			if_axis_in_m  => s_if_axis_m_3,
			if_axis_in_s  => s_if_axis_s_3,
			if_axis_out_m => s_if_axis_m_4,
			if_axis_out_s => s_if_axis_s_4
		);

	i_ip_version_split : entity ipfix_exporter.ip_version_split
		port map(
			clk                => clk,
			rst                => rst,

			if_axis_in_m       => s_if_axis_m_4,
			if_axis_in_s       => s_if_axis_s_4,

			if_axis_out_ipv6_m => if_axis_out_ipv6_m,
			if_axis_out_ipv6_s => if_axis_out_ipv6_s,

			if_axis_out_ipv4_m => if_axis_out_ipv4_m,
			if_axis_out_ipv4_s => if_axis_out_ipv4_s
		);
end architecture;
