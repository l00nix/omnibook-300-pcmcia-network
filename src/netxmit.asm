bits 16
org 0x100

%define NIC_BASE 0x0300
%define TX_PAGE  0x40
%define RX_START 0x46
%define RX_STOP  0x80

start:
    push cs
    pop ds

    mov dx, msg_title
    call puts

    mov dx, msg_byte
    call puts
    mov al, 0x48
    call init_nic
    mov byte [frame_marker], 'B'
    call send_three_byte

    mov dx, msg_word
    call puts
    mov al, 0x49
    call init_nic
    mov byte [frame_marker], 'W'
    call send_three_word

    mov dx, msg_done
    call puts
    mov ax, 0x4c00
    int 0x21

; AL is the DCR value: 48h for byte mode, 49h for word mode.
init_nic:
    push ax
    mov dx, NIC_BASE
    mov al, 0x21
    out dx, al

    mov dx, NIC_BASE + 0x0e
    pop ax
    out dx, al

    xor al, al
    mov dx, NIC_BASE + 0x0a
    out dx, al
    inc dx
    out dx, al

    mov al, 0x20
    mov dx, NIC_BASE + 0x0c
    out dx, al
    mov al, 0x02
    inc dx
    out dx, al

    mov al, TX_PAGE
    mov dx, NIC_BASE + 0x04
    out dx, al
    mov al, RX_START
    mov dx, NIC_BASE + 0x01
    out dx, al
    mov al, RX_STOP
    inc dx
    out dx, al
    mov al, RX_START
    inc dx
    out dx, al

    mov al, 0xff
    mov dx, NIC_BASE + 0x07
    out dx, al
    xor al, al
    mov dx, NIC_BASE + 0x0f
    out dx, al

    mov dx, NIC_BASE
    mov al, 0x61
    out dx, al

    mov si, source_mac
    mov dx, NIC_BASE + 0x01
    mov cx, 6
.par:
    lodsb
    out dx, al
    inc dx
    loop .par

    mov al, RX_START + 1
    mov dx, NIC_BASE + 0x07
    out dx, al
    mov al, 0xff
    mov dx, NIC_BASE + 0x08
    mov cx, 8
.mar:
    out dx, al
    inc dx
    loop .mar

    mov dx, NIC_BASE
    mov al, 0x22
    out dx, al
    mov al, 0xff
    mov dx, NIC_BASE + 0x07
    out dx, al
    xor al, al
    mov dx, NIC_BASE + 0x0d
    out dx, al
    mov al, 0x04
    mov dx, NIC_BASE + 0x0c
    out dx, al
    ret

send_three_byte:
    mov byte [frame_sequence], '1'
    mov bp, 3
.next:
    call remote_write_byte
    call trigger_tx
    inc byte [frame_sequence]
    call short_delay
    dec bp
    jnz .next
    ret

send_three_word:
    mov byte [frame_sequence], '1'
    mov bp, 3
.next:
    call remote_write_word
    call trigger_tx
    inc byte [frame_sequence]
    call short_delay
    dec bp
    jnz .next
    ret

prepare_remote_write:
    mov al, 0x40
    mov dx, NIC_BASE + 0x07
    out dx, al
    xor al, al
    mov dx, NIC_BASE + 0x08
    out dx, al
    mov al, TX_PAGE
    inc dx
    out dx, al
    mov al, frame_end - frame
    mov dx, NIC_BASE + 0x0a
    out dx, al
    xor al, al
    inc dx
    out dx, al
    mov dx, NIC_BASE
    mov al, 0x12
    out dx, al
    ret

remote_write_byte:
    call prepare_remote_write
    mov si, frame
    mov cx, frame_end - frame
    mov dx, NIC_BASE + 0x10
.write:
    lodsb
    out dx, al
    loop .write
    call wait_rdc
    ret

remote_write_word:
    call prepare_remote_write
    mov si, frame
    mov cx, (frame_end - frame) / 2
    mov dx, NIC_BASE + 0x10
.write:
    lodsw
    out dx, ax
    loop .write
    call wait_rdc
    ret

wait_rdc:
    mov cx, 0xffff
.wait:
    mov dx, NIC_BASE + 0x07
    in al, dx
    test al, 0x40
    jnz .done
    loop .wait
    mov dx, msg_rdc_timeout
    call puts
.done:
    ret

trigger_tx:
    mov al, TX_PAGE
    mov dx, NIC_BASE + 0x04
    out dx, al
    mov al, frame_end - frame
    inc dx
    out dx, al
    xor al, al
    inc dx
    out dx, al
    mov al, 0xff
    inc dx
    out dx, al

    mov dx, NIC_BASE
    mov al, 0x26
    out dx, al

    mov cx, 0xffff
.wait:
    mov dx, NIC_BASE + 0x07
    in al, dx
    test al, 0x03
    jnz .status
    loop .wait
    mov dx, msg_tx_timeout
    call puts
.status:
    mov dx, msg_isr
    call puts
    mov dx, NIC_BASE + 0x07
    in al, dx
    call print_hex8
    mov dx, msg_tsr
    call puts
    mov dx, NIC_BASE + 0x04
    in al, dx
    call print_hex8
    call crlf
    ret

short_delay:
    push cx
    push dx
    mov dx, 0x0010
.outer:
    mov cx, 0xffff
.inner:
    loop .inner
    dec dx
    jnz .outer
    pop dx
    pop cx
    ret

puts:
    mov ah, 0x09
    int 0x21
    ret

putc:
    mov ah, 0x02
    int 0x21
    ret

crlf:
    mov dl, 13
    call putc
    mov dl, 10
    call putc
    ret

print_hex8:
    push ax
    push bx
    mov bl, al
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    call print_nibble
    mov al, bl
    and al, 0x0f
    call print_nibble
    pop bx
    pop ax
    ret

print_nibble:
    and al, 0x0f
    cmp al, 10
    jb .digit
    add al, 'A' - 10
    jmp .emit
.digit:
    add al, '0'
.emit:
    mov dl, al
    call putc
    ret

msg_title db 13,10,'NETXMIT v0.1 - raw NE2000 transmit test at 300h',13,10,'EtherType 88B5, source 02:00:00:04:25:01',13,10,'$'
msg_byte db 'Byte-mode frames:',13,10,'$'
msg_word db 'Word-mode frames:',13,10,'$'
msg_isr db '  ISR=','$'
msg_tsr db ' TSR=','$'
msg_rdc_timeout db '  Remote DMA timeout',13,10,'$'
msg_tx_timeout db '  Transmit timeout',13,10,'$'
msg_done db 'Done. Reboot before loading the normal network stack.',13,10,'$'

frame:
    db 0xff,0xff,0xff,0xff,0xff,0xff
source_mac:
    db 0x02,0x00,0x00,0x04,0x25,0x01
    db 0x88,0xb5
    db 'O','m','n','i','B','o','o','k',' ','4','2','5',' ','N','E','2','0','0','0',' ','r','a','w',' ','T','X',' '
frame_marker db 'M'
frame_sequence db '0'
    times 60-($-frame) db 0
frame_end:
