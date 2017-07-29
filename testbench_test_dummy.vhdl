library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! simple loopback entity to connect the testbench generator and checker directly together
entity testbench_test_dummy is
	generic(
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
		if_axis_out_s_tready : in  std_ulogic
	);
end entity;

architecture arch of testbench_test_dummy is
begin
	if_axis_out_m_tdata  <= if_axis_in_m_tdata;
	if_axis_out_m_tvalid <= if_axis_in_m_tvalid;
	if_axis_out_m_tkeep  <= if_axis_in_m_tkeep;
	if_axis_out_m_tlast  <= if_axis_in_m_tlast;
	if_axis_in_s_tready  <= if_axis_out_s_tready;

	assert g_in_tdata_width = g_out_tdata_width
		report "testbench_test_dummy may only used with the same tdata width"
		severity failure;
end architecture;
