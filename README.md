# OmniBook 300 PCMCIA Network Stack

PCMCIA NE2000-family Ethernet enablement for the HP OmniBook 300.

This project provides an OmniBook 300-specific card enabler and DOS helper
files that make several 16-bit PCMCIA NE2000-compatible Ethernet cards visible
at I/O base `300h`, then hand off to Rod Whitby's `LXEN2216.COM` packet driver.
Once the packet driver is loaded, normal DOS TCP/IP software such as Michael
Brutman's mTCP and MicroWeb can use the network.

![Four tested PCMCIA Ethernet cards](docs/images/tested-cards.jpg)

## Status

Release 1.0 is the first known working public package for the OmniBook 300.

Confirmed on an HP OmniBook 300 with these cards:

| Card | Result |
| --- | --- |
| Netgear FA411 10/100 PCMCIA Mobile Adapter | DHCP, ping, MicroWeb working |
| Buffalo Tough Connect LPC3-CLT | DHCP, ping, MicroWeb working |
| MAP Japan MPL-972/Tamarack | MAC detection and packet-driver load confirmed |
| Accton EN2216-1 | DHCP, ping, MicroWeb working |

The OmniBook 300 also continued to recognize a PCMCIA storage card in the other
slot while the network stack was loaded.

Experimental OmniBook 425 testing is tracked separately in
[docs/OMNIBOOK_425.md](docs/OMNIBOOK_425.md). The short version: the Netgear
FA411 can be enabled on the 425 with the same CIS-parsing enabler, but it uses
the generic Crynwr `NE2000.COM` packet driver instead of `LXEN2216.COM`.

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

This repository does not include MS-DOS, Windows, mTCP, MicroWeb, or the
third-party `LXEN2216.COM` packet driver.

Useful upstream links:

- Rod Whitby's LXETH package containing `LXEN2216.COM` and `TERMIN.COM`:
  <https://sourceforge.net/projects/rwhitby/files/HP200LX%20Ethernet%20Drivers/1.0/lxeth10b.zip/download>
- Crynwr packet drivers, useful for the experimental OmniBook 425 FA411 path:
  <http://crynwr.com/drivers/>
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

Install the LXETH packet driver files separately:

```text
C:\LXNET\LXEN2216.COM
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
the same MAC address and install on packet interrupt `0x66`. `NICUP` uses
IRQ 5 by default.

If the MAC address appears but mTCP DHCP times out, the card is probably mapped
but the receive IRQ is wrong. Try the alternate wrappers from a clean boot, or
run `NICDN` before the next attempt:

```dos
NICUP10
TCPUP
```

Available wrappers are `NICUP3`, `NICUP4`, `NICUP5`, `NICUP7`, `NICUP9`,
`NICUP10`, `NICUP11`, `NICUP12`, and `NICUP15`.

Diagnostic helpers are included for bring-up on related OmniBooks. `PKTSCAN`,
`PKTSTAT`, and `PKTLIST` inspect the packet-driver interface through mTCP's
packet tool. `NEREG` dumps NE2000 page registers, and `NERING` snapshots the
receive-ring header bytes at I/O base `300h`. `NETXMIT`, normally invoked by
`TXTEST`, performs a raw byte-mode and word-mode transmit test without loading
the packet driver.

Then test mTCP:

```dos
TCPUP
C:\MTCP\PING.EXE 10.0.0.1
WEB http://68k.news/
```

Use your own gateway address if DHCP reports something other than `10.0.0.1`.

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
