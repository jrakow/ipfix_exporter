library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_common_subtypes.all;
use ipfix_exporter.pkg_ipfix_data_record.all;
use ipfix_exporter.pkg_protocol_types.all;

--! data types and conversion functions
package pkg_types is
	constant c_reset_active       : std_ulogic := '1';

	constant c_number_of_counters_preparation : natural := 3;
	constant c_number_of_counters_collect     : natural := 4;
	constant c_number_of_counters_export      : natural := 6;
	constant c_number_of_counters             : natural := c_number_of_counters_preparation
	                                                       + 2 * (c_number_of_counters_collect + c_number_of_counters_export)
	                                                       + 1; -- combined output frames

	/**
	 * check a condition like `assert`
	 *
	 * This is equivalent to normal `assert`.
	 * However this procedure may be called with a static condition.
	 * Failing is delayed until run.
	 */
	procedure static_assert(b : in boolean; s : in string; f : in severity_level);

	-- safe IP packet total length : 1500 bytes
	constant c_ipfix_message_max_length  : natural := 1500 - 40 - 8;
	constant c_ipv6_ipfix_records_per_message : natural := (c_ipfix_message_max_length - 20) * 8 / c_ipfix_ipv6_data_record_width;
	constant c_ipv4_ipfix_records_per_message : natural := (c_ipfix_message_max_length - 20) * 8 / c_ipfix_ipv4_data_record_width;
end package;

package body pkg_types is
	procedure static_assert(b : in boolean; s : in string; f : in severity_level) is
	begin
		assert b
			report s
			severity f;
	end procedure;
end package body;
