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
		if_axis_out_s_tready : in  std_ulogic;

		read_enable  : in  std_ulogic;
		write_enable : in  std_ulogic;
		data_in      : out std_ulogic_vector(31 downto 0);
		data_out     : in  std_ulogic_vector(31 downto 0);
		address      : in  std_ulogic_vector(31 downto 0);
		read_valid   : out std_ulogic
	);
end entity;

architecture arch of testbench_test_dummy is
	signal s_scratchpad : std_ulogic_vector(31 downto 0);
begin
	if_axis_out_m_tdata  <= if_axis_in_m_tdata;
	if_axis_out_m_tvalid <= if_axis_in_m_tvalid;
	if_axis_out_m_tkeep  <= if_axis_in_m_tkeep;
	if_axis_out_m_tlast  <= if_axis_in_m_tlast;
	if_axis_in_s_tready  <= if_axis_out_s_tready;

	assert g_in_tdata_width = g_out_tdata_width
		report "testbench_test_dummy may only used with the same tdata width"
		severity failure;

	p_read : process(clk)
	begin
		if rising_edge(clk) then
			if rst then
				data_in    <= (others => '0');
				read_valid <= '0';
			elsif read_enable then
				read_valid <= '1';
				case address is
					when x"00000000"  => data_in    <= s_scratchpad;
					when others => read_valid <= '0';
				end case;
			else
				read_valid <= '0';
			end if;
		end if;
	end process;

	p_write : process(clk)
	begin
		if rising_edge(clk) then
			if rst  then
				s_scratchpad           <= (others => '0');
			elsif write_enable then
				case address is
					when x"00000000"  => s_scratchpad <= data_out;
					when others =>
				end case;
			end if;
		end if;
	end process;
end architecture;
