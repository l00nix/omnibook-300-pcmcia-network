# Tested Cards

These cards were tested on an HP OmniBook 300 using `O300NIC.COM`,
`LXEN2216.COM 0x66`, mTCP DHCP, mTCP ping, and MicroWeb.

| Card | Result |
| --- | --- |
| Netgear FA411 10/100 PCMCIA Mobile Adapter | DHCP, ping, MicroWeb working |
| Buffalo Tough Connect LPC3-CLT | MAC detection and packet-driver load confirmed |
| MAP Japan MPL-972/Tamarack | MAC detection and packet-driver load confirmed |
| Accton EN2216-1 | MAC detection and packet-driver load confirmed |

The storage-card coexistence test also passed: with the network stack loaded,
the OmniBook 300 still recognized a PCMCIA storage card inserted in the other
slot.
