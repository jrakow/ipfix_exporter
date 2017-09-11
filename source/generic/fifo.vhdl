library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
	generic (
		g_data_width : natural;
		g_depth      : natural
		);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		data_in      : in  std_ulogic_vector(g_data_width - 1 downto 0);
		write_enable : in  std_ulogic;
		full         : out std_ulogic;
		data_out     : out std_ulogic_vector(g_data_width - 1 downto 0);
		read_enable  : in  std_ulogic;
		empty        : out std_ulogic
	);
end entity;

architecture arch of fifo is
	type t_fifo is array (0 to g_depth - 1) of std_logic_vector(g_data_width - 1 downto 0);
	signal s_fifo : t_fifo;

	function log2(n : positive) return natural is
		variable tmp : natural := n;
		variable ret : natural := 0;
	begin
		while tmp > 1 loop
			ret := ret + 1;
			tmp := tmp / 2;
		end loop;
		return ret;
	end function;

	constant c_addr_width : natural := log2(g_depth);
	signal s_addr_write : unsigned(c_addr_width - 1 downto 0);
	signal s_addr_read  : unsigned(c_addr_width - 1 downto 0);
begin
	assert 2**c_addr_width = g_depth;

	p_write : process(clk)
	begin
		if rising_edge(clk) then
			if rst then
				s_addr_write <= (others => '0');
			elsif write_enable and not full then
				s_fifo(to_integer(s_addr_write)) <= data_in;
				s_addr_write                     <= s_addr_write + 1;
			end if;
		end if;
	end process;

	p_read : process(clk)
	begin
		if rising_edge(clk) then
			data_out <= s_fifo(to_integer(s_addr_read));
			if rst then
				s_addr_read <= (others => '0');
			elsif read_enable and not empty then
				s_addr_read <= s_addr_read + 1;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst then
				full  <= '0';
				empty <= '0';
			else
				full  <= '1' when s_addr_write = s_addr_read - 1 else '0';
				empty <= '1' when s_addr_write = s_addr_read     else '0';
			end if;
		end if;
	end process;
end architecture;
