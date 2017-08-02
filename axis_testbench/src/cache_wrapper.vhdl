library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
The axis_testbench does not test RAM interfaces.
So the modules cache_insertion, cache and cache_extraction do not fit into the testbench.
It is however possible to test the combination.
This entity wraps these modules.
 */
entity cache_wrapper is
	generic(
		g_addr_width      : natural := 12;
		g_in_tdata_width  : natural;
		g_out_tdata_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m_tdata  : in  std_ulogic_vector(g_in_tdata_width - 1 downto 0);
		if_axis_in_m_tvalid : in  std_ulogic;
		if_axis_in_s        : out t_if_axis_s;

		if_axis_out_m_tdata  : out std_ulogic_vector(g_out_tdata_width - 1 downto 0);
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s        : in  t_if_axis_s;

		cpu_collision_event        : out std_ulogic;
		cpu_cache_active_timeout   : in t_timeout;
		cpu_cache_inactive_timeout : in t_timeout;
		cpu_timestamp              : in t_timestamp
	);
end entity;

architecture arch of cache_wrapper is
	constant c_frame_info_width : natural := g_in_tdata_width;
	constant c_record_width     : natural := g_out_tdata_width;

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
begin
	i_cache_insertion : entity ipfix_exporter.cache_insertion
		generic map(
			g_addr_width       => g_addr_width,
			g_frame_info_width => c_frame_info_width,
			g_record_width     => c_record_width
		)
		port map(
			clk                 => clk,
			rst                 => rst,

			if_axis_in_m_tdata  => if_axis_in_m_tdata,
			if_axis_in_m_tvalid => if_axis_in_m_tvalid,
			if_axis_in_s        => if_axis_in_s,

			enable              => s_enable_a,
			write_enable        => s_write_enable_a,
			addr                => s_addr_a,
			data_in             => s_data_in_a,
			data_out            => s_data_out_a,

			cpu_collision_event => cpu_collision_event
		);
	i_cache : entity ipfix_exporter.ram
		generic map(
			g_addr_width => g_addr_width,
			g_data_width => c_record_width
		)
		port map(
			clk            => clk,

			enable_a       => s_enable_a,
			write_enable_a => s_write_enable_a,
			addr_a         => s_addr_a,
			data_in_a      => s_data_in_a,
			data_out_a     => s_data_out_a,

			enable_b       => s_enable_b,
			write_enable_b => s_write_enable_b,
			addr_b         => s_addr_b,
			data_in_b      => s_data_in_b,
			data_out_b     => s_data_out_b
		);
	i_cache_extraction : entity ipfix_exporter.cache_extraction
		generic map(
			g_addr_width   => g_addr_width,
			g_record_width => c_record_width
		)
		port map(
			clk                        => clk,
			rst                        => rst,

			enable                     => s_enable_b,
			write_enable               => s_write_enable_b,
			addr                       => s_addr_b,
			data_in                    => s_data_in_b,
			data_out                   => s_data_out_b,

			if_axis_out_m_tdata        => if_axis_out_m_tdata,
			if_axis_out_m_tvalid       => if_axis_out_m_tvalid,
			if_axis_out_s              => if_axis_out_s,

			cpu_cache_active_timeout   => cpu_cache_active_timeout,
			cpu_cache_inactive_timeout => cpu_cache_inactive_timeout,
			cpu_timestamp              => cpu_timestamp
		);
end architecture;
