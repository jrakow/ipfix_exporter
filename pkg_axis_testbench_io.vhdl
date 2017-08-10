use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! basic file IO and conversion functions for the @ref axis_generator and @ref axis_checker modules
package pkg_axis_testbench_io is
	--! convert a string of hexadecimal characters to a std_ulogic_vector
	function to_std_ulogic_vector(s : string) return std_ulogic_vector;

	/**
	 * given a file descriptor get the first non-empty and non-comment line
	 *
	 * empty lines and lines having a `#` in the first column are ignored
	 */
	procedure get_line_from_file(file f : text; line : out line; line_number : inout natural);

	/**
	 * convert a number of bytes to a std_ulogic_vector
	 *
	 * @param number of valid bytes in tdata
	 * @param tkeep_width width of return tkeep std_ulogic_vector
	 * @return filled with n `'1'`s from the left
	 */
	function to_tkeep(n : positive; tkeep_width : natural) return std_ulogic_vector;
end package;

package body pkg_axis_testbench_io is
	function to_std_ulogic_vector(c : character) return std_ulogic_vector is
	begin
		case c is
			when '0'       => return x"0";
			when '1'       => return x"1";
			when '2'       => return x"2";
			when '3'       => return x"3";
			when '4'       => return x"4";
			when '5'       => return x"5";
			when '6'       => return x"6";
			when '7'       => return x"7";
			when '8'       => return x"8";
			when '9'       => return x"9";
			when 'a' | 'A' => return x"a";
			when 'b' | 'B' => return x"b";
			when 'c' | 'C' => return x"c";
			when 'd' | 'D' => return x"d";
			when 'e' | 'E' => return x"e";
			when 'f' | 'F' => return x"f";
--! @cond doxygen cannot handle '-'
			when '-'    => return x"-";
--! @endcond
			when others => return x"X";
		end case;
	end;

	function to_std_ulogic_vector(s : string) return std_ulogic_vector is
		variable ret : std_ulogic_vector(0 to s'length * 4 - 1);
	begin
		for i in 0 to s'length - 1 loop
			ret(i * 4 to (i + 1) * 4 - 1) := to_std_ulogic_vector(s(s'left + i));
		end loop;
		return ret;
	end;

	procedure get_line_from_file(file f : text; line : out line; line_number : inout natural) is
	begin
		if not endfile(f) then
			-- get line
			readline(f, line);
			line_number := line_number + 1;
			-- skip empty and comment lines
			while line'length = 0 or line.all(1) = '#' loop
				if endfile(f) then
					line := null;
					return;
				else
					readline(f, line);
					line_number := line_number + 1;
				end if;
			end loop;
		else
			line := null;
			return;
		end if;
	end;

	function to_tkeep(n : positive; tkeep_width : natural) return std_ulogic_vector is
		variable ret : std_ulogic_vector(tkeep_width - 1 downto 0) := (others => '0');
	begin
		assert 1 <= n
			report "tkeep must be <= 1 is " & integer'image(n)
			severity error;
		assert n <= tkeep_width
			report "tkeep must be <= tkeep_width is " & integer'image(n) & " not <= " & integer'image(tkeep_width)
			severity error;
		for i in 0 to tkeep_width - 1 loop
			ret(tkeep_width - i - 1) := '1';
			if i + 1 >= n then
				return ret;
			end if;
		end loop;
		return ret;
	end;
end package body;
