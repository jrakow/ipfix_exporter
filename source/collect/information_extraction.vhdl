library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_common_subtypes.all;
use ipfix_exporter.pkg_frame_info.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module extracts flow information from the incoming Ethernet frame and fills an IPFIX data record.

The extracted information includes the quintuple use for identifying the flow and additional information (see [data types](doc/data_types.md)).
The output format is @ref t_ipv6_frame_info or @ref t_ipv4_frame_info for the IP version.

configuration in:
* `timestamp`
 */
entity information_extraction is
	generic(
		g_frame_info_width : natural
	);
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m_tdata  : out std_ulogic_vector(g_frame_info_width - 1 downto 0);
		if_axis_out_m_tvalid : out std_ulogic;
		if_axis_out_s        : in  t_if_axis_s;

		cpu_timestamp : in t_timestamp
	);
end entity;

architecture arch of information_extraction is
	function get_ip_version(width : natural) return positive is
	begin
		if width = c_ipv6_frame_info_width then
			return 6;
		else
			return 4;
		end if;
	end function;
	constant c_ip_version : positive := get_ip_version(g_frame_info_width);

	-- incoming frames are collected until the ip header and the udp header are filled
	-- if remaining frames is 0 then all the information is collected
	function get_max_remaining_frames(ip_version : positive) return natural is
	begin
		if ip_version = 6 then
			return 3;
		else
			return 2;
		end if;
	end;
	constant c_max_remaining_frames : natural := get_max_remaining_frames(c_ip_version);

	type t_fsm is (collect, wait_read);
	type t_reg is record
		fsm : t_fsm;

		remaining_frames : natural range 0 to c_max_remaining_frames;

		-- assembled ip and udp headers
		-- only ipv6 or ipv4 is used
		ipv6_header : std_ulogic_vector(c_ipv6_header_width - 1 downto 0);
		ipv4_header : std_ulogic_vector(c_ipv4_header_width - 1 downto 0);
		udp_header  : std_ulogic_vector(c_udp_header_width  - 1 downto 0);

		-- output
		if_axis_in_s         : t_if_axis_s;
		ipv6_frame_info      : t_ipv6_frame_info;
		ipv4_frame_info      : t_ipv4_frame_info;
		if_axis_out_m_tvalid : std_ulogic;
	end record;
	constant c_reg_default : t_reg := (
		fsm                  => collect,
		remaining_frames     => c_max_remaining_frames,
		ipv6_header          => (others => '0'),
		ipv4_header          => (others => '0'),
		udp_header           => (others => '0'),
		if_axis_in_s         => c_if_axis_s_default,
		ipv6_frame_info      => c_ipv6_frame_info_default,
		ipv4_frame_info      => c_ipv4_frame_info_default,
		if_axis_out_m_tvalid => '0'
	);
	signal r, r_nxt : t_reg := c_reg_default;
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

	p_comb : process(cpu_timestamp,
		if_axis_in_m, if_axis_in_s,
		if_axis_out_m_tvalid, if_axis_out_s,
		r
		)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when collect =>
				v.if_axis_in_s.tready := '1';

				if if_axis_in_m.tvalid and if_axis_in_s.tready then
					case v.remaining_frames is
						when 3 =>
							v.ipv6_header(319 downto 192) := if_axis_in_m.tdata;
							if if_axis_in_m.tlast then
								v := c_reg_default;
							end if;
						when 2 =>
							v.ipv6_header(191 downto 64) := if_axis_in_m.tdata;
							v.ipv4_header(159 downto 32) := if_axis_in_m.tdata;
							if if_axis_in_m.tlast then
								v := c_reg_default;
							end if;
						when 1 =>
							-- collect final parts
							v.ipv6_header(63 downto 0) := if_axis_in_m.tdata(127 downto 64);
							v.ipv4_header(31 downto 0) := if_axis_in_m.tdata(127 downto 96);
							-- treat as udp to get ports
							if c_ip_version = 6 then
								v.udp_header := if_axis_in_m.tdata(63 downto 0);
							else
								v.udp_header := if_axis_in_m.tdata(95 downto 32);
							end if;

							-- assemble frame_info
							v.ipv6_frame_info.timestamp := cpu_timestamp;
							v.ipv4_frame_info.timestamp := cpu_timestamp;
							v.ipv6_frame_info.src_port  := to_udp_header(v.udp_header).source;
							v.ipv4_frame_info.src_port  := to_udp_header(v.udp_header).source;
							v.ipv6_frame_info.dest_port := to_udp_header(v.udp_header).destination;
							v.ipv4_frame_info.dest_port := to_udp_header(v.udp_header).destination;
--							v.ipv6_frame_info.tcp_flags := TODO
--							v.ipv4_frame_info.tcp_flags := TODO
							if c_ip_version = 6 then
								v.ipv6_frame_info.src_ip_addr   := to_ipv6_header(v.ipv6_header).source;
								v.ipv6_frame_info.dest_ip_addr  := to_ipv6_header(v.ipv6_header).destination;
								-- length in ipv6 header is without header
								v.ipv6_frame_info.octet_count   := to_ipv6_header(v.ipv6_header).payload_length + 40;
								v.ipv6_frame_info.next_header   := to_ipv6_header(v.ipv6_header).next_header;
								v.ipv6_frame_info.traffic_class := to_ipv6_header(v.ipv6_header).traffic_class;
							else
								v.ipv4_frame_info.src_ip_addr   := to_ipv4_header(v.ipv4_header).source;
								v.ipv4_frame_info.dest_ip_addr  := to_ipv4_header(v.ipv4_header).destination;
								v.ipv4_frame_info.octet_count   := to_ipv4_header(v.ipv4_header).total_length;
								v.ipv4_frame_info.next_header   := to_ipv4_header(v.ipv4_header).protocol;
								v.ipv4_frame_info.traffic_class := to_ipv4_header(v.ipv4_header).traffic_class;
							end if;

							v.if_axis_out_m_tvalid := '1';
							if if_axis_in_m.tlast then
								-- forget incoming frames until tlast
								v.if_axis_in_s.tready := '0';
							end if;

							v.fsm                  := wait_read;
					end case;
					v.remaining_frames := r.remaining_frames - 1;
				end if;

			when wait_read =>
				if if_axis_in_m.tvalid and if_axis_in_s.tready and if_axis_in_m.tlast then
					-- forget incoming frames until tlast
					v.if_axis_in_s.tready := '0';
				end if;
				if if_axis_out_m_tvalid and if_axis_out_s.tready then
					-- disable sending
					v.if_axis_out_m_tvalid := '0';
				end if;

				-- handle next packet iff all incoming frames have been dropped and information has been sent
				if v.if_axis_in_s.tready = '0' and if_axis_out_m_tvalid = '0' then
					-- reset
					v := c_reg_default;
					-- not necessary, silences Sigasi warning
					v.fsm := collect;
				end if;
		end case;

		r_nxt <= v;
	end process;

	if_axis_in_s         <= r.if_axis_in_s;
	if_axis_out_m_tdata  <= to_std_ulogic_vector(r.ipv6_frame_info) when c_ip_version = 6 else to_std_ulogic_vector(r.ipv4_frame_info);
	if_axis_out_m_tvalid <= r.if_axis_out_m_tvalid;
end architecture;
