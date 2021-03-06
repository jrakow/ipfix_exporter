# `ipfix_exporter` – FPGA based network monitoring
This repository contains a library to export information about network flows.

## Top level view
Incoming Ethernet frames are prepared by inserting padding after VLAN tags.
Information about the Ethernet frames is extracted.
This is the quintuple used for identifying the flow and additional information such as the frame length and a timestamp.
With this information a cache lookup is performed and an existing flow is updated with the additional information or a new one created.
This concludes the processing of new frames.

Meanwhile the cache is searched for expired (timed out) flows.
If such a flow is found, the cache entry is reset and the flows is forwarded.

Flows are collected to form IPFIX messages.
If an IPFIX message is ready, it is wrapped in the UDP, IP and Ethernet protocols and sent.
