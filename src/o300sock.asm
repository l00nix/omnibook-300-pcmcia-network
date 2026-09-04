; O300SOCK.COM - compact Socket Services CIS socket scanner
;
; Build:
;   nasm -f bin -o O300SOCK.COM o300sock.asm
;
; Read-only diagnostic. It reads the first 64 attribute-memory bytes from
; sockets 0..7 through the OmniBook Card BIOS and prints the result.

bits 16
org 100h

start:
    push cs
    pop ds

    mov ax, cs
    mov [rw_bseg], ax

    mov dx, banner
    call puts

    mov byte [sock_num], 0
.socket_loop:
    mov dx, socket_msg
    call puts
    mov al, [sock_num]
    call print_hex8
    call crlf

    call clear_rawbuf
    mov al, [sock_num]
    mov [rw_sock], al
    mov byte [rw_func], 8
    mov word [rw_tlen], 64
    mov word [rw_clow], 0
    mov word [rw_chig], 0
    mov word [rw_boff], rawbuf

    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    mov [last_ax], ax
    mov byte [last_cf], 0
    jnc .ok
    mov byte [last_cf], 1

.ok:
    call print_cf_status
    cmp byte [last_cf], 0
    jne .next_socket

    mov dx, bytes_msg
    call puts
    mov si, rawbuf
    mov cx, 64
    call dump_bytes

.next_socket:
    call crlf
    inc byte [sock_num]
    cmp byte [sock_num], 8
    jb .socket_loop

    mov dx, done_msg
    call puts
    mov ax, 4c00h
    int 21h

print_cf_status:
    cmp byte [last_cf], 0
    jne .cf_set
    mov dx, ok_msg
    call puts
    jmp .ax
.cf_set:
    mov dx, cf_msg
    call puts
.ax:
    mov dx, ax_msg
    call puts
    mov ax, [last_ax]
    call print_hex16
    call crlf
    ret

clear_rawbuf:
    push ax
    push cx
    push di
    mov di, rawbuf
    mov cx, 64
    xor al, al
    rep stosb
    pop di
    pop cx
    pop ax
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
rw_sock db 0
rw_memt db 0
rw_memh dw 0
rw_tlen dw 64
rw_clow dw 0
rw_chig dw 0
rw_boff dw rawbuf
rw_bseg dw 0

sock_num db 0
last_cf db 0
last_ax dw 0
rawbuf times 64 db 0

banner db 13,10,'O300SOCK v0.1 - CIS socket scan 0..7',13,10,'$'
socket_msg db 'Socket 0x$'
ok_msg db 'OK $'
cf_msg db 'CF $'
ax_msg db 'AX=0x$'
bytes_msg db '  bytes: $'
done_msg db 'Done.',13,10,'$'
