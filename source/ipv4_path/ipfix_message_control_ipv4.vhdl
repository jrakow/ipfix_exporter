library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module accumulates IPFIX data records and forwards them, if an IPFIX message is ready.

Incoming IPFIX data records are saved until an IPFIX message is full (this is determined by the width of an IPFIX data record) or until the IPFIX message timeout is reached.
The timeout is computed by subtracting a one Hertz pulse from the given timeout.
If the message is ready, the IPFIX set header is computed and it and the whole set is forwarded.

@todo configuration in: `ipfix_message_timeout`
 */
entity ipfix_message_control_ipv4 is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_ipv4_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s
	);
end entity;

architecture arch of ipfix_message_control_ipv4 is
begin
end architecture;
