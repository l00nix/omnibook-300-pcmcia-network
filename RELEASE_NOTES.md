# O300NET 1.0

First public release of the HP OmniBook 300 PCMCIA NE2000-family card enabler
and DOS helper files.

Confirmed OmniBook 300 baseline hardware:

- Netgear FA411 10/100 PCMCIA Mobile Adapter
- Buffalo Tough Connect LPC3-CLT
- Accton EN2216-1

MAP Japan MPL-972/Tamarack is not compatible with the frozen OmniBook 300
baseline. It can be detected and its MAC can be read, but DHCP and static ARP
produce zero received packets and packet-driver transmit errors.

Release package contents:

- `O300NIC.COM`, the OmniBook 300-specific card enabler
- diagnostic helper COM files
- DOS batch wrappers for enable/disable, IRQ-specific bring-up, mTCP DHCP, and
  MicroWeb launch
- sample `MTCP.CFG`

External dependencies are not bundled. Install Rod Whitby's LXETH packet driver,
Michael Brutman's mTCP, and MicroWeb separately.

## Post-1.0 Notes

Current development adds dynamic socket I/O-window discovery to `O300NIC.COM`,
`O300SOCK.COM` for read-only Card BIOS socket scans, and `NE2KUP`/`NE2KDN`
wrappers for Crynwr `NE2000.COM` experiments. The OmniBook 425 FA411 path
worked with Crynwr; Accton EN2216-1 and Buffalo LPC3-CLT enumerate on the 425
but fail at the NE2000 reset/remote-DMA stage. The live OmniBook 300 FA411 test
currently loads Crynwr and transmits DHCP packets but receives none. See
`docs/TECHNICAL_NOTES.md` and `docs/OMNIBOOK_425.md`.
