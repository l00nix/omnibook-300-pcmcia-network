; O300SIZ.COM - Socket Services I/O window size matrix for OmniBook 300
;
; Build:
;   nasm -f bin -o O300SIZ.COM o300siz.asm
;
; This test writes the FA411 COR/FCSR like O300NE, then tries I/O windows
; 04h-07h at base 0300h with several window sizes. It reports only the result
; of the Socket Services set-window call.

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

    call write_cor
    jc fail
    mov dx, cor_ok
    call puts

    call write_fcsr
    jc fail
    mov dx, fcsr_ok
    call puts

    mov byte [speed_idx], 0
.speed_loop:
    mov al, [speed_idx]
    xor ah, ah
    mov bx, ax
    mov al, [speed_list + bx]
    mov [speed_val], al

    mov dx, speed_test_msg
    call puts
    mov al, [speed_val]
    call print_hex8
    call crlf

    mov byte [win_num], 4
.win_loop:
    mov word [size_ptr], size_list
    mov byte [size_left], 6
.size_loop:
    mov si, [size_ptr]
    lodsw
    mov [size_ptr], si
    mov [win_size], ax

    mov dx, try_msg
    call puts
    mov al, [win_num]
    call print_hex8
    mov dx, size_msg
    call puts
    mov ax, [win_size]
    call print_hex16
    mov dx, result_msg
    call puts

    call set_window
    mov [last_ax], ax
    jc .bad
    mov dx, ok_msg
    call puts
    jmp .next_size
.bad:
    mov dx, cf_msg
    call puts
    mov al, [last_ax + 1]
    call print_hex8
    call crlf

.next_size:
    dec byte [size_left]
    jnz .size_loop

    inc byte [win_num]
    cmp byte [win_num], 8
    jb .win_loop

    inc byte [speed_idx]
    cmp byte [speed_idx], 2
    jb .speed_loop

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

set_window:
    mov ax, 8900h
    mov bh, [win_num]
    mov bl, 1
    mov cx, [win_size]
    mov dx, 0500h
    mov dl, [speed_val]
    mov si, 0300h
    xor di, di
    int 1ah
    ret

write_cor:
    mov word [rw_boff], corval
    mov byte [corval], 47h
    mov byte [rw_func], 9
    mov word [rw_tlen], 1
    mov word [rw_clow], 01e0h
    mov word [rw_chig], 0
    mov ax, 0b000h
    mov bx, rwreq
    int 1ah
    ret

write_fcsr:
    mov word [rw_boff], fcsrval
    mov byte [rw_func], 8
    mov word [rw_tlen], 1
    mov word [rw_clow], 01e1h
    mov word [rw_chig], 0
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
rw_func db 9
rw_sock db 1
rw_memt db 0
rw_memh dw 0
rw_tlen dw 1
rw_clow dw 01e0h
rw_chig dw 0
rw_boff dw corval
rw_bseg dw 0

win_num db 4
win_size dw 1
size_ptr dw 0
size_left db 0
speed_idx db 0
speed_val db 1
last_ax dw 0
corval db 47h
fcsrval db 0
size_list dw 1, 2, 4, 8, 16, 32
speed_list db 1, 20h

banner db 13,10,'O300SIZ v0.1 - I/O window size matrix',13,10,'$'
cor_ok db 'write COR 47h at 01E0h OK',13,10,'$'
fcsr_ok db 'write FCSR at 01E1h OK',13,10,'$'
speed_test_msg db 13,10,'Speed 0x$'
try_msg db 'win 0x$'
size_msg db ' size 0x$'
result_msg db ' -> $'
ok_msg db 'OK',13,10,'$'
cf_msg db 'CF AH=0x$'
fail_msg db 'Card BIOS call failed, AX=0x$'
done_msg db 'Done.',13,10,'$'
