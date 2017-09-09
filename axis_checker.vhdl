use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

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

`tready` is switched on and off randomly.
The duty cycle is accepted by generic.
This is needed to test whether an implementation of the AXIS protocol is correct.
 */
entity axis_checker is
	generic(
		g_filename      : string;
		g_tdata_width   : natural;
		g_random_seed_0 : positive;
		g_random_seed_1 : positive;
		g_tready_ratio  : real
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_m_tdata  : in  std_ulogic_vector(g_tdata_width     - 1 downto 0);
		if_axis_m_tkeep  : in  std_ulogic_vector(g_tdata_width / 8 - 1 downto 0);
		if_axis_m_tlast  : in  std_ulogic;
		if_axis_m_tvalid : in  std_ulogic;
		if_axis_s_tready : out std_ulogic;

		finished        : out boolean := false;
		generator_event : in  boolean;
		checker_event   : out boolean;
		emulator_event  : in  boolean
	);
end entity;

architecture arch of axis_checker is
	signal wait_for_generator : boolean := false;
	signal wait_for_emulator  : boolean := false;
begin
	p_checker : process(clk)
		file check_file      : text open read_mode is g_filename;
		variable check_line  : line;
		variable line_number : natural := 0;

		variable frame_string   : string(1 to g_tdata_width / 4);
		variable tkeep_expected : std_ulogic_vector(g_tdata_width / 8 - 1 downto 0) := (others => '0');
		variable tlast_expected : std_ulogic := '0';

		variable success : boolean := true;

		variable random_seed_0 : positive := g_random_seed_0;
		variable random_seed_1 : positive := g_random_seed_1;
		variable random        : real;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				if_axis_s_tready   <= '0';
				finished           <= false;
				checker_event      <= false;
				wait_for_generator <= false;
				wait_for_emulator  <= false;
			else
				if    (wait_for_generator  and not generator_event)
				   or (wait_for_emulator   and not emulator_event) then
					-- sleep while waiting
					null;
				else
					if wait_for_generator and generator_event then
						wait_for_generator <= false;
					end if;
					if wait_for_emulator and emulator_event then
						wait_for_emulator <= false;
					end if;

					uniform(random_seed_0, random_seed_1, random);
					if random < g_tready_ratio and not finished then
						if_axis_s_tready <= '1';
					else
						if_axis_s_tready <= '0';
					end if;

					checker_event <= false;

					-- line empty so get new line
					if check_line = null then
						get_line_from_file(check_file, check_line, line_number);
						-- no more lines in file
						if check_line = null then
							if_axis_s_tready <= '0';
							finished         <= true;
						else
							if check_line.all(1) = '%' then
								if check_line.all(1 to 6) = "%EVENT" then
									report "chk event";
									check_line    := null;
									checker_event <= true;
								elsif check_line.all(1 to 9) = "%WAIT_GEN" then
									report "chk waits for gen";
									check_line         := null;
									wait_for_generator <= true;
									if_axis_s_tready <= '0';
								elsif check_line.all(1 to 9) = "%WAIT_EMU" then
									report "chk waits for emu";
									check_line   := null;
									wait_for_emulator <= true;
									if_axis_s_tready <= '0';
								end if;
							end if;
						end if;
					end if;

					-- axis transaction on tvalid and tready
					if if_axis_m_tvalid = '1' and if_axis_s_tready = '1' then
						-- get frame
						-- condition only needed if finished
						if check_line /= null then

							if check_line'length >= frame_string'length then
								tkeep_expected := (others => '1');
								read(check_line, frame_string);
							else
								-- use line length before it is changed
								-- stimulus line length is nibbles
								frame_string(check_line'length + 1 to g_tdata_width / 4) := (others => '-');
								-- tkeep is bytes
								tkeep_expected := to_tkeep(check_line'length / 2, g_tdata_width / 8);
								read(check_line, frame_string(1 to check_line'length));
							end if;

							-- checkline is only /= null if it contains another frame
							if check_line'length = 0 then
								tlast_expected := '1';
								check_line     := null;
							else
								tlast_expected := '0';
							end if;
						end if;

	--! @cond doxygen cannot handle ?=
						assert to_std_ulogic_vector(frame_string) ?= if_axis_m_tdata
							report "line " & integer'image(line_number) & ": tdata is 0x" & to_hstring(if_axis_m_tdata) & " should be 0x" & frame_string;
						success := success and ((to_std_ulogic_vector(frame_string) ?= if_axis_m_tdata) = '1');
	--! @endcond
						assert tkeep_expected = if_axis_m_tkeep
							report "line " & integer'image(line_number) & ": tkeep is 0x" & to_bstring(if_axis_m_tkeep) & " should be 0x" & to_bstring(tkeep_expected);
						success := success and (tkeep_expected = if_axis_m_tkeep);
						assert tlast_expected = if_axis_m_tlast
							report "line " & integer'image(line_number) & ": tlast is 0b" & std_ulogic'image(if_axis_m_tlast) & " should be 0" & std_ulogic'image(tlast_expected);
						success := success and (tlast_expected = if_axis_m_tlast);

						if not success then
							stop(2);
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;
