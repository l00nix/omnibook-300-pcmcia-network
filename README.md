# OmniBook 300 PCMCIA Network Stack

PCMCIA NE2000-family Ethernet enablement for the HP OmniBook 300.

This project provides an OmniBook 300-specific card enabler and DOS helper
files that make several 16-bit PCMCIA NE2000-compatible Ethernet cards visible
at I/O base `300h`, then hand off to a DOS packet driver. The confirmed
OmniBook 300 path uses Rod Whitby's `LXEN2216.COM`; the current development
branch also adds an experimental Crynwr `NE2000.COM` path. Once the packet
driver is loaded, normal DOS TCP/IP software such as Michael Brutman's mTCP and
MicroWeb can use the network.

![Four tested PCMCIA Ethernet cards](docs/images/tested-cards.jpg)

## Status

Release 1.0 is the first known working public package for the OmniBook 300.

Confirmed on an HP OmniBook 300 with these cards:

| Card | Result |
| --- | --- |
| Netgear FA411 10/100 PCMCIA Mobile Adapter | DHCP, ping, MicroWeb working |
| Buffalo Tough Connect LPC3-CLT | DHCP, ping, MicroWeb working with GitHub `NICUP` path |
| Accton EN2216-1 | DHCP, ping, MicroWeb working |
| MAP Japan MPL-972/Tamarack | Not compatible with the frozen OmniBook 300 baseline |

The OmniBook 300 also continued to recognize a PCMCIA storage card in the other
slot while the network stack was loaded.

Experimental Crynwr and OmniBook 425 testing is tracked separately in
[docs/OMNIBOOK_425.md](docs/OMNIBOOK_425.md) and
[docs/TECHNICAL_NOTES.md](docs/TECHNICAL_NOTES.md). The short version:
Netgear FA411 is the only card currently proven working on the 425, using
`O300NIC.COM 5` and Crynwr `NE2000.COM 0x66 5 0x300`. Accton EN2216-1 and
Buffalo LPC3-CLT are visible on the 425 and their MACs can be read, but both
fail the NE2000 reset/remote-DMA path before DHCP. The same Crynwr driver
currently transmits without receiving on the live OmniBook 300 FA411 test
machine.

The OmniBook 300 baseline is frozen on the GitHub 2499-byte `O300NIC.COM`,
`NICUP` IRQ 5, and `LXEN2216.COM 0x66`. Netgear FA411, Accton EN2216-1, and
Buffalo LPC3-CLT are compatible with that baseline. MAP Japan
MPL-972/Tamarack is not compatible with the frozen baseline: it enumerates and
loads both `LXEN2216.COM` and the vendor `PCMPD.COM` with a valid MAC address,
but DHCP and static ARP/ping fail with zero received packets. Re-testing after
replacing the CAT5 coupler produced the same packet-driver stats:
`Packets in: 0`, `Packets out: 31`, `Errors out: 30`. IRQs 7, 10, and 11 were
also tested. An experimental build matching vendor `DIRECTEN.EXE` window
attributes made the vendor `DIAG.EXE` on-board RAM buffer test pass after
`O300NIC`, but the card still fails loopback through ENC. The same ENC failure
occurs after the vendor `DIRECTEN.EXE` enabler, so the remaining failure
currently looks like a card/MAM/media path problem rather than an `O300NIC`
window-mapping problem.

During MPL-972 investigation, an experimental 2633-byte `O300NIC.COM` changed
the high NE2000 I/O-window attribute and pre-initialized the 8390 before
loading `LXEN2216.COM`. That regressed EN2216-family cards: Buffalo and Accton
still enumerated, read MAC addresses, and received external frames in polling
diagnostics, but LXEN saw zero received packets. Restoring the GitHub
2499-byte `O300NIC.COM` restored the baseline `NICUP` path immediately:
FA411, Accton, and Buffalo all received DHCP leases, and all three cards
returned 4/4 gateway ping replies.

## What This Does

`O300NIC.COM` is a non-resident card enabler. It:

- reads the inserted card's CIS through the OmniBook 300 card BIOS interface
- checks for a LAN function and a `300h` CFTABLE I/O entry
- derives the card's COR/FCSR offsets and COR value from CIS data
- writes the card configuration registers
- maps the socket's PCMCIA I/O windows as two adjacent 16-byte windows
- configures the socket IRQ, defaulting to IRQ 5
- probes the NE2000 PROM and prints the MAC address

It does not stay resident. After enablement, `LXEN2216.COM` provides the packet
driver interface on software interrupt `0x66`.

## What This Does Not Include

This repository does not include MS-DOS, Windows, mTCP, MicroWeb, or
third-party packet-driver binaries.

Useful upstream links:

- Crynwr packet drivers, useful for the experimental OmniBook 425 FA411 path:
  <http://crynwr.com/drivers/>
- Unofficial GitHub mirror of Russ Nelson's Crynwr DOS packet drivers:
  <https://github.com/fragglet/crynwr_mirror>
- Rod Whitby's LXETH package containing `LXEN2216.COM` and `TERMIN.COM`:
  <https://sourceforge.net/projects/rwhitby/files/HP200LX%20Ethernet%20Drivers/1.0/lxeth10b.zip/download>
- Michael Brutman's mTCP:
  <https://www.brutman.com/mTCP/mTCP.html>
- mTCP January 10, 2025 ZIP:
  <https://www.brutman.com/mTCP/download/mTCP_2025-01-10.zip>
- MicroWeb:
  <https://github.com/jhhoward/MicroWeb>
- MicroWeb v2.1 release:
  <https://github.com/jhhoward/MicroWeb/releases/tag/v2.1>

## Quick Install

The release ZIP contains an `O300NET` directory. Copy it to the root of the
OmniBook 300 C: drive:

```dos
XCOPY O300NET C:\O300NET /S
```

Install the confirmed LXETH packet driver files separately:

```text
C:\LXNET\LXEN2216.COM
C:\LXNET\TERMIN.COM
```

For the experimental Crynwr path, install the Crynwr NE2000 packet driver
separately:

```text
C:\O300NET\CRYNWR\NE2000.COM
```

For packet-driver unload, install a compatible `TERMIN.COM` in
`C:\O300NET\CRYNWR` or keep the LXETH copy in `C:\LXNET`:

```text
C:\LXNET\TERMIN.COM
```

Optional mTCP and MicroWeb layout used during testing:

```text
C:\MTCP\DHCP.EXE
C:\MTCP\PING.EXE
C:\MTCP\MTCP.CFG
C:\MWEB\MICROWEB.EXE
C:\MWEB\*.DAT
```

Add these paths to `AUTOEXEC.BAT` if desired:

```dos
PATH C:\O300NET;C:\LXNET;C:\MTCP;C:\MWEB;%PATH%
SET MTCPCFG=C:\MTCP\MTCP.CFG
```

## Test Sequence

Insert one of the supported PCMCIA Ethernet cards, then run:

```dos
C:
CD \O300NET
NICUP
```

The enabler should print a real MAC address, then `LXEN2216.COM` should print
the same MAC address and install on packet interrupt `0x66`.

For Crynwr experiments, use `NE2KUP` instead. It uses IRQ 5 by default. Pass
another IRQ as the first argument when testing:

```dos
NE2KUP 10
```

If the MAC address appears but mTCP DHCP times out, the card is probably mapped
but the receive IRQ is wrong. Try alternate IRQs from a clean boot, or run
`NE2KDN`/`NICDN` before the next attempt:

```dos
NE2KUP 10
TCPUP
```

Available wrappers are `NICUP3`, `NICUP4`, `NICUP5`, `NICUP7`, `NICUP9`,
`NICUP10`, `NICUP11`, `NICUP12`, and `NICUP15`.

Diagnostic helpers are included for bring-up on related OmniBooks. `PKTSCAN`,
`PKTSTAT`, and `PKTLIST` inspect the packet-driver interface through mTCP's
packet tool. `O300SOCK` scans Card BIOS sockets for CIS data, `NEREG` dumps
NE2000 page registers, and `NERING` snapshots the receive-ring header bytes at
I/O base `300h`. `NERXPOLL` initializes receive without a packet driver or
hardware IRQ and polls for external frames. `NETLOOP` exercises 8390 loopback
and remote DMA without a packet driver. `NETXMIT`, normally invoked by
`TXTEST`, performs a raw byte-mode and word-mode transmit test without loading
the packet driver.

Then test mTCP:

```dos
TCPUP
C:\MTCP\PING.EXE gateway-address
WEB http://68k.news/
```

Use the gateway address reported by DHCP.

Unload the packet driver with:

```dos
NICDN
```

## Proof Of Life

DHCP lease through mTCP:

![mTCP DHCP on OmniBook 300](docs/images/mtcp-dhcp.jpg)

Ping through mTCP:

![mTCP ping on OmniBook 300](docs/images/mtcp-ping.jpg)

MicroWeb browsing `68k.news`:

![MicroWeb browsing 68k.news](docs/images/microweb-68k-news.jpg)

O300NIC identifying a tested card and handing off to the packet driver:

![O300NIC Netgear FA411 enablement](docs/images/o300nic-fa411.jpg)

## Build

Install NASM, then run:

```sh
./build.sh
```

The build emits `.COM` files into `bin/` and checks the DOS batch wrappers for
CRLF line endings.

## Notes

If you are booting an OmniBook 300 C: drive from a PCMCIA/CF storage card, the
machine still needs the OmniBook 300 System/Application ROM card in the D slot
to initiate C-drive booting. That ROM card requirement is separate from this
network enabler.

This is early retrocomputing software. Keep a backup of bootable cards before
testing.
