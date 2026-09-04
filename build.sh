#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
./tools/check-dos-bat-line-endings.sh
mkdir -p bin
nasm -f bin -D GENERIC -o bin/O300NIC.COM src/o300ne.asm
nasm -f bin -o bin/O300DIAG.COM src/o300diag.asm
nasm -f bin -o bin/O300SOCK.COM src/o300sock.asm
nasm -f bin -o bin/O300RAW.COM src/o300raw.asm
nasm -f bin -o bin/O300WIN.COM src/o300win.asm
nasm -f bin -o bin/O300SIZ.COM src/o300siz.asm
nasm -f bin -o bin/O300CFG.COM src/o300cfg.asm
nasm -f bin -o bin/NEREG.COM src/nereg.asm
nasm -f bin -o bin/NERING.COM src/nering.asm
nasm -f bin -o bin/NERXPOLL.COM src/nerxpoll.asm
nasm -f bin -o bin/NETXMIT.COM src/netxmit.asm
nasm -f bin -o bin/NETLOOP.COM src/netloop.asm
ls -l bin/O300NIC.COM bin/O300DIAG.COM bin/O300SOCK.COM bin/O300RAW.COM bin/O300WIN.COM bin/O300SIZ.COM bin/O300CFG.COM bin/NEREG.COM bin/NERING.COM bin/NERXPOLL.COM bin/NETXMIT.COM bin/NETLOOP.COM
