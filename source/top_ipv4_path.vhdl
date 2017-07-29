library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the IPv4 data path.

It instantiates and connects the @ref information_extraction_ipv4, @ref cache_insertion_ipv4, @ref ram as cache, @ref cache_extraction_ipv4, ipfix_message_control_ipv4 and @ref top_export modules.
 */
entity top_ipv4_path is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of top_ipv4_path is
	signal s_if_axis_m_0 : t_if_axis_ipv4_m;
	signal s_if_axis_s_0 : t_if_axis_s;

	signal s_if_axis_m_1 : t_if_axis_ipv4_m;
	signal s_if_axis_s_1 : t_if_axis_s;

	signal s_if_axis_m_2 : t_if_axis_frame_m;
	signal s_if_axis_s_2 : t_if_axis_s;
begin
	i_information_extraction_ipv4 : entity ipfix_exporter.information_extraction_ipv4
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m => s_if_axis_m_0,
			if_axis_out_s => s_if_axis_s_0
		);

	i_cache_insertion_ipv4 : entity ipfix_exporter.cache_insertion_ipv4
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m => s_if_axis_m_0,
			if_axis_in_s => s_if_axis_s_0
		);

	i_cache : entity ipfix_exporter.ram
		port map(
			clk => clk,
			rst => rst
		);

	i_cache_extraction_ipv4 : entity ipfix_exporter.cache_extraction_ipv4
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_out_m => s_if_axis_m_1,
			if_axis_out_s => s_if_axis_s_1
		);

	i_ipfix_message_control_ipv4 : entity ipfix_exporter.ipfix_message_control_ipv4
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_1,
			if_axis_in_s  => s_if_axis_s_1,

			if_axis_out_m => s_if_axis_m_2,
			if_axis_out_s => s_if_axis_s_2
		);

	i_top_export : entity ipfix_exporter.top_export
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_2,
			if_axis_in_s  => s_if_axis_s_2,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s
		);
end architecture;
