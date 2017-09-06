library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/*!
This module drops the Ethernet header.
MAC addresses are dropped.

This module assumes there are more than 4 byte following the mac addresses (i. e. there is a second frame).
 */
entity ethernet_dropping is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of ethernet_dropping is
begin
	i_generic_dropping : entity ipfix_exporter.generic_dropping
		generic map(
			g_kept_bytes => 4
		)
		port map(
			clk => clk,
			rst => rst,

			if_axis_in_m => if_axis_in_m,
			if_axis_in_s => if_axis_in_s,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s
		);
end architecture;
