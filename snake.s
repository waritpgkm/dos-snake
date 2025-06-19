org 0x100

section .data
VIDEO_MEM_SEG equ 0xA000
WIDTH equ 320
HEIGHT equ 200
BLOCK_LEN equ 10

snake_x dw 150
snake_y dw 100

snake_dx dw 0
snake_dy dw 0

food_x dw 0
food_y dw 0

section .bss
rows_offset resw 200

section .text
global start

start:
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    mov ax, VIDEO_MEM_SEG      ; video memory segment
    mov es, ax

    call set_rows_offset

    call get_random_x
    call get_random_y

    call draw_block
    call food_block

main_loop:
    mov ax, [snake_x]
    cmp ax, [food_x]
    jne continue_loop
    mov ax, [snake_y]
    cmp ax, [food_y]
    jne continue_loop
    call get_random_x
    call get_random_y
    call food_block
continue_loop:
    call check_input
    call clear_block
    call update_pos
    call draw_block
    call wait_for_tick

    jmp main_loop

set_rows_offset:
    mov cx, 200
    xor ax, ax
    xor si, si
.loop:
    mov bx, si
    shl bx, 1
    mov [rows_offset + bx], ax
    add ax, WIDTH
    inc si
    loop .loop

    ret

get_random_x:
    mov ah, 0
    int 0x1A

    mov ax, dx
    xor dx, dx
    mov cx, 31
    div cx

    mov ax, dx
    mov dx, 10
    mul dx
    mov word [food_x], ax
    ret
get_random_y:
    mov ah, 0           
    int 0x1A

    mov ax, dx
    xor dx, dx
    mov cx, 20
    div cx

    mov ax, dx
    mov dx, 10
    mul dx
    mov word [food_y], ax
    ret

check_input:
    mov ah, 1
    int 0x16
    jz .no_input

    mov ah, 0
    int 0x16

    cmp ah, 1
    je exit

    cmp al, 0
    jne .no_input

    mov bx, [snake_dx]
    cmp ah, 72
    je .up
    cmp ah, 80
    je .down
    cmp ah, 75
    je .left
    cmp ah, 77
    je .right
.no_input:
    ret
.up:
    mov word [snake_dx], 0
    mov word [snake_dy], -10
    ret
.down:
    mov word [snake_dx], 0
    mov word [snake_dy], 10
    ret
.left:
    mov word [snake_dx], -10
    mov word [snake_dy], 0
    ret
.right:
    mov word [snake_dx], 10
    mov word [snake_dy], 0
    ret

update_pos:
    mov ax, [snake_x]
    cmp ax, 0
    jle .near_l_edge
    cmp ax, 310
    jge .near_r_edge
.valid_x:
    add ax, [snake_dx]
    mov [snake_x], ax

    mov ax, [snake_y]
    cmp ax, 0
    jle .near_t_edge
    cmp ax, 190
    jge .near_b_edge
.valid_y:
    add ax, [snake_dy]
    mov [snake_y], ax

    ret

.near_l_edge:
    mov bx, [snake_dx]
    cmp bx, -10
    je .reset
    jmp .valid_x
.near_r_edge:
    mov bx, [snake_dx]
    cmp bx, 10
    je .reset
    jmp .valid_x
.near_t_edge:
    mov bx, [snake_dy]
    cmp bx, -10
    je .reset
    jmp .valid_y
.near_b_edge:
    mov bx, [snake_dy]
    cmp bx, 10
    je .reset
    jmp .valid_y

.reset:
    mov word [snake_x], 150
    mov word [snake_y], 100
    mov word [snake_dx], 0
    mov word [snake_dy], 0
    ret

draw_block:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, 0

.draw_row:
    mov cx, 0

.draw_col:
    mov bx, [snake_y]
    add bx, si
    shl bx, 1
    mov ax, [rows_offset+bx]
    mov bx, [snake_x]
    add ax, bx
    add ax, cx
    mov di, ax
    mov al, 2
    mov es:[di], al

    inc cx
    cmp cx, BLOCK_LEN
    jl .draw_col

    inc si
    cmp si, BLOCK_LEN
    jl .draw_row

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

clear_block:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, 0

.clear_row:
    mov cx, 0

.clear_col:
    mov bx, [snake_y]
    add bx, si
    shl bx, 1
    mov ax, [rows_offset+bx]
    mov bx, [snake_x]
    add ax, bx
    add ax, cx
    mov di, ax
    mov al, 0
    mov es:[di], al

    inc cx
    cmp cx, BLOCK_LEN
    jl .clear_col

    inc si
    cmp si, BLOCK_LEN
    jl .clear_row

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

food_block:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, 0

.food_row:
    mov cx, 0

.food_col:
    mov bx, [food_y]
    add bx, si
    shl bx, 1
    mov ax, [rows_offset + bx]
    mov bx, [food_x]
    add ax, bx
    add ax, cx
    mov di, ax
    mov al, 4
    mov es:[di], al

    inc cx
    cmp cx, BLOCK_LEN
    jl .food_col

    inc si
    cmp si, BLOCK_LEN
    jl .food_row

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

wait_for_tick:
    push bx
    mov ah, 0        ; Function 0: Get system time
    int 0x1A          ; Result: CX:DX = tick count
    mov bx, dx       ; Save current tick

.wait:
    int 0x1A
    cmp dx, bx       ; Wait until tick changes
    je .wait
    pop bx
    ret

exit:
    sti
    mov ax, 3
    int 0x10

    mov ax, 0x4C00      ; Exit to DOS
    int 0x21
