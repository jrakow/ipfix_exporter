library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module prefixes MAC addresses.

configuration in:
* `destination_mac_address`
* `source_mac_address`
 */
entity ethernet_header is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_ethernet_config : in t_ethernet_config
	);
end entity;

architecture arch of ethernet_header is
	constant c_prefix_width : natural := 96;
	signal s_prefix : std_ulogic_vector(95 downto 0);
begin
	s_prefix <= cpu_ethernet_config.destination & cpu_ethernet_config.source;

	i_generic_prefix : entity ipfix_exporter.generic_prefix
		generic map(
			g_prefix_width => c_prefix_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => if_axis_in_m,
			if_axis_in_s  => if_axis_in_s,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s,

			prefix        => s_prefix
		);
end architecture;
