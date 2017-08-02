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

		g_in_tdata_width  : natural := 0;
		g_out_tdata_width : natural := 0;
		g_ip_version      : natural := 0;

		g_random_tvalid_seed_0 : positive := 1;
		g_random_tvalid_seed_1 : positive := 2;
		g_random_tready_seed_0 : positive := 3;
		g_random_tready_seed_1 : positive := 4;
		g_tvalid_ratio         : real     := 0.5;
		g_tready_ratio         : real     := 0.5;

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

	signal s_generator_event    : boolean;
	signal s_checker_event      : boolean;
	signal s_emulator_event     : boolean;

	signal s_generator_finished : boolean;
	signal s_checker_finished   : boolean;
	signal s_emulator_finished  : boolean;
begin
	s_clk <= not s_clk after g_period / 2;

	p_testrun : process
	begin
		s_rst <= '1';
		wait until rising_edge(s_clk);
		s_rst <= '0';

		loop
			wait until rising_edge(s_clk);
			if rising_edge(s_generator_finished) then
				report "generator finished";
			end if;
			if rising_edge(s_checker_finished) then
				report "checker finished";
			end if;
			if rising_edge(s_emulator_finished) then
				report "emulator finished";
			end if;

			if s_generator_finished and s_checker_finished and s_emulator_finished then
				-- exit without failure
				stop(0);
			end if;
		end loop;
	end process;

	i_axis_generator : entity axis_testbench.axis_generator
		generic map(
			g_filename      => g_in_filename,
			g_tdata_width   => g_in_tdata_width,
			g_random_seed_0 => g_random_tvalid_seed_0,
			g_random_seed_1 => g_random_tvalid_seed_1,
			g_tvalid_ratio  => g_tvalid_ratio
		)
		port map(
			clk              => s_clk,
			rst              => s_rst,
			if_axis_m_tdata  => s_if_axis_in_m_tdata,
			if_axis_m_tkeep  => s_if_axis_in_m_tkeep,
			if_axis_m_tlast  => s_if_axis_in_m_tlast,
			if_axis_m_tvalid => s_if_axis_in_m_tvalid,
			if_axis_s_tready => s_if_axis_in_s_tready,
			finished         => s_generator_finished,
			generator_event  => s_generator_event,
			checker_event    => s_checker_event,
			emulator_event   => s_emulator_event
		);

	i_axis_checker : entity axis_testbench.axis_checker
		generic map(
			g_filename          => g_out_filename,
			g_tdata_width       => g_out_tdata_width,
			g_random_seed_0     => g_random_tready_seed_0,
			g_random_seed_1     => g_random_tready_seed_1,
			g_tready_ratio      => g_tready_ratio
		)
		port map(
			clk              => s_clk,
			rst              => s_rst,
			if_axis_m_tdata  => s_if_axis_out_m_tdata,
			if_axis_m_tvalid => s_if_axis_out_m_tvalid,
			if_axis_m_tkeep  => s_if_axis_out_m_tkeep,
			if_axis_m_tlast  => s_if_axis_out_m_tlast,
			if_axis_s_tready => s_if_axis_out_s_tready,
			finished         => s_checker_finished,
			generator_event  => s_generator_event,
			checker_event    => s_checker_event,
			emulator_event   => s_emulator_event
		);

	i_design_under_test : entity axis_testbench.module_wrapper
		generic map(
			g_module          => g_module,
			g_in_tdata_width  => g_in_tdata_width,
			g_out_tdata_width => g_out_tdata_width,
			g_ip_version      => g_ip_version
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
			if_axis_out_s_tready => s_if_axis_out_s_tready,

			read_enable          => s_read_enable,
			write_enable         => s_write_enable,
			data_in              => s_data_in,
			data_out             => s_data_out,
			address              => s_address,
			read_valid           => s_read_valid
		);

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

			finished     => s_emulator_finished,
			generator_event  => s_generator_event,
			checker_event    => s_checker_event,
			emulator_event   => s_emulator_event
		);

	p_timeout : process
	begin
		wait for g_timeout;
		assert false report "timeout reached" severity failure;
		stop(1);
	end process;
end architecture;
