library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_types.all;

/*!
This module inserts VLAN tags.

The IP packet is prefixed by one or more VLAN tags.
`vlan0` is the earliest tag.

configuration in:
* `number_of_vlans`
* `vlan_tag_0`
* `vlan_tag_1`
 */
entity vlan_insertion is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_vlan_config : t_vlan_config
	);
end entity;

architecture arch of vlan_insertion is
begin
end architecture;
