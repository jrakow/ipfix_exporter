library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the IPv4 data path.

It instantiates and connects the @ref information_extraction, @ref cache_insertion, @ref ram as cache, @ref cache_extraction and @ref ipfix_message_control modules.

@dot
digraph overview
	{
	node [shape=box];
	input  [ label="input"  shape=circle ];
	output [ label="output" shape=circle ];

	information_extraction [ label="information_extraction" URL="@ref information_extraction" ];
	cache_insertion        [ label="cache_insertion"        URL="@ref cache_insertion"        ];
	cache                  [ label="cache"                  URL="@ref ram"                    ];
	cache_extraction       [ label="cache_extraction"       URL="@ref cache_extraction"       ];
	ipfix_message_control  [ label="ipfix_message_control"  URL="@ref ipfix_message_control"  ];

	input -> information_extraction -> cache_insertion -> cache -> cache_extraction -> ipfix_message_control -> output;
	}
@enddot
 */
entity top_collect is
	generic(
		g_addr_width  : natural;
		g_record_width : natural
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

architecture arch of top_collect is
	signal s_if_axis_m_tdata_0  : std_ulogic_vector(g_record_width - 1 downto 0);
	signal s_if_axis_m_tvalid_0 : std_ulogic;
	signal s_if_axis_s_0        : t_if_axis_s;

	signal s_if_axis_m_tdata_1  : std_ulogic_vector(g_record_width - 1 downto 0);
	signal s_if_axis_m_tvalid_1 : std_ulogic;
	signal s_if_axis_s_1        : t_if_axis_s;

	signal s_enable_a       : std_ulogic;
	signal s_write_enable_a : std_ulogic;
	signal s_addr_a         : std_ulogic_vector(g_addr_width - 1 downto 0);
	signal s_data_in_a      : std_ulogic_vector(g_record_width - 1 downto 0);
	signal s_data_out_a     : std_ulogic_vector(g_record_width - 1 downto 0);

	signal s_enable_b       : std_ulogic;
	signal s_write_enable_b : std_ulogic;
	signal s_addr_b         : std_ulogic_vector(g_addr_width - 1 downto 0);
	signal s_data_in_b      : std_ulogic_vector(g_record_width - 1 downto 0);
	signal s_data_out_b     : std_ulogic_vector(g_record_width - 1 downto 0);
begin
	i_information_extraction : entity ipfix_exporter.information_extraction
		generic map (
			g_record_width => g_record_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m_tdata  => s_if_axis_m_tdata_0,
			if_axis_out_m_tvalid => s_if_axis_m_tvalid_0,
			if_axis_out_s        => s_if_axis_s_0
		);

	i_cache_insertion : entity ipfix_exporter.cache_insertion
		generic map(
			g_addr_width => g_addr_width,
			g_record_width => g_record_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m_tdata  => s_if_axis_m_tdata_0,
			if_axis_in_m_tvalid => s_if_axis_m_tvalid_0,
			if_axis_in_s        => s_if_axis_s_0,

			enable       => s_enable_a       ,
			write_enable => s_write_enable_a ,
			addr         => s_addr_a         ,
			data_in      => s_data_in_a      ,
			data_out     => s_data_out_a
		);

	i_cache : entity ipfix_exporter.ram
		generic map(
			g_addr_width => g_addr_width,
			g_data_width => g_record_width
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

	i_cache_extraction : entity ipfix_exporter.cache_extraction
		generic map(
			g_addr_width => g_addr_width,
			g_record_width => g_record_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			enable       => s_enable_b       ,
			write_enable => s_write_enable_b ,
			addr         => s_addr_b         ,
			data_in      => s_data_in_b      ,
			data_out     => s_data_out_b     ,

			if_axis_out_m_tdata  => s_if_axis_m_tdata_1,
			if_axis_out_m_tvalid => s_if_axis_m_tvalid_1,
			if_axis_out_s        => s_if_axis_s_1
		);

	i_ipfix_message_control : entity ipfix_exporter.ipfix_message_control
			generic map (
				g_record_width => g_record_width
			)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m_tdata  => s_if_axis_m_tdata_1,
			if_axis_in_m_tvalid => s_if_axis_m_tvalid_1,
			if_axis_in_s        => s_if_axis_s_1,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s
		);
end architecture;
