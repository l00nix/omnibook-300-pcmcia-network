# OmniBook 425 Notes

These notes summarize the OmniBook 425 experiments from September 2026.

## Current Result

The Netgear FA411 was brought up on the OmniBook 425 using this shape:

```dos
C:
CD \OBNET
O300NIC 5
C:\OBNET\CRYNWR\NE2000.COM 0x66 5 0x300
C:\OBNET\MTCP\DHCP.EXE
```

After DHCP succeeded, MicroWeb loaded `http://68k.news/` with:

```dos
MICROWEB.EXE -video=h http://68k.news/
```

The same FA411 approach also worked with a PCMCIA storage card present in the
other OmniBook 425 slot.

## Important Difference From The OmniBook 300

The OmniBook 300 working path maps socket 1 I/O through Socket Services windows
`04h` and `05h`. On the OmniBook 425, socket 1 was observed using windows `06h`
and `07h`. Rewriting `04h`/`05h` on the 425 can collide with a PCMCIA storage
card and cause DOS errors such as:

```text
General failure writing drive C
```

`O300NIC.COM` v1.3 therefore scans for the socket 1 I/O windows before mapping
the NE2000 register block. This keeps the OmniBook 300 behavior while allowing
the OmniBook 425 FA411 path to use `06h`/`07h` when that is what the card BIOS
has assigned.

## Packet Driver Notes

The OmniBook 300 release path still uses Rod Whitby's `LXEN2216.COM`. On the
OmniBook 425 FA411 tests, `LXEN2216.COM` loaded but DHCP timed out; the generic
Crynwr `NE2000.COM` packet driver completed DHCP and MicroWeb browsing.

Buffalo Tough Connect LPC3-CLT and Accton EN2216-1 cards are confirmed working
on the OmniBook 300 release path, but did not work in the OmniBook 425 FA411
test path.
