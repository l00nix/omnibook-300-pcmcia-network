# O300NET 1.0

First public release of the HP OmniBook 300 PCMCIA NE2000-family card enabler
and DOS helper files.

Confirmed hardware:

- Netgear FA411 10/100 PCMCIA Mobile Adapter
- Buffalo Tough Connect LPC3-CLT
- MAP Japan MPL-972/Tamarack
- Accton EN2216-1

Release package contents:

- `O300NIC.COM`, the OmniBook 300-specific card enabler
- diagnostic helper COM files
- DOS batch wrappers for enable/disable, IRQ-specific bring-up, mTCP DHCP, and
  MicroWeb launch
- sample `MTCP.CFG`

External dependencies are not bundled. Install Rod Whitby's LXETH packet driver,
Michael Brutman's mTCP, and MicroWeb separately.

## Post-1.0 Notes

Current development adds dynamic socket I/O-window discovery to `O300NIC.COM`.
That keeps the OmniBook 300 path intact and records an experimental OmniBook
425 FA411 path using Crynwr `NE2000.COM`; see `docs/OMNIBOOK_425.md`.
