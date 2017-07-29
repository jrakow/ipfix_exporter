library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_types.all;

/*!
This module provides a CPU interface to the `ipfix_exporter`.

The CPU interface is a simple memory mapping with a single data channel.
For a write transaction the CPU sets the `address` and `write_enable` signals as well as the data to be written on `data_out`.
For a read transaction the `address`, `read_enable` and `data_in` signals are considered.
If the CPU reads from a valid address, the `read_valid` signal is set.
Else it is reset.

See [CPU interface](doc/cpu_interface.md) for the registers provided.
 */
entity cpu_interface is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		read_enable  : in  std_ulogic;
		write_enable : in  std_ulogic;
		data_in      : out std_ulogic_vector(31 downto 0);
		data_out     : in  std_ulogic_vector(31 downto 0);
		address      : in  std_ulogic_vector(31 downto 0);
		read_valid   : out std_ulogic;

		drop_source_mac_enable : out std_ulogic;
		timestamp              : out t_timestamp;
		cache_active_timeout   : out t_timeout;
		cache_inactive_timeout : out t_timeout;
		ipfix_message_timeout  : out t_timeout;
		ipfix_config_ipv6      : out t_ipfix_config;
		ipfix_config_ipv4      : out t_ipfix_config;
		udp_config             : out t_udp_config;
		ip_config              : out t_ip_config;
		vlan_config            : out t_vlan_config;
		ethernet_config        : out t_ethernet_config;

		events : in std_ulogic_vector(c_number_of_counters - 1 downto 0)
	);
end entity;

architecture arch of cpu_interface is
	constant c_used_width         : natural := 8;

	type t_counter_array is array(0 to c_number_of_counters - 1) of unsigned(31 downto 0);
	signal s_counter_array : t_counter_array;

	signal s_scratchpad : std_ulogic_vector(31 downto 0);
begin
	p_read : process(clk)
		alias offset is address(c_used_width - 1 downto 0);
	begin
		if rising_edge(clk) then
			if rst = c_reset_active then
				data_in    <= (others => '0');
				read_valid <= '0';
			elsif read_enable then
				read_valid <= '1';
				case offset is
					-- config
					when x"00" => data_in <= s_scratchpad;
					when x"04" =>
						if ip_config.version = x"6" then
							data_in <= x"000000" & "000" & std_ulogic_vector(vlan_config.number_of_vlans) & drop_source_mac_enable & '1' & '0';
						else
							data_in <= x"000000" & "000" & std_ulogic_vector(vlan_config.number_of_vlans) & drop_source_mac_enable & '0' & '0';
						end if;
					when x"08" => data_in <= std_ulogic_vector(timestamp);
					when x"0C" => data_in <= std_ulogic_vector(cache_active_timeout) & std_ulogic_vector(cache_inactive_timeout);
					when x"10" => data_in <= x"0000" & std_ulogic_vector(ipfix_message_timeout);
					when x"14" => data_in <= ipfix_config_ipv6.template_id & ipfix_config_ipv4.template_id;
					when x"18" =>
						-- same for ipv6 and ipv4
						data_in <= ipfix_config_ipv6.observation_domain_id;
					when x"1C" => data_in <= udp_config.source & udp_config.destination;
					when x"20" => data_in <= ip_config.ipv6_source_address( 31 downto  0);
					when x"24" => data_in <= ip_config.ipv6_source_address( 63 downto 32);
					when x"28" => data_in <= ip_config.ipv6_source_address( 95 downto 64);
					when x"2C" => data_in <= ip_config.ipv6_source_address(127 downto 96);
					when x"30" => data_in <= ip_config.ipv6_destination_address( 31 downto  0);
					when x"34" => data_in <= ip_config.ipv6_destination_address( 63 downto 32);
					when x"38" => data_in <= ip_config.ipv6_destination_address( 95 downto 64);
					when x"3C" => data_in <= ip_config.ipv6_destination_address(127 downto 96);
					when x"40" => data_in <= ip_config.ipv4_source_address;
					when x"44" => data_in <= ip_config.ipv4_destination_address;
					when x"48" => data_in <= x"000" & ip_config.ipv6_flow_label;
					when x"4C" => data_in <= x"0000" & ip_config.ipv4_identification;
					when x"50" => data_in <= x"0000" & ip_config.hop_limit & ip_config.traffic_class;
					when x"54" => data_in <= vlan_config.tag_0;
					when x"58" => data_in <= vlan_config.tag_1;
--					when x"5C" => *invalid*
					when x"60" => data_in <= ethernet_config.source(31 downto  0);
					when x"64" => data_in <= x"0000" & ethernet_config.source(47 downto 32);
					when x"68" => data_in <= ethernet_config.destination(31 downto  0);
					when x"6C" => data_in <= x"0000" & ethernet_config.destination(47 downto 32);
					-- counters
					when x"70" => data_in <= std_ulogic_vector(s_counter_array( 0));
					when x"74" => data_in <= std_ulogic_vector(s_counter_array( 1));
					when x"78" => data_in <= std_ulogic_vector(s_counter_array( 2));
					when x"7C" => data_in <= std_ulogic_vector(s_counter_array( 3));
					when x"80" => data_in <= std_ulogic_vector(s_counter_array( 4));
					when x"84" => data_in <= std_ulogic_vector(s_counter_array( 5));
					when x"88" => data_in <= std_ulogic_vector(s_counter_array( 6));
					when x"8C" => data_in <= std_ulogic_vector(s_counter_array( 7));
					when x"90" => data_in <= std_ulogic_vector(s_counter_array( 8));
					when x"94" => data_in <= std_ulogic_vector(s_counter_array( 9));
					when x"98" => data_in <= std_ulogic_vector(s_counter_array(10));
					when x"9C" => data_in <= std_ulogic_vector(s_counter_array(11));
					when x"A0" => data_in <= std_ulogic_vector(s_counter_array(12));
					when x"A4" => data_in <= std_ulogic_vector(s_counter_array(13));
					when x"A8" => data_in <= std_ulogic_vector(s_counter_array(14));
--					when x"AC" => *invalid*;
					when x"B0" => data_in <= std_ulogic_vector(s_counter_array(15));
					when x"B4" => data_in <= std_ulogic_vector(s_counter_array(16));
					when x"B8" => data_in <= std_ulogic_vector(s_counter_array(17));
					when x"BC" => data_in <= std_ulogic_vector(s_counter_array(18));
					when x"C0" => data_in <= std_ulogic_vector(s_counter_array(19));
					when x"C4" => data_in <= std_ulogic_vector(s_counter_array(20));
					when x"C8" => data_in <= std_ulogic_vector(s_counter_array(21));
					when x"CC" => data_in <= std_ulogic_vector(s_counter_array(22));
					when x"D0" => data_in <= std_ulogic_vector(s_counter_array(23));
					when x"D4" => data_in <= std_ulogic_vector(s_counter_array(24));
					when x"D8" => data_in <= std_ulogic_vector(s_counter_array(25));
					when others =>
						read_valid <= '0';
				end case;
			else
				read_valid <= '0';
			end if;
		end if;
	end process;

	p_write : process(clk)
		alias offset is address(c_used_width - 1 downto 0);
	begin
		if rising_edge(clk) then
			if rst = c_reset_active then
				s_counter_array        <= (others => (others => '0'));
				s_scratchpad           <= (others => '0');
				drop_source_mac_enable <= '0';
				timestamp              <= (others => '0');
				cache_active_timeout   <= (others => '0');
				cache_inactive_timeout <= (others => '0');
				ipfix_message_timeout  <= (others => '0');
				ipfix_config_ipv6      <= c_ipfix_config_default;
				ipfix_config_ipv4      <= c_ipfix_config_default;
				udp_config             <= c_udp_config_default;
				ip_config              <= c_ip_config_default;
				vlan_config            <= c_vlan_config_default;
				ethernet_config        <= c_ethernet_config_default;
			elsif write_enable then
				case offset is
					-- config
					when x"00" => s_scratchpad <= data_out;
					when x"04" =>
						--! @todo synchronize writing of addresses
						if data_out(1) then
							ip_config.version <= x"6";
						else
							ip_config.version <= x"4";
						end if;
						drop_source_mac_enable      <= data_out(2);
						vlan_config.number_of_vlans <= unsigned(data_out(4 downto 3));
					when x"08" => timestamp <= unsigned(data_out);
					when x"0C" =>
						cache_active_timeout   <= unsigned(data_out(31 downto 16));
						cache_inactive_timeout <= unsigned(data_out(15 downto  0));
					when x"10" => ipfix_message_timeout <= unsigned(data_out(15 downto 0));
					when x"14" =>
						ipfix_config_ipv6.template_id <= data_out(31 downto 16);
						ipfix_config_ipv4.template_id <= data_out(15 downto  0);
					when x"18" =>
						-- same for ipv6 and ipv4
						ipfix_config_ipv6.observation_domain_id <= data_out;
						ipfix_config_ipv4.observation_domain_id <= data_out;
					when x"1C" =>
						udp_config.source       <= data_out(31 downto 16);
						udp_config.destination  <= data_out(15 downto  0);
					when x"20" => ip_config.ipv6_source_address( 31 downto  0) <= data_out;
					when x"24" => ip_config.ipv6_source_address( 63 downto 32) <= data_out;
					when x"28" => ip_config.ipv6_source_address( 95 downto 64) <= data_out;
					when x"2C" => ip_config.ipv6_source_address(127 downto 96) <= data_out;
					when x"30" => ip_config.ipv6_destination_address( 31 downto  0) <= data_out;
					when x"34" => ip_config.ipv6_destination_address( 63 downto 32) <= data_out;
					when x"38" => ip_config.ipv6_destination_address( 95 downto 64) <= data_out;
					when x"3C" => ip_config.ipv6_destination_address(127 downto 96) <= data_out;
					when x"40" => ip_config.ipv4_source_address      <= data_out;
					when x"44" => ip_config.ipv4_destination_address <= data_out;
					when x"48" => ip_config.ipv6_flow_label <= data_out(19 downto 0);
					when x"4C" => ip_config.ipv4_identification <= data_out(15 downto 0);
					when x"50" =>
						ip_config.hop_limit     <= data_out(15 downto 8);
						ip_config.traffic_class <= data_out( 7 downto 0);
					when x"54" => vlan_config.tag_0 <= data_out;
					when x"58" => vlan_config.tag_1 <= data_out;
--					when x"5C" => *invalid*
					when x"60" => ethernet_config.source(31 downto  0) <= data_out;
					when x"64" => ethernet_config.source(47 downto 32) <= data_out(15 downto 0);
					when x"68" => ethernet_config.destination(31 downto  0) <= data_out;
					when x"6C" => ethernet_config.destination(47 downto 32) <= data_out(15 downto 0);
					-- counters
					when x"70" => s_counter_array( 0) <= unsigned(data_out);
					when x"74" => s_counter_array( 1) <= unsigned(data_out);
					when x"78" => s_counter_array( 2) <= unsigned(data_out);
					when x"7C" => s_counter_array( 3) <= unsigned(data_out);
					when x"80" => s_counter_array( 4) <= unsigned(data_out);
					when x"84" => s_counter_array( 5) <= unsigned(data_out);
					when x"88" => s_counter_array( 6) <= unsigned(data_out);
					when x"8C" => s_counter_array( 7) <= unsigned(data_out);
					when x"90" => s_counter_array( 8) <= unsigned(data_out);
					when x"94" => s_counter_array( 9) <= unsigned(data_out);
					when x"98" => s_counter_array(10) <= unsigned(data_out);
					when x"9C" => s_counter_array(11) <= unsigned(data_out);
					when x"A0" => s_counter_array(12) <= unsigned(data_out);
					when x"A4" => s_counter_array(13) <= unsigned(data_out);
					when x"A8" => s_counter_array(14) <= unsigned(data_out);
					when x"AC" => s_counter_array(15) <= unsigned(data_out);
					when x"B0" => s_counter_array(16) <= unsigned(data_out);
					when x"B4" => s_counter_array(17) <= unsigned(data_out);
					when x"B8" => s_counter_array(18) <= unsigned(data_out);
					when x"BC" => s_counter_array(19) <= unsigned(data_out);
					when x"C0" => s_counter_array(20) <= unsigned(data_out);
					when x"C4" => s_counter_array(21) <= unsigned(data_out);
					when x"C8" => s_counter_array(22) <= unsigned(data_out);
					when x"CC" => s_counter_array(23) <= unsigned(data_out);
					when x"D0" => s_counter_array(24) <= unsigned(data_out);
					when x"D4" => s_counter_array(25) <= unsigned(data_out);
					when others =>
				end case;
			end if;
			if rst /= c_reset_active then
				for i in 0 to c_number_of_counters - 1 loop
					if events(i) then
						s_counter_array(i) <= s_counter_array(i) + 1;
					end if;
				end loop;
			end if;
		end if;
	end process;
end architecture;
