; NEREG.COM - NE2000 register snapshot helper
;
; This is a read-oriented diagnostic for the OmniBook PCMCIA NE2000 bring-up.
; It assumes the card has already been enabled and mapped at I/O base 300h.
; The program selects page 0 and page 1 long enough to dump the 8390 register
; bytes, then restores the original command register value.

bits 16
org 100h

%define NE_BASE 0300h

start:
    push cs
    pop ds

    mov dx, banner
    call puts

    mov dx, NE_BASE
    in al, dx
    mov [orig_cr], al

    mov dx, cr_msg
    call puts
    mov al, [orig_cr]
    call print_hex8
    call crlf

    mov dx, page0_msg
    call puts
    mov al, [orig_cr]
    and al, 3fh
    mov dx, NE_BASE
    out dx, al
    call dump_16_regs

    mov dx, page1_msg
    call puts
    mov al, [orig_cr]
    and al, 3fh
    or al, 40h
    mov dx, NE_BASE
    out dx, al
    call dump_16_regs

    mov al, [orig_cr]
    mov dx, NE_BASE
    out dx, al

    mov dx, restored_msg
    call puts
    mov ax, 4c00h
    int 21h

dump_16_regs:
    push ax
    push bx
    push cx
    push dx

    mov dx, offs_msg
    call puts
    xor bx, bx
.offs:
    mov al, bl
    call print_hex8
    mov dl, ' '
    call putc
    inc bl
    cmp bl, 10h
    jne .offs
    call crlf

    mov dx, vals_msg
    call puts
    xor bx, bx
.vals:
    mov dx, NE_BASE
    add dx, bx
    in al, dx
    call print_hex8
    mov dl, ' '
    call putc
    inc bl
    cmp bl, 10h
    jne .vals
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

orig_cr db 0

banner db 13,10,'NEREG v0.1 - NE2000 regs at 300h',13,10,'$'
cr_msg db 'Original CR: $'
page0_msg db 'Page 0 registers',13,10,'$'
page1_msg db 'Page 1 registers',13,10,'$'
offs_msg db 'ofs: $'
vals_msg db 'val: $'
restored_msg db 'CR restored',13,10,'$'
