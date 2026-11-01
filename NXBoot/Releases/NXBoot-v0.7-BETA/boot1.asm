[BITS 16]
[ORG 0x7C00]

STAGE2_SEGMENT  equ 0x0000
STAGE2_OFFSET   equ 0x8000
BOUNCE          equ 0x2000
CHUNK_SECTORS   equ 32
CHUNK_BYTES     equ CHUNK_SECTORS * 512
STAGE2_CHUNKS   equ (STAGE2_SECTORS + CHUNK_SECTORS - 1) / CHUNK_SECTORS
LOW_END         equ STAGE2_OFFSET + LOW_SECTORS * 512

%if (LOW_SECTORS % CHUNK_SECTORS) != 0
%error LOW_SECTORS must be a multiple of CHUNK_SECTORS
%endif

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

    call enable_a20
    call disk_load

    mov dl, [BOOT_DRIVE]
    jmp STAGE2_SEGMENT:STAGE2_OFFSET

enable_a20:
    call a20_test
    jnz .done
    mov ax, 0x2401
    int 0x15
    call a20_test
    jnz .done
    in al, 0x92
    or al, 2
    and al, 0xFE
    out 0x92, al
    mov cx, 0xFFFF
.wait:
    call a20_test
    jnz .done
    loop .wait
    jmp a20_error
.done:
    ret

a20_test:
    push ds
    push es
    push si
    push di
    xor ax, ax
    mov ds, ax
    not ax
    mov es, ax
    mov si, 0x0500
    mov di, 0x0510
    mov al, [si]
    mov ah, [es:di]
    push ax
    mov byte [si], 0x00
    mov byte [es:di], 0xFF
    cmp byte [si], 0xFF
    pop ax
    mov [si], al
    mov [es:di], ah
    pop di
    pop si
    pop es
    pop ds
    ret

disk_load:
.next:
    mov si, DAP
    mov dl, [BOOT_DRIVE]
    mov ah, 0x42
    int 0x13
    jc disk_error
    call copy_chunk
    add dword [DAP_LBA], CHUNK_SECTORS
    dec word [CHUNKS_LEFT]
    jnz .next
    ret

copy_chunk:
    pushad
    cli
    lgdt [GDT_PTR]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp .pm
.pm:
    mov ax, 0x08
    mov fs, ax
    mov eax, cr0
    and al, 0xFE
    mov cr0, eax
    sti
    mov edi, [DEST]
    mov si, BOUNCE
    mov cx, CHUNK_BYTES / 4
.copy:
    mov eax, [si]
    mov [fs:edi], eax
    add si, 4
    add edi, 4
    loop .copy
    cmp edi, LOW_END
    jne .keep
    mov edi, HIGH_BASE
.keep:
    mov [DEST], edi
    popad
    ret

disk_error:
    mov si, MSG_DISK_ERR
    call print_string
    cli
    hlt
    jmp $

a20_error:
    mov si, MSG_A20_ERR
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
CHUNKS_LEFT      dw STAGE2_CHUNKS
DEST             dd STAGE2_OFFSET
MSG_LOADING      db "NXBoot: loading stage 2...", 13, 10, 0
MSG_DISK_ERR     db "Critical Error! Code:CRSBS", 0
MSG_A20_ERR      db "Critical Error! Code:CRSA2", 0

DAP:             db 0x10, 0
                 dw CHUNK_SECTORS
                 dw BOUNCE
                 dw 0
DAP_LBA:         dd 1
                 dd 0

GDT:             dq 0
                 dw 0xFFFF, 0x0000
                 db 0x00, 10010010b, 11001111b, 0x00
GDT_PTR:         dw $ - GDT - 1
                 dd GDT

times 510-($-$$) db 0
dw 0xAA55
