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

`address` and `data` are not prefixed eight character hexadecimal literals.

Examples:
* `verify 01234567 89abcdef`
* `write 01234567 89abcdef`
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

		finished : out boolean
	);
end entity;

architecture arch of cpu_emulator is
	constant c_line_max_length : natural := 6 -- verify / write
	                              + 1
	                              + 8 -- address hex
	                              + 1
	                              + 8; -- data hex

	-- verifying takes two steps
	type t_verify_fsm is (idle, fetching, reading);
	signal s_verify_fsm : t_verify_fsm;
begin
	p_checker : process(clk)
		file emu_file     : text open read_mode is g_filename;
		variable emu_line : line;
		variable emu_string : string(1 to c_line_max_length);
	begin
		if rising_edge(clk) then
			if rst = '1' then
				read_enable  <= '0';
				write_enable <= '0';
				data_out     <= (others => '0');
				address      <= (others => '0');
				finished     <= false;
				s_verify_fsm <= idle;
			else
				if s_verify_fsm = fetching then
					s_verify_fsm <= reading;
				elsif s_verify_fsm = reading then
					s_verify_fsm <= idle;
					assert(read_valid)
						report "cpu read not valid at address 0x" & to_hstring(address)
						severity failure;
--! @cond doxygen cannot handle ?=
					assert(data_in ?= to_std_ulogic_vector(emu_string(17 to 24)))
						report "cpu read data is 0x" & to_hstring(data_in) & " should be 0x" & emu_string(17 to 24)
						severity failure;
--! @endcond
				elsif not finished then
					get_line_from_file(emu_file, emu_line);
					-- no more lines in file
					if emu_line /= null then
						if emu_line'length = c_line_max_length - 1 then
							-- "write" line
							read(emu_line, emu_string(1 to c_line_max_length - 1));
							emu_string(c_line_max_length) := '1';
						elsif emu_line'length = c_line_max_length then
							-- "verify" line
							read(emu_line, emu_string);
						else
							assert false
								report "emu_line'length " & integer'image(emu_line'length) & " is invalid"
								severity failure;
						end if;

						read_enable  <= '0';
						write_enable <= '0';
						case emu_string(1 to 6) is
							when "verify" =>
								-- "verify aaaabbbb ccccdddd"
								--           1         2
								--  123456 89012345 78901234
								read_enable  <= '1';
								s_verify_fsm <= fetching;
								address      <= to_std_ulogic_vector(emu_string(8 to 15));
							when "write " =>
								-- "write aaaabbbb ccccdddd"
								--           1         2
								--  12345 78901234 67890123
								write_enable <= '1';
								address      <= to_std_ulogic_vector(emu_string( 7 to 14));
								data_out     <= to_std_ulogic_vector(emu_string(16 to 23));
							when others =>
								assert false
									report "invalid emulator command: '" & emu_string(1 to 6) & "'"
									severity failure;
						end case;
					else
						finished <= true;
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;
