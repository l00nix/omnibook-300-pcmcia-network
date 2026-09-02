# Installation

## Files

The repository contains these installable files:

```text
O300NET\O300NIC.COM
O300NET\O300DIAG.COM
O300NET\O300RAW.COM
O300NET\O300WIN.COM
O300NET\O300SIZ.COM
O300NET\NEREG.COM
O300NET\NERING.COM
O300NET\NETXMIT.COM
O300NET\NICUP.BAT
O300NET\NICUP3.BAT
O300NET\NICUP4.BAT
O300NET\NICUP5.BAT
O300NET\NICUP7.BAT
O300NET\NICUP9.BAT
O300NET\NICUP10.BAT
O300NET\NICUP11.BAT
O300NET\NICUP12.BAT
O300NET\NICUP15.BAT
O300NET\NICDN.BAT
O300NET\NETUP.BAT
O300NET\NETDN.BAT
O300NET\TCPUP.BAT
O300NET\PKTDN.BAT
O300NET\PKTSCAN.BAT
O300NET\PKTSTAT.BAT
O300NET\PKTLIST.BAT
O300NET\NEREG.BAT
O300NET\NERING.BAT
O300NET\TXTEST.BAT
O300NET\WEB.BAT
O300NET\MTCP.CFG
```

The `.COM` files are this project's OmniBook 300 tools. The `.BAT` files are
convenience wrappers.

## Dependencies

Install these separately:

```text
C:\LXNET\LXEN2216.COM
C:\LXNET\TERMIN.COM
```

For TCP/IP testing, install mTCP separately:

```text
C:\MTCP\DHCP.EXE
C:\MTCP\PING.EXE
C:\MTCP\MTCP.CFG
```

For web browsing, install MicroWeb separately:

```text
C:\MWEB\MICROWEB.EXE
C:\MWEB\*.DAT
```

## Bring-Up

```dos
C:
CD \O300NET
NICUP
TCPUP
C:\MTCP\PING.EXE gateway-address
WEB http://68k.news/
```

`NICUP` uses IRQ 5. If the enabler and packet driver show a real MAC address
but DHCP times out, try `NICUP10`, `NICUP11`, `NICUP12`, or the other IRQ
wrappers from a clean boot.

## Raw Transmit Diagnostic

`TXTEST.BAT` directly reinitializes the NIC and sends three byte-mode and
three word-mode broadcast test frames using experimental EtherType `88B5`.
Run it only after a fresh boot, and reboot when the test finishes:

```dos
B:
CD \OBNET
TXTEST 5
```

If the wrapper cannot be used, run the equivalent commands directly:

```dos
O300NIC 5
NETXMIT
```

## Shutdown

```dos
NICDN
```

`NICDN` unloads the packet driver from interrupt `0x66` using `TERMIN.COM`.

## OmniBook 425

The OmniBook 425 path is experimental and documented separately in
[`docs/OMNIBOOK_425.md`](docs/OMNIBOOK_425.md). Do not assume the OmniBook 300
packet-driver pairing applies unchanged on the 425.
