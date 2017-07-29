# Modules used in `ipfix_exporter`
Most modules will use AXI streams as interfaces.
Small modules shall be used with minimal tasks.
This simplifies development and testing.
Think of UNIX tools piped one after another.

@dot
digraph overview
	{
	node [shape=box];
	input  [ label="input"  shape=circle ];
	output [ label="output" shape=circle ];

	top_preparation             [ label="top_preparation"             URL="@ref top_preparation"             ];
	top_collect_ipv6            [ label="top_collect_ipv6"            URL="@ref top_collect"                 ];
	top_collect_ipv4            [ label="top_collect_ipv4"            URL="@ref top_collect"                 ];
	axis_combiner               [ label="axis_combiner"               URL="@ref axis_combiner"               ];

	input -> top_preparation;
	top_preparation -> top_collect_ipv6 -> axis_combiner;
	top_preparation -> top_collect_ipv4 -> axis_combiner;
	axis_combiner -> output;
	}
@enddot

## selective dropping
* AXIS in: Ethernet frame
* AXIS out: Ethernet frame

## Ethernet dropping
* AXIS in: Ethernet frame
* AXIS out: IP packet

## IP version split
* AXIS in: segmented Ethernet frame
* AXIS out 0: segmented IPv6 Ethernet frame
* AXIS out 1: segmented IPv4 Ethernet frame

## information extraction
* AXIS in: segmented IPvN Ethernet frame
* AXIS out: IPvN frame info

## cache insertion
* AXIS in: IPvN frame info
* RAM: cache port A

## cache extraction
* RAM: cache port B
* AXIS out: IPFIX IPvN data record

## IPFIX message control
* AXIS in: IPFIX IPvN data record
* AXIS out: IPFIX IPvN set

## IPFIX header
* AXIS in: IPFIX IPvN set header and payload
* AXIS out: IPFIX message

## UDP header
* AXIS in: IPFIX message
* AXIS out: UDP packet

## IP header
* AXIS in: UDP packet
* AXIS out: IP packet

## Ethertype insertion
* AXIS in: IP packet
* AXIS out: IP packet with Ethertype

## VLAN insertion
* AXIS in: IP packet with Ethertype
* AXIS out: IP packet with VLAN tags

## Ethernet header
* AXIS in: IP packet with VLAN tags
* AXIS out: Ethernet frame

## AXIS combiner
* AXIS in 0: Ethernet frame (IPFIX IPv6 data record)
* AXIS in 1: Ethernet frame (IPFIX IPv4 data record)
* AXIS out: Ethernet frame
