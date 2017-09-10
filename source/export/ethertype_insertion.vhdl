library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_types.all;

/*!
This module inserts the Ethertype field.
 */
entity ethertype_insertion is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of ethertype_insertion is
	constant c_prefix_width : natural := 16;
	signal s_prefix : std_ulogic_vector(c_prefix_width - 1 downto 0);
begin
	-- ip version from ip header
	s_prefix <= x"86DD" when if_axis_in_m.tdata(127 downto 124) = x"6" else x"0800";

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
