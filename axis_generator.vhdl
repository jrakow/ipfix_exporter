use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

library axis_testbench;
use axis_testbench.pkg_axis_testbench_io.all;

/*!
The AXIS generator reads hexadecimal streams from a file and send them using an AXI stream interface.

The AXIS generator reads hexadecimal lines from a test case file.
These lines are then split into single frames using a generic width.
A single frame is transmitted if both `tvalid` and `tready` are asserted.
For the last frame, the `tkeep` signal is set according to the number of bytes in the last transaction.
Also `tlast` is set.
The generator will then continue with the next line of the file.
If the last line has been sent, the generator is finished.

As the generator is not checking anything, it may not fail.

`tvalid` is switched on and off randomly.
The duty cycle is accepted by generic.
This is needed to test whether an implementation of the AXIS protocol is correct.
 */
entity axis_generator is
	generic(
		g_filename      : string;
		g_tdata_width   : natural;
		g_random_seed_0 : positive;
		g_random_seed_1 : positive;
		g_tvalid_ratio  : real
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_m_tdata  : out std_ulogic_vector(g_tdata_width     - 1 downto 0);
		if_axis_m_tkeep  : out std_ulogic_vector(g_tdata_width / 8 - 1 downto 0);
		if_axis_m_tlast  : out std_ulogic;
		if_axis_m_tvalid : out std_ulogic;
		if_axis_s_tready : in  std_ulogic;

		finished : out boolean := false;
		generator_event : out boolean;
		checker_event   : in  boolean;
		emulator_event  : in  boolean
	);
end entity;

architecture arch of axis_generator is
	signal s_first_frame : boolean := true;

	signal wait_for_checker  : boolean := false;
	signal wait_for_emulator : boolean := false;
begin
	p_generator : process(clk)
		file     stimulus_file : text open read_mode is g_filename;
		variable stimulus_line : line;
		variable line_number   : natural := 0;

		variable frame_string  : string(1 to g_tdata_width / 4);

		variable random_seed_0 : positive := g_random_seed_0;
		variable random_seed_1 : positive := g_random_seed_1;
		variable random        : real;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				if_axis_m_tdata   <= (others => '0');
				if_axis_m_tvalid  <= '0';
				finished          <= false;
				s_first_frame     <= true;
				generator_event   <= false;
				wait_for_checker  <= false;
				wait_for_emulator <= false;
			else
				if    (wait_for_checker  and not checker_event)
				   or (wait_for_emulator and not emulator_event) then
					-- sleep while waiting
					null;
				else
					if wait_for_checker and checker_event then
						wait_for_checker <= false;
					end if;
					if wait_for_emulator and emulator_event then
						wait_for_emulator <= false;
					end if;
	
					uniform(random_seed_0, random_seed_1, random);
					-- if set once, tvalid must be held
					if random < g_tvalid_ratio and if_axis_m_tvalid = '0' and not finished then
						if_axis_m_tvalid <= '1';
					else
						if_axis_m_tvalid <= '0';
					end if;
	
					generator_event <= false;
					-- line empty so get new line
					if stimulus_line = null then
						get_line_from_file(stimulus_file, stimulus_line, line_number);
						if stimulus_line /= null and stimulus_line.all(1) = '%' then
							if stimulus_line.all(1 to 6) = "%EVENT" then
								report "gen event";
								stimulus_line   := null;
								generator_event <= true;
							elsif stimulus_line.all(1 to 9) = "%WAIT_CHK" then
								report "gen waits for chk";
								stimulus_line   := null;
								wait_for_checker <= true;
								if_axis_m_tvalid <= '0';
							elsif stimulus_line.all(1 to 9) = "%WAIT_EMU" then
								report "gen waits for emu";
								stimulus_line   := null;
								wait_for_emulator <= true;
								if_axis_m_tvalid <= '0';
							end if;
						end if;
					end if;

					if s_first_frame or (if_axis_m_tvalid = '1' and if_axis_s_tready = '1') then
						s_first_frame <= false;

						-- no more lines in file
						if stimulus_line = null then
							if_axis_m_tvalid <= '0';
							if_axis_m_tkeep  <= (others => '0');
							if_axis_m_tlast  <= '0';
							finished         <= true;
						else
							-- get frame
							if stimulus_line'length >= frame_string'length then
								if_axis_m_tkeep <= (others => '1');
								read(stimulus_line, frame_string);
							else
								-- use line length before it is changed
								-- stimulus line length is nibbles
								frame_string(stimulus_line'length + 1 to g_tdata_width / 4) := (others => '-');
								-- tkeep is bytes
								if_axis_m_tkeep <= to_tkeep(stimulus_line'length / 2, g_tdata_width / 8);
								read(stimulus_line, frame_string(1 to stimulus_line'length));
							end if;
	
							-- stimulus_line is only /= null if it contains another frame
							if stimulus_line'length = 0 then
								if_axis_m_tlast <= '1' ;
								stimulus_line   := null;
							else
								if_axis_m_tlast <= '0' ;
							end if;
						end if;
	
						if_axis_m_tdata <= to_std_ulogic_vector(frame_string);
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;
