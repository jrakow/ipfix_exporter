library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axis_testbench;

-- TODO user libraries here

/*!
This module wraps is a wrapper for a design under test.
It contains no functionality.

The design under test is chosen based on the g_module generic.
 */
entity module_wrapper is
	generic(
		g_module          : string;
		g_in_tdata_width  : natural;
		g_out_tdata_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m_tdata  : in  std_ulogic_vector(g_in_tdata_width     - 1 downto 0);
		if_axis_in_m_tkeep  : in  std_ulogic_vector(g_in_tdata_width / 8 - 1 downto 0);
		if_axis_in_m_tlast  : in  std_ulogic;
		if_axis_in_m_tvalid : in  std_ulogic;
		if_axis_in_s_tready : out std_ulogic;

		if_axis_out_m_tdata  : out std_ulogic_vector(g_out_tdata_width     - 1 downto 0);
		if_axis_out_m_tkeep  : out std_ulogic_vector(g_out_tdata_width / 8 - 1 downto 0);
		if_axis_out_m_tlast  : out std_ulogic;
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s_tready : in  std_ulogic;

		read_enable  : in  std_ulogic;
		write_enable : in  std_ulogic;
		data_in      : out std_ulogic_vector(31 downto 0);
		data_out     : in  std_ulogic_vector(31 downto 0);
		address      : in  std_ulogic_vector(31 downto 0);
		read_valid   : out std_ulogic
	);
end entity;

architecture arch of module_wrapper is
	-- TODO user signals here
begin
	-- TODO user modules here
	-- may be conditionally generated

	i_testbench_test_dummy : if g_module = "testbench_test_dummy" generate
		i_cond_gen : entity axis_testbench.testbench_test_dummy
			generic map(
				g_in_tdata_width  => g_in_tdata_width,
				g_out_tdata_width => g_out_tdata_width
			)
			port map(
				clk                  => clk,
				rst                  => rst,

				if_axis_in_m_tdata   => if_axis_in_m_tdata,
				if_axis_in_m_tkeep   => if_axis_in_m_tkeep,
				if_axis_in_m_tlast   => if_axis_in_m_tlast,
				if_axis_in_m_tvalid  => if_axis_in_m_tvalid,
				if_axis_in_s_tready  => if_axis_in_s_tready,

				if_axis_out_m_tdata  => if_axis_out_m_tdata,
				if_axis_out_m_tkeep  => if_axis_out_m_tkeep,
				if_axis_out_m_tlast  => if_axis_out_m_tlast,
				if_axis_out_m_tvalid => if_axis_out_m_tvalid,
				if_axis_out_s_tready => if_axis_out_s_tready
			);
		end generate;
end architecture;
