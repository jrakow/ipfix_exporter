library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the export path.

It instantiates and connects the @ref ipfix_header, @ref udp_header, @ref ip_header, @ref ethertype_insertion, @ref vlan_insertion and @ref ethernet_header modules.

@dot
digraph overview
	{
	node [shape=box];
	input  [ label="input"  shape=circle ];
	output [ label="output" shape=circle ];

	ipfix_header        [ label="ipfix_header"        URL="@ref ipfix_header"        ];
	udp_header          [ label="udp_header"          URL="@ref udp_header"          ];
	ip_header           [ label="ip_header"           URL="@ref ip_header"           ];
	ethertype_insertion [ label="ethertype_insertion" URL="@ref ethertype_insertion" ];
	vlan_insertion      [ label="vlan_insertion"      URL="@ref vlan_insertion"      ];
	ethernet_header     [ label="ethernet_header"     URL="@ref ethernet_header"     ];

	input -> ipfix_header -> udp_header -> ip_header -> ethertype_insertion -> vlan_insertion -> ethernet_header -> output;
	}
@enddot
 */
entity top_export is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_timestamp       : in t_timestamp;
		cpu_ipfix_config    : in t_ipfix_config;
		cpu_udp_config      : in t_udp_config;
		cpu_ip_config       : in t_ip_config;
		cpu_vlan_config     : in t_vlan_config;
		cpu_ethernet_config : in t_ethernet_config
	);
end entity;

architecture arch of top_export is
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
	i_ipfix_header : entity ipfix_exporter.ipfix_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m => s_if_axis_m_0,
			if_axis_out_s => s_if_axis_s_0,

			cpu_ipfix_config => cpu_ipfix_config,
			cpu_timestamp    => cpu_timestamp
		);
	i_udp_header : entity ipfix_exporter.udp_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_0,
			if_axis_in_s  => s_if_axis_s_0,

			if_axis_out_m => s_if_axis_m_1,
			if_axis_out_s => s_if_axis_s_1,

			cpu_udp_config => cpu_udp_config,
			cpu_ip_config  => cpu_ip_config
		);
	i_ip_header : entity ipfix_exporter.ip_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_1,
			if_axis_in_s  => s_if_axis_s_1,

			if_axis_out_m => s_if_axis_m_2,
			if_axis_out_s => s_if_axis_s_2,

			cpu_ip_config => cpu_ip_config
		);
	i_ethertype_insertion : entity ipfix_exporter.ethertype_insertion
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_2,
			if_axis_in_s  => s_if_axis_s_2,

			if_axis_out_m => s_if_axis_m_3,
			if_axis_out_s => s_if_axis_s_3
		);
	i_vlan_insertion : entity ipfix_exporter.vlan_insertion
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_3,
			if_axis_in_s  => s_if_axis_s_3,

			if_axis_out_m => s_if_axis_m_4,
			if_axis_out_s => s_if_axis_s_4,

			cpu_vlan_config => cpu_vlan_config
		);
	i_ethernet_header : entity ipfix_exporter.ethernet_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_4,
			if_axis_in_s  => s_if_axis_s_4,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s,

			cpu_ethernet_config => cpu_ethernet_config
		);
end architecture;
