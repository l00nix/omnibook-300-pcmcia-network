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
  WEB http://68k.news/

Use your own gateway address if DHCP reports something other than 10.0.0.1.

Tested cards:

  Netgear FA411
  Buffalo Tough Connect LPC3-CLT
  MAP Japan MPL-972/Tamarack
  Accton EN2216-1

NICUP uses IRQ 5 by default. If NICUP prints a real MAC address but
TCPUP times out, try an IRQ-specific wrapper from a clean boot:

  NICUP10
  TCPUP

Available wrappers:

  NICUP3   NICUP4   NICUP5   NICUP7   NICUP9
  NICUP10  NICUP11  NICUP12  NICUP15

WEB.BAT runs MicroWeb with -video=h, the tested OmniBook video mode.

Diagnostic wrappers included:

  PKTSCAN   PKTSTAT   PKTLIST   NEREG   NERING   TXTEST

If booting the OmniBook 300 C: drive from PCMCIA/CF storage, the
OmniBook 300 System/Application ROM card in the D slot is still needed
to initiate C-drive booting. That ROM-card requirement is separate from
this network enabler.
