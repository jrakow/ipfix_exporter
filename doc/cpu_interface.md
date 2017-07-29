# CPU interface of the `ipfix_exporter`

The following registers are provided for reading and writing by the CPU:
| Offset | Content                                                              |
| -----: | -------------------------------------------------------------------- |
| `0x00` | scratchpad                                                           |
| `0x04` | configuration register (see [configuration register](#config_reg))   |
| `0x08` | UNIX timestamp                                                       |
| `0x0C` | cache active timeout, cache inactive timeout                         |
| `0x10` | `0x00`, `0x00`, IPFIX message timeout                                |
| `0x14` | IPFIX IPv6 template ID, IPFIX IPv4 template ID                       |
| `0x18` | IPFIX observation domain ID                                          |
| `0x1C` | UDP source port, UDP destination port                                |
| `0x20` | IPv6 source address(bytes  3- 0)                                     |
| `0x24` | IPv6 source address(bytes  7- 4)                                     |
| `0x28` | IPv6 source address(bytes 11- 8)                                     |
| `0x2C` | IPv6 source address(bytes 15-12)                                     |
| `0x30` | IPv6 destination address(bytes  3- 0)                                |
| `0x34` | IPv6 destination address(bytes  7- 4)                                |
| `0x38` | IPv6 destination address(bytes 11- 8)                                |
| `0x3C` | IPv6 destination address(bytes 15-12)                                |
| `0x40` | IPv4 source address                                                  |
| `0x44` | IPv4 destination address                                             |
| `0x48` | 0x00, 0x0, IPv6 flow label                                           |
| `0x4C` | 0x00, 0x00, IPv4 identification                                      |
| `0x50` | 0x00, 0x00, IP hop limit, IP traffic class                           |
| `0x54` | VLAN tag 0 (the first)                                               |
| `0x58` | VLAN tag 1 (the second)                                              |
| `0x5C` | *invalid*                                                            |
| `0x60` | source MAC address(bytes 3-0)                                        |
| `0x64` | source MAC address(bytes 5-4)                                        |
| `0x68` | destination MAC address(bytes 3-0)                                   |
| `0x6C` | destination MAC address(bytes 5-4)                                   |

## Counters
| Offset | Content                                         |
| -----: | ----------------------------------------------- |
| `0x70` | input frames                                    |
| `0x74` | frames after @ref selective_dropping            |
| `0x78` | frames after @ref ethernet_dropping             |
| `0x7C` | frames after @ref axis_combiner (output frames) |
| `0x80` | IPv6 frames after @ref ip_version_split         |
| `0x84` | IPv6 flows after @ref information_extraction    |
| `0x88` | IPv6 flow hash collisions                       |
| `0x8C` | IPv6 flows after @ref cache_extraction          |
| `0x90` | IPv6 frames after @ref ipfix_message_control    |
| `0x94` | IPv6 frames after @ref ipfix_header             |
| `0x98` | IPv6 frames after @ref udp_header               |
| `0x9C` | IPv6 frames after @ref ip_header                |
| `0xA0` | IPv6 frames after @ref ethertype_insertion      |
| `0xA4` | IPv6 frames after @ref vlan_insertion           |
| `0xA8` | IPv6 frames after @ref ethernet_header          |
| `0xAC` | *invalid*                                       |
| `0xB0` | IPv4 frames after @ref ip_version_split         |
| `0xB4` | IPv4 flows after @ref information_extraction    |
| `0xB8` | IPv4 flow hash collisions                       |
| `0xBC` | IPv4 flows after @ref cache_extraction          |
| `0xC0` | IPv4 frames after @ref ipfix_message_control    |
| `0xC4` | IPv4 frames after @ref ipfix_header             |
| `0xC8` | IPv4 frames after @ref udp_header               |
| `0xCC` | IPv4 frames after @ref ip_header                |
| `0xD0` | IPv4 frames after @ref ethertype_insertion      |
| `0xD4` | IPv4 frames after @ref vlan_insertion           |
| `0xD8` | IPv4 frames after @ref ethernet_header          |

<h2 id="config_reg">Configuration register</h2>

| Bit    | Content                                                 |
| -----: | ------------------------------------------------------- |
|    `0` | `1`: commit addresses and ports (read as `0`)           |
|    `1` | IPv6 instead of IPv4                                    |
|    `2` | enable dropping of own frames (@ref selective_dropping) |
|  `4-3` | number of VLAN tags that should be used                 |
| `31-5` | `0`                                                     |
