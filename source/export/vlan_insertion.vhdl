library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_types.all;

/*!
This module inserts VLAN tags.

The IP packet is prefixed by one or more VLAN tags.
`vlan0` is the earliest tag.

configuration in:
* `number_of_vlans`
* `vlan_tag_0`
* `vlan_tag_1`
 */
entity vlan_insertion is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_vlan_config : t_vlan_config
	);
end entity;

architecture arch of vlan_insertion is
	constant c_vlan_tag_width : natural := 32;

	signal s_enable_vlan_0 : std_ulogic;
	signal s_enable_vlan_1 : std_ulogic;

	signal s_if_axis_m_connect : t_if_axis_frame_m;
	signal s_if_axis_s_connect : t_if_axis_s;
begin
	s_enable_vlan_0 <= '1' when cpu_vlan_config.number_of_vlans >= 2 else '0';
	s_enable_vlan_1 <= '1' when cpu_vlan_config.number_of_vlans >= 1 else '0';

	b_vlan_1_insertion : block
		signal s_if_axis_m_0 : t_if_axis_frame_m;
		signal s_if_axis_s_0 : t_if_axis_s;
		signal s_if_axis_m_1 : t_if_axis_frame_m;
		signal s_if_axis_s_1 : t_if_axis_s;
		signal s_if_axis_m_2 : t_if_axis_frame_m;
		signal s_if_axis_s_2 : t_if_axis_s;
	begin
		i_conditional_split : entity ipfix_exporter.conditional_split
			port map(
				clk             => clk,
				rst             => rst,
				target_1_not_0  => s_enable_vlan_1,

				if_axis_in_m    => if_axis_in_m,
				if_axis_in_s    => if_axis_in_s,

				if_axis_out_0_m => s_if_axis_m_0,
				if_axis_out_0_s => s_if_axis_s_0,

				if_axis_out_1_m => s_if_axis_m_1,
				if_axis_out_1_s => s_if_axis_s_1
			);
		i_generic_prefix : entity ipfix_exporter.generic_prefix
			generic map(
				g_prefix_width => c_vlan_tag_width
			)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m  => s_if_axis_m_1,
				if_axis_in_s  => s_if_axis_s_1,

				if_axis_out_m => s_if_axis_m_2,
				if_axis_out_s => s_if_axis_s_2,

				prefix        => cpu_vlan_config.tag_1
			);
		i_axis_combiner : entity ipfix_exporter.axis_combiner
			port map(
				clk            => clk,
				rst            => rst,

				if_axis_in_m_0 => s_if_axis_m_0,
				if_axis_in_s_0 => s_if_axis_s_0,

				if_axis_in_m_1 => s_if_axis_m_2,
				if_axis_in_s_1 => s_if_axis_s_2,

				if_axis_out_m  => s_if_axis_m_connect,
				if_axis_out_s  => s_if_axis_s_connect
			);
	end block;

	b_vlan_0_insertion : block
		signal s_if_axis_m_0 : t_if_axis_frame_m;
		signal s_if_axis_s_0 : t_if_axis_s;
		signal s_if_axis_m_1 : t_if_axis_frame_m;
		signal s_if_axis_s_1 : t_if_axis_s;
		signal s_if_axis_m_2 : t_if_axis_frame_m;
		signal s_if_axis_s_2 : t_if_axis_s;
	begin
		i_conditional_split : entity ipfix_exporter.conditional_split
			port map(
				clk             => clk,
				rst             => rst,
				target_1_not_0  => s_enable_vlan_0,

				if_axis_in_m    => s_if_axis_m_connect,
				if_axis_in_s    => s_if_axis_s_connect,

				if_axis_out_0_m => s_if_axis_m_0,
				if_axis_out_0_s => s_if_axis_s_0,

				if_axis_out_1_m => s_if_axis_m_1,
				if_axis_out_1_s => s_if_axis_s_1
			);
		i_generic_prefix : entity ipfix_exporter.generic_prefix
			generic map(
				g_prefix_width => c_vlan_tag_width
			)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m  => s_if_axis_m_1,
				if_axis_in_s  => s_if_axis_s_1,

				if_axis_out_m => s_if_axis_m_2,
				if_axis_out_s => s_if_axis_s_2,

				prefix        => cpu_vlan_config.tag_0
			);
		i_axis_combiner : entity ipfix_exporter.axis_combiner
			port map(
				clk            => clk,
				rst            => rst,

				if_axis_in_m_0 => s_if_axis_m_0,
				if_axis_in_s_0 => s_if_axis_s_0,

				if_axis_in_m_1 => s_if_axis_m_2,
				if_axis_in_s_1 => s_if_axis_s_2,

				if_axis_out_m  => if_axis_out_m,
				if_axis_out_s  => if_axis_out_s
			);
	end block;
end architecture;
