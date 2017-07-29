use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axis_testbench;
use axis_testbench.pkg_axis_testbench_io.all;

/*!
This module sets and gets values from a module.

Commands to execute are read from a file.
There are two supported actions conforming to the following format:
* `verify address data` : read from address and compare with data. Fail if not equal.
* `write address data` : write data to address.

`address` and `data` are not prefixed eight character hexadecimal literals, e. g. `verify 01234567 89abcde`, `write 01234567 89abcde`
 */
entity cpu_emulator is
	generic(
		g_filename : string
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		read_enable  : out std_ulogic;
		write_enable : out std_ulogic;
		data_in      : in  std_ulogic_vector(31 downto 0);
		data_out     : out std_ulogic_vector(31 downto 0);
		address      : out std_ulogic_vector(31 downto 0);
		read_valid   : in  std_ulogic;

		finished : out std_ulogic
	);
end entity;

architecture arch of cpu_emulator is
	constant c_line_max_length : natural := 6 -- verify / write
	                              + 1
	                              + 8 -- address hex
	                              + 1
	                              + 8; -- data hex

	signal s_verifying : std_ulogic;
begin
	p_checker : process(clk)
		file emu_file     : text open read_mode is g_filename;
		variable emu_line : line;
		variable emu_string : string(0 to c_line_max_length - 1);
	begin
		if rising_edge(clk) then
			if rst = '1' then
				read_enable  <= '0';
				write_enable <= '0';
				data_out     <= (others => '0');
				address      <= (others => '0');
				s_verifying  <= '0';
			else
				if s_verifying then
					s_verifying <= '0';
					assert(read_valid)
						report "cpu read not valid at address 0x" & to_hstring(address)
						severity failure;
--! @cond doxygen cannot handle ?=
					assert(data_in ?= to_std_ulogic_vector(emu_string(16 to 23)))
						report "cpu read data is 0x" & to_hstring(data_in) & " should be 0x" & emu_string(16 to 23)
						severity failure;
--! @endcond
				else
					get_line_from_file(emu_file, emu_line);
					-- no more lines in file
					if emu_line /= null then
						read(emu_line, emu_string);
						read_enable  <= '0';
						write_enable <= '0';
						case emu_string(0 to 5) is
							when "verify" =>
								-- "verify aaaabbbb ccccdddd"
								--  0         1         2
								--  012345 78901234 67890123
								read_enable <= '1';
								s_verifying <= '1';
								address     <= to_std_ulogic_vector(emu_string(7 to 14));
							when "write " =>
								-- "write aaaabbbb ccccdddd"
								--  0         1         2
								--  01234 67890123 56789012
								write_enable <= '1';
								address      <= to_std_ulogic_vector(emu_string( 6 to 13));
								data_out     <= to_std_ulogic_vector(emu_string(15 to 22));
							when others =>
								null;
						end case;
					else
						finished         <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;