# Modules used in `ipfix_exporter`
Most modules will use AXI streams as interfaces.
Small modules shall be used with minimal tasks.
This simplifies development and testing.
Think of UNIX tools piped one after another.

## selective dropping
* AXIS in: Ethernet frame
* configuration in: `drop_source_mac_enable`, `export_source_mac_address`
* AXIS out: Ethernet frame

This module drops frames originating from `ipfix_exporter`.

This opens the possibility to insert IPFIX messages in front of the collector without them being measured.

Incoming Ethernet frames are expected to start at the destination MAC address and end with transport layer payload. Network byte order is used.
Frames to be dropped are recognized by the source MAC address.
This module can be enabled / disabled by setting a flag in the configuration register.
If this module is disabled, all Ethernet frames are forwarded.

## Ethernet dropping
* AXIS in: Ethernet frame
* AXIS out: IP packet

This module drops the Ethernet header.

Up to three VLAN tags are supported.
The output IP packet starts at the IP header.
MAC addresses, VLAN tags and the Ethertype field are dropped.

## IP version split
* AXIS in: segmented Ethernet frame
* AXIS out 0: segmented IPv6 Ethernet frame
* AXIS out 1: segmented IPv4 Ethernet frame

This module splits the incoming data by IP version.

The first one or two frames (depending on the number of VLANs) are buffered.
Only the IP version field of the IP header at the beginning of the third frame is considered.

This splits the data path into an IPv6 and an IPv4 path.

## packet classification
* AXIS in: segmented IPvN Ethernet frame
* configuration in: `timestamp`
* AXIS out: IPFIX IPvN data record

This module extracts flow information from the incoming Ethernet frame and fills an IPFIX data record.

The extracted information includes the quintuple use for identifying the flow and additional information (see [data types](doc/data_types.md)).
The output format is the IPFIX data record data type for the corresponding IP version.
The signals as specified in the introduction are used.

## cache insertion
* AXIS in: IPFIX IPvN data record
* configuration out: `collision_counter`
* RAM: cache port A

This module inserts new flows into the cache.

The quintuple of incoming frames is hashed and used as the address of the cache, which is a hash table.
A cache slot is read.
If the cache slot is empty, a new flow is created.
If the cache slot is used and the quintuples do not match, a collision occured and the collision counter is incremented.
If the matching flow was found, it is updated with the new frame length and a new timestamp.

## cache extraction
* RAM: cache port B
* configuration in: `cache_active_timeout`, `cache_inactive_timeout`, `timestamp`
* AXIS out: IPFIX IPvN data record

This module searches the cache for expired flows and exports these.

The cache, which is a hash table, is searched in linear order for expired flows.
A flows is expired, if the last frame is older than the inactive timeout or if the first frame is older than the active timeout.
Expired flows are put directly onto the AXIS interface.
`tkeep` and `tlast` are not used, because a whole data record is transported with each transaction.

## IPFIX message control
* AXIS in: IPFIX IPvN data record
* configuration in: `ipfix_message_timeout`
* AXIS out: IPFIX IPvN set

This module accumulates IPFIX data records and forwards them, if an IPFIX message is ready.

Incoming IPFIX data records are saved until an IPFIX message is full (this is determined by the width of an IPFIX data record) or until the IPFIX message timeout is reached.
The timeout is computed by subtracting a one Hertz pulse from the given timeout.
If the message is ready, the IPFIX set header is computed and it and the whole set is forwarded.

## IPFIX header
* AXIS in: IPFIX IPvN set header and payload
* configuration in: `ipfix_ipvN_template_id`, `ipfix_observation_domain_id`, `timestamp`
* AXIS out: IPFIX message

This module generates an IPFIX header for an incoming stream of IPFIX sets.

The sequence number is kept track of.
For the length field the length field of the set header is used.

Multiple sets in a single message are not supported.
A new header is prefixed for every set.
The whole IPFIX message is forwarded.

## UDP header
* AXIS in: IPFIX message
* configuration in: `ip_version`, `ipvN_source_address`, `ipvN_destination_address`, `source_port`, `destination_port`
* AXIS out: UDP packet

This module prefixes an IPFIX message with an UDP header.

This module buffers a whole packet.
While buffering the length and checksum are computed.
This module does not use information from the payload.

The IP version may be set at runtime.

## IP header
* AXIS in: UDP packet
* configuration in: `ip_version`, `ip_traffic_class`, `ipv6_flow_label`, `ipv4_identification`, `hop_limit`, `ipvN_source_address`, `ipvN_destination_address`
* AXIS out: IP packet

This module prefixes an IPv6 or IPv4 header.

The IP version may be set at runtime.

## VLAN / Ethertype insertion
* AXIS in: IP packet
* configuration in: `number_of_vlans`, `vlan0`, `vlan1`
* AXIS out: IP packet with VLAN tags

This module inserts VLAN tags and the Ethertype field.

The IP packet is prefixed by one or more VLAN tags.
`vlan0` is the earliest tag.

## Ethernet header
* AXIS in: IP packet with VLAN tags
* configuration in: `destination_mac_address`, `source_mac_address`
* AXIS out: Ethernet frame

This module prefixes MAC addresses.

## AXIS combiner
* AXIS in 0: Ethernet frame (IPFIX IPv6 data record)
* AXIS in 1: Ethernet frame (IPFIX IPv4 data record)
* AXIS out: Ethernet frame

This module combines the seperate Ethernet frames from the IPv6 and the IPv4 data path into a single one.
