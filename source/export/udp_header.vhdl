library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ipfix_exporter;
use ipfix_exporter.pkg_axi_stream.all;
use ipfix_exporter.pkg_config.all;
use ipfix_exporter.pkg_protocol_types.all;
use ipfix_exporter.pkg_types.all;

/*!
This module prefixes an arbitrary payload with an UDP header.

This module buffers a whole packet.
While buffering the length and checksum are computed.
This module does not use information from the payload.

The IP version may be set at runtime.

configuration in:
* `ip_version`
* `ipvN_source_address`
* `ipvN_destination_address`
* `source_port`
* `destination_port`
 */
entity udp_header is
	port(
		clk : in std_ulogic;
		rst : in std_ulogic;

		if_axis_in_m : in  t_if_axis_frame_m;
		if_axis_in_s : out t_if_axis_s;

		if_axis_out_m : out t_if_axis_frame_m;
		if_axis_out_s : in  t_if_axis_s;

		cpu_udp_config : in t_udp_config;
		cpu_ip_config  : in t_ip_config;

		-- ip config for ip header
		udp_ip_config : out t_ip_config
	);
end entity;

architecture arch of udp_header is
	type t_fsm is (fill_fifo, send);

	type t_reg is record
		fsm : t_fsm;
		partial_checksum : t_partial_checksum;
		length : unsigned(15 downto 0);

		-- output
		fifo_in_enable  : std_ulogic;
		fifo_out_enable : std_ulogic;

		udp_header    : t_udp_header;
		udp_ip_config : t_ip_config;
	end record;
	constant c_reg_default : t_reg := (
		fsm              => fill_fifo,
		partial_checksum => (others => '0'),
		length           => (others => '0'),
		fifo_in_enable   => '0',
		fifo_out_enable  => '0',
		udp_header       => c_udp_header_default,
		udp_ip_config    => c_ip_config_default
	);
	signal r, r_nxt : t_reg := c_reg_default;

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

	p_comb : process(if_axis_in_m, if_axis_in_s,
	                 s_if_axis_m, s_if_axis_s,
	                 cpu_udp_config, cpu_ip_config,
	                 r)
		variable v : t_reg := c_reg_default;
	begin
		v := r;

		case r.fsm is
			when fill_fifo =>
				v.fifo_in_enable  := '1';
				v.fifo_out_enable := '0';

				if r.fifo_in_enable and if_axis_in_m.tvalid and if_axis_in_s.tready then
					v.length := v.length + tkeep_to_integer(if_axis_in_m.tkeep);

					-- checksum all parts
					v.partial_checksum := partial_checksum(
						std_ulogic_vector(r.partial_checksum)
						& (if_axis_in_m.tdata and tkeep_to_mask(if_axis_in_m.tkeep)));

					if if_axis_in_m.tlast then
						-- construct udp header
						v.udp_header.source      := cpu_udp_config.source;
						v.udp_header.destination := cpu_udp_config.destination;
						v.udp_header.length      := c_udp_header_width / 8 + v.length;

						v.udp_header.checksum := udp_checksum(v.udp_header, v.partial_checksum, cpu_ip_config);

						v.fifo_in_enable := '0';
						v.fsm := send;
					end if;
				end if;

			when send =>
				v.fifo_in_enable  := '0';
				v.fifo_out_enable := '1';

				if r.fifo_out_enable and s_if_axis_m.tvalid and s_if_axis_s.tready and s_if_axis_m.tlast then
					v := c_reg_default;
					-- silence dead state warning
					v.fsm := fill_fifo;
				end if;
		end case;

		r_nxt <= v;
	end process;

	udp_ip_config <= r.udp_ip_config;

	b_instantiations : block
		signal s_if_axis_in_m_tvalid : std_ulogic;
		signal s_if_axis_in_s        : t_if_axis_s;
		signal s_if_axis_m_tvalid    : std_ulogic;
		signal s_if_axis_s_tready    : std_ulogic;
	begin
		-- fifo controlled by p_comb
		s_if_axis_in_m_tvalid <= if_axis_in_m.tvalid and r.fifo_in_enable;
		if_axis_in_s.tready <= s_if_axis_in_s.tready and r.fifo_in_enable;

		s_if_axis_m_tvalid <= s_if_axis_m.tvalid and r.fifo_out_enable;
		s_if_axis_s_tready <= s_if_axis_s.tready and r.fifo_out_enable;

		i_axis_fifo : entity ipfix_exporter.axis_fifo
			generic map(
				-- bytes to frames
				-- round up
				g_depth => c_ipfix_message_max_length / 16 + 1
			)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tvalid => s_if_axis_in_m_tvalid,
				if_axis_in_m.tdata  => if_axis_in_m.tdata,
				if_axis_in_m.tkeep  => if_axis_in_m.tkeep,
				if_axis_in_m.tlast  => if_axis_in_m.tlast,
				if_axis_in_s  => s_if_axis_in_s,

				if_axis_out_m        => s_if_axis_m,
				if_axis_out_s.tready => s_if_axis_s_tready
			);
		i_generic_prefix : entity ipfix_exporter.generic_prefix
			generic map(
				g_prefix_width => c_udp_header_width
			)
			port map(
				clk           => clk,
				rst           => rst,

				if_axis_in_m.tvalid => s_if_axis_m_tvalid,
				if_axis_in_m.tdata  => s_if_axis_m.tdata,
				if_axis_in_m.tkeep  => s_if_axis_m.tkeep,
				if_axis_in_m.tlast  => s_if_axis_m.tlast,
				if_axis_in_s  => s_if_axis_s,

				if_axis_out_m => if_axis_out_m,
				if_axis_out_s => if_axis_out_s,

				prefix        => to_std_ulogic_vector(r.udp_header)
			);
	end block;
end architecture;
