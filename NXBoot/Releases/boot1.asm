[BITS 16]
[ORG 0x7C00]

STAGE2_SEGMENT  equ 0x0000
STAGE2_OFFSET   equ 0x8000
STAGE2_SECTORS  equ 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [BOOT_DRIVE], dl

    mov si, MSG_LOADING
    call print_string

    mov bx, STAGE2_OFFSET
    mov dh, STAGE2_SECTORS
    mov dl, [BOOT_DRIVE]
    call disk_load

    jmp STAGE2_SEGMENT:STAGE2_OFFSET

disk_load:
    push dx
    mov ah, 0x02
    mov al, dh
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02
    int 0x13
    jc disk_error
    pop dx
    cmp al, dh
    jne disk_error
    ret

disk_error:
    mov si, MSG_DISK_ERR
    call print_string
    cli
    hlt
    jmp $

print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

BOOT_DRIVE       db 0
MSG_LOADING      db "NixelOS: loading stage 2...", 13, 10, 0
MSG_DISK_ERR     db "Disk read error!", 0

times 510-($-$$) db 0
dw 0xAA55
