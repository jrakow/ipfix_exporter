use std.textio.all;
use std.env.all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module drops a single VLAN tag.
It consists of generic components.

@dot
digraph overview
	{
	node [shape=box];
	input  [ label="input"  shape=circle ];
	output [ label="output" shape=circle ];

	i_conditional_split_0 [label="i_conditional_split_0" URL="@ref conditional_split"];
	i_conditional_split_1 [label="i_conditional_split_1" URL="@ref conditional_split"];
	i_generic_dropping_0  [label="i_generic_dropping_0"  URL="@ref generic_dropping" ];
	i_generic_dropping_1  [label="i_generic_dropping_1"  URL="@ref generic_dropping" ];
	i_axis_combiner_0     [label="i_axis_combiner_0"     URL="@ref axis_combiner"    ];
	i_axis_combiner_1     [label="i_axis_combiner_1"     URL="@ref axis_combiner"    ];

	input -> i_conditional_split_0;
	i_conditional_split_0 -> i_axis_combiner_0 [label="no_first_tag"];
	i_conditional_split_0 -> i_generic_dropping_0 -> i_axis_combiner_0 [label="first_tag"];
	i_axis_combiner_0     -> i_conditional_split_1;
	i_conditional_split_1 -> i_axis_combiner_1 [label="no_tags"];
	i_conditional_split_1 -> i_generic_dropping_1 -> i_axis_combiner_1 [label="second_tag"];
	i_axis_combiner_1     -> output;
	}
@enddot
 */
entity vlan_dropping is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of vlan_dropping is
	signal s_if_axis_middle_m : t_if_axis_frame_m;
	signal s_if_axis_middle_s : t_if_axis_s;
begin
	b_drop_first_tag : block
		signal s_has_tag  : std_ulogic;
		alias ethertype : std_ulogic_vector(15 downto 0) is if_axis_in_m.tdata(127 downto 112);

		signal s_if_axis_tag_0_m  : t_if_axis_frame_m;
		signal s_if_axis_tag_0_s  : t_if_axis_s;
		signal s_if_axis_tag_1_m  : t_if_axis_frame_m;
		signal s_if_axis_tag_1_s  : t_if_axis_s;
		signal s_if_axis_no_tag_m : t_if_axis_frame_m;
		signal s_if_axis_no_tag_s : t_if_axis_s;
	begin
		s_has_tag <= '1' when ethertype = x"88A8" else '0';

		i_conditional_split : entity ipfix_exporter.conditional_split
			port map(
				clk => clk,
				rst => rst,

				target_1_not_0  => s_has_tag,

				if_axis_in_m => if_axis_in_m,
				if_axis_in_s => if_axis_in_s,

				if_axis_out_0_m => s_if_axis_no_tag_m,
				if_axis_out_0_s => s_if_axis_no_tag_s,

				if_axis_out_1_m => s_if_axis_tag_0_m,
				if_axis_out_1_s => s_if_axis_tag_0_s
				);
		i_generic_dropping : entity ipfix_exporter.generic_dropping
			generic map(
				g_kept_bytes => 12
			)
			port map(
				clk => clk,
				rst => rst,

				if_axis_in_m => s_if_axis_tag_0_m,
				if_axis_in_s => s_if_axis_tag_0_s,

				if_axis_out_m => s_if_axis_tag_1_m,
				if_axis_out_s => s_if_axis_tag_1_s
			);
		i_axis_combiner : entity ipfix_exporter.axis_combiner
			port map(
				clk            => clk,
				rst            => rst,

				if_axis_in_m_0 => s_if_axis_tag_1_m,
				if_axis_in_s_0 => s_if_axis_tag_1_s,

				if_axis_in_m_1 => s_if_axis_no_tag_m,
				if_axis_in_s_1 => s_if_axis_no_tag_s,

				if_axis_out_m  => s_if_axis_middle_m,
				if_axis_out_s  => s_if_axis_middle_s
			);
	end block;

	b_drop_second_tag : block
		signal s_has_tag  : std_ulogic;
		alias ethertype : std_ulogic_vector(15 downto 0) is s_if_axis_middle_m.tdata(127 downto 112);

		signal s_if_axis_tag_0_m  : t_if_axis_frame_m;
		signal s_if_axis_tag_0_s  : t_if_axis_s;
		signal s_if_axis_tag_1_m  : t_if_axis_frame_m;
		signal s_if_axis_tag_1_s  : t_if_axis_s;
		signal s_if_axis_no_tag_m : t_if_axis_frame_m;
		signal s_if_axis_no_tag_s : t_if_axis_s;
	begin
		s_has_tag <= '1' when ethertype = x"8100" else '0';

		i_conditional_split : entity ipfix_exporter.conditional_split
			port map(
				clk => clk,
				rst => rst,

				target_1_not_0  => s_has_tag,

				if_axis_in_m => s_if_axis_middle_m,
				if_axis_in_s => s_if_axis_middle_s,

				if_axis_out_0_m => s_if_axis_no_tag_m,
				if_axis_out_0_s => s_if_axis_no_tag_s,

				if_axis_out_1_m => s_if_axis_tag_0_m,
				if_axis_out_1_s => s_if_axis_tag_0_s
				);
		i_generic_dropping : entity ipfix_exporter.generic_dropping
			generic map(
				g_kept_bytes => 12
			)
			port map(
				clk => clk,
				rst => rst,

				if_axis_in_m => s_if_axis_tag_0_m,
				if_axis_in_s => s_if_axis_tag_0_s,

				if_axis_out_m => s_if_axis_tag_1_m,
				if_axis_out_s => s_if_axis_tag_1_s
			);
		i_axis_combiner : entity ipfix_exporter.axis_combiner
			port map(
				clk            => clk,
				rst            => rst,

				if_axis_in_m_0 => s_if_axis_tag_1_m,
				if_axis_in_s_0 => s_if_axis_tag_1_s,

				if_axis_in_m_1 => s_if_axis_no_tag_m,
				if_axis_in_s_1 => s_if_axis_no_tag_s,

				if_axis_out_m  => if_axis_out_m,
				if_axis_out_s  => if_axis_out_s
			);
	end block;
end architecture;
