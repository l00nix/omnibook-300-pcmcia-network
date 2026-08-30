O300NET 1.0 - HP OmniBook 300 PCMCIA Ethernet Enabler
=====================================================

This package contains the OmniBook 300-specific NE2000-family
PCMCIA card enabler and DOS helper files.

Copy the O300NET directory to the root of the OmniBook 300 C: drive:

  XCOPY O300NET C:\O300NET /S

External files required separately:

  C:\LXNET\LXEN2216.COM
  C:\LXNET\TERMIN.COM

Optional test software:

  Michael Brutman's mTCP in C:\MTCP
  MicroWeb in C:\MWEB

Quick test:

  C:
  CD \O300NET
  NICUP
  TCPUP
  C:\MTCP\PING.EXE 10.0.0.1
  WEB http://68k.news

Use your own gateway address if DHCP reports something other than 10.0.0.1.

Tested cards:

  Netgear FA411                 00:40:F4:10:DF:C2
  Buffalo Tough Connect LPC3-CLT 00:07:40:19:1A:4D
  MAP Japan MPL-972/Tamarack    00:C0:0C:02:7F:26
  Accton EN2216-1               00:00:EB:3A:43:01

If booting the OmniBook 300 C: drive from PCMCIA/CF storage, the
OmniBook 300 System/Application ROM card in the D slot is still needed
to initiate C-drive booting. That ROM-card requirement is separate from
this network enabler.
