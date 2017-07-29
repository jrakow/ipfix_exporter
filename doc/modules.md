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
	information_extraction_ipv6 [ label="information_extraction_ipv6" URL="@ref information_extraction_ipv6" ];
	information_extraction_ipv4 [ label="information_extraction_ipv4" URL="@ref information_extraction_ipv4" ];
	cache_insertion_ipv6        [ label="cache_insertion_ipv6"        URL="@ref cache_insertion_ipv6"        ];
	cache_insertion_ipv4        [ label="cache_insertion_ipv4"        URL="@ref cache_insertion_ipv4"        ];
	cache_ipv6                  [ label="cache"                       URL="@ref cache" shape=octagon         ];
	cache_ipv4                  [ label="cache"                       URL="@ref cache" shape=octagon         ];
	cache_extraction_ipv6       [ label="cache_extraction_ipv6"       URL="@ref cache_extraction_ipv6"       ];
	cache_extraction_ipv4       [ label="cache_extraction_ipv4"       URL="@ref cache_extraction_ipv4"       ];
	ipfix_message_control_ipv6  [ label="ipfix_message_control_ipv6"  URL="@ref ipfix_message_control_ipv6"  ];
	ipfix_message_control_ipv4  [ label="ipfix_message_control_ipv4"  URL="@ref ipfix_message_control_ipv4"  ];
	ipfix_header_ipv6           [ label="ipfix_header"                URL="@ref ipfix_header"                ];
	ipfix_header_ipv4           [ label="ipfix_header"                URL="@ref ipfix_header"                ];
	udp_header_ipv6             [ label="udp_header"                  URL="@ref udp_header"                  ];
	udp_header_ipv4             [ label="udp_header"                  URL="@ref udp_header"                  ];
	ip_header_ipv6              [ label="ip_header"                   URL="@ref ip_header"                   ];
	ip_header_ipv4              [ label="ip_header"                   URL="@ref ip_header"                   ];
	ethertype_insertion_ipv6    [ label="ethertype_insertion"         URL="@ref ethertype_insertion"         ];
	ethertype_insertion_ipv4    [ label="ethertype_insertion"         URL="@ref ethertype_insertion"         ];
	vlan_insertion_ipv6         [ label="vlan_insertion"              URL="@ref vlan_insertion"              ];
	vlan_insertion_ipv4         [ label="vlan_insertion"              URL="@ref vlan_insertion"              ];
	ethernet_header_ipv6        [ label="ethernet_header"             URL="@ref ethernet_header"             ];
	ethernet_header_ipv4        [ label="ethernet_header"             URL="@ref ethernet_header"             ];
	axis_combiner               [ label="axis_combiner"               URL="@ref axis_combiner"               ];

	input -> top_preparation;
	top_preparation -> information_extraction_ipv6 -> cache_insertion_ipv6 -> cache_ipv6
		-> cache_extraction_ipv6 -> ipfix_message_control_ipv6
		-> ipfix_header_ipv6 -> udp_header_ipv6 -> ip_header_ipv6 -> ethertype_insertion_ipv6 -> vlan_insertion_ipv6 -> ethernet_header_ipv6
		-> axis_combiner;
	top_preparation -> information_extraction_ipv4 -> cache_insertion_ipv4 -> cache_ipv4
		-> cache_extraction_ipv4 -> ipfix_message_control_ipv4
		-> ipfix_header_ipv4 -> udp_header_ipv4 -> ip_header_ipv4 -> ethertype_insertion_ipv4 -> vlan_insertion_ipv4 -> ethernet_header_ipv4
		-> axis_combiner;
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
* AXIS out: IPFIX IPvN data record

## cache insertion
* AXIS in: IPFIX IPvN data record
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
