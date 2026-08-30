; O300RAW.COM - read-only NE2000 I/O probe for OmniBook 300 experiments
;
; Build:
;   nasm -f bin -o O300RAW.COM o300raw.asm
;
; This program intentionally makes no Card BIOS calls and does not write
; PCMCIA configuration registers. Use it after a separate enabler/recognizer
; such as OBCIC.EXE to see whether an NE2000 I/O window is already mapped.

bits 16
org 100h

start:
    push cs
    pop ds

    mov dx, banner
    call puts
    call scan_proms

    mov ax, 4c00h
    int 21h

read_prom:
    mov dx, [io_base]
    add dx, 1fh
    in al, dx
    mov cx, 1600
.wait:
    in al, 61h
    loop .wait
    out dx, al

    mov dx, [io_base]
    add dx, 0ch
    mov al, 04h
    out dx, al

    inc dx
    mov al, 02h
    out dx, al

    inc dx
    mov al, 49h
    out dx, al

    xor al, al
    mov dx, [io_base]
    add dx, 08h
    out dx, al
    inc dx
    out dx, al

    inc dx
    mov al, 20h
    out dx, al

    inc dx
    xor al, al
    out dx, al

    mov dx, [io_base]
    mov al, 0ah
    out dx, al

    mov cx, 16
    mov di, prombuf
    mov dx, [io_base]
    add dx, 10h
.read:
    in al, dx
    stosb
    loop .read
    ret

scan_proms:
    mov word [base_ptr], base_list
    mov byte [base_left], 5
.loop:
    mov si, [base_ptr]
    lodsw
    mov [base_ptr], si
    mov [io_base], ax

    mov dx, base_msg
    call puts
    mov ax, [io_base]
    call print_hex16
    call crlf

    call read_prom
    mov dx, prom_msg
    call puts
    mov si, prombuf
    mov cx, 16
    call dump_bytes

    dec byte [base_left]
    jnz .loop
    ret

puts:
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret

putc:
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret

crlf:
    push dx
    mov dl, 13
    call putc
    mov dl, 10
    call putc
    pop dx
    ret

dump_bytes:
    push ax
    push bx
    push cx
    push dx
    mov bx, cx
.next:
    lodsb
    call print_hex8
    mov dl, ' '
    call putc
    dec bx
    jnz .next
    call crlf
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_hex16:
    push ax
    xchg al, ah
    call print_hex8
    pop ax
    call print_hex8
    ret

print_hex8:
    push ax
    shr al, 4
    call print_nibble
    pop ax
    and al, 0fh
    call print_nibble
    ret

print_nibble:
    and al, 0fh
    add al, '0'
    cmp al, '9'
    jbe .emit
    add al, 7
.emit:
    mov dl, al
    call putc
    ret

io_base dw 0300h
base_ptr dw 0
base_left db 0
prombuf times 16 db 0
base_list dw 0300h, 0340h, 0360h, 0200h, 0220h

banner db 13,10,'O300RAW v0.1 - read-only NE2000 I/O probe',13,10,'$'
base_msg db 'Probe base 0x$'
prom_msg db 'NE2000 PROM bytes: $'
