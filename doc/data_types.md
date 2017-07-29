# Data types in `ipfix_exporter`

## AXI stream interfaces
There are two different AXIS interfaces used:
1. For lots of data: 128 bit wide many frames per transaction stream.
   The following signals are used: `tdata`, `tvalid`, `tkeep`, `tlast` and `tready`.
2. For single IPFIX data records: single frame per transaction stream.
   The used bit width is the bit width of an IPFIX data record (depending on the IP version)
   The following signals are used: `tdata`, `tvalid` and `tready`.
   As this interface does not use `tkeep` and `tlast`, these may be tied high.

## IPFIX data records
### IPv6 template
| element ID | length | name                     |
| ---------: | -----: | ------------------------ |
|         27 |     16 | sourceIPv6Address        |
|         28 |     16 | destinationIPv6Address   |
|          7 |      2 | sourceTransportPort      |
|         11 |      2 | destinationTransportPort |
|        150 |      4 | flowStartSeconds         |
|        151 |      4 | flowEndSeconds           |
|          1 |      4 | octetDeltaCount          |
|          2 |      4 | packetDeltaCount         |
|          4 |      1 | protocolIdentifier       |
|          5 |      1 | ipClassOfService         |
|          6 |      1 | tcpControlBits           |
|        210 |      9 | paddingOctets            |
|            |     64 | *total*                  |

### IPv4 template
| element ID | length | name                     |
| ---------: | -----: | ------------------------ |
|          8 |      4 | sourceIPv4Address        |
|         12 |      4 | destinationIPv4Address   |
|          7 |      2 | sourceTransportPort      |
|         11 |      2 | destinationTransportPort |
|        150 |      4 | flowStartSeconds         |
|        151 |      4 | flowEndSeconds           |
|          1 |      4 | octetDeltaCount          |
|          2 |      4 | packetDeltaCount         |
|          4 |      1 | protocolIdentifier       |
|          5 |      1 | ipClassOfService         |
|          6 |      1 | tcpControlBits           |
|        210 |      1 | paddingOctets            |
|            |     32 | *total*                  |
