; O300NE.COM - experimental OmniBook 300 NE2000 PCMCIA enabler
;
; Build:
;   nasm -f bin -o O300NE.COM o300ne.asm
;
; This is intentionally not resident. It writes one card's COR/FCSR values,
; configures socket 1, maps the card at I/O base 300h, and probes the PROM
; bytes. v1.0 first tries the CIS-advertised 1Fh I/O size, then falls back to
; two adjacent 16-byte windows.
;
; Build with -D GENERIC for O300NIC.COM, which derives COR/FCSR from the
; inserted card's CIS rather than using card-specific constants.

bits 16
org 100h

%ifdef GENERIC
%define CARD_COR_VALUE 00h
%define CARD_COR_OFFSET 0000h
%define CARD_FCSR_OFFSET 0000h
%elifdef EN2216_FAMILY
%define CARD_COR_VALUE 60h
%define CARD_COR_OFFSET 01fch
%define CARD_FCSR_OFFSET 01fdh
%elifdef BUFFALO
%define CARD_COR_VALUE 60h
%define CARD_COR_OFFSET 01fch
%define CARD_FCSR_OFFSET 01fdh
%else
%define CARD_COR_VALUE 47h
%define CARD_COR_OFFSET 01e0h
%define CARD_FCSR_OFFSET 01e1h
%endif

start:
    push cs
    pop ds
    push cs
    pop es

    mov ax, cs
    mov [rw_bseg], ax

    call parse_tail

    mov dx, banner
    call puts
    mov dx, irq_msg
    call puts
    mov al, [irq_num]
    call print_hex8
    call crlf

%ifdef GENERIC
    call read_cis
    jc fail
    call parse_cis
    jc parse_fail
    call print_derived
%endif

    call write_cor
    jc fail
    mov dx, cor_ok
    call puts

    call write_fcsr
    jc fail
    mov dx, fcsr_ok
    call puts

    call map_single_1f
    jnc .mapped

    mov dx, fallback_msg
    call puts
    call map_dual_window
    jc fail

.mapped:
    call set_socket
    jc fail
    mov dx, sock_ok
    call puts

    call probe_current_base

    mov dx, done_msg
    call puts
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

%ifdef GENERIC
parse_fail:
    mov dx, parse_fail_msg
    call puts
    mov ax, 4c02h
    int 21h
%endif

parse_tail:
    mov byte [irq_num], 5
    mov word [irq_di], 8005h
    xor cx, cx
    mov cl, [80h]
    mov si, 81h
.next:
    jcxz .done
    lodsb
    dec cx
    cmp al, '5'
    je .irq5
    cmp al, '1'
    jne .next
    jcxz .done
    lodsb
    dec cx
    cmp al, '1'
    je .irq11
    cmp al, '2'
    je .irq12
    jmp .next
.irq5:
    mov byte [irq_num], 5
    mov word [irq_di], 8005h
    jmp .next
.irq11:
    mov byte [irq_num], 11
    mov word [irq_di], 800bh
    jmp .next
.irq12:
    mov byte [irq_num], 12
    mov word [irq_di], 800ch
    jmp .next
.done:
    ret

set_socket:
    mov ax, 8e00h
    mov bx, 8001h
    mov cx, 0111h
    xor dx, dx
    mov si, 2
    mov di, [irq_di]
    int 1ah
    ret

set_window:
    mov ax, 8900h
    mov bh, [win_bh]
    mov bl, 1
    mov cx, [win_size]
    mov dx, 0520h
    mov si, [win_base]
    xor di, di
    int 1ah
    ret

map_single_1f:
    mov ax, [io_base]
    mov [win_base], ax
    mov word [win_size], 1fh
    mov byte [win_bh], 4
    call set_window
    jc .bad

    mov dx, win_ok1
    call puts
    mov al, [win_bh]
    call print_hex8
    mov dx, win_1f_ok
    call puts
    clc
    ret
.bad:
    mov [last_ax], ax
    mov dx, win_try_msg
    call puts
    mov al, [win_bh]
    call print_hex8
    mov dx, win_1f_fail
    call puts
    mov ax, [last_ax]
    call print_hex16
    call crlf
    mov ax, [last_ax]
    stc
    ret

map_dual_window:
    mov ax, [io_base]
    mov [win_base], ax
    mov word [win_size], 10h
    mov byte [win_bh], 4
    call set_window
    jc .bad

    mov [last_ax], ax
    mov dx, win_ok1
    call puts
    mov al, [win_bh]
    call print_hex8
    mov dx, win_ok2
    call puts

    mov ax, [io_base]
    add ax, 10h
    mov [win_base], ax
    mov byte [win_bh], 5
    call set_window
    jc .bad

    mov [last_ax], ax
    mov dx, win_ok1
    call puts
    mov al, [win_bh]
    call print_hex8
    mov dx, win_ok3
    call puts

    clc
    ret
.bad:
    mov [last_ax], ax
    mov dx, win_try_msg
    call puts
    mov al, [win_bh]
    call print_hex8
    mov dx, win_fail_msg
    call puts
    mov ax, [last_ax]
    call print_hex16
    call crlf
    mov ax, [last_ax]
    stc
    ret

write_cor:
    mov word [rw_boff], corval
%ifdef GENERIC
    mov byte [rw_func], 9
    mov word [rw_tlen], 1
    mov ax, [cor_offset]
    mov [rw_clow], ax
    mov word [rw_chig], 0
%else
    mov byte [corval], CARD_COR_VALUE
    mov byte [rw_func], 9
    mov word [rw_tlen], 1
    mov word [rw_clow], CARD_COR_OFFSET
    mov word [rw_chig], 0
%endif
    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    ret

write_fcsr:
    mov word [rw_boff], fcsrval
    mov byte [rw_func], 8
    mov word [rw_tlen], 1
%ifdef GENERIC
    mov ax, [fcsr_offset]
    mov [rw_clow], ax
    mov word [rw_chig], 0
%else
    mov word [rw_clow], CARD_FCSR_OFFSET
    mov word [rw_chig], 0
%endif
    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    jc .done

    or byte [fcsrval], 28h
    mov byte [rw_func], 9
    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
.done:
    mov word [rw_boff], corval
    ret

%ifdef GENERIC
read_cis:
    mov dx, cis_msg
    call puts
    mov byte [rw_func], 8
    mov byte [rw_sock], 1
    mov word [rw_tlen], 256
    mov word [rw_clow], 0
    mov word [rw_chig], 0
    mov word [rw_boff], rawbuf
    mov word [rw_bseg], cs
    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    ret

parse_cis:
    mov byte [have_config], 0
    mov byte [have_cftable], 0
    mov byte [have_lan], 0
    mov si, rawbuf
    mov word [cis_left], 256
.next_tuple:
    cmp word [cis_left], 1
    jb .done
    lodsb
    dec word [cis_left]
    cmp al, 0ffh
    je .done
    cmp al, 00h
    je .next_tuple
    mov [tuple_code], al

    cmp word [cis_left], 1
    jb .done
    lodsb
    dec word [cis_left]
    xor ah, ah
    mov [tuple_len], ax
    cmp ax, [cis_left]
    ja .done

    cmp byte [tuple_code], 21h
    je .funcid
    cmp byte [tuple_code], 1ah
    je .config
    cmp byte [tuple_code], 1bh
    je .cftable
    jmp .advance
.funcid:
    call parse_funcid
    jmp .advance
.config:
    call parse_config
    jmp .advance
.cftable:
    call parse_cftable

.advance:
    mov ax, [tuple_len]
    add si, ax
    sub [cis_left], ax
    jmp .next_tuple

.done:
    cmp byte [have_lan], 1
    jne .bad
    cmp byte [have_config], 1
    jne .bad
    cmp byte [have_cftable], 1
    jne .bad
    clc
    ret
.bad:
    stc
    ret

parse_funcid:
    cmp word [tuple_len], 1
    jb .done
    cmp byte [si], 06h
    jne .done
    mov byte [have_lan], 1
.done:
    ret

parse_config:
    cmp word [tuple_len], 5
    jb .done
    mov al, [si]
    and al, 03h
    cmp al, 01h
    jne .done
    mov ax, [si+2]
    shr ax, 1
    mov [cor_offset], ax
    inc ax
    mov [fcsr_offset], ax
    mov byte [have_config], 1
.done:
    ret

parse_cftable:
    cmp word [tuple_len], 3
    jb .done
    mov al, [si]
    and al, 3fh
    or al, 40h
    mov [candidate_cor], al

    push si
    mov cx, [tuple_len]
    sub cx, 1
.scan:
    cmp cx, 1
    jbe .scan_done
    cmp byte [si], 00h
    jne .next
    cmp byte [si+1], 03h
    jne .next
    mov al, [candidate_cor]
    mov [corval], al
    mov byte [have_cftable], 1
    jmp .scan_done
.next:
    inc si
    dec cx
    jmp .scan
.scan_done:
    pop si
.done:
    ret

print_derived:
    mov dx, lan_msg
    call puts
    mov dx, cor_off_msg
    call puts
    mov ax, [cor_offset]
    call print_hex16
    call crlf
    mov dx, fcsr_off_msg
    call puts
    mov ax, [fcsr_offset]
    call print_hex16
    call crlf
    mov dx, cor_val_msg
    call puts
    mov al, [corval]
    call print_hex8
    call crlf
    ret
%endif

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

    mov al, 00h
    mov dx, [io_base]
    add dx, 08h
    out dx, al
    inc dx
    out dx, al

    inc dx
    mov al, 20h
    out dx, al

    inc dx
    mov al, 00h
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

probe_current_base:
    mov dx, map_msg
    call puts
    mov ax, [io_base]
    call print_hex16
    call crlf

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

    mov dx, mac_msg
    call puts
    mov si, prombuf
    call print_mac
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

print_mac:
    push ax
    push bx
    push cx
    push dx
    mov cx, 6
.next:
    lodsb
    call print_hex8
    dec cx
    jz .done
    mov dl, ':'
    call putc
    jmp .next
.done:
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
rw_func db 9
rw_sock db 1
rw_memt db 0
rw_memh dw 0
rw_tlen dw 1
rw_clow dw CARD_COR_OFFSET
rw_chig dw 0
rw_boff dw corval
rw_bseg dw 0

irq_num db 5
irq_di dw 8005h
win_bh db 9
io_base dw 0300h
win_base dw 0300h
win_size dw 0010h
last_ax dw 0
corval db CARD_COR_VALUE
fcsrval db 0
prombuf times 16 db 0

%ifdef GENERIC
cor_offset dw 0
fcsr_offset dw 0
cis_left dw 0
tuple_len dw 0
tuple_code db 0
candidate_cor db 0
have_lan db 0
have_config db 0
have_cftable db 0
rawbuf times 256 db 0
%endif

%ifdef GENERIC
banner db 13,10,'O300NIC v0.1 - CIS-parsing NE2000 300h setup test',13,10,'$'
cor_ok db 'write derived COR OK',13,10,'$'
fcsr_ok db 'write derived FCSR OK',13,10,'$'
%elifdef EN2216_FAMILY
banner db 13,10,'O300E16 v0.1 - EN2216-family NE2000 300h setup test',13,10,'$'
cor_ok db 'write COR 60h at 01FCh OK',13,10,'$'
fcsr_ok db 'write FCSR at 01FDh OK',13,10,'$'
%elifdef BUFFALO
banner db 13,10,'O300BUF v0.1 - Buffalo LPC3-CLT/NE2000 300h setup test',13,10,'$'
cor_ok db 'write COR 60h at 01FCh OK',13,10,'$'
fcsr_ok db 'write FCSR at 01FDh OK',13,10,'$'
%else
banner db 13,10,'O300NE v1.0 - FA411/NE2000 300h setup test',13,10,'$'
cor_ok db 'write COR 47h at 01E0h OK',13,10,'$'
fcsr_ok db 'write FCSR at 01E1h OK',13,10,'$'
%endif
irq_msg db 'IRQ 0x$'
sock_ok db 'set socket OK',13,10,'$'
win_ok1 db 'set window ID 0x$'
win_1f_ok db ' size 1Fh OK',13,10,'$'
win_1f_fail db ' size 1Fh failed, AX=0x$'
win_ok2 db ' low 16 OK',13,10,'$'
win_ok3 db ' high 16 OK',13,10,'$'
win_try_msg db 'set window ID 0x$'
win_fail_msg db ' failed, AX=0x$'
fallback_msg db 'Falling back to dual 16-byte windows',13,10,'$'
map_msg db 'Configured base 0x$'
base_msg db 'Probe base 0x$'
prom_msg db 'NE2000 PROM bytes: $'
mac_msg db 'MAC address: $'
done_msg db 'Done. Try LXEN2216 0x66 next.',13,10,'$'
fail_msg db 'Card BIOS call failed, AX=0x$'
%ifdef GENERIC
cis_msg db 'Reading CIS from socket 1',13,10,'$'
lan_msg db 'LAN function and 300h CFTABLE entry found',13,10,'$'
cor_off_msg db 'Derived COR offset 0x$'
fcsr_off_msg db 'Derived FCSR offset 0x$'
cor_val_msg db 'Derived COR value 0x$'
parse_fail_msg db 'Could not derive LAN/COR/CFTABLE data from CIS',13,10,'$'
%endif
