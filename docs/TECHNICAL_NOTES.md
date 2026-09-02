# Technical Notes

The OmniBook 300 PCMCIA interface is not a normal desktop PCIC-compatible setup.
Common DOS Card Services stacks either fail to find the controller or fail to
configure the socket. This project talks to the OmniBook 300 card BIOS instead.

`O300NIC.COM` reads CIS tuple data from socket `1`, finds a LAN function, finds
a `300h` CFTABLE entry, and derives the card-specific configuration register
locations.

Two working configuration families have been observed:

| Family | Config base | COR offset | FCSR offset | COR value |
| --- | ---: | ---: | ---: | ---: |
| Netgear FA411 | `03C0h` | `01E0h` | `01E1h` | `47h` |
| EN2216-family cards | `03F8h` | `01FCh` | `01FDh` | `60h` |

The O300 card BIOS accepts 16-byte I/O windows but rejects a single 32-byte
window for the NE2000 register block. The enabler therefore maps two adjacent
16-byte windows. On the OmniBook 300 these are normally:

```text
window 04 -> I/O 300h-30Fh
window 05 -> I/O 310h-31Fh
```

`O300NIC.COM` v1.3 discovers the socket's I/O window IDs before mapping the
card. This preserves the OmniBook 300 `04h`/`05h` behavior while avoiding a
425-specific failure mode where the network socket was assigned windows
`06h`/`07h` and `04h`/`05h` belonged to storage.

After that, the HP 200LX `LXEN2216.COM` packet driver can use the card as an
NE2000-compatible adapter at `300h`. The enabler accepts IRQ arguments `3`,
`4`, `5`, `7`, `9`, `10`, `11`, `12`, and `15`; IRQ 5 is the default used by
`NICUP`.

On the OmniBook 425, the Netgear FA411 reached DHCP and MicroWeb with Crynwr
`NE2000.COM` instead of `LXEN2216.COM`. The 425 path is still experimental; see
`docs/OMNIBOOK_425.md`.

Observed mTCP proof:

```text
IPADDR 10.0.0.20
NETMASK 255.255.255.0
GATEWAY 10.0.0.1
NAMESERVER 10.0.0.1
```

Observed ping proof:

```text
Packets sent: 4, Replies received: 4, Replies lost: 0
```
