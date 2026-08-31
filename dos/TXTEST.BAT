@ECHO OFF
REM Raw transmit test. Run after a fresh boot, then reboot when complete.
IF "%1"=="" GOTO DEFAULT
O300NIC %1
GOTO SEND
:DEFAULT
O300NIC 5
:SEND
NETXMIT

