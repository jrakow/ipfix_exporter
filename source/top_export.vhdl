library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the export path.

It instantiates and connects the @ref ipfix_header, @ref udp_header, @ref ip_header, @ref ethertype_insertion, @ref vlan_insertion and @ref ethernet_header modules.
 */
entity top_export is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
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
			if_axis_out_s => s_if_axis_s_0
		);
	i_udp_header : entity ipfix_exporter.udp_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_0,
			if_axis_in_s  => s_if_axis_s_0,

			if_axis_out_m => s_if_axis_m_1,
			if_axis_out_s => s_if_axis_s_1
		);
	i_ip_header : entity ipfix_exporter.ip_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_1,
			if_axis_in_s  => s_if_axis_s_1,

			if_axis_out_m => s_if_axis_m_2,
			if_axis_out_s => s_if_axis_s_2
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
			if_axis_out_s => s_if_axis_s_4
		);
	i_ethernet_header : entity ipfix_exporter.ethernet_header
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_4,
			if_axis_in_s  => s_if_axis_s_4,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s
		);
end architecture;
