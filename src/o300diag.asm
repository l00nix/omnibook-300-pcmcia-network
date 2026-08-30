; O300DIAG.COM - non-destructive OmniBook 300 PCMCIA/Card BIOS probe
;
; Build on macOS/Linux with:
;   nasm -f bin -o O300DIAG.COM o300diag.asm
;
; This program is intentionally read-only. It does not configure, reset, or
; enable the inserted PC Card. Its job is to test whether the OmniBook 300 ROM
; environment exposes the INT 1Ah Card BIOS calls used by LXCIC.COM.

bits 16
org 100h

start:
    push cs
    pop ds
    push cs
    pop es

    mov ax, cs
    mov [rtuple_bseg], ax
    mov [rw_bseg], ax

    mov dx, banner
    call puts

    call print_bda_flag

    xor bl, bl
    call probe_socket

    mov bl, 1
    call probe_socket

    mov dx, done_msg
    call puts
    mov ax, 4c00h
    int 21h

; ---------------------------------------------------------------------------
; Probe one socket number in BL.

probe_socket:
    mov [sock_byte], bl
    mov [rtuple_sock], bx

    mov dx, socket_msg
    call puts
    mov al, [sock_byte]
    call print_hex8
    call crlf

    mov al, 15h              ; CISTPL_VERS_1/product/manufacturer
    mov dx, tpl_15_msg
    call probe_tuple

    mov al, 21h              ; CISTPL_FUNCID
    mov dx, tpl_21_msg
    call probe_tuple

    mov al, 1ah              ; CISTPL_CONFIG
    mov dx, tpl_1a_msg
    call probe_tuple

    mov al, 1bh              ; CISTPL_CFTABLE_ENTRY
    mov dx, tpl_1b_msg
    call probe_tuple

    call probe_raw_cis
    ret

; ---------------------------------------------------------------------------
; Input: AL tuple code, DX label.

probe_tuple:
    push ax
    call puts
    pop ax

    mov [rtuple_dtup], al
    mov byte [rtuple_func], 80h
    call clear_tbuf

    mov ax, 0b000h
    mov bx, rtuple
    int 1ah
    mov [last_ax], ax
    mov byte [last_cf], 0
    jnc .get_status
    mov byte [last_cf], 1
.get_status:
    mov dx, get_msg
    call puts
    call print_cf_status
    cmp byte [last_cf], 0
    jne .tuple_done

    mov byte [rtuple_func], 82h
    mov ax, 0b000h
    mov bx, rtuple
    int 1ah
    mov [last_ax], ax
    mov byte [last_cf], 0
    jnc .data_status
    mov byte [last_cf], 1
.data_status:
    mov dx, data_msg
    call puts
    call print_cf_status
    cmp byte [last_cf], 0
    jne .tuple_done

    mov dx, bytes_msg
    call puts
    mov si, tbuf
    mov cx, 32
    call dump_bytes

.tuple_done:
    call crlf
    ret

; ---------------------------------------------------------------------------

probe_raw_cis:
    mov dx, raw_msg
    call puts
    call clear_rawbuf

    mov al, [sock_byte]
    mov [rw_sock], al
    mov word [rw_bseg], cs
    mov byte [rw_func], 8     ; read attribute/common memory
    mov word [rw_clow], 0
    mov word [rw_chig], 0
    mov word [rw_tlen], 256

    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    mov [last_ax], ax
    mov byte [last_cf], 0
    jnc .raw_status
    mov byte [last_cf], 1
.raw_status:
    call print_cf_status
    cmp byte [last_cf], 0
    jne .raw_done

    mov dx, bytes_msg
    call puts
    mov si, rawbuf
    mov cx, 256
    call dump_bytes

.raw_done:
    call crlf
    ret

; ---------------------------------------------------------------------------

print_bda_flag:
    mov dx, bda_msg
    call puts

    push ds
    xor ax, ax
    mov ds, ax
    mov al, [04cch]
    pop ds

    call print_hex8
    call crlf
    ret

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

clear_tbuf:
    push ax
    push cx
    push di
    mov di, tbuf
    mov cx, 64
    mov al, 0
    rep stosb
    pop di
    pop cx
    pop ax
    ret

clear_rawbuf:
    push ax
    push cx
    push di
    mov di, rawbuf
    mov cx, 256
    mov al, 0
    rep stosb
    pop di
    pop cx
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

; ---------------------------------------------------------------------------
; Card BIOS request packets. Layouts mirror LXCIC.ASM.

rtuple:
rtuple_leng db 25
rtuple_func db 80h
rtuple_sock dw 0
rtuple_flag dw 0
rtuple_loff dd 0
rtuple_coff dd 0
rtuple_attr db 0
rtuple_dtup db 0
rtuple_boff dw tbuf
rtuple_bseg dw 0
rtuple_blng dw 64
rtuple_toff dw 1
rtuple_bytr db 0

rwreq:
rw_leng db 16
rw_func db 8
rw_sock db 0
rw_memt db 0
rw_memh dw 0
rw_tlen dw 256
rw_clow dw 0
rw_chig dw 0
rw_boff dw rawbuf
rw_bseg dw 0

sock_byte db 0
last_cf db 0
last_ax dw 0
tbuf times 64 db 0
rawbuf times 256 db 0

banner db 13,10,'O300DIAG v0.3 - INT 1Ah PCMCIA probe',13,10,'$'
bda_msg db 'BDA/card status byte [0000:04CC]=0x$'
socket_msg db 13,10,'Socket 0x$'
tpl_15_msg db '  CISTPL_VERS_1 15h',13,10,'$'
tpl_21_msg db '  CISTPL_FUNCID  21h',13,10,'$'
tpl_1a_msg db '  CISTPL_CONFIG  1Ah',13,10,'$'
tpl_1b_msg db '  CFTABLE_ENTRY  1Bh',13,10,'$'
raw_msg db '  Raw CIS read',13,10,'$'
get_msg db '    get tuple: $'
data_msg db '    get data : $'
bytes_msg db '    bytes    : $'
ok_msg db 'OK $'
cf_msg db 'CF $'
ax_msg db 'AX=0x$'
done_msg db 13,10,'Done.',13,10,'$'
