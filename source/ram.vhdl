library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module is a generic block RAM with two true ports used as cache for active flows.
 */
entity ram is
	generic(
		g_addr_width : natural;
		g_data_width : natural
	);
	port(
		clk : in std_ulogic;

		enable_a       : in  std_ulogic;
		write_enable_a : in  std_ulogic;
		addr_a         : in  std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in_a      : in  std_ulogic_vector(g_data_width - 1 downto 0);
		data_out_a     : out std_ulogic_vector(g_data_width - 1 downto 0);

		enable_b       : in  std_ulogic;
		write_enable_b : in  std_ulogic;
		addr_b         : in  std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in_b      : in  std_ulogic_vector(g_data_width - 1 downto 0);
		data_out_b     : out std_ulogic_vector(g_data_width - 1 downto 0)
	);
end entity;

architecture arch of ram is
	type t_ram is array (2**g_addr_width - 1 downto 0) of std_ulogic_vector(g_data_width - 1 downto 0);
	shared variable ram : t_ram;
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if enable_a then
				data_out_a <= ram(to_integer(unsigned(addr_a)));
				if write_enable_a then
					ram(to_integer(unsigned(addr_a))) := data_in_a;
				end if;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if enable_b then
				data_out_b <= ram(to_integer(unsigned(addr_b)));
				if write_enable_b then
					ram(to_integer(unsigned(addr_b))) := data_in_b;
				end if;
			end if;
		end if;
	end process;
end architecture;
