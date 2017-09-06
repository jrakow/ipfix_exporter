library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_axi_stream is
	--! AXI stream master interface
	type t_if_axis_frame_m is record
		tvalid : std_ulogic;
		tdata  : std_ulogic_vector(127 downto 0);
		tkeep  : std_ulogic_vector( 15 downto 0);
		tlast  : std_ulogic;
	end record;
	constant c_if_axis_frame_m_default : t_if_axis_frame_m := (
		tvalid => '0',
		tdata  => (others => '0'),
		tkeep  => (others => '0'),
		tlast  => '0'
	);

	--! AXI stream slave interface
	type t_if_axis_s is record
		tready : std_ulogic;
	end record;
	constant c_if_axis_s_default : t_if_axis_s := (
		tready => '0'
	);

	/**
	 * convert a number of bytes to a std_ulogic_vector
	 *
	 * @param number of valid bytes in tdata
	 * @param tkeep_width width of return tkeep std_ulogic_vector
	 * @return filled with n `'1'`s from the left
	 */
	function to_tkeep(n : positive; tkeep_width : natural) return std_ulogic_vector;

	/**
	 * convert a tkeep std_ulogic_vector to a number of bytes
	 */
	function tkeep_to_integer(tkeep : std_ulogic_vector) return positive;
end package;

package body pkg_axi_stream is
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

	function tkeep_to_integer(tkeep : std_ulogic_vector) return positive is
		variable ret : natural := 0;
	begin
		for i in tkeep'range loop
			if tkeep(i) then
				ret := ret + 1;
			end if;
		end loop;
		assert ret /= 0
			report "tkeep may not be null"
			severity error;
		return ret;
	end;
end;
