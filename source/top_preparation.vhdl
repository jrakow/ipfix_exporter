library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

entity top_preparation is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_ipv6_m : out t_if_axis_frame_m;
		if_axis_out_ipv6_s : in  t_if_axis_s;

		if_axis_out_ipv4_m : out t_if_axis_frame_m;
		if_axis_out_ipv4_s : in  t_if_axis_s
	);
end entity;

architecture arch of top_preparation is
	signal s_if_axis_m_0 : t_if_axis_frame_m;
	signal s_if_axis_s_0 : t_if_axis_s;

	signal s_if_axis_m_1 : t_if_axis_frame_m;
	signal s_if_axis_s_1 : t_if_axis_s;
begin
	i_selective_dropping : entity ipfix_exporter.selective_dropping
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m => s_if_axis_m_0,
			if_axis_out_s => s_if_axis_s_0
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

	i_ip_version_split : entity ipfix_exporter.ip_version_split
		port map(
			clk                => clk,
			rst                => rst,

			if_axis_in_m       => s_if_axis_m_1,
			if_axis_in_s       => s_if_axis_s_1,

			if_axis_out_ipv6_m => if_axis_out_ipv6_m,
			if_axis_out_ipv6_s => if_axis_out_ipv6_s,

			if_axis_out_ipv4_m => if_axis_out_ipv4_m,
			if_axis_out_ipv4_s => if_axis_out_ipv4_s
		);
end architecture;
