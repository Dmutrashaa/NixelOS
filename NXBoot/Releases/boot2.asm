[BITS 16]
[ORG 0x8000]

stage2_start:
    cli
    mov ax, 0x0003
    int 0x10
    sti

    call check_memory
    jc .no_ram

    call check_cpuid
    jc .bad_cpu

    call check_long_mode
    jc .bad_cpu

    mov si, MSG_CANNOT_BOOT
    mov cx, MSG_CANNOT_BOOT_LEN
    jmp show_error

.no_ram:
    mov si, MSG_NO_RAM
    mov cx, MSG_NO_RAM_LEN
    jmp show_error

.bad_cpu:
    mov si, MSG_BAD_CPU
    mov cx, MSG_BAD_CPU_LEN
    jmp show_error

check_memory:
    clc
    mov ah, 0x88
    int 0x15
    jc .no_mem
    cmp ax, 3072
    jb .no_mem
    clc
    ret
.no_mem:
    stc
    ret

check_cpuid:
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx
    jz .no_cpuid
    clc
    ret
.no_cpuid:
    stc
    ret

check_long_mode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_lm

    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_lm

    clc
    ret
.no_lm:
    stc
    ret

show_error:
    push si
    push cx

    mov ax, 0x1003
    xor bx, bx
    int 0x10

    mov ah, 0x01
    mov ch, 0x20
    mov cl, 0x00
    int 0x10

    mov si, MSG_ERROR
    mov cx, MSG_ERROR_LEN
    mov dh, 7
    mov bl, 0x04
    call print_colored

    pop cx
    pop si
    mov dh, 9
    mov bl, 0x0F
    call print_colored

    mov si, MSG_INFO
    mov cx, MSG_INFO_LEN
    mov dh, 11
    call print_centered

    mov si, MSG_HINT
    mov cx, MSG_HINT_LEN
    mov dh, 12
    call print_centered

    mov byte [SELECTED], 0

.redraw:
    mov si, BTN_REBOOT
    mov cx, BTN_LEN
    mov dh, 14
    mov bl, 0x07
    mov al, [SELECTED]
    cmp al, 0
    jne .r_skip
    mov bl, 0xF0
.r_skip:
    call print_button

    mov si, BTN_SHUTDOWN
    mov cx, BTN_LEN
    mov dh, 15
    mov bl, 0x07
    mov al, [SELECTED]
    cmp al, 1
    jne .s_skip
    mov bl, 0xF0
.s_skip:
    call print_button

    mov si, BTN_TERMINAL
    mov cx, BTN_LEN
    mov dh, 16
    mov bl, 0x07
    mov al, [SELECTED]
    cmp al, 2
    jne .t_skip
    mov bl, 0xF0
.t_skip:
    call print_button

.wait_key:
    xor ax, ax
    int 0x16
    cmp al, 0x0D
    je .confirm
    cmp ah, 0x48
    je .move_up
    cmp ah, 0x50
    je .move_down
    jmp .wait_key
.move_up:
    cmp byte [SELECTED], 0
    je .redraw
    dec byte [SELECTED]
    jmp .redraw
.move_down:
    cmp byte [SELECTED], 2
    je .redraw
    inc byte [SELECTED]
    jmp .redraw
.confirm:
    mov al, [SELECTED]
    cmp al, 0
    je .confirm_reboot
    cmp al, 1
    je .confirm_shutdown
    jmp run_terminal
.confirm_reboot:
    call do_reboot
    cli
    hlt
    jmp $
.confirm_shutdown:
    call do_shutdown
    cli
    hlt
    jmp $

print_colored:
    mov al, 80
    sub al, cl
    shr al, 1
    mov dl, al
    xor bh, bh
    mov ah, 0x02
    int 0x10
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x09
    mov cx, 1
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    jmp .loop
.done:
    ret

print_centered:
    mov al, 80
    sub al, cl
    shr al, 1
    mov dl, al
    xor bh, bh
    mov ah, 0x02
    int 0x10
    mov ah, 0x0E
.loop:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

print_button:
    mov al, 80
    sub al, cl
    shr al, 1
    mov dl, al
    xor bh, bh
    mov ah, 0x02
    int 0x10
.loop:
    lodsb
    mov ah, 0x09
    push cx
    mov cx, 1
    int 0x10
    pop cx
    inc dl
    mov ah, 0x02
    int 0x10
    loop .loop
    ret

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

print_attr:
    pusha
    xor bh, bh
    mov ah, 0x03
    int 0x10
.loop:
    lodsb
    or al, al
    jz .done
    cmp al, 13
    je .cr
    cmp al, 10
    je .lf
    mov ah, 0x02
    int 0x10
    mov ah, 0x09
    mov cx, 1
    int 0x10
    inc dl
    jmp .loop
.cr:
    xor dl, dl
    jmp .loop
.lf:
    inc dh
    jmp .loop
.done:
    mov ah, 0x02
    int 0x10
    popa
    ret

spin_delay:
    pusha
    mov ah, 0x86
    mov cx, 0x0002
    mov dx, 0x49F0
    int 0x15
    popa
    ret

match_cmd:
.loop:
    mov al, [si]
    mov ah, [di]
    or ah, ah
    jz .ref_end
    or al, 0x20
    cmp al, ah
    jne .no_match
    inc si
    inc di
    jmp .loop
.ref_end:
    mov al, [si]
    cmp al, ' '
    je .match
    cmp al, 0
    je .match
    jmp .no_match
.match:
    stc
    ret
.no_match:
    clc
    ret

read_line:
    pusha
    mov di, INPUT_BUF
    xor cx, cx
.key_loop:
    xor ax, ax
    int 0x16
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .backspace
    cmp al, 0x20
    jb .key_loop
    cmp cx, 63
    jae .key_loop
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .key_loop
.backspace:
    cmp cx, 0
    je .key_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .key_loop
.done:
    mov byte [di], 0
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    popa
    ret

show_time:
    pusha
    mov ah, 0x02
    int 0x1A
    mov al, ch
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    mov al, cl
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    mov al, dh
    call print_bcd
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    popa
    ret

print_bcd:
    push bx
    mov bl, al
    shr al, 4
    add al, '0'
    mov ah, 0x0E
    int 0x10
    mov al, bl
    and al, 0x0F
    add al, '0'
    mov ah, 0x0E
    int 0x10
    pop bx
    ret

print_dec32:
    pushad
    mov ebx, 10
    xor ecx, ecx
    test eax, eax
    jnz .divloop
    mov al, '0'
    mov ah, 0x0E
    int 0x10
    jmp .done
.divloop:
    xor edx, edx
    div ebx
    push dx
    inc cx
    test eax, eax
    jnz .divloop
.printloop:
    pop dx
    mov al, dl
    add al, '0'
    mov ah, 0x0E
    int 0x10
    loop .printloop
.done:
    popad
    ret

show_sysinfo:
    pusha

    mov si, MSG_SYSINF_CPU
    call print_string

    call check_cpuid
    jc .cpu32
    call check_long_mode
    jc .cpu32
    mov si, MSG_64BIT
    call print_string
    jmp .cpu_done
.cpu32:
    mov si, MSG_32BIT
    call print_string
.cpu_done:

    mov si, MSG_SYSINF_RAM
    call print_string

    clc
    mov ah, 0x88
    int 0x15
    jc .no_ext_mem
    movzx eax, ax
    add eax, 1024
    jmp .have_mem
.no_ext_mem:
    xor eax, eax
.have_mem:
    shr eax, 10
    call print_dec32

    mov si, MSG_MB_SUFFIX
    call print_string

    call check_memory
    jc .cant_run
    call check_cpuid
    jc .cant_run
    call check_long_mode
    jc .cant_run
    mov si, MSG_CAN_RUN
    call print_string
    jmp .sysinfo_done
.cant_run:
    mov si, MSG_CANT_RUN
    call print_string
.sysinfo_done:
    popa
    ret

handle_command:
    cmp byte [INPUT_BUF], 0
    je .ret

    mov si, INPUT_BUF
    mov di, CMD_HELP
    call match_cmd
    jc .do_help

    mov si, INPUT_BUF
    mov di, CMD_EXIT
    call match_cmd
    jc .do_exit

    mov si, INPUT_BUF
    mov di, CMD_TIME
    call match_cmd
    jc .do_time

    mov si, INPUT_BUF
    mov di, CMD_BOOT
    call match_cmd
    jc .do_boot

    mov si, INPUT_BUF
    mov di, CMD_SHUTDOWN
    call match_cmd
    jc .do_shutdown

    mov si, INPUT_BUF
    mov di, CMD_ABOUT
    call match_cmd
    jc .do_about

    mov si, INPUT_BUF
    mov di, CMD_SYSINF
    call match_cmd
    jc .do_sysinf

    mov si, MSG_UNKNOWN
    call print_string
    ret

.do_help:
    mov si, MSG_HELP
    call print_string
    ret

.do_exit:
    call do_reboot
    cli
    hlt
    jmp $

.do_time:
    call show_time
    ret

.do_boot:
    cmp byte [si], 0
    je .boot_usage
    inc si
    cmp byte [si], 0
    je .boot_usage
    push si
    mov si, MSG_BOOTING1
    call print_string
    pop si
    call print_string
    mov si, MSG_BOOTING2
    call print_string
    ret

.boot_usage:
    mov si, MSG_BOOT_USAGE
    call print_string
    ret

.do_shutdown:
    call do_shutdown
    cli
    hlt
    jmp $

.do_about:
    mov si, MSG_ABOUT
    call print_string
    ret

.do_sysinf:
    call show_sysinfo
    ret

.ret:
    ret

run_terminal:
    mov ax, 0x0003
    int 0x10

    mov ah, 0x01
    mov ch, 0x20
    mov cl, 0x00
    int 0x10

    mov dh, 9
    mov dl, LOGO_COL
    xor bh, bh
    mov ah, 0x02
    int 0x10
    mov si, LOGO_L1
    mov bl, 0x0F
    call print_attr

    mov dh, 10
    mov dl, LOGO_COL
    xor bh, bh
    mov ah, 0x02
    int 0x10
    mov si, LOGO_L2
    mov bl, 0x0F
    call print_attr

    mov dh, 11
    mov dl, LOGO_COL
    xor bh, bh
    mov ah, 0x02
    int 0x10
    mov si, LOGO_L3
    mov bl, 0x0F
    call print_attr

    mov dh, 12
    mov dl, LOGO_COL
    xor bh, bh
    mov ah, 0x02
    int 0x10
    mov si, LOGO_L4
    mov bl, 0x0F
    call print_attr

    mov dh, 13
    mov dl, LOGO_COL
    xor bh, bh
    mov ah, 0x02
    int 0x10
    mov si, LOGO_L5
    mov bl, 0x0F
    call print_attr
    mov si, LOGO_VERSION
    call print_string

    mov dh, 15
    mov dl, SPIN_COL
    xor bh, bh
    mov ah, 0x02
    int 0x10

    xor si, si
    mov cx, 16
.spin_loop:
    push cx
    mov al, [SPIN_CHARS + si]
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    mov ah, 0x09
    int 0x10
    call spin_delay
    pop cx
    inc si
    and si, 3
    loop .spin_loop

    mov ax, 0x0003
    int 0x10

    mov si, MSG_WELCOME
    mov bl, 0x0F
    call print_attr

    mov si, MSG_WELCOME_HINT
    mov bl, 0x07
    call print_attr

terminal_loop:
    mov si, MSG_PROMPT
    call print_string
    call read_line
    call handle_command
    jmp terminal_loop

do_shutdown:
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    mov ax, 0x5308
    mov bx, 1
    mov cx, 1
    int 0x15
    mov ax, 0x5307
    mov bx, 1
    mov cx, 3
    int 0x15
    ret

do_reboot:
    mov word [0x0472], 0x1234
    jmp 0xFFFF:0x0000

SELECTED            db 0
MSG_NO_RAM          db "Cannot boot NixelOS. Error code: NOT_ENOUGH_RAM", 0
MSG_NO_RAM_LEN      equ $ - MSG_NO_RAM - 1
MSG_BAD_CPU         db "Cannot boot NixelOS. Error code: BAD_CPU_CONFIG", 0
MSG_BAD_CPU_LEN     equ $ - MSG_BAD_CPU - 1
MSG_CANNOT_BOOT     db "Cannot boot NixelOS. Error code: CANNOT_BOOT", 0
MSG_CANNOT_BOOT_LEN equ $ - MSG_CANNOT_BOOT - 1
MSG_ERROR           db "Error!", 0
MSG_ERROR_LEN       equ $ - MSG_ERROR - 1
MSG_INFO            db "Check https://t.me/NixelOS for more information.", 0
MSG_INFO_LEN        equ $ - MSG_INFO - 1
MSG_HINT            db "Try to Reboot your PC, or shutdown it...", 0
MSG_HINT_LEN        equ $ - MSG_HINT - 1
BTN_REBOOT          db "     Reboot     "
BTN_SHUTDOWN        db "    Shutdown    "
BTN_TERMINAL        db "Run BL Terminal "
BTN_LEN             equ 16

LOGO_L1             db "_   ___  __ ____              _   ", 0
LOGO_L1_LEN         equ $ - LOGO_L1 - 1
LOGO_COL            equ (80 - LOGO_L1_LEN) / 2
SPIN_COL            equ (80 - 1) / 2
LOGO_L2             db "| \ | \ \/ /| __ )  ___   ___ | |_ ", 0
LOGO_L3             db "|  \| |\  / |  _ \ / _ \ / _ \| __|", 0
LOGO_L4             db "| |\  |/  \ | |_) | (_) | (_) | |_ ", 0
LOGO_L5             db "|_| \_/_/\_\|____/ \___/ \___/ \__|", 0
LOGO_VERSION        db " v0.4", 0
SPIN_CHARS          db '-', '/', '|', 0x5C

MSG_WELCOME         db "Welcome to NXBoot Terminal!", 13, 10, 0
MSG_WELCOME_HINT    db 'Type "help" to see list of all commands.', 13, 10, 0
MSG_PROMPT          db "NXBoot>", 0
MSG_HELP            db "Available commands:", 13, 10
                    db "  help          - shows this help message", 13, 10
                    db "  boot [file]   - boots the system from the given file", 13, 10
                    db "  exit          - reboots your machine", 13, 10
                    db "  time          - shows the current time", 13, 10
                    db "  shutdown      - shuts down your machine", 13, 10
                    db "  about         - shows info about the bootloader and the terminal", 13, 10
                    db "  sysinf        - shows your current system specification", 13, 10, 0
MSG_UNKNOWN         db "Unknown command. Type 'help' for a list of commands.", 13, 10, 0
MSG_BOOT_USAGE      db "Usage: boot [file]", 13, 10, 0
MSG_BOOTING1        db "Booting from ", 0
MSG_BOOTING2        db "... file loading is not wired up yet.", 13, 10, 0

MSG_ABOUT           db "NXBoot v0.4. A bootloader made by Nixel Tech community for NixelOS.", 13, 10
                    db "Build date:2026.09.11", 13, 10
                    db 13, 10
                    db "NixelOS (c). All rights reserved!", 13, 10, 0

MSG_SYSINF_CPU      db "CPU: ", 0
MSG_SYSINF_RAM      db "RAM: ", 0
MSG_64BIT           db "64-bit", 13, 10, 0
MSG_32BIT           db "32-bit", 13, 10, 0
MSG_MB_SUFFIX       db " MB", 13, 10, 0
MSG_CAN_RUN         db "This machine can run NixelOS.", 13, 10, 0
MSG_CANT_RUN        db "This machine can't run NixelOS.", 13, 10, 0

CMD_HELP            db "help", 0
CMD_EXIT            db "exit", 0
CMD_TIME            db "time", 0
CMD_BOOT            db "boot", 0
CMD_SHUTDOWN        db "shutdown", 0
CMD_ABOUT           db "about", 0
CMD_SYSINF          db "sysinf", 0

INPUT_BUF           times 64 db 0

enter_protected_mode:
    cli
    lgdt [gdt32.pointer]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG32:protected_mode_main

[BITS 32]
protected_mode_main:
    mov ax, DATA_SEG32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    jmp setup_long_mode

PML4_ADDR equ 0x9000
PDPT_ADDR equ 0xA000
PD_ADDR   equ 0xB000

setup_long_mode:
    mov edi, PML4_ADDR
    xor eax, eax
    mov ecx, 0x3000 / 4
    rep stosd

    mov eax, PDPT_ADDR
    or eax, 0b11
    mov [PML4_ADDR], eax

    mov eax, PD_ADDR
    or eax, 0b11
    mov [PDPT_ADDR], eax

    mov eax, 0x0000000
    or eax, 0b10000011
    mov [PD_ADDR], eax

    mov eax, PML4_ADDR
    mov cr3, eax

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    lgdt [gdt64.pointer]
    jmp CODE_SEG64:long_mode_main

[BITS 64]
long_mode_main:
    mov ax, DATA_SEG64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

.halt_loop:
    hlt
    jmp .halt_loop

gdt32:
    dq 0x0000000000000000

    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
.pointer:
    dw $ - gdt32 - 1
    dd gdt32

CODE_SEG32 equ 0x08
DATA_SEG32 equ 0x10

gdt64:
    dq 0x0000000000000000

    dw 0x0000, 0x0000
    db 0x00, 10011010b, 00100000b, 0x00

    dw 0x0000, 0x0000
    db 0x00, 10010010b, 00000000b, 0x00
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

CODE_SEG64 equ 0x08
DATA_SEG64 equ 0x10

times ((512 - (($ - $$) % 512)) % 512) db 0
