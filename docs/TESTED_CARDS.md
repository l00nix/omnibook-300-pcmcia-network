# Tested Cards

These cards were tested on an HP OmniBook 300 using `O300NIC.COM`,
`LXEN2216.COM 0x66`, mTCP DHCP, mTCP ping, and MicroWeb.

| Card | Result |
| --- | --- |
| Netgear FA411 10/100 PCMCIA Mobile Adapter | DHCP, ping, MicroWeb working |
| Buffalo Tough Connect LPC3-CLT | DHCP, ping, MicroWeb working with GitHub `NICUP` path |
| Accton EN2216-1 | DHCP, ping, MicroWeb working |
| MAP Japan MPL-972/Tamarack | Not compatible with the frozen OmniBook 300 baseline |

The storage-card coexistence test also passed: with the network stack loaded,
the OmniBook 300 still recognized a PCMCIA storage card inserted in the other
slot.

## EN2216-family Regression Notes

The Buffalo Tough Connect LPC3-CLT was inserted in the live OmniBook 300 socket
and identified as `BUFFALO` / `LPC3-CLT` / `R01`. The Accton EN2216-1 was
identified as `ACCTON` / `EN2216-PCMCIA-ETHERNET` / `EN2216` / `R02`.
Both cards use the EN2216-family CIS shape: COR offset `01FCh`, FCSR offset
`01FDh`, and COR value `60h`.

During MPL-972 investigation, an experimental 2633-byte `O300NIC.COM` changed
the high NE2000 I/O-window attribute and pre-initialized the 8390 before
loading `LXEN2216.COM`. With that experimental enabler, both Buffalo and
Accton still enumerated and loaded LXEN with matching MAC addresses, but DHCP
and static ARP showed transmitted packets with zero packet-driver receives.
`NERXPOLL.COM` observed external ARP frames without a packet driver or hardware
IRQ, proving the cards and link could receive at the NIC level.

Restoring the exact GitHub 2499-byte `O300NIC.COM` restored the baseline
`NICUP` path. FA411, Accton, and Buffalo each loaded on IRQ 5 with valid card
MAC addresses, received DHCP leases, and returned 4/4 gateway ping replies.

## MPL-972 Live Notes

The MPL-972/Tamarack card was inserted in the live OmniBook 300 socket and
identified as `TAMARACK MICROELECTRONICS` / `2408LAN`. It is not compatible
with the frozen OmniBook 300 baseline. `O300NIC.COM` derived COR offset
`01FCh`, FCSR offset `01FDh`, COR value `60h`, and a valid card MAC address.

DHCP did not complete with `LXEN2216.COM` on IRQ 5, 7, 10, or 11. mTCP packet
stats after each DHCP run showed zero received packets and transmit errors.
With the baseline `NICUP` path on IRQ 5, DHCP reported that no packets were
seen on the wire; packet-driver stats showed `Packets out: 31`, `Errors out:
30`, and `Packets in: 0` after DHCP plus a static ARP/ping attempt to
the local gateway. Re-testing with a different CAT5 coupler produced the same
final stats, so the coupler is not treated as the cause.
The vendor `PCMPD.COM 0x66 11 0x300` also loaded with the same MAC but DHCP
still timed out with zero received packets.

Vendor `DIAG.EXE` passes I/O port assignment and NIC register access. With
the original `O300NIC.COM` split-window attributes, it failed the on-board RAM
buffer test. An experimental build matching vendor `DIRECTEN.EXE` behavior by
mapping the high NE2000 window with attribute `0Dh` makes the RAM buffer test
pass, but loopback through ENC still fails. A clean all-vendor run using
`DIRECTEN.EXE` followed by `DIAG.EXE` fails at the same ENC loopback stage,
after the same MAC, I/O, register, and RAM-buffer passes. With that
experimental window-attribute build, `LXEN2216.COM` no longer reports
packet-driver send errors, but DHCP still receives no packets.

## OmniBook 425

The Netgear FA411 was also tested on an OmniBook 425. The working path used
`O300NIC.COM` to enable the card and Crynwr `NE2000.COM` as the packet driver:

```dos
O300NIC.COM 5
C:\O300NET\CRYNWR\NE2000.COM 0x66 5 0x300
SET MTCPCFG=C:\MTCP\MTCP.CFG
C:\MTCP\DHCP.EXE
```

DHCP leased an address, gateway ping returned 4/4 replies, DNS resolution
worked, and an external host returned 4/4 ping replies.

| Card | O425 status |
| --- | --- |
| Netgear FA411 | Working with Crynwr `NE2000.COM`; fails with `LXEN2216.COM` |
| Accton EN2216-1 | Not working; reset warning and `NETLOOP` remote-DMA timeouts |
| Accton EN2216-1 in B slot | Not working; visible as socket `02`, but same remote-DMA/DHCP failure |
| Buffalo Tough Connect LPC3-CLT | Not working; reset warning and `NETLOOP` remote-DMA timeouts |
| MAP Japan MPL-972/Tamarack | Not proven on O425; excluded from current candidates because it fails the frozen O300 baseline |

The O425 failures are not simple card-detection failures. Accton and Buffalo
both expose CIS data, accept COR/FCSR writes, map I/O windows, and report valid
MAC addresses. The failure appears at the NE2000 reset and 8390 remote-DMA
stage, before DHCP or ARP.
