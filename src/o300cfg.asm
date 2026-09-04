bits 16
org 100h

start:
    push cs
    pop ds
    push cs
    pop es

    mov ax, cs
    mov [rw_bseg], ax

    mov dx, banner
    call puts

    mov byte [rw_func], 8
    mov word [rw_tlen], 16
    mov word [rw_clow], 01f0h
    mov word [rw_chig], 0
    mov word [rw_boff], cfgbuf
    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    jc fail

    mov dx, off_msg
    call puts
    mov ax, 01f0h
    call print_hex16
    call crlf

    mov dx, bytes_msg
    call puts
    mov si, cfgbuf
    mov cx, 16
    call dump_bytes

    mov ax, 4c00h
    int 21h

fail:
    mov [last_ax], ax
    mov dx, fail_msg
    call puts
    mov ax, [last_ax]
    call print_hex16
    call crlf
    mov ax, 4c01h
    int 21h

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

rwreq:
rw_leng db 16
rw_func db 8
rw_sock db 1
rw_memt db 0
rw_memh dw 0
rw_tlen dw 16
rw_clow dw 01f0h
rw_chig dw 0
rw_boff dw cfgbuf
rw_bseg dw 0

last_ax dw 0
cfgbuf times 16 db 0

banner db 13,10,'O300CFG v0.1 - socket 1 attr 01F0h config dump',13,10,'$'
off_msg db 'Offset 0x$'
bytes_msg db 'bytes: $'
fail_msg db 'Card BIOS read failed, AX=0x$'
