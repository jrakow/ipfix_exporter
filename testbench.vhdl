use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

library axis_testbench;

/*!
The testbench is a full environment to test a single module or combination of modules with AXI stream interfaces.

The testbench instantiates an AXIS generator and an AXIS checker.

The testbench generates a clock signal with a period specified by generic.
For a single clock signal the global reset signal is set to active.
The testbench then waites for the AXIS generator and checker modules.

Also the test fails if a timeout is met.

One AXIS interface connects the generator to the design under test input, another the output to the checker.
 */
entity testbench is
	generic (
		in_filename  : string := "cases/testbench_00_in.dat";
		out_filename : string := "cases/testbench_00_out.dat";

		g_in_tdata_width  : natural := 64;
		g_out_tdata_width : natural := 64;

		g_period  : time := 10 ns;
		g_timeout : time :=  1 ms
	);
end entity;

architecture arch of testbench is
	signal s_clk : std_ulogic := '1';
	signal s_rst : std_ulogic;

	signal s_if_axis_in_m_tdata   : std_ulogic_vector(g_in_tdata_width - 1 downto 0);
	signal s_if_axis_in_m_tvalid  : std_ulogic;
	signal s_if_axis_in_s_tready  : std_ulogic;
	signal s_if_axis_out_m_tdata  : std_ulogic_vector(g_out_tdata_width - 1 downto 0);
	signal s_if_axis_out_m_tvalid : std_ulogic;
	signal s_if_axis_out_s_tready : std_ulogic;

	signal s_generator_finished : std_ulogic;
	signal s_checker_finished   : std_ulogic;
begin
	s_clk <= not s_clk after g_period / 2;

	p_testrun : process
	begin
		report "start";
		s_rst <= '1';
		wait until rising_edge(s_clk);
		s_rst <= '0';

		wait until rising_edge(s_clk) and s_generator_finished = '1';
		report "generator finished";
		wait until rising_edge(s_clk) and s_checker_finished = '1';
		report "checker finished";
		report "simulation finished";
		-- exit without failure
		stop(0);
	end process;

	i_axis_generator : entity axis_testbench.axis_generator
		generic map(
			g_filename    => in_filename,
			g_tdata_width => g_in_tdata_width
		)
		port map(
			clk              => s_clk,
			rst              => s_rst,
			if_axis_m_tdata  => s_if_axis_in_m_tdata,
			if_axis_m_tvalid => s_if_axis_in_m_tvalid,
			if_axis_s_tready => s_if_axis_in_s_tready,
			finished         => s_generator_finished
		);

	i_axis_checker : entity axis_testbench.axis_checker
		generic map(
			g_filename    => out_filename,
			g_tdata_width => g_out_tdata_width
		)
		port map(
			clk              => s_clk,
			rst              => s_rst,
			if_axis_m_tdata  => s_if_axis_out_m_tdata,
			if_axis_m_tvalid => s_if_axis_out_m_tvalid,
			if_axis_s_tready => s_if_axis_out_s_tready,
			finished         => s_checker_finished
		);

	i_design_under_test : entity axis_testbench.testbench_test_dummy
		generic map(
			g_in_tdata_width  => g_out_tdata_width,
			g_out_tdata_width => g_out_tdata_width
		)
		port map(
			clk                  => s_clk,
			rst                  => s_rst,
			if_axis_in_m_tdata   => s_if_axis_in_m_tdata,
			if_axis_in_m_tvalid  => s_if_axis_in_m_tvalid,
			if_axis_in_s_tready  => s_if_axis_in_s_tready,
			if_axis_out_m_tdata  => s_if_axis_out_m_tdata,
			if_axis_out_m_tvalid => s_if_axis_out_m_tvalid,
			if_axis_out_s_tready => s_if_axis_out_s_tready
		);

	p_timeout : process
	begin
		report "timeout started";
		wait for g_timeout;
		assert false report "timeout reached" severity failure;
		stop(1);
	end process;
end architecture;
