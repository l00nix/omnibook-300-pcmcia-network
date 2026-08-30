; O300WIN.COM - OmniBook 300 Socket Services window diagnostic
;
; Build:
;   nasm -f bin -o O300WIN.COM o300win.asm
;
; This program is read-only. It uses Socket Services AH=87h and AH=88h to dump
; window capabilities and current window state. It does not enable or configure
; any inserted PC Card.

bits 16
org 100h

start:
    push cs
    pop ds

    mov dx, banner
    call puts

    mov byte [win_num], 0
    mov byte [win_left], 16
.loop:
    mov dx, win_msg
    call puts
    mov al, [win_num]
    call print_hex8
    call crlf

    call inquire_window
    mov dx, inq_msg
    call puts
    call print_cf_status
    cmp byte [last_cf], 0
    jne .get

    mov dx, cap_msg
    call puts
    mov al, [last_bx]
    call print_hex8
    mov dx, sockmap_msg
    call puts
    mov ax, [last_cx]
    call print_hex16
    mov dx, speed_msg
    call puts
    mov al, [last_dx]
    call print_hex8
    mov dx, memptr_msg
    call puts
    mov ax, [last_ds]
    call print_hex16
    mov dl, ':'
    call putc
    mov ax, [last_si]
    call print_hex16
    mov dx, ioptr_msg
    call puts
    mov ax, [last_ds]
    call print_hex16
    mov dl, ':'
    call putc
    mov ax, [last_di]
    call print_hex16
    call crlf

.get:
    call get_window
    mov dx, get_msg
    call puts
    call print_cf_status
    cmp byte [last_cf], 0
    jne .next

    mov dx, assign_msg
    call puts
    mov al, [last_bx]
    call print_hex8
    mov dx, size_msg
    call puts
    mov ax, [last_cx]
    call print_hex16
    mov dx, attr_msg
    call puts
    mov al, [last_dx + 1]
    call print_hex8
    mov dx, speed_msg
    call puts
    mov al, [last_dx]
    call print_hex8
    mov dx, base_msg
    call puts
    mov ax, [last_si]
    call print_hex16
    mov dx, offs_msg
    call puts
    mov ax, [last_di]
    call print_hex16
    call crlf

.next:
    call crlf
    inc byte [win_num]
    dec byte [win_left]
    jnz .loop

    mov ax, 4c00h
    int 21h

inquire_window:
    mov ax, 8700h
    mov bh, [win_num]
    int 1ah
    jmp store_regs

get_window:
    mov ax, 8800h
    mov bh, [win_num]
    int 1ah
    jmp store_regs

store_regs:
    pushf
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push cs
    pop ds
    pop word [last_ds]
    pop word [last_di]
    pop word [last_si]
    pop word [last_dx]
    pop word [last_cx]
    pop word [last_bx]
    pop word [last_ax]
    popf
    mov byte [last_cf], 0
    jnc .done
    mov byte [last_cf], 1
.done:
    ret

print_cf_status:
    cmp byte [last_cf], 0
    jne .cf_set
    mov dx, ok_msg
    call puts
    ret
.cf_set:
    mov dx, cf_msg
    call puts
    mov al, [last_ax + 1]
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

win_num db 0
win_left db 0
last_cf db 0
last_ax dw 0
last_bx dw 0
last_cx dw 0
last_dx dw 0
last_si dw 0
last_di dw 0
last_ds dw 0

banner db 13,10,'O300WIN v0.1 - Socket Services window dump',13,10,'$'
win_msg db 'Window 0x$'
inq_msg db '  inquire: $'
get_msg db '  get    : $'
ok_msg db 'OK',13,10,'$'
cf_msg db 'CF AH=0x$'
cap_msg db '    cap=0x$'
sockmap_msg db ' sockets=0x$'
speed_msg db ' speed=0x$'
memptr_msg db ' memtbl=$'
ioptr_msg db ' iotbl=$'
assign_msg db '    socket=0x$'
size_msg db ' size=0x$'
attr_msg db ' attr=0x$'
base_msg db ' base=0x$'
offs_msg db ' offs=0x$'
