; NERXPOLL.COM - NE2000 polling receive diagnostic
;
; Assumes an NE2000-compatible PCMCIA card has already been enabled and mapped
; at I/O base 300h. This diagnostic initializes the 8390 receive path and polls
; the RX ring directly, without a packet driver or hardware IRQ.

bits 16
org 100h

%define NE_BASE 0300h
%define RX_START 46h
%define RX_STOP  80h
%define RX_FIRST (RX_START + 1)

start:
    push cs
    pop ds

    mov dx, banner
    call puts

    call reset_nic
    call init_rx

    mov dx, wait_msg
    call puts

    mov ah, 00h
    int 1ah
    add dx, 180
    mov [deadline], dx

.poll:
    call read_state
    test byte [isr], 01h
    jnz .got_packet
    cmp byte [curr], RX_FIRST
    jne .got_packet

    mov ah, 00h
    int 1ah
    mov ax, dx
    sub ax, [deadline]
    jb .poll

    mov dx, none_msg
    call puts
    jmp .report

.got_packet:
    mov dx, got_msg
    call puts

.report:
    call print_state
    call read_ring_bytes
    mov dx, done_msg
    call puts
    mov ax, 4c00h
    int 21h

reset_nic:
    mov dx, NE_BASE + 1fh
    in al, dx
    mov bl, al
    mov cx, 1600
.delay:
    in al, 61h
    loop .delay
    mov al, bl
    out dx, al
    ret

init_rx:
    mov dx, NE_BASE
    mov al, 21h
    out dx, al

    mov dx, NE_BASE + 0eh
    mov al, 48h
    out dx, al

    xor al, al
    mov dx, NE_BASE + 0ah
    out dx, al
    inc dx
    out dx, al

    mov dx, NE_BASE + 0ch
    mov al, 20h
    out dx, al
    inc dx
    mov al, 02h
    out dx, al

    mov dx, NE_BASE + 01h
    mov al, RX_START
    out dx, al
    inc dx
    mov al, RX_STOP
    out dx, al
    inc dx
    mov al, RX_START
    out dx, al

    mov dx, NE_BASE + 07h
    mov al, 0ffh
    out dx, al

    mov dx, NE_BASE + 0fh
    xor al, al
    out dx, al

    mov dx, NE_BASE
    mov al, 61h
    out dx, al

    mov si, station_mac
    mov dx, NE_BASE + 01h
    mov cx, 6
.par:
    lodsb
    out dx, al
    inc dx
    loop .par

    mov dx, NE_BASE + 07h
    mov al, RX_FIRST
    out dx, al

    mov dx, NE_BASE + 08h
    xor al, al
    mov cx, 8
.mar:
    out dx, al
    inc dx
    loop .mar

    mov dx, NE_BASE
    mov al, 22h
    out dx, al

    mov dx, NE_BASE + 0dh
    xor al, al
    out dx, al

    mov dx, NE_BASE + 0ch
    mov al, 14h
    out dx, al

    mov dx, NE_BASE + 07h
    mov al, 0ffh
    out dx, al
    ret

read_state:
    mov dx, NE_BASE
    mov al, 22h
    out dx, al

    mov dx, NE_BASE + 03h
    in al, dx
    mov [bnry], al
    mov dx, NE_BASE + 07h
    in al, dx
    mov [isr], al
    mov dx, NE_BASE + 0ch
    in al, dx
    mov [rsr], al

    mov dx, NE_BASE
    mov al, 62h
    out dx, al
    mov dx, NE_BASE + 07h
    in al, dx
    mov [curr], al

    mov dx, NE_BASE
    mov al, 22h
    out dx, al
    ret

read_ring_bytes:
    mov al, [bnry]
    inc al
    cmp al, RX_STOP
    jb .store
    mov al, RX_START
.store:
    mov [dump_page], al

    mov dx, ring_msg
    call puts
    mov al, [dump_page]
    call print_hex8
    mov dx, page_suffix
    call puts

    mov dx, NE_BASE
    mov al, 22h
    out dx, al

    mov dx, NE_BASE + 07h
    mov al, 40h
    out dx, al

    mov dx, NE_BASE + 0ah
    mov al, 32
    out dx, al
    inc dx
    xor al, al
    out dx, al

    mov dx, NE_BASE + 08h
    xor al, al
    out dx, al
    inc dx
    mov al, [dump_page]
    out dx, al

    mov dx, NE_BASE
    mov al, 0ah
    out dx, al

    mov di, ringbuf
    mov cx, 32
    mov dx, NE_BASE + 10h
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

print_state:
    mov dx, state_msg
    call puts
    mov al, [bnry]
    call print_hex8
    mov dx, curr_msg
    call puts
    mov al, [curr]
    call print_hex8
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

station_mac db 00h,07h,40h,19h,1ah,4dh
deadline dw 0
bnry db 0
curr db 0
isr db 0
rsr db 0
dump_page db 0
ringbuf times 32 db 0

banner db 13,10,'NERXPOLL v0.1 - NE2000 polling RX test at 300h',13,10,'$'
wait_msg db 'Polling for external RX for about 10 seconds...',13,10,'$'
got_msg db 'RX activity observed.',13,10,'$'
none_msg db 'No RX activity observed.',13,10,'$'
state_msg db 'BNRY $'
curr_msg db ' CURR $'
isr_msg db ' ISR $'
rsr_msg db ' RSR $'
ring_msg db 'Ring bytes at page $'
page_suffix db '00h',13,10,'$'
bytes_msg db 'bytes: $'
done_msg db 'Done.',13,10,'$'
