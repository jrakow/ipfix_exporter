library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_frame_info.all;
use ipfix_exporter.pkg_hash.all;
use ipfix_exporter.pkg_ipfix_data_record.all;
use ipfix_exporter.pkg_types.all;

/*!
This module inserts new flows into the cache.

Incoming information is used to update existing IPFIX data records.
The quintuple of incoming frames is hashed and used as the address of the cache, which is a hash table.
A cache slot is read.
If the cache slot is empty, a new flow is created.
If the cache slot is used and the quintuples do not match, a collision occured and the collision counter is incremented.
If the matching flow was found, it is updated with the new frame length and a new timestamp.

configuration out:
* `collision_event`
 */
entity cache_insertion is
	generic(
		g_addr_width       : natural;
		g_record_width     : natural;
		g_frame_info_width : natural;
		g_ram_delay        : natural := 1
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m_tdata  : in  std_ulogic_vector(g_frame_info_width - 1 downto 0);
		if_axis_in_m_tvalid : in  std_ulogic;
		if_axis_in_s        : out t_if_axis_s;

		enable       : out std_ulogic;
		write_enable : out std_ulogic;
		addr         : out std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in      : out std_ulogic_vector(g_record_width - 1 downto 0);
		data_out     : in  std_ulogic_vector(g_record_width - 1 downto 0);

		cpu_collision_event : out std_ulogic
	);
end entity;

architecture arch of cache_insertion is
	constant c_ip_version : positive := get_ip_version_from_frame_info_width(g_frame_info_width);

	type t_fsm is (receive, lookup, ram_delay, write);

	type t_reg is record
		fsm : t_fsm;

		-- registered input
		in_ipv6_frame_info : t_ipv6_frame_info;
		in_ipv4_frame_info : t_ipv4_frame_info;

		ram_delay_counter : natural range 0 to g_ram_delay;

		-- outputs
		if_axis_in_s        : t_if_axis_s;
		enable              : std_ulogic;
		write_enable        : std_ulogic;
		addr                : std_ulogic_vector(g_addr_width - 1 downto 0);
		data_in_ipv6        : t_ipfix_ipv6_data_record;
		data_in_ipv4        : t_ipfix_ipv4_data_record;
		cpu_collision_event : std_ulogic;
	end record;
	constant c_reg_default : t_reg := (
		fsm                 => receive,
		in_ipv6_frame_info  => c_ipv6_frame_info_default,
		in_ipv4_frame_info  => c_ipv4_frame_info_default,
		ram_delay_counter   => g_ram_delay,
		if_axis_in_s        => c_if_axis_s_default,
		enable              => '0',
		write_enable        => '0',
		addr                => (others => '0'),
		data_in_ipv6        => c_ipfix_ipv6_data_record_default,
		data_in_ipv4        => c_ipfix_ipv4_data_record_default,
		cpu_collision_event => '0'
	);
	signal r, r_nxt : t_reg := c_reg_default;

	function hash_quintuple(f : t_ipv6_frame_info) return std_ulogic_vector is
	begin
		return hash(f.src_ip_addr & f.dest_ip_addr & f.src_port & f.dest_port & f.next_header);
	end;
	function hash_quintuple(f : t_ipv4_frame_info) return std_ulogic_vector is
	begin
		return hash(f.src_ip_addr & f.dest_ip_addr & f.src_port & f.dest_port & f.next_header);
	end;
begin
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

	p_comb : process(if_axis_in_m_tdata, if_axis_in_m_tvalid, if_axis_in_s,
	                 data_out,
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		-- single cycle high signals
		v.if_axis_in_s.tready := '0';
		v.enable              := '0';
		v.write_enable        := '0';

		case r.fsm is
			when receive =>
				v.if_axis_in_s.tready := '1';

				if if_axis_in_m_tvalid and if_axis_in_s.tready then
					if c_ip_version = 6 then
						v.in_ipv6_frame_info := to_ipv6_frame_info(if_axis_in_m_tdata);
					else
						v.in_ipv4_frame_info := to_ipv4_frame_info(if_axis_in_m_tdata);
					end if;

					v.if_axis_in_s.tready := '0';
					-- wait one cycle for the hash
					v.fsm := lookup;
				end if;

			when lookup =>
				v.enable            := '1';
				v.fsm               := ram_delay;

			when ram_delay =>
				v.ram_delay_counter := r.ram_delay_counter - 1;
				if v.ram_delay_counter = 0 then
					v.ram_delay_counter := g_ram_delay;

					v.fsm := write;
				end if;

			when write =>
				-- state overview:
				-- * create or update record
				-- * write to ram

				v.enable       := '1';
				v.write_enable := '1';
				v.fsm          := receive;

				-- create or update record
				if c_ip_version = 6 then
					v.data_in_ipv6 := to_ipfix_ipv6_data_record(data_out);

					-- if slot is not taken
					if v.data_in_ipv6.start_time = 0 and v.data_in_ipv6.end_time = 0 then
						-- create entry
						v.data_in_ipv6.src_ip_addr   := v.in_ipv6_frame_info.src_ip_addr  ;
						v.data_in_ipv6.dest_ip_addr  := v.in_ipv6_frame_info.dest_ip_addr ;
						v.data_in_ipv6.src_port      := v.in_ipv6_frame_info.src_port     ;
						v.data_in_ipv6.dest_port     := v.in_ipv6_frame_info.dest_port    ;
						-- copy timestamp to both start and end time
						v.data_in_ipv6.start_time    := v.in_ipv6_frame_info.timestamp    ;
						v.data_in_ipv6.end_time      := v.in_ipv6_frame_info.timestamp    ;
						v.data_in_ipv6.octet_count   := x"00000000" & v.in_ipv6_frame_info.octet_count;
						-- set packet count to 1
						v.data_in_ipv6.packet_count  := to_unsigned(1, 32);
						v.data_in_ipv6.next_header   := v.in_ipv6_frame_info.next_header  ;
						v.data_in_ipv6.traffic_class := v.in_ipv6_frame_info.traffic_class;
						v.data_in_ipv6.tcp_flags     := v.in_ipv6_frame_info.tcp_flags    ;
					else
						-- TODO check here for collision

						v.data_in_ipv6.end_time      := v.in_ipv6_frame_info.timestamp    ;
						v.data_in_ipv6.octet_count   :=
							v.data_in_ipv6.octet_count + v.in_ipv6_frame_info.octet_count;
						v.data_in_ipv6.packet_count  :=
							v.data_in_ipv6.packet_count + 1;
						-- cumulative or of all packets
						v.data_in_ipv6.tcp_flags     :=
							v.data_in_ipv6.tcp_flags or v.in_ipv6_frame_info.tcp_flags    ;
					end if;
				else
					v.data_in_ipv4 := to_ipfix_ipv4_data_record(data_out);

					-- if slot is not taken
					if v.data_in_ipv4.start_time = 0 and v.data_in_ipv4.end_time = 0 then
						-- create entry
						v.data_in_ipv4.src_ip_addr   := v.in_ipv4_frame_info.src_ip_addr  ;
						v.data_in_ipv4.dest_ip_addr  := v.in_ipv4_frame_info.dest_ip_addr ;
						v.data_in_ipv4.src_port      := v.in_ipv4_frame_info.src_port     ;
						v.data_in_ipv4.dest_port     := v.in_ipv4_frame_info.dest_port    ;
						-- copy timestamp to both start and end time
						v.data_in_ipv4.start_time    := v.in_ipv4_frame_info.timestamp    ;
						v.data_in_ipv4.end_time      := v.in_ipv4_frame_info.timestamp    ;
						v.data_in_ipv4.octet_count   := x"00000000" & v.in_ipv4_frame_info.octet_count  ;
						-- set packet count to 1
						v.data_in_ipv4.packet_count  := to_unsigned(1, 32);
						v.data_in_ipv4.next_header   := v.in_ipv4_frame_info.next_header  ;
						v.data_in_ipv4.traffic_class := v.in_ipv4_frame_info.traffic_class;
						v.data_in_ipv4.tcp_flags     := v.in_ipv4_frame_info.tcp_flags    ;
					else
						-- TODO check here for collision

						v.data_in_ipv4.end_time      := v.in_ipv4_frame_info.timestamp    ;
						v.data_in_ipv4.octet_count   :=
							v.data_in_ipv4.octet_count + v.in_ipv4_frame_info.octet_count;
						v.data_in_ipv4.packet_count  :=
							v.data_in_ipv4.packet_count + 1;
						-- cumulative or of all packets
						v.data_in_ipv4.tcp_flags     :=
							v.data_in_ipv4.tcp_flags or v.in_ipv4_frame_info.tcp_flags    ;
					end if;
				end if;
		end case;

		-- input is registered so hash does not have to be
		if c_ip_version = 6 then
			v.addr := hash_quintuple(v.in_ipv6_frame_info);
		else
			v.addr := hash_quintuple(v.in_ipv4_frame_info);
		end if;

		r_nxt <= v;
	end process;

	if_axis_in_s        <= r.if_axis_in_s       ;
	enable              <= r.enable             ;
	write_enable        <= r.write_enable       ;
	addr                <= r.addr               ;
	data_in             <= to_std_ulogic_vector(r.data_in_ipv6) when c_ip_version = 6 else to_std_ulogic_vector(r.data_in_ipv4);
	cpu_collision_event <= r.cpu_collision_event;
end architecture;
