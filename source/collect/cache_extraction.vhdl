library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_common_subtypes.all;
use ipfix_exporter.pkg_ipfix_data_record.all;
use ipfix_exporter.pkg_types.all;

/*!
This module searches the cache for expired flows and exports these.

The cache, which is a hash table, is searched in linear order for expired flows.
A flows is expired, if the last frame is older than the inactive timeout or if the first frame is older than the active timeout.
Expired flows are put directly onto the AXIS interface.
`tkeep` and `tlast` are not used, because a whole data record is transported with each transaction.

configuration in:
* `cache_active_timeout`
* `cache_inactive_timeout`
* `timestamp`
 */
entity cache_extraction is
	generic(
		g_addr_width  : natural;
		g_record_width : natural;
		g_ram_delay    : natural := 1
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		enable       : out std_ulogic;
		write_enable : out std_ulogic;
		addr         : out std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in      : out std_ulogic_vector(g_record_width - 1 downto 0);
		data_out     : in  std_ulogic_vector(g_record_width - 1 downto 0);

		if_axis_out_m_tdata  : out std_ulogic_vector(g_record_width - 1 downto 0);
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s        : in  t_if_axis_s;

		cpu_cache_active_timeout   : in t_timeout;
		cpu_cache_inactive_timeout : in t_timeout;
		cpu_timestamp              : in t_timestamp
	);
end entity;

architecture arch of cache_extraction is
	constant c_ip_version : positive := get_ip_version_from_ipfix_data_record_width(g_record_width);

	type t_fsm is (read, ram_delay, compareandsend, wait_read);
	type t_reg is record
		fsm : t_fsm;

		ram_delay_counter : natural range 0 to g_ram_delay;

		-- output
		enable       : std_ulogic;
		write_enable : std_ulogic;
		addr         : std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in      : std_ulogic_vector(g_record_width - 1 downto 0);

		if_axis_out_m_tdata  : std_ulogic_vector(g_record_width - 1 downto 0);
		if_axis_out_m_tvalid : std_ulogic;
	end record;
	constant c_reg_default : t_reg := (
		fsm                  => read,
		ram_delay_counter    => 0,
		enable               => '0',
		write_enable         => '0',
		addr                 => (others => '0'),
		data_in              => (others => '0'),
		if_axis_out_m_tdata  => (others => '0'),
		if_axis_out_m_tvalid => '0'
	);
	signal r, r_nxt : t_reg := c_reg_default;

	-- aliases
	signal ram_out_ipv6 : t_ipfix_ipv6_data_record;
	signal ram_out_ipv4 : t_ipfix_ipv4_data_record;
begin
	ram_out_ipv6 <= to_ipfix_ipv6_data_record(data_out) when c_ip_version = 6 else c_ipfix_ipv6_data_record_default;
	ram_out_ipv4 <= to_ipfix_ipv4_data_record(data_out) when c_ip_version = 4 else c_ipfix_ipv4_data_record_default;

	p_seq : process(clk)
	begin
		if rising_edge(clk) then
			if rst = c_reset_active then
				r <= c_reg_default;
			else
				r <= r_nxt;
			end if;
		end if;
	end process;

	p_comb : process(if_axis_out_m_tvalid, if_axis_out_s,
	                 cpu_cache_active_timeout, cpu_cache_inactive_timeout, cpu_timestamp,
	                 ram_out_ipv4, ram_out_ipv6,
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		-- single cycle active signals
		v.enable               := '0';
		v.write_enable         := '0';

		case v.fsm is
			when read =>
				v.enable := '1';
				-- linear search
				v.addr := std_ulogic_vector(unsigned(r.addr) + to_unsigned(1, g_addr_width));
				v.ram_delay_counter := g_ram_delay;
				v.fsm := ram_delay;

			when ram_delay =>
				v.ram_delay_counter := r.ram_delay_counter - 1;
				if v.ram_delay_counter = 0 then
					v.ram_delay_counter := g_ram_delay;
					v.fsm := compareandsend;
				end if;

			when compareandsend =>
				if    (c_ip_version = 6 and (   ram_out_ipv6.end_time   + cpu_cache_inactive_timeout < cpu_timestamp
				                             or ram_out_ipv6.start_time + cpu_cache_active_timeout   < cpu_timestamp)
				                        and (ram_out_ipv6.start_time /= 0 or ram_out_ipv6.end_time /= 0))
				   or (c_ip_version = 4 and (   ram_out_ipv4.end_time   + cpu_cache_inactive_timeout < cpu_timestamp
				                             or ram_out_ipv4.start_time + cpu_cache_active_timeout   < cpu_timestamp)
				                        and (ram_out_ipv4.start_time /= 0 or ram_out_ipv4.end_time /= 0)) then
					-- timeout reached
					v.enable       := '1';
					v.write_enable := '1';
					v.if_axis_out_m_tdata := to_std_ulogic_vector(ram_out_ipv6) when c_ip_version = 6 else to_std_ulogic_vector(ram_out_ipv4);
					v.if_axis_out_m_tvalid := '1';
					v.fsm := wait_read;
				else
					v.fsm := read;
				end if;

			when wait_read =>
				if if_axis_out_m_tvalid and if_axis_out_s.tready then
					v.if_axis_out_m_tvalid := '0';
					v.fsm := read;
				end if;
		end case;

		r_nxt <= v;
	end process;

	enable       <= r.enable      ;
	write_enable <= r.write_enable;
	addr         <= r.addr        ;
	data_in      <= r.data_in     ;
	if_axis_out_m_tdata  <= (others => '0');
	if_axis_out_m_tvalid <= r.if_axis_out_m_tvalid;
end architecture;
