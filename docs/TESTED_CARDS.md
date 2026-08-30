# Tested Cards

These cards were tested on an HP OmniBook 300 using `O300NIC.COM`,
`LXEN2216.COM 0x66`, mTCP DHCP, mTCP ping, and MicroWeb.

| Card | MAC observed by O300NIC/LXEN2216 | Result |
| --- | --- | --- |
| Netgear FA411 10/100 PCMCIA Mobile Adapter | `00:40:F4:10:DF:C2` | DHCP, ping, MicroWeb working |
| Buffalo Tough Connect LPC3-CLT | `00:07:40:19:1A:4D` | MAC detection working |
| MAP Japan MPL-972/Tamarack | `00:C0:0C:02:7F:26` | MAC detection working |
| Accton EN2216-1 | `00:00:EB:3A:43:01` | MAC detection working |

The storage-card coexistence test also passed: with the network stack loaded,
the OmniBook 300 still recognized a PCMCIA storage card inserted in the other
slot.
