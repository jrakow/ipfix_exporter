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

	signal s_if_axis_ipv4_m_0 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_0 : t_if_axis_s;
	signal s_if_axis_ipv4_m_1 : t_if_axis_frame_m;
	signal s_if_axis_ipv4_s_1 : t_if_axis_s;
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
			if_axis_out_ipv4_s => s_if_axis_ipv4_s_0
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
			if_axis_out_s => s_if_axis_ipv6_s_1
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
			if_axis_out_s => s_if_axis_ipv4_s_1
		);

	i_axis_combiner : entity ipfix_exporter.axis_combiner
		port map(
			clk            => clk,
			rst            => rst,

			if_axis_in_m_0 => s_if_axis_ipv6_m_1,
			if_axis_in_s_0 => s_if_axis_ipv6_s_1,

			if_axis_in_m_1 => s_if_axis_ipv4_m_1,
			if_axis_in_s_1 => s_if_axis_ipv4_s_1,

			if_axis_out_m  => if_axis_out_m,
			if_axis_out_s  => if_axis_out_s
		);
end architecture;
