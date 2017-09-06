library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/*!
This module is the top level for the IPv4 data path.

It instantiates and connects the @ref information_extraction, @ref cache_insertion, @ref ram as cache, @ref cache_extraction, @ref ipfix_message_control and @ref ipfix_header modules.

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
	ipfix_header           [ label="ipfix_header"           URL="@ref ipfix_header"           ];

	input -> information_extraction -> cache_insertion -> cache -> cache_extraction -> ipfix_message_control -> ipfix_header -> output;
	}
@enddot
 */
entity top_collect is
	generic(
		g_addr_width : natural;
		g_ip_version : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_timestamp              : in  t_timestamp;
		cpu_cache_active_timeout   : in  t_timeout;
		cpu_cache_inactive_timeout : in  t_timeout;
		cpu_ipfix_message_timeout  : in  t_timeout;
		cpu_ipfix_config           : in t_ipfix_config;

		events : out std_ulogic_vector(c_number_of_counters_collect - 1 downto 0)
	);
end entity;

architecture arch of top_collect is
	function ip_version_to_record_width(v : natural) return natural is
	begin
		if v = 6 then
			return c_ipfix_ipv6_data_record_width;
		elsif v = 4 then
			return c_ipfix_ipv4_data_record_width;
		else
			assert false
				report integer'image(v) & " is not a valid IP version"
				severity failure;
		end if;
	end;
	constant c_record_width : natural := ip_version_to_record_width(g_ip_version);
	function ip_version_to_frame_info_width(v : natural) return natural is
	begin
		if v = 6 then
			return c_ipv6_frame_info_width;
		elsif v = 4 then
			return c_ipv4_frame_info_width;
		else
			assert false
				report integer'image(v) & " is not a valid IP version"
				severity failure;
		end if;
	end;
	constant c_frame_info_width : natural := ip_version_to_frame_info_width(g_ip_version);

	signal s_if_axis_m_tdata_0  : std_ulogic_vector(c_frame_info_width - 1 downto 0);
	signal s_if_axis_m_tvalid_0 : std_ulogic;
	signal s_if_axis_s_0        : t_if_axis_s;

	signal s_if_axis_m_tdata_1  : std_ulogic_vector(c_record_width - 1 downto 0);
	signal s_if_axis_m_tvalid_1 : std_ulogic;
	signal s_if_axis_s_1        : t_if_axis_s;

	signal s_if_axis_m_2 : t_if_axis_frame_m;
	signal s_if_axis_s_2 : t_if_axis_s;

	signal s_enable_a       : std_ulogic;
	signal s_write_enable_a : std_ulogic;
	signal s_addr_a         : std_ulogic_vector(g_addr_width - 1 downto 0);
	signal s_data_in_a      : std_ulogic_vector(c_record_width - 1 downto 0);
	signal s_data_out_a     : std_ulogic_vector(c_record_width - 1 downto 0);

	signal s_enable_b       : std_ulogic;
	signal s_write_enable_b : std_ulogic;
	signal s_addr_b         : std_ulogic_vector(g_addr_width - 1 downto 0);
	signal s_data_in_b      : std_ulogic_vector(c_record_width - 1 downto 0);
	signal s_data_out_b     : std_ulogic_vector(c_record_width - 1 downto 0);

	signal s_collision_event : std_logic;
begin
	events(0) <= if_axis_in_m.tvalid and if_axis_in_m.tlast and if_axis_in_s.tready;
	events(1) <= s_if_axis_m_tvalid_0 and s_if_axis_s_0.tready;
	events(2) <= s_collision_event;
	events(3) <= s_if_axis_m_tvalid_1 and s_if_axis_s_1.tready;
	events(4) <= s_if_axis_m_2.tvalid and s_if_axis_m_2.tlast and s_if_axis_s_2.tready;

	i_information_extraction : entity ipfix_exporter.information_extraction
		generic map (
			g_frame_info_width => c_frame_info_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m_tdata  => s_if_axis_m_tdata_0,
			if_axis_out_m_tvalid => s_if_axis_m_tvalid_0,
			if_axis_out_s        => s_if_axis_s_0,

			cpu_timestamp => cpu_timestamp
		);

	i_cache_insertion : entity ipfix_exporter.cache_insertion
		generic map(
			g_addr_width => g_addr_width,
			g_record_width => c_record_width,
			g_frame_info_width => c_frame_info_width
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
			data_out     => s_data_out_a     ,

			cpu_collision_event => s_collision_event
		);

	i_cache : entity ipfix_exporter.ram
		generic map(
			g_addr_width => g_addr_width,
			g_data_width => c_record_width
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
			g_record_width => c_record_width
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
			if_axis_out_s        => s_if_axis_s_1,

			cpu_cache_active_timeout   => cpu_cache_active_timeout,
			cpu_cache_inactive_timeout => cpu_cache_inactive_timeout,
			cpu_timestamp              => cpu_timestamp
		);

	i_ipfix_message_control : entity ipfix_exporter.ipfix_message_control
			generic map (
				g_record_width => c_record_width
			)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m_tdata  => s_if_axis_m_tdata_1,
			if_axis_in_m_tvalid => s_if_axis_m_tvalid_1,
			if_axis_in_s        => s_if_axis_s_1,

			if_axis_out_m => s_if_axis_m_2,
			if_axis_out_s => s_if_axis_s_2,

			cpu_ipfix_config          => cpu_ipfix_config,
			cpu_ipfix_message_timeout => cpu_ipfix_message_timeout
		);
	i_ipfix_header : entity ipfix_exporter.ipfix_header
		generic map (
			g_ip_version => g_ip_version
			)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m_2,
			if_axis_in_s  => s_if_axis_s_2,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s,

			cpu_ipfix_config => cpu_ipfix_config,
			cpu_timestamp    => cpu_timestamp
		);
end architecture;
