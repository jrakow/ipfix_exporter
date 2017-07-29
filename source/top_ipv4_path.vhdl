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
	generic(
		g_addr_width : natural
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

architecture arch of top_ipv4_path is
	signal s_if_axis_m_0 : t_if_axis_ipv4_m;
	signal s_if_axis_s_0 : t_if_axis_s;

	signal s_if_axis_m_1 : t_if_axis_ipv4_m;
	signal s_if_axis_s_1 : t_if_axis_s;

	signal s_enable_a       : std_ulogic;
	signal s_write_enable_a : std_ulogic;
	signal s_addr_a         : std_ulogic_vector(g_addr_width - 1 downto 0);
	signal s_data_in_a      : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0);
	signal s_data_out_a     : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0);

	signal s_enable_b       : std_ulogic;
	signal s_write_enable_b : std_ulogic;
	signal s_addr_b         : std_ulogic_vector(g_addr_width - 1 downto 0);
	signal s_data_in_b      : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0);
	signal s_data_out_b     : std_ulogic_vector(c_ipfix_ipv4_data_record_width - 1 downto 0);

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
		generic map(
			g_addr_width => g_addr_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m => s_if_axis_m_0,
			if_axis_in_s => s_if_axis_s_0,

			enable       => s_enable_a       ,
			write_enable => s_write_enable_a ,
			addr         => s_addr_a         ,
			data_in      => s_data_in_a      ,
			data_out     => s_data_out_a
		);

	i_cache : entity ipfix_exporter.ram
		generic map(
			g_addr_width => g_addr_width,
			g_data_width => c_ipfix_ipv4_data_record_width
		)
		port map(
			clk => clk,

			enable_a       => s_enable_a       ,
			write_enable_a => s_write_enable_a ,
			addr_a         => s_addr_a         ,
			data_in_a      => s_data_in_a      ,
			data_out_a     => s_data_out_a     ,

			enable_b       => s_enable_b       ,
			write_enable_b => s_write_enable_b ,
			addr_b         => s_addr_b         ,
			data_in_b      => s_data_in_b      ,
			data_out_b     => s_data_out_b
		);

	i_cache_extraction_ipv4 : entity ipfix_exporter.cache_extraction_ipv4
		generic map(
			g_addr_width => g_addr_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			enable       => s_enable_b       ,
			write_enable => s_write_enable_b ,
			addr         => s_addr_b         ,
			data_in      => s_data_in_b      ,
			data_out     => s_data_out_b     ,

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
