; NERING.COM - NE2000 receive-ring snapshot helper
;
; Assumes an NE2000-compatible PCMCIA card has already been enabled and mapped
; at I/O base 300h. This diagnostic reads the 8390 page registers and performs
; a small remote-DMA read from the receive ring without using the packet driver.

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

    call read_page0_state
    call read_page1_state
    call restore_cr

    call print_state
    call print_empty_hint
    call pick_next_page
    call read_ring_bytes
    call read_ring_words
    call restore_cr

    mov dx, done_msg
    call puts
    mov ax, 4c00h
    int 21h

read_page0_state:
    mov dx, NE_BASE
    mov al, [orig_cr]
    and al, 3fh
    or al, 20h
    out dx, al

    mov dx, NE_BASE+1
    in al, dx
    mov [pstart], al
    inc dx
    in al, dx
    mov [pstop], al
    inc dx
    in al, dx
    mov [bnry], al
    mov dx, NE_BASE+7
    in al, dx
    mov [isr], al
    mov dx, NE_BASE+0ch
    in al, dx
    mov [rsr], al
    ret

read_page1_state:
    mov dx, NE_BASE
    mov al, [orig_cr]
    and al, 3fh
    or al, 60h
    out dx, al

    mov dx, NE_BASE+7
    in al, dx
    mov [curr], al
    ret

pick_next_page:
    mov al, [bnry]
    inc al
    cmp al, [pstop]
    jb .store
    mov al, [pstart]
.store:
    mov [dump_page], al
    ret

read_ring_bytes:
    mov dx, byte_ring_msg
    call puts
    mov al, [dump_page]
    call print_hex8
    mov dx, page_suffix
    call puts

    call setup_remote_read

    mov di, ringbuf
    mov cx, 32
    mov dx, NE_BASE+10h
.read:
    in al, dx
    stosb
    loop .read

    mov dx, bytes_msg
    call puts
    mov si, ringbuf
    mov cx, 32
    call dump_bytes
    ret

read_ring_words:
    mov dx, word_ring_msg
    call puts
    mov al, [dump_page]
    call print_hex8
    mov dx, page_suffix
    call puts

    call setup_remote_read

    mov di, wordbuf
    mov cx, 16
    mov dx, NE_BASE+10h
.read:
    in ax, dx
    stosw
    loop .read

    mov dx, bytes_msg
    call puts
    mov si, wordbuf
    mov cx, 32
    call dump_bytes
    ret

setup_remote_read:
    mov dx, NE_BASE
    mov al, [orig_cr]
    and al, 3fh
    or al, 20h
    out dx, al

    mov dx, NE_BASE+7
    mov al, 40h
    out dx, al

    mov dx, NE_BASE+0ah
    mov al, 32
    out dx, al
    inc dx
    xor al, al
    out dx, al

    mov dx, NE_BASE+8
    xor al, al
    out dx, al
    inc dx
    mov al, [dump_page]
    out dx, al

    mov dx, NE_BASE
    mov al, 0ah
    out dx, al
    ret

print_state:
    mov dx, cr_msg
    call puts
    mov al, [orig_cr]
    call print_hex8
    call crlf

    mov dx, pstart_msg
    call puts
    mov al, [pstart]
    call print_hex8
    mov dx, pstop_msg
    call puts
    mov al, [pstop]
    call print_hex8
    mov dx, bnry_msg
    call puts
    mov al, [bnry]
    call print_hex8
    mov dx, curr_msg
    call puts
    mov al, [curr]
    call print_hex8
    call crlf

    mov dx, isr_msg
    call puts
    mov al, [isr]
    call print_hex8
    mov dx, rsr_msg
    call puts
    mov al, [rsr]
    call print_hex8
    call crlf
    ret

print_empty_hint:
    mov al, [bnry]
    cmp al, [curr]
    jne .done
    mov dx, empty_msg
    call puts
.done:
    ret

restore_cr:
    mov dx, NE_BASE
    mov al, [orig_cr]
    out dx, al
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
pstart db 0
pstop db 0
bnry db 0
curr db 0
isr db 0
rsr db 0
dump_page db 0
ringbuf times 32 db 0
wordbuf times 32 db 0

banner db 13,10,'NERING v0.2 - NE2000 RX ring at 300h',13,10,'$'
cr_msg db 'CR: $'
pstart_msg db 'PSTART $'
pstop_msg db ' PSTOP $'
bnry_msg db ' BNRY $'
curr_msg db ' CURR $'
isr_msg db 'ISR $'
rsr_msg db ' RSR $'
empty_msg db 'BNRY equals CURR: ring appears empty; dumps below may be stale.',13,10,'$'
byte_ring_msg db 'Byte-mode ring bytes at page $'
word_ring_msg db 'Word-mode ring bytes at page $'
page_suffix db '00h',13,10,'$'
bytes_msg db 'bytes: $'
done_msg db 'Done. Header is status,next,count-lo,count-hi if a packet is present.',13,10,'$'
