use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! basic file IO and conversion functions for the @ref axis_generator and @ref axis_checker modules
package pkg_axis_testbench_io is
	/**
	 * convert a hex character to a 4 bit std_ulogic_vector
	 *
	 * @param c hexadecimal character `[0-9a-f\-]`. May be `-` (don't care).
	 * @return `X` is returned for invalid inputs
	 */
	function to_std_ulogic_vector(c : character) return std_ulogic_vector;

	--! convert a string of hexadecimal characters to a std_ulogic_vector
	function to_std_ulogic_vector(s : string) return std_ulogic_vector;

	/**
	 * given a file descriptor get the first non-empty and non-comment line
	 *
	 * empty lines and lines having a `#` in the first column are ignored
	 */
	procedure get_line_from_file(file f : text; line : out line);

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
			when '0'    => return x"0";
			when '1'    => return x"1";
			when '2'    => return x"2";
			when '3'    => return x"3";
			when '4'    => return x"4";
			when '5'    => return x"5";
			when '6'    => return x"6";
			when '7'    => return x"7";
			when '8'    => return x"8";
			when '9'    => return x"9";
			when 'a'    => return x"a";
			when 'b'    => return x"b";
			when 'c'    => return x"c";
			when 'd'    => return x"d";
			when 'e'    => return x"e";
			when 'f'    => return x"f";
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
			ret(i * 4 to (i + 1) * 4 - 1) := to_std_ulogic_vector(s(i));
		end loop;
		return ret;
	end;

	procedure get_line_from_file(file f : text; line : out line) is
	begin
		if not endfile(f) then
			-- get line
			readline(f, line);
			-- skip empty and comment lines
			while line'length = 0 or line.all(1) = '#' loop
				if endfile(f) then
					line := null;
					return;
				else
					readline(f, line);
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
		assert n <= tkeep_width;
		for i in 0 to tkeep_width - 1 loop
			ret(tkeep_width - i - 1) := '1';
			if i >= n then
				return ret;
			end if;
		end loop;
		return ret;
	end;
end package body;
