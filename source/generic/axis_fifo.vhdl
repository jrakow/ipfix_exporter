library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;

entity axis_fifo is
	generic (
		g_depth : natural
		);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of axis_fifo is
	signal s_data_in  : std_ulogic_vector(128 + 16 downto 0);
	signal s_data_out : std_ulogic_vector(128 + 16 downto 0);
	signal s_full     : std_ulogic;
	signal s_empty    : std_ulogic;
begin
	s_data_in <= if_axis_in_m.tlast & if_axis_in_m.tkeep & if_axis_in_m.tdata;
	if_axis_in_s.tready  <= not s_full ;

	if_axis_out_m.tlast  <= s_data_out(128 + 16);
	if_axis_out_m.tkeep  <= s_data_out(128 + 15 downto 128);
	if_axis_out_m.tdata  <= s_data_out(127 downto 0);
	if_axis_out_m.tvalid <= not s_empty;

	i_fifo : entity ipfix_exporter.fifo
		generic map(
			g_data_width => 1 + 16 + 128,
			g_depth      => g_depth
		)
		port map(
			clk          => clk,
			rst          => rst,

			data_in      => s_data_in,
			write_enable => if_axis_in_m.tvalid,
			full         => s_full,

			data_out     => s_data_out,
			read_enable  => if_axis_out_s.tready,
			empty        => s_empty
		);
end architecture;
