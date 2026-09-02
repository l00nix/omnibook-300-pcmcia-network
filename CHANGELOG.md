# Changelog

## Unreleased

- Generalized `O300NIC.COM` I/O-window selection so related OmniBooks can use
  the socket windows assigned by the card BIOS instead of assuming `04h/05h`.
- Added OmniBook 425 experimental notes for the Netgear FA411 plus Crynwr
  `NE2000.COM` packet-driver path.
- Updated the MicroWeb launcher to pass `-video=h`.
- Added a build-time check for DOS batch-file CRLF line endings.

## 1.0.0 - 2026-08-30

- First public release.
- Added generic CIS-parsing OmniBook 300 PCMCIA NE2000 enabler.
- Confirmed MAC detection on four NE2000-family PCMCIA Ethernet cards.
- Confirmed mTCP DHCP and ping on the Netgear FA411.
- Confirmed MicroWeb browsing over the packet driver path.
