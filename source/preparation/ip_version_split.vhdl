library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/*!
This module splits the incoming data by IP version.

The first one or two frames (depending on the number of VLANs) are buffered.
Only the IP version field of the IP header at the beginning of the third frame is considered.

This splits the data path into an IPv6 and an IPv4 path.
 */
entity ip_version_split is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_ipv6_m : out t_if_axis_frame_m;
		if_axis_out_ipv6_s : in  t_if_axis_s;

		if_axis_out_ipv4_m : out t_if_axis_frame_m;
		if_axis_out_ipv4_s : in  t_if_axis_s
	);
end entity;

architecture arch of ip_version_split is
	signal s_ipv6_else_ipv4 : std_ulogic;
begin
	p_condition : process(all)
	begin
		-- only read if in_transaction
		s_ipv6_else_ipv4 <= '1' when if_axis_in_m.tdata(127 downto 124) = x"6" else '0';
	end process;

	i_conditional_split : entity ipfix_exporter.conditional_split
		port map(
			clk => clk,
			rst => rst,

			target_1_not_0  => s_ipv6_else_ipv4,

			if_axis_in_m => if_axis_in_m,
			if_axis_in_s => if_axis_in_s,

			if_axis_out_0_m => if_axis_out_ipv4_m,
			if_axis_out_0_s => if_axis_out_ipv4_s,

			if_axis_out_1_m => if_axis_out_ipv6_m,
			if_axis_out_1_s => if_axis_out_ipv6_s
			);
end architecture;
