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
window 04 -> I/O 300h-30Fh, attr 05h
window 05 -> I/O 310h-31Fh, attr 05h
```

`O300NIC.COM` v1.3 discovers the socket's I/O window IDs before mapping the
card. This preserves the OmniBook 300 `04h`/`05h` behavior while avoiding a
425-specific failure mode where the network socket was assigned windows
`06h`/`07h` and `04h`/`05h` belonged to storage.

After that, the HP 200LX `LXEN2216.COM` packet driver can use the card as an
NE2000-compatible adapter at `300h`.

The current development branch also tests Crynwr `NE2000.COM`:

```dos
NE2000.COM 0x66 irq 0x300
```

On the live OmniBook 300 with Netgear FA411, Crynwr `NE2000.COM` 11.4.3 loads
and reports the correct MAC address, but mTCP DHCP times out. Packet-driver
stats after DHCP show transmit only:

```text
Packets in:            0
Packets out:           3
Bytes in:              0
Bytes out:           909
```

The same machine, card, cable, and DHCP server immediately succeed with
`LXEN2216.COM` on IRQ 5, so this is not a link/DHCP baseline failure. IRQ 10
was also tested with Crynwr and produced the same transmit-only result.

The enabler accepts IRQ arguments `3`, `4`, `5`, `7`, `9`, `10`, `11`, `12`,
and `15`; IRQ 5 is the default used by `NE2KUP` and `NICUP`.

During MPL-972 investigation, an experimental 2633-byte `O300NIC.COM` changed
the high NE2000 I/O-window attribute and pre-initialized the 8390 before
loading `LXEN2216.COM`. That build regressed EN2216-family cards. Buffalo
LPC3-CLT and Accton EN2216-1 still parsed cleanly, read their MAC addresses,
and loaded LXEN, but DHCP and static ARP showed packet-driver transmit only
with zero receives. `NERXPOLL.COM` observed external ARP frames without a
packet driver or hardware IRQ, proving the NIC receive path and physical link
were alive below LXEN.

Restoring the exact GitHub 2499-byte `O300NIC.COM` restored the baseline
`NICUP` path on IRQ 5. FA411, Accton, and Buffalo all received DHCP leases,
returned 4/4 gateway ping replies, and showed received packets in packet-driver
stats.
This is the frozen OmniBook 300 baseline; MPL-972/Tamarack is excluded from
the compatible-card set.

Live MPL-972/Tamarack testing on the OmniBook 300 shows a different failure
from the FA411 Crynwr case. `O300NIC.COM` v1.3 maps the card at `300h`, reads a
valid card MAC address, and `LXEN2216.COM` loads, but DHCP on IRQ 5, 7, 10, and
11 still shows no receive packets. The card's vendor `PCMPD.COM` also loads at
`0x66 11 0x300`, but DHCP still times out with zero receive packets.
With the baseline `NICUP` path on IRQ 5, DHCP reports that no packets were
seen on the wire; after DHCP plus a static ARP/ping attempt, packet-driver
stats show `Packets out: 31`, `Errors out: 30`, and `Packets in: 0`. Re-testing
after replacing the CAT5 coupler produced the same result.

The vendor `DIAG.EXE` narrows this down below DHCP. With both halves of the
split I/O window mapped as attribute `05h`, I/O assignment and NIC register
access pass but the on-board RAM buffer test fails. Vendor `DIRECTEN.EXE`
maps `300h-30Fh` as `05h` and `310h-31Fh` as `0Dh`; an experimental
`O300NIC.COM` build matching that behavior makes the RAM buffer test pass and
eliminates `LXEN2216.COM` packet-driver send errors. The next failure is
loopback through ENC, and raw `NETXMIT.COM` still times out with
`ISR=00 TSR=02`.

The ENC failure is not unique to `O300NIC.COM`: a clean run using the vendor
`DIRECTEN.EXE /IRQ=11 /MEM=D0 /IO=300 /SKT=0 /O` enabler followed by vendor
`DIAG.EXE` passes MAC, I/O assignment, NIC register access, and on-board RAM,
then fails at the same `Loopback through ENC` step. Vendor `DIAG.EXE` explicitly
warns that the Media Access Module must be attached before testing. This points
to a remaining card, ENC, MAM, or physical media-path issue rather than an
IRQ-only or `O300NIC` window-mapping problem.

## OmniBook 425 Findings

On the OmniBook 425, the Netgear FA411 reached DHCP, gateway ping, DNS ping,
and MicroWeb with Crynwr `NE2000.COM` instead of `LXEN2216.COM`. The working
path was:

```dos
O300NIC.COM 5
C:\O300NET\CRYNWR\NE2000.COM 0x66 5 0x300
SET MTCPCFG=C:\MTCP\MTCP.CFG
C:\MTCP\DHCP.EXE
```

The O425 FA411 run reported a valid card MAC address, received a DHCP address,
pinged the local gateway with 4/4 replies, and resolved/pinged an external host
with 4/4 replies.

The FA411 is technically distinct from the EN2216-family cards that failed on
the O425:

| Card family | Config base | COR offset | FCSR offset | COR value | O425 reset result |
| --- | ---: | ---: | ---: | ---: | --- |
| Netgear FA411 | `03C0h` | `01E0h` | `01E1h` | `47h` | `NE2000 hardware reset OK` |
| EN2216-family, Accton/Buffalo | `03F8h` | `01FCh` | `01FDh` | `60h` | reset did not assert |

Accton EN2216-1 and Buffalo LPC3-CLT both enumerate on the O425, derive
COR/FCSR values, write configuration registers, map socket I/O windows, and
read valid MAC addresses. They then fail below the packet-driver layer:
`O300NIC.COM` warns that reset did not assert, `NETLOOP.COM` reports remote
DMA timeouts in every tested mode, and DHCP fails with packet-driver transmit
only. Accton was also tested in the B: PCMCIA slot. `O300SOCK.COM` saw it as
socket `02`; a socket-2/window-6-7 enabler mapped it at `300h`/`310h`, but it
failed with the same remote-DMA and DHCP symptoms.

The current O425 assessment is that the FA411 has a more compatible
NE2000/8390 implementation or bus interface for the O425 Card BIOS I/O-window
setup. The EN2216-family cards are close enough to expose registers and PROM,
but their 8390 remote-DMA/data-port path does not work correctly on the O425.
See `docs/OMNIBOOK_425.md` for the card-by-card status table.

Observed mTCP proof:

```text
IPADDR <dhcp-address>
NETMASK 255.255.255.0
GATEWAY <gateway-address>
NAMESERVER <dns-server>
```

Observed ping proof:

```text
Packets sent: 4, Replies received: 4, Replies lost: 0
```
