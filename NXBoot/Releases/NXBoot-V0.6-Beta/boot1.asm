[BITS 16]
[ORG 0x7C00]

STAGE2_SEGMENT  equ 0x0000
STAGE2_OFFSET   equ 0x8000
CHUNK_SECTORS   equ 32                              ; 16 KB per BIOS read
CHUNK_COUNT     equ 6
STAGE2_SECTORS  equ CHUNK_SECTORS * CHUNK_COUNT     ; 192 sectors = 96 KB max

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

    call disk_load

    mov dl, [BOOT_DRIVE]
    jmp STAGE2_SEGMENT:STAGE2_OFFSET

; Loads stage 2 (code + splash picture) with LBA reads, starting at LBA 1
disk_load:
    mov cx, CHUNK_COUNT
.next:
    push cx
    mov si, DAP
    mov dl, [BOOT_DRIVE]
    mov ah, 0x42
    int 0x13
    pop cx
    jc disk_error
    add dword [DAP_LBA], CHUNK_SECTORS
    add word [DAP_SEG], CHUNK_SECTORS * 32          ; 512 bytes = 32 paragraphs
    loop .next
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
MSG_LOADING      db "NXBoot: loading stage 2...", 13, 10, 0
MSG_DISK_ERR     db "Critical Error! Code:CRSBS", 0

DAP:             db 0x10, 0
                 dw CHUNK_SECTORS
DAP_OFF:         dw 0
DAP_SEG:         dw STAGE2_OFFSET >> 4
DAP_LBA:         dd 1
                 dd 0

times 510-($-$$) db 0
dw 0xAA55
