library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the export path.

It instantiates and connects the @ref udp_header, @ref ip_header, @ref ethertype_insertion, @ref vlan_insertion and @ref ethernet_header modules.

@dot
digraph overview
	{
	node [shape=box];
	input  [ label="input"  shape=circle ];
	output [ label="output" shape=circle ];

	udp_header          [ label="udp_header"          URL="@ref udp_header"          ];
	ip_header           [ label="ip_header"           URL="@ref ip_header"           ];
	ethertype_insertion [ label="ethertype_insertion" URL="@ref ethertype_insertion" ];
	vlan_insertion      [ label="vlan_insertion"      URL="@ref vlan_insertion"      ];
	ethernet_header     [ label="ethernet_header"     URL="@ref ethernet_header"     ];

	input -> udp_header -> ip_header -> ethertype_insertion -> vlan_insertion -> ethernet_header -> output;
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

		cpu_udp_config      : in t_udp_config;
		cpu_ip_config       : in t_ip_config;
		cpu_vlan_config     : in t_vlan_config;
		cpu_ethernet_config : in t_ethernet_config;

		events : out std_ulogic_vector(c_number_of_counters_export - 1 downto 0)
	);
end entity;

architecture arch of top_export is
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
	events(1) <= s_if_axis_m_1.tvalid and s_if_axis_m_1.tlast and s_if_axis_s_1.tready;
	events(2) <= s_if_axis_m_2.tvalid and s_if_axis_m_2.tlast and s_if_axis_s_2.tready;
	events(3) <= s_if_axis_m_3.tvalid and s_if_axis_m_3.tlast and s_if_axis_s_3.tready;
	events(4) <= s_if_axis_m_4.tvalid and s_if_axis_m_4.tlast and s_if_axis_s_4.tready;
	events(5) <= if_axis_out_m.tvalid and if_axis_out_m.tlast and if_axis_out_s.tready;

	i_udp_header : entity ipfix_exporter.udp_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

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
