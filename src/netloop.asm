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

    mov si, mode_pairs
    mov cx, (mode_pairs_end - mode_pairs) / 2
.next_pair:
    lodsb
    mov [dcr_mode], al
    lodsb
    mov [rcr_mode], al
    push cx
    push si
    call run_pair
    pop si
    pop cx
    loop .next_pair

    mov dx, msg_done
    call puts
    mov ax, 0x4c00
    int 0x21

run_pair:
    mov dx, msg_dcr
    call puts
    mov al, [dcr_mode]
    call print_hex8
    mov dx, msg_rcr
    call puts
    mov al, [rcr_mode]
    call print_hex8
    call crlf

    mov si, tcr_modes
    mov cx, tcr_modes_end - tcr_modes
.next_mode:
    lodsb
    mov [tcr_mode], al
    push cx
    push si
    call run_mode
    pop si
    pop cx
    loop .next_mode
    ret

run_mode:
    mov dx, msg_tcr
    call puts
    mov al, [tcr_mode]
    call print_hex8
    call crlf

    call reset_nic
    call init_nic
    call remote_write_byte
    call trigger_tx
    call dump_status
    ret

reset_nic:
    mov dx, NIC_BASE + 0x1f
    in al, dx
    mov bl, al
    mov cx, 1600
.delay:
    in al, 0x61
    loop .delay
    mov al, bl
    out dx, al
    ret

init_nic:
    mov dx, NIC_BASE
    mov al, 0x21
    out dx, al

    mov dx, NIC_BASE + 0x0e
    mov al, [dcr_mode]
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
    mov dx, NIC_BASE + 0x0d
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

    mov dx, NIC_BASE + 0x0d
    mov al, [tcr_mode]
    out dx, al

    mov dx, NIC_BASE + 0x0c
    mov al, [rcr_mode]
    out dx, al
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
    mov dx, NIC_BASE + 0x10
    test byte [dcr_mode], 1
    jnz .word_write
    mov cx, frame_end - frame
.write:
    lodsb
    out dx, al
    loop .write
    jmp .wait
.word_write:
    mov cx, (frame_end - frame) / 2
    rep outsw
.wait:
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
    mov dx, NIC_BASE + 0x07
    out dx, al

    mov dx, NIC_BASE
    mov al, 0x26
    out dx, al

    mov cx, 0xffff
.wait:
    mov dx, NIC_BASE + 0x07
    in al, dx
    test al, 0x03
    jnz .done
    loop .wait
    mov dx, msg_tx_timeout
    call puts
.done:
    ret

dump_status:
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

    mov dx, msg_rsr
    call puts
    mov dx, NIC_BASE + 0x0c
    in al, dx
    call print_hex8

    mov dx, msg_curr
    call puts
    mov dx, NIC_BASE
    mov al, 0x62
    out dx, al
    mov dx, NIC_BASE + 0x07
    in al, dx
    call print_hex8

    mov dx, NIC_BASE
    mov al, 0x22
    out dx, al
    call crlf
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
    shr al, 4
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

mode_pairs db 48h, 04h
           db 41h, 01h
           db 49h, 01h
mode_pairs_end:
tcr_modes db 00h, 02h, 03h, 04h, 05h, 06h, 07h
tcr_modes_end:
tcr_mode db 0
dcr_mode db 0
rcr_mode db 0

msg_title db 13,10,'NETLOOP v0.1 - 8390 TCR loopback matrix at 300h',13,10,'$'
msg_dcr db 'DCR=','$'
msg_rcr db ' RCR=','$'
msg_tcr db 'TCR=','$'
msg_isr db '  ISR=','$'
msg_tsr db ' TSR=','$'
msg_rsr db ' RSR=','$'
msg_curr db ' CURR=','$'
msg_rdc_timeout db '  Remote DMA timeout',13,10,'$'
msg_tx_timeout db '  Transmit timeout',13,10,'$'
msg_done db 'Done. Reboot before loading the normal network stack.',13,10,'$'

frame:
    db 0xff,0xff,0xff,0xff,0xff,0xff
source_mac:
    db 0x02,0x00,0x00,0x04,0x25,0x01
    db 0x88,0xb5
    db 'O','m','n','i','B','o','o','k',' ','3','0','0',' ','N','E','2','K',' ','l','o','o','p',' ','T','C','R',' '
    db '0','0'
    times 60-($-frame) db 0
frame_end:
