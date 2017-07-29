use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axis_testbench;
use axis_testbench.pkg_axis_testbench_io.all;

/*!
The AXIS checker receives an AXI stream and compares it with a file.

The AXIS checker reads frames from a test case file in the same way as the @ref axis_generator.
A single frame is received if both `tvalid` and `tready` are asserted.
For a received frame the `tdata` signal is checked with the data frame in the test case file.
Also for the last frame, the `tkeep` and `tlast` signals according to the number of bytes in the last transaction.
This is done for every line in the test file.

The checker fails on the following conditions:
* The transmitted `tdata` is wrong.
* For frames which are not the last frame:
	* `tkeep` is not all ones.
	* `tlast` is asserted.
* For the last frame:
	* The `tkeep` signal does not match the number of bytes in the last frame.
	* The `tlast` signal is not set for the last frame.
* Less data is send than expected.
  In this case the @ref testbench simply times out.

The following condition is unchecked.
* More data is send than expected.
  There is no deterministic way of checking for this as more data may arrive at an arbitrary point in time.

A future version should support switching `tready` on and off randomly.
The duty cycle should be accepted by a generic.
This is needed to test whether an implementation of the AXIS protocol is correct.
 */
entity axis_checker is
	generic(
		g_filename    : string;
		g_tdata_width : natural
	);
	port(
		clk              : in  std_ulogic;
		rst              : in  std_ulogic;

		if_axis_m_tdata  : in  std_ulogic_vector(g_tdata_width - 1 downto 0);
		if_axis_m_tvalid : in  std_ulogic;
		if_axis_s_tready : out std_ulogic;

		finished         : out std_ulogic
	);
end entity;

architecture arch of axis_checker is
begin
	p_checker : process(clk)
		file check_file     : text open read_mode is g_filename;
		variable check_line : line;

		variable frame_string : string(0 to g_tdata_width / 4 - 1);
	begin
		if rising_edge(clk) then
			if rst = '1' then
				if_axis_s_tready <= '0';
				finished         <= '0';
			else
				if_axis_s_tready <= '1';

				-- line empty so get new line
				if check_line = null then
					get_line_from_file(check_file, check_line);
					-- no more lines in file
					-- end condition is independent of tvalid
					if check_line = null then
						if_axis_s_tready <= '0';
						finished         <= '1';
					end if;
				end if;

				-- axis transaction on tvalid and tready
				if if_axis_m_tvalid = '1' and if_axis_s_tready = '1' then
					-- get frame
					-- condition only needed if finished
					if check_line /= null then
						-- TODO tkeep check
						-- TODO tlast check
						read(check_line, frame_string);

						-- checkline is only /= null if it contains another frame
						if check_line'length = 0 then
							check_line := null;
						end if;
					end if;

					-- compare frames
					assert to_std_ulogic_vector(frame_string) = if_axis_m_tdata
						report "tdata is 0x" & to_hstring(if_axis_m_tdata) & " should be 0x" & frame_string
						severity failure;
					report "tdata is correct 0x" & to_hstring(if_axis_m_tdata);
				end if;
			end if;
		end if;
	end process;
end architecture;
