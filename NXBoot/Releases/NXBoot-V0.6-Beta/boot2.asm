[BITS 16]
[ORG 0x8000]

stage2_start:
    mov [FAT_DRIVE], dl
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

delay_150ms:
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

    mov si, INPUT_BUF
    mov di, CMD_DIR
    call match_cmd
    jc .do_dir

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

.do_dir:
    call fat32_dir
    ret

.ret:
    ret

; ---------------------------------------------------------------
; Splash screen (VBE, linear framebuffer, 24/32 bpp)
; Picture is taken from image_data.inc (RGB24) and centred.
; Looks for 640x384 first, then falls back to 640x400/640x480/800x600
; (see SPLASH_TARGETS). If nothing fits, the splash is just skipped.
; ---------------------------------------------------------------
VBE_INFO        equ 0x6000      ; 512 bytes
VBE_MODE_INFO   equ 0x6200      ; 256 bytes

show_splash:
    pushad

    mov di, VBE_INFO
    mov ax, 0x4F00
    int 0x10
    cmp ax, 0x004F
    jne .done
    cmp dword [VBE_INFO], 0x41534556        ; 'VESA'
    jne .done

    mov ax, [VBE_INFO + 0x10]               ; mode list: segment
    mov [SPL_LIST_SEG], ax
    mov ax, [VBE_INFO + 0x0E]               ; mode list: offset
    mov [SPL_LIST_OFF], ax
    mov word [SPL_TARGET], SPLASH_TARGETS

.next_target:
    mov bx, [SPL_TARGET]
    mov ax, [bx]
    test ax, ax
    jz .done
    mov [SPL_WANT_X], ax
    mov ax, [bx + 2]
    mov [SPL_WANT_Y], ax
    add bx, 4
    mov [SPL_TARGET], bx
    mov si, [SPL_LIST_OFF]

.mode_loop:
    mov fs, [SPL_LIST_SEG]
    mov cx, [fs:si]
    cmp cx, 0xFFFF
    je .next_target
    add si, 2
    mov [SPL_MODE], cx
    push si
    mov di, VBE_MODE_INFO
    mov ax, 0x4F01
    int 0x10
    pop si
    cmp ax, 0x004F
    jne .mode_loop
    mov ax, [VBE_MODE_INFO]                 ; supported + graphics + LFB
    and ax, 0x0091
    cmp ax, 0x0091
    jne .mode_loop
    mov ax, [VBE_MODE_INFO + 0x12]          ; XResolution
    cmp ax, [SPL_WANT_X]
    jne .mode_loop
    mov ax, [VBE_MODE_INFO + 0x14]          ; YResolution
    cmp ax, [SPL_WANT_Y]
    jne .mode_loop
    mov eax, [VBE_MODE_INFO + 0x28]         ; PhysBasePtr
    test eax, eax
    jz .mode_loop
    mov al, [VBE_MODE_INFO + 0x19]          ; BitsPerPixel
    cmp al, 24
    je .found
    cmp al, 32
    jne .mode_loop

.found:
    mov eax, [VBE_MODE_INFO + 0x28]
    mov [SPL_LFB], eax
    mov ax, [VBE_MODE_INFO + 0x10]          ; BytesPerScanLine
    mov [SPL_PITCH], ax
    mov al, [VBE_MODE_INFO + 0x19]
    shr al, 3                               ; bytes per pixel (3 or 4)
    mov [SPL_BPP], al

    mov bx, [SPL_MODE]
    or bx, 0x4000                           ; use linear framebuffer
    mov ax, 0x4F02
    int 0x10
    cmp ax, 0x004F
    jne .done

    call enter_unreal                       ; fs/gs -> 4 GB flat

    ; destination = LFB + ((H - img_h) / 2) * pitch + ((W - img_w) / 2) * bpp
    mov esi, image_data
    movzx eax, word [SPL_WANT_Y]
    sub eax, img_height
    shr eax, 1
    movzx ebx, word [SPL_PITCH]
    mul ebx
    mov edi, [SPL_LFB]
    add edi, eax
    movzx eax, word [SPL_WANT_X]
    sub eax, img_width
    shr eax, 1
    movzx ebp, byte [SPL_BPP]
    mul ebp
    add edi, eax

    mov dx, img_height
.row:
    push edi
    mov cx, img_width
.pixel:
    mov al, [gs:esi]                        ; B (image_data is stored BGR)
    mov [fs:edi], al
    mov al, [gs:esi + 1]                    ; G
    mov [fs:edi + 1], al
    mov al, [gs:esi + 2]                    ; R
    mov [fs:edi + 2], al
    add esi, 3
    add edi, ebp
    dec cx
    jnz .pixel
    pop edi
    add edi, ebx
    dec dx
    jnz .row

    mov cx, 16                              ; show for ~2.4 s
.wait:
    call delay_150ms
    loop .wait
.done:
    popad
    ret

; Unreal mode: real mode + 4 GB limit on FS and GS
enter_unreal:
    cli
    lgdt [gdt32.pointer]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp .pm
.pm:
    mov ax, DATA_SEG32
    mov fs, ax
    mov gs, ax
    mov eax, cr0
    and al, 0xFE
    mov cr0, eax
    sti
    ret

run_terminal:
    call show_splash

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

FAT32_LBA           equ 2048
SECTOR_BUF          equ 0x5000
FAT_BUF             equ 0x5200

fat32_read_sector:
    push si
    push dx
    mov [FAT_DAP_LBA], eax
    mov [FAT_DAP_OFF], di
    mov si, FAT_DAP
    mov dl, [FAT_DRIVE]
    mov ah, 0x42
    int 0x13
    pop dx
    pop si
    ret

fat32_mount:
    mov eax, FAT32_LBA
    mov di, SECTOR_BUF
    call fat32_read_sector
    jc .fail
    cmp word [SECTOR_BUF + 510], 0xAA55
    jne .fail
    cmp word [SECTOR_BUF + 11], 512
    jne .fail
    cmp word [SECTOR_BUF + 17], 0
    jne .fail
    cmp word [SECTOR_BUF + 22], 0
    jne .fail
    mov al, [SECTOR_BUF + 13]
    test al, al
    jz .fail
    mov [FAT_SPC], al
    mov eax, [SECTOR_BUF + 44]
    cmp eax, 2
    jb .fail
    mov [FAT_ROOT], eax
    movzx eax, word [SECTOR_BUF + 14]
    add eax, FAT32_LBA
    mov [FAT_LBA], eax
    movzx ecx, byte [SECTOR_BUF + 16]
    mov edx, [SECTOR_BUF + 36]
    imul ecx, edx
    add eax, ecx
    mov [FAT_DATA], eax
    clc
    ret
.fail:
    stc
    ret

fat32_cluster_lba:
    sub eax, 2
    movzx ecx, byte [FAT_SPC]
    mul ecx
    add eax, [FAT_DATA]
    ret

fat32_next_cluster:
    push ebx
    push edi
    mov ebx, eax
    shr eax, 7
    add eax, [FAT_LBA]
    mov di, FAT_BUF
    call fat32_read_sector
    jc .err
    and ebx, 127
    mov eax, [FAT_BUF + ebx * 4]
    and eax, 0x0FFFFFFF
    jmp .out
.err:
    mov eax, 0x0FFFFFFF
.out:
    pop edi
    pop ebx
    ret

fat32_print_entry:
    pusha
    xor bh, bh
    mov di, si
    mov cx, 8
.name:
    lodsb
    cmp al, ' '
    je .name_done
    mov ah, 0x0E
    int 0x10
    loop .name
.name_done:
    lea si, [di + 8]
    cmp byte [si], ' '
    je .no_ext
    mov al, '.'
    mov ah, 0x0E
    int 0x10
    mov cx, 3
.ext:
    lodsb
    cmp al, ' '
    je .no_ext
    mov ah, 0x0E
    int 0x10
    loop .ext
.no_ext:
    test byte [di + 11], 0x10
    jz .file
    mov si, MSG_FAT_DIRTAG
    call print_string
    jmp .done
.file:
    mov si, MSG_FAT_SEP
    call print_string
    mov eax, [di + 28]
    call print_dec32
    mov si, MSG_FAT_BYTES
    call print_string
.done:
    popa
    ret

fat32_dir:
    pusha
    call fat32_mount
    jc .fail
    mov eax, [FAT_ROOT]
.next_cluster:
    mov [FAT_CUR], eax
    call fat32_cluster_lba
    mov [FAT_SEC], eax
    movzx eax, byte [FAT_SPC]
    mov [FAT_LEFT], eax
.next_sector:
    mov eax, [FAT_SEC]
    mov di, SECTOR_BUF
    call fat32_read_sector
    jc .fail
    mov si, SECTOR_BUF
    mov cx, 16
.entry:
    mov al, [si]
    cmp al, 0
    je .done
    cmp al, 0xE5
    je .skip
    mov al, [si + 11]
    and al, 0x3F
    cmp al, 0x0F
    je .skip
    test byte [si + 11], 0x08
    jnz .skip
    call fat32_print_entry
.skip:
    add si, 32
    loop .entry
    inc dword [FAT_SEC]
    dec dword [FAT_LEFT]
    jnz .next_sector
    mov eax, [FAT_CUR]
    call fat32_next_cluster
    cmp eax, 2
    jb .done
    cmp eax, 0x0FFFFFF8
    jb .next_cluster
.done:
    popa
    ret
.fail:
    mov si, MSG_FAT_ERR
    call print_string
    popa
    ret

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

MSG_WELCOME         db "Welcome to NXBoot Terminal!", 13, 10, 0
MSG_WELCOME_HINT    db 'Type "help" to see list of all commands.', 13, 10, 0
MSG_PROMPT          db "NXBoot>", 0
MSG_HELP            db "Available commands:", 13, 10
                    db "  help          - shows this help message", 13, 10
                    db "  boot [file]   - boots the system from the given file", 13, 10
                    db "  dir           - lists files in the FAT32 root directory", 13, 10
                    db "  exit          - reboots your machine", 13, 10
                    db "  time          - shows the current time", 13, 10
                    db "  shutdown      - shuts down your machine", 13, 10
                    db "  about         - shows info about the bootloader and the terminal", 13, 10
                    db "  sysinf        - shows your current system specification", 13, 10, 0
MSG_UNKNOWN         db "Unknown command. Type 'help' for a list of commands.", 13, 10, 0
MSG_BOOT_USAGE      db "Usage: boot [file]", 13, 10, 0
MSG_BOOTING1        db "Booting from ", 0
MSG_BOOTING2        db "... file loading is not wired up yet.", 13, 10, 0

MSG_ABOUT           db "NXBoot v0.6 Beta. A bootloader made by Nixel Tech community for NixelOS.", 13, 10
                    db "Build date:2026.10.15", 13, 10
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
CMD_DIR             db "dir", 0

FAT_DRIVE           db 0
FAT_SPC             db 0
FAT_ROOT            dd 0
FAT_LBA             dd 0
FAT_DATA            dd 0
FAT_CUR             dd 0
FAT_SEC             dd 0
FAT_LEFT            dd 0
FAT_DAP             db 0x10, 0
                    dw 1
FAT_DAP_OFF         dw 0
                    dw 0
FAT_DAP_LBA         dd 0
                    dd 0
MSG_FAT_ERR         db "FAT32 volume not found or unreadable.", 13, 10, 0
MSG_FAT_DIRTAG      db "  <DIR>", 13, 10, 0
MSG_FAT_SEP         db "  ", 0
MSG_FAT_BYTES       db " bytes", 13, 10, 0

SPLASH_TARGETS      dw 640, 384
                    dw 640, 400
                    dw 640, 480
                    dw 800, 600
                    dw 0
SPL_LIST_SEG        dw 0
SPL_LIST_OFF        dw 0
SPL_TARGET          dw 0
SPL_WANT_X          dw 0
SPL_WANT_Y          dw 0
SPL_MODE            dw 0
SPL_PITCH           dw 0
SPL_BPP             db 0
SPL_LFB             dd 0

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

; Splash picture (must stay last: it is addressed through 32-bit FS/GS)
%include "image_data.inc"

times ((512 - (($ - $$) % 512)) % 512) db 0
