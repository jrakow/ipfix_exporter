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
		g_in_filename  : string := "this should be overwritten";
		g_out_filename : string := "this should be overwritten";
		g_emu_filename : string := "this should be overwritten";
		g_module       : string := "testbench_test_dummy";

		g_in_tdata_width  : natural := 64;
		g_out_tdata_width : natural := 64;

		g_period  : time := 10 ns;
		g_timeout : time :=  1 ms
	);
end entity;

architecture arch of testbench is
	signal s_clk : std_ulogic := '1';
	signal s_rst : std_ulogic;

	signal s_if_axis_in_m_tdata   : std_ulogic_vector(g_in_tdata_width     - 1 downto 0);
	signal s_if_axis_in_m_tkeep   : std_ulogic_vector(g_in_tdata_width / 8 - 1 downto 0);
	signal s_if_axis_in_m_tlast   : std_ulogic;
	signal s_if_axis_in_m_tvalid  : std_ulogic;
	signal s_if_axis_in_s_tready  : std_ulogic;
	signal s_if_axis_out_m_tdata  : std_ulogic_vector(g_out_tdata_width     - 1 downto 0);
	signal s_if_axis_out_m_tkeep  : std_ulogic_vector(g_out_tdata_width / 8 - 1 downto 0);
	signal s_if_axis_out_m_tlast  : std_ulogic;
	signal s_if_axis_out_m_tvalid : std_ulogic;
	signal s_if_axis_out_s_tready : std_ulogic;

	signal s_read_enable  : std_ulogic;
	signal s_write_enable : std_ulogic;
	signal s_data_in      : std_ulogic_vector(31 downto 0);
	signal s_data_out     : std_ulogic_vector(31 downto 0);
	signal s_address      : std_ulogic_vector(31 downto 0);
	signal s_read_valid   : std_ulogic;

	signal s_generator_finished : std_ulogic;
	signal s_checker_finished   : std_ulogic;
	signal s_emulator_finished  : std_ulogic;
begin
	s_clk <= not s_clk after g_period / 2;

	p_testrun : process
	begin
		s_rst <= '1';
		wait until rising_edge(s_clk);
		s_rst <= '0';

		wait until rising_edge(s_clk) and s_emulator_finished = '1';
		report "emulator finished";
		wait until rising_edge(s_clk) and s_generator_finished = '1';
		report "generator finished";
		wait until rising_edge(s_clk) and s_checker_finished = '1';
		report "checker finished";
		-- exit without failure
		stop(0);
	end process;

	i_axis_generator : entity axis_testbench.axis_generator
		generic map(
			g_filename    => g_in_filename,
			g_tdata_width => g_in_tdata_width
		)
		port map(
			clk              => s_clk,
			rst              => s_rst,
			if_axis_m_tdata  => s_if_axis_in_m_tdata,
			if_axis_m_tkeep  => s_if_axis_in_m_tkeep,
			if_axis_m_tlast  => s_if_axis_in_m_tlast,
			if_axis_m_tvalid => s_if_axis_in_m_tvalid,
			if_axis_s_tready => s_if_axis_in_s_tready,
			finished         => s_generator_finished
		);

	i_axis_checker : entity axis_testbench.axis_checker
		generic map(
			g_filename          => g_out_filename,
			g_tdata_width       => g_out_tdata_width
		)
		port map(
			clk              => s_clk,
			rst              => s_rst,
			if_axis_m_tdata  => s_if_axis_out_m_tdata,
			if_axis_m_tvalid => s_if_axis_out_m_tvalid,
			if_axis_m_tkeep  => s_if_axis_out_m_tkeep,
			if_axis_m_tlast  => s_if_axis_out_m_tlast,
			if_axis_s_tready => s_if_axis_out_s_tready,
			finished         => s_checker_finished
		);

	i_design_under_test : if g_module = "testbench_test_dummy" generate
		i_cond_gen : entity axis_testbench.testbench_test_dummy
			generic map(
				g_in_tdata_width  => g_in_tdata_width,
				g_out_tdata_width => g_out_tdata_width
			)
			port map(
				clk                  => s_clk,
				rst                  => s_rst,

				if_axis_in_m_tdata   => s_if_axis_in_m_tdata,
				if_axis_in_m_tkeep   => s_if_axis_in_m_tkeep,
				if_axis_in_m_tlast   => s_if_axis_in_m_tlast,
				if_axis_in_m_tvalid  => s_if_axis_in_m_tvalid,
				if_axis_in_s_tready  => s_if_axis_in_s_tready,
				if_axis_out_m_tdata  => s_if_axis_out_m_tdata,
				if_axis_out_m_tkeep  => s_if_axis_out_m_tkeep,
				if_axis_out_m_tlast  => s_if_axis_out_m_tlast,
				if_axis_out_m_tvalid => s_if_axis_out_m_tvalid,
				if_axis_out_s_tready => s_if_axis_out_s_tready
			);
		end generate;

	-- paste more modules here

	i_cpu_emulator : entity axis_testbench.cpu_emulator
		generic map(
			g_filename => g_emu_filename
		)
		port map(
			clk          => s_clk,
			rst          => s_rst,

			read_enable  => s_read_enable,
			write_enable => s_write_enable,
			data_in      => s_data_in,
			data_out     => s_data_out,
			address      => s_address,
			read_valid   => s_read_valid,

			finished     => s_emulator_finished
		);

	p_timeout : process
	begin
		wait for g_timeout;
		assert false report "timeout reached" severity failure;
		stop(1);
	end process;
end architecture;
