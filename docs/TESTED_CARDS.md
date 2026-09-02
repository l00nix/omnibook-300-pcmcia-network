# Tested Cards

These cards were tested on an HP OmniBook 300 using `O300NIC.COM`,
`LXEN2216.COM 0x66`, mTCP DHCP, mTCP ping, and MicroWeb.

| Card | Result |
| --- | --- |
| Netgear FA411 10/100 PCMCIA Mobile Adapter | DHCP, ping, MicroWeb working |
| Buffalo Tough Connect LPC3-CLT | DHCP, ping, MicroWeb working |
| MAP Japan MPL-972/Tamarack | MAC detection and packet-driver load confirmed |
| Accton EN2216-1 | DHCP, ping, MicroWeb working |

The storage-card coexistence test also passed: with the network stack loaded,
the OmniBook 300 still recognized a PCMCIA storage card inserted in the other
slot.

## OmniBook 425

The Netgear FA411 was also tested on an OmniBook 425. The working experimental
path used `O300NIC.COM` to enable the card and Crynwr `NE2000.COM` as the packet
driver. DHCP, ping, and MicroWeb worked.

Buffalo Tough Connect LPC3-CLT and Accton EN2216-1 cards remain OmniBook
300-only successes for now; they did not work in the OmniBook 425 FA411 test
path.
