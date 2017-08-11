library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module drops the Ethertype field.

The output IP packet starts at the IP header.
The Ethertype field is dropped.
 */
entity ethertype_dropping is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of ethertype_dropping is
begin
	i_generic_dropping : entity ipfix_exporter.generic_dropping
		generic map(
			g_kept_bytes => 14
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
