library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axis_testbench;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module wraps is a wrapper for a design under test.
It contains no functionality.

The design under test is chosen based on the g_module generic.

The following modules are not tested, as they do not fit into the testbench:
* ip_version_split
* axis_combiner
 */
entity module_wrapper is
	generic(
		g_module          : string;
		-- g_ip_version is only used for ipfix_header
		-- all other ip version dependent modules can derive it from the port widths
		g_ip_version      : natural;
		g_in_tdata_width  : natural;
		g_out_tdata_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m_tdata  : in  std_ulogic_vector(g_in_tdata_width     - 1 downto 0);
		if_axis_in_m_tkeep  : in  std_ulogic_vector(g_in_tdata_width / 8 - 1 downto 0);
		if_axis_in_m_tlast  : in  std_ulogic;
		if_axis_in_m_tvalid : in  std_ulogic;
		if_axis_in_s_tready : out std_ulogic;

		if_axis_out_m_tdata  : out std_ulogic_vector(g_out_tdata_width     - 1 downto 0);
		if_axis_out_m_tkeep  : out std_ulogic_vector(g_out_tdata_width / 8 - 1 downto 0);
		if_axis_out_m_tlast  : out std_ulogic;
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s_tready : in  std_ulogic;

		read_enable  : in  std_ulogic;
		write_enable : in  std_ulogic;
		data_in      : out std_ulogic_vector(31 downto 0);
		data_out     : in  std_ulogic_vector(31 downto 0);
		address      : in  std_ulogic_vector(31 downto 0);
		read_valid   : out std_ulogic
	);
end entity;

architecture arch of module_wrapper is
	signal s_drop_source_mac_enable : std_ulogic;
	signal s_timestamp              : t_timestamp;
	signal s_cache_active_timeout   : t_timeout;
	signal s_cache_inactive_timeout : t_timeout;
	signal s_ipfix_message_timeout  : t_timeout;
	signal s_ipfix_config_ipv6      : t_ipfix_config;
	signal s_ipfix_config_ipv4      : t_ipfix_config;
	signal s_ipfix_config_used      : t_ipfix_config;
	signal s_udp_config             : t_udp_config;
	signal s_ip_config              : t_ip_config;
	signal s_vlan_config            : t_vlan_config;
	signal s_ethernet_config        : t_ethernet_config;

	signal s_events : std_ulogic_vector(c_number_of_counters - 1 downto 0);
begin
	s_events(0) <= if_axis_in_m_tvalid  and if_axis_in_m_tlast  and if_axis_in_s_tready;
	s_events(3) <= if_axis_out_m_tvalid and if_axis_out_m_tlast and if_axis_out_s_tready;

	i_testbench_test_dummy : if g_module = "testbench_test_dummy" generate
		i_cond_gen : entity axis_testbench.testbench_test_dummy
			generic map(
				g_in_tdata_width  => g_in_tdata_width,
				g_out_tdata_width => g_out_tdata_width
			)
			port map(
				clk                  => clk,
				rst                  => rst,

				if_axis_in_m_tdata   => if_axis_in_m_tdata,
				if_axis_in_m_tkeep   => if_axis_in_m_tkeep,
				if_axis_in_m_tlast   => if_axis_in_m_tlast,
				if_axis_in_m_tvalid  => if_axis_in_m_tvalid,
				if_axis_in_s_tready  => if_axis_in_s_tready,

				if_axis_out_m_tdata  => if_axis_out_m_tdata,
				if_axis_out_m_tkeep  => if_axis_out_m_tkeep,
				if_axis_out_m_tlast  => if_axis_out_m_tlast,
				if_axis_out_m_tvalid => if_axis_out_m_tvalid,
				if_axis_out_s_tready => if_axis_out_s_tready,

				read_enable  => read_enable,
				write_enable => write_enable,
				data_in      => data_in,
				data_out     => data_out,
				address      => address,
				read_valid   => read_valid
			);
		end generate;

	i_selective_dropping : if g_module = "selective_dropping" generate
		i_cond_gen : entity ipfix_exporter.selective_dropping
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_drop_source_mac_enable => s_drop_source_mac_enable,
				cpu_ethernet_config        => s_ethernet_config
			);
		end generate;

	i_ethernet_dropping : if g_module = "ethernet_dropping" generate
		i_cond_gen : entity ipfix_exporter.ethernet_dropping
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready
			);
		end generate;

	i_vlan_dropping : if g_module = "vlan_dropping" generate
		i_cond_gen : entity ipfix_exporter.vlan_dropping
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready
			);
		end generate;

	i_ethertype_dropping : if g_module = "ethertype_dropping" generate
		i_cond_gen : entity ipfix_exporter.ethertype_dropping
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready
			);
		end generate;

	i_information_extraction : if g_module = "information_extraction" generate
		i_cond_gen : entity ipfix_exporter.information_extraction
			generic map (
				g_frame_info_width => g_out_tdata_width
				)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m_tdata  => if_axis_out_m_tdata ,
				if_axis_out_m_tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_timestamp => s_timestamp
			);
		if_axis_out_m_tkeep <= (others => '1');
		if_axis_out_m_tlast <= '1';
		end generate;

	i_cache_wrapper : if g_module = "cache_wrapper" generate
		i_cond_gen : entity axis_testbench.cache_wrapper
			generic map(
				g_in_tdata_width  => g_in_tdata_width,
				g_out_tdata_width => g_out_tdata_width
			)
			port map(
				clk                        => clk,
				rst                        => rst,
				if_axis_in_m_tdata         => if_axis_in_m_tdata,
				if_axis_in_m_tvalid        => if_axis_in_m_tvalid,
				if_axis_in_s.tready        => if_axis_in_s_tready,

				if_axis_out_m_tdata        => if_axis_out_m_tdata,
				if_axis_out_m_tvalid       => if_axis_out_m_tvalid,
				if_axis_out_s.tready       => if_axis_out_s_tready,

				cpu_collision_event        => s_events(6),
				cpu_cache_active_timeout   => s_cache_active_timeout,
				cpu_cache_inactive_timeout => s_cache_inactive_timeout,

				cpu_timestamp              => s_timestamp
			);
			s_events(17) <= s_events(6);
		end generate;

	i_ipfix_message_control : if g_module = "ipfix_message_control" generate
		i_cond_gen : entity ipfix_exporter.ipfix_message_control
			generic map (
				g_record_width => g_in_tdata_width
				)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m_tdata  => if_axis_in_m_tdata ,
				if_axis_in_m_tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_ipfix_config          => s_ipfix_config_used,
				cpu_ipfix_message_timeout => s_ipfix_message_timeout
			);
		end generate;

	s_ipfix_config_used <= s_ipfix_config_ipv6 when g_ip_version = 6 else s_ipfix_config_ipv4;
	i_ipfix_header : if g_module = "ipfix_header" generate
		i_cond_gen : entity ipfix_exporter.ipfix_header
			generic map (
				g_ip_version => g_ip_version
				)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_ipfix_config => s_ipfix_config_used,
				cpu_timestamp    => s_timestamp
			);
		end generate;

	i_udp_header : if g_module = "udp_header" generate
		i_cond_gen : entity ipfix_exporter.udp_header
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_udp_config => s_udp_config,
				cpu_ip_config  => s_ip_config
			);
		end generate;

	i_ip_header : if g_module = "ip_header" generate
		i_cond_gen : entity ipfix_exporter.ip_header
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_ip_config => s_ip_config
			);
		end generate;

	i_ethertype_insertion : if g_module = "ethertype_insertion" generate
		i_cond_gen : entity ipfix_exporter.ethertype_insertion
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready
			);
		end generate;

	i_vlan_insertion : if g_module = "vlan_insertion" generate
		i_cond_gen : entity ipfix_exporter.vlan_insertion
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_vlan_config => s_vlan_config
			);
		end generate;

	i_ethernet_header : if g_module = "ethernet_header" generate
		i_cond_gen : entity ipfix_exporter.ethernet_header
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tdata  => if_axis_in_m_tdata ,
				if_axis_in_m.tkeep  => if_axis_in_m_tkeep ,
				if_axis_in_m.tlast  => if_axis_in_m_tlast ,
				if_axis_in_m.tvalid => if_axis_in_m_tvalid,
				if_axis_in_s.tready => if_axis_in_s_tready,

				if_axis_out_m.tdata  => if_axis_out_m_tdata ,
				if_axis_out_m.tkeep  => if_axis_out_m_tkeep ,
				if_axis_out_m.tlast  => if_axis_out_m_tlast ,
				if_axis_out_m.tvalid => if_axis_out_m_tvalid,
				if_axis_out_s.tready => if_axis_out_s_tready,

				cpu_ethernet_config => s_ethernet_config
			);
		end generate;

	-- never tested
	-- only for compile checks
	i_ip_version_split : if g_module="i_ip_version_split" generate
		i_never_happens : entity ipfix_exporter.ip_version_split
			port map(
				clk                    => clk,
				rst                    => rst,

				if_axis_in_m => c_if_axis_frame_m_default ,
				if_axis_in_s => open,

				if_axis_out_ipv6_m => open,
				if_axis_out_ipv6_s => c_if_axis_s_default,

				if_axis_out_ipv4_m => open,
				if_axis_out_ipv4_s => c_if_axis_s_default
			);
		end generate;

	i_cpu_interface : if g_module /= "testbench_test_dummy" generate
		i_cond_gen : entity ipfix_exporter.cpu_interface
			port map(
				clk                    => clk,
				rst                    => rst,

				read_enable            => read_enable,
				write_enable           => write_enable,
				data_in                => data_in,
				data_out               => data_out,
				address                => address,
				read_valid             => read_valid,

				drop_source_mac_enable => s_drop_source_mac_enable,
				timestamp              => s_timestamp,
				cache_active_timeout   => s_cache_active_timeout,
				cache_inactive_timeout => s_cache_inactive_timeout,
				ipfix_message_timeout  => s_ipfix_message_timeout,
				ipfix_config_ipv6      => s_ipfix_config_ipv6,
				ipfix_config_ipv4      => s_ipfix_config_ipv4,
				udp_config             => s_udp_config,
				ip_config              => s_ip_config,
				vlan_config            => s_vlan_config,
				ethernet_config        => s_ethernet_config,
				events                 => s_events
			);
		end generate;
end architecture;
