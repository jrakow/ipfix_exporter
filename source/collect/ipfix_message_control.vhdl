library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_common_subtypes.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_ipfix_data_record.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module accumulates IPFIX data records and forwards them, if an IPFIX message is ready.

Incoming IPFIX data records are saved until an IPFIX message is full (this is determined by the width of an IPFIX data record) or until the IPFIX message timeout is reached.
The timeout is computed by subtracting a one Hertz pulse from the given timeout.
If the message is ready, the IPFIX set header is computed and it and the whole set is forwarded.

configuration in:
* `ipfix_message_timeout`
* `ipfix_template_id`
 */
entity ipfix_message_control is
	generic(
		g_record_width : natural;
		g_period       : time
	);
	port(
		clk                       : in  std_ulogic;
		rst                       : in  std_ulogic;
		if_axis_in_m_tdata        : in  std_ulogic_vector(g_record_width - 1 downto 0);
		if_axis_in_m_tvalid       : in  std_ulogic;
		if_axis_in_s              : out t_if_axis_s;

		if_axis_out_m             : out t_if_axis_frame_m;
		if_axis_out_s             : in  t_if_axis_s;

		cpu_ipfix_config          : in t_ipfix_config;
		cpu_ipfix_message_timeout : in t_timeout;
		-- only used for ipfix header, not timeout
		cpu_timestamp             : in t_timestamp
	);
end entity;

architecture arch of ipfix_message_control is
	constant c_ip_version              : positive := get_ip_version_from_ipfix_data_record_width(g_record_width);
	function get_max_ipfix_data_records_per_message(ip_version : positive) return natural is
	begin
		if ip_version = 6 then
			return c_ipv6_ipfix_records_per_message;
		else
			return c_ipv4_ipfix_records_per_message;
		end if;
	end;
	constant c_max_records_per_message : natural := get_max_ipfix_data_records_per_message(c_ip_version);

	-- g_record_width is always a multiple of 128
	constant c_frames_per_record : natural := g_record_width / 128;

	type t_fsm is (collect, send_header, send, wait_read);
	type t_records is array (c_max_records_per_message - 1 downto 0) of std_ulogic_vector(g_record_width - 1 downto 0);

	type t_reg is record
		fsm                 : t_fsm;
		records             : t_records;
		record_count        : natural range 0 to c_max_records_per_message;
		remaining_timeout   : t_timeout;
		send_record_counter : natural range 1 to c_max_records_per_message;
		send_frame_counter  : natural range 1 to c_frames_per_record;
		ipfix_header        : t_ipfix_header;
		ipfix_set_header    : t_ipfix_set_header;
		ipfix_header_part   : std_ulogic_vector(c_ipfix_set_header_width - 1 downto 0);

		-- output
		if_axis_in_s  : t_if_axis_s;
		if_axis_out_m : t_if_axis_frame_m;
	end record;
	constant c_reg_default : t_reg := (
		fsm                 => collect,
		records             => (others => (others => '0')),
		record_count        => 0,
		remaining_timeout   => x"0001",
		send_record_counter => 1,
		send_frame_counter  => c_frames_per_record,
		ipfix_header        => c_ipfix_header_default,
		ipfix_set_header    => c_ipfix_set_header_default,
		ipfix_header_part   => (others => '0'),
		if_axis_in_s        => c_if_axis_s_default,
		if_axis_out_m       => c_if_axis_frame_m_default
	);
	signal r, r_nxt : t_reg := c_reg_default;

	signal s_one_hertz_pulse : std_ulogic;
	signal s_ipfix_header_part : std_ulogic_vector(c_ipfix_set_header_width - 1 downto 0);
	signal s_if_axis_m : t_if_axis_frame_m;
	signal s_if_axis_s : t_if_axis_s;
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
	                 s_if_axis_m, s_if_axis_s,
	                 s_one_hertz_pulse, cpu_ipfix_message_timeout, cpu_timestamp, cpu_ipfix_config,
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when collect =>
				v.if_axis_in_s.tready := '1';

				if if_axis_in_m_tvalid and if_axis_in_s.tready then
					v.records(v.record_count) := if_axis_in_m_tdata;
					v.record_count            := v.record_count + 1;
				end if;

				if    v.record_count = c_max_records_per_message
				   or (v.remaining_timeout = 0 and v.record_count /= 0) then
					v.if_axis_in_s.tready := '0';

					-- construct ipfix header and ipfix set header
					v.ipfix_header.export_time           := cpu_timestamp;
					v.ipfix_header.observation_domain_id := cpu_ipfix_config.observation_domain_id;
					-- sequence number incremented after sending
					v.ipfix_set_header.set_id            := cpu_ipfix_config.template_id;
					v.ipfix_set_header.length            := to_unsigned(4 + g_record_width / 8 * v.record_count, 16);
					v.ipfix_header.length                := v.ipfix_set_header.length + c_ipfix_header_width / 8;

					-- first part of ipfix header is prefixed by generic_prefix
					-- second part and set header are the first frame
					v.ipfix_header_part := to_std_ulogic_vector(v.ipfix_header)(127 downto 96);

					v.fsm := send_header;
				elsif v.record_count = 0 then
					v.remaining_timeout := cpu_ipfix_message_timeout;
				elsif s_one_hertz_pulse = '1' and v.remaining_timeout /= 0 then
					v.remaining_timeout := v.remaining_timeout - 1;
				end if;

			when send_header =>
				v.if_axis_out_m.tvalid := '1';
				v.if_axis_out_m.tdata  := to_std_ulogic_vector(v.ipfix_header)(95 downto 0) & to_std_ulogic_vector(v.ipfix_set_header);
				v.if_axis_out_m.tkeep := (others => '1');
				v.if_axis_out_m.tlast := '0';

				if s_if_axis_m.tvalid and s_if_axis_s.tready then
					v.ipfix_header.sequence_number := v.ipfix_header.sequence_number + v.record_count;
					v.if_axis_out_m.tvalid := '0';
					v.fsm := send;
				end if;

			when send =>
				v.if_axis_out_m.tvalid := '1';
				v.if_axis_out_m.tdata := r.records(v.send_record_counter - 1)(v.send_frame_counter * 128 - 1 downto (v.send_frame_counter - 1) * 128);
				v.if_axis_out_m.tkeep := (others => '1');
				v.if_axis_out_m.tlast := '0';

				if s_if_axis_m.tvalid and s_if_axis_s.tready then
					if r.send_frame_counter = 1 then
						v.send_frame_counter  := c_frames_per_record;
						v.send_record_counter := r.send_record_counter + 1;
					else
						v.send_frame_counter := r.send_frame_counter - 1;
					end if;

					if v.send_record_counter = r.record_count and v.send_frame_counter = 1 then
						v.if_axis_out_m.tdata := r.records(v.send_record_counter - 1)(127 downto 0);
						v.if_axis_out_m.tlast := '1';
						v.fsm := wait_read;
					end if;
				end if;

			when wait_read =>
				if s_if_axis_m.tvalid and s_if_axis_s.tready then
					-- reset
					v.if_axis_out_m.tvalid := c_reg_default.if_axis_out_m.tvalid;
					v.record_count         := c_reg_default.record_count;
					v.send_frame_counter   := c_reg_default.send_frame_counter;
					v.send_record_counter  := c_reg_default.send_record_counter;
					-- silence warning about dead state
					v.fsm := collect;

					-- set timeout to (new) cpu timeout
					v.remaining_timeout := cpu_ipfix_message_timeout;
				end if;
		end case;

		r_nxt <= v;
	end process;

	if_axis_in_s        <= r.if_axis_in_s ;
	s_if_axis_m         <= r.if_axis_out_m;
	s_ipfix_header_part <= r.ipfix_header_part;

	b_one_hertz_counter : block
		constant c_one_hertz_counter_max : natural                                    := 1 sec / g_period;
		signal s_one_hertz_counter       : natural range 0 to c_one_hertz_counter_max := c_one_hertz_counter_max;
	begin
		p_counter : process(clk)
		begin
			if rising_edge(clk) then
				if rst = c_reset_active then
					s_one_hertz_pulse   <= '0';
					s_one_hertz_counter <= c_one_hertz_counter_max;
				else
					s_one_hertz_pulse <= '0';
					if s_one_hertz_counter = 0 then
						s_one_hertz_pulse   <= '1';
						s_one_hertz_counter <= c_one_hertz_counter_max;
					else
						s_one_hertz_counter <= s_one_hertz_counter - 1;
					end if;
				end if;
			end if;
		end process;
	end block;

	i_generic_prefix : entity ipfix_exporter.generic_prefix
		generic map(
			g_prefix_width => c_ipfix_set_header_width
		)
		port map(
			clk           => clk,
			rst           => rst,

			if_axis_in_m  => s_if_axis_m,
			if_axis_in_s  => s_if_axis_s,

			if_axis_out_m => if_axis_out_m,
			if_axis_out_s => if_axis_out_s,

			prefix        => to_std_ulogic_vector(s_ipfix_header_part)
		);
end architecture;
