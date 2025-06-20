org 0x100

section .data
VIDEO_MEM_SEG equ 0xA000
WIDTH equ 320
HEIGHT equ 200
BLOCK_LEN equ 10

head_x dw 0
head_y dw 0

tail_x dw 0
tail_y dw 0
tail_d db 0

snake_d db 0
snake_dx dw 0
snake_dy dw 0

food_x dw 0
food_y dw 0

SPACE equ 0
UP equ 1
DOWN equ 2
LEFT equ 3
RIGHT equ 4
FOOD equ 5

section .bss
rows_offset resw 200
minimap resb 640

section .text

start:
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    mov ax, VIDEO_MEM_SEG      ; video memory segment
    mov es, ax

    call set_rows_offset
    call init_values

    call get_random_x
    call get_random_y

    call draw_block
    call food_block

    call wait_first_input

main_loop:
    mov ax, [head_x]
    cmp ax, [food_x]
    jne continue_loop
    mov ax, [head_y]
    cmp ax, [food_y]
    jne continue_loop
    call get_random_x
    call get_random_y
    call food_block
continue_loop:
    call check_input
    call set_minimap
    call clear_block
    call update_pos
    call draw_block
    call wait_for_tick

    jmp main_loop

init_values:
    mov word [head_x], 15
    mov word [head_y], 10

    ret

wait_first_input:
    mov ah, 0
    int 0x16

    cmp ah, 1
    je exit

    cmp ah, 72
    je .up
    cmp ah, 80
    je .down
    cmp ah, 75
    je .left
    cmp ah, 77
    je .right
    jmp wait_first_input
.up:
    mov word [snake_dx], 0
    mov word [snake_dy], -1
    mov byte [snake_d], UP
    jmp .first_move
.down:
    mov word [snake_dx], 0
    mov word [snake_dy], 1
    mov byte [snake_d], DOWN
    jmp .first_move
.left:
    mov word [snake_dx], -1
    mov word [snake_dy], 0
    mov byte [snake_d], LEFT
    jmp .first_move
.right:
    mov word [snake_dx], 1
    mov word [snake_dy], 0
    mov byte [snake_d], RIGHT
    jmp .first_move
.first_move:
    mov ax, [head_x]
    mov [tail_x], ax
    mov ax, [head_y]
    mov [tail_y], ax
    mov ax, [head_y]
    mov bx, 32
    mul bx
    mov bx, ax
    add bx, [head_x]
    mov al, [snake_d]
    mov [minimap+bx], al

    mov ax, [head_x]
    add ax, [snake_dx]
    mov [head_x], ax

    mov ax, [head_y]
    add ax, [snake_dy]
    mov [head_y], ax

    call draw_block
    ret

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
    mov cx, 32
    div cx

    mov [food_x], dx
    ret
get_random_y:
    mov ah, 0           
    int 0x1A

    mov ax, dx
    xor dx, dx
    mov cx, 20
    div cx

    mov [food_y], dx
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
    mov ax, [snake_dy]
    cmp ax, 1
    je .invalid_move
    mov word [snake_dx], 0
    mov word [snake_dy], -1
    mov byte [snake_d], UP
    ret
.down:
    mov ax, [snake_dy]
    cmp ax, -1
    je .invalid_move
    mov word [snake_dx], 0
    mov word [snake_dy], 1
    mov byte [snake_d], DOWN
    ret
.left:
    mov ax, [snake_dx]
    cmp ax, 1
    je .invalid_move
    mov word [snake_dx], -1
    mov word [snake_dy], 0
    mov byte [snake_d], LEFT
    ret
.right:
    mov ax, [snake_dx]
    cmp ax, -1
    je .invalid_move
    mov word [snake_dx], 1
    mov word [snake_dy], 0
    mov byte [snake_d], RIGHT
    ret
.invalid_move:
    ret

set_minimap:
    mov ax, [tail_y]
    mov bx, 32
    mul bx
    mov bx, [tail_x]
    add ax, bx
    mov si, ax
    mov al, [minimap+si]
    mov [tail_d], al
    mov al, 0
    mov [minimap+si], al

    mov ax, [head_y]
    mov bx, 32
    mul bx
    mov bx, [head_x]
    add ax, bx
    mov si, ax
    mov al, [snake_d]
    mov [minimap+si], al

    ret

update_pos:
    mov ax, [head_x]
    cmp ax, 0
    jle .near_l_edge
    cmp ax, 31
    jge .near_r_edge
.valid_x:
    add ax, [snake_dx]
    mov [head_x], ax

    mov ax, [head_y]
    cmp ax, 0
    jle .near_t_edge
    cmp ax, 19
    jge .near_b_edge
.valid_y:
    add ax, [snake_dy]
    mov [head_y], ax

    mov al, [tail_d]
    cmp al, UP
    je .tail_up
    cmp al, DOWN
    je .tail_down
    cmp al, LEFT
    je .tail_left
    cmp al, RIGHT
    je .tail_right

    ret

.near_l_edge:
    mov bx, [snake_dx]
    cmp bx, -1
    je .reset
    jmp .valid_x
.near_r_edge:
    mov bx, [snake_dx]
    cmp bx, 1
    je .reset
    jmp .valid_x
.near_t_edge:
    mov bx, [snake_dy]
    cmp bx, -1
    je .reset
    jmp .valid_y
.near_b_edge:
    mov bx, [snake_dy]
    cmp bx, 1
    je .reset
    jmp .valid_y

.reset:
    mov cx, 64000
    xor al, al
    rep stosb
    jmp start
    ret

.tail_up:
    mov ax, [tail_y]
    dec ax
    mov [tail_y], ax
    jmp .ret
.tail_down:
    mov ax, [tail_y]
    inc ax
    mov [tail_y], ax
    jmp .ret
.tail_left:
    mov ax, [tail_x]
    dec ax
    mov [tail_x], ax
    jmp .ret
.tail_right:
    mov ax, [tail_x]
    inc ax
    mov [tail_x], ax
    jmp .ret
.ret:
    ret

draw_block:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

 ;   mov ax, [head_y]
 ;   mov cx, 10
 ;   mul cx
 ;   mov dx, ax
 ;   mov ax, [head_x]
 ;   mul cx

    mov si, 0

.draw_row:
    mov cx, 0

.draw_col:
    mov ax, [head_y]
    mov bx, 10
    mul bx
    add ax, si
    mov bx, ax
    shl bx, 1
    mov ax, [rows_offset+bx]
    mov di, ax
    mov ax, [head_x]
    mov bx, 10
    mul bx
    add di, ax
    add di, cx
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
    mov ax, [tail_y]
    mov bx, 10
    mul bx
    add ax, si
    mov bx, ax
    shl bx, 1
    mov ax, [rows_offset+bx]
    mov di, ax
    mov ax, [tail_x]
    mov bx, 10
    mul bx
    add di, ax
    add di, cx
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
    mov ax, [food_y]
    mov bx, 10
    mul bx
    add ax, si
    mov bx, ax
    shl bx, 1
    mov ax, [rows_offset+bx]
    mov di, ax
    mov ax, [food_x]
    mov bx, 10
    mul bx
    add di, ax
    add di, cx
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
