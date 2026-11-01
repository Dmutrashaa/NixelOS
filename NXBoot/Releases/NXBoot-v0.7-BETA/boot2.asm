[BITS 16]
[ORG 0x8000]

LOW_SECTORS         equ 64
HIGH_BASE           equ 0x100000
KERNEL_BASE_DEF     equ 0x100000
ELF_HDR             equ 0x6400
ELF_PH              equ 0x6440
BOOT_INFO           equ 0x6B80
BOOT_MAGIC          equ 0x5442584E
BOOT_STACK          equ 0x90000
CLOSE_PAUSE_STEPS   equ 4
BOOT_PAUSE_STEPS    equ 4
EARLY_TERM_STEPS    equ 8
DLG_X               equ 19
DLG_Y               equ 9
DLG_W               equ 42
DLG_H               equ 7
DLG_ATTR            equ 0x1F
DLG_ATTR_SEL        equ 0xF1
DLG_SAVE            equ 0x3000
LOG_BUF             equ 0x3400
LOG_MAX             equ 3072
EV_PAGE             equ 0x1000
EV_X                equ 7
EV_Y                equ 3
EV_W                equ 66
EV_H                equ 17
EV_LOG_Y            equ 9
EV_LOG_H            equ 10
EV_LOG_X            equ 9
EV_LOG_W            equ 60
EV_BAR_X            equ 71
EV_TRACK            equ 8
MB_SEG              equ 0x2000
MB_TAB              equ 0x1000
MB_MAX              equ 16
MB_ENT              equ 104
MB_ARGOFF           equ 40
MB_NAME_MAX         equ 39
MB_ARG_MAX          equ 63
MB_FILE_MAX         equ 4095
MB_VIS              equ 8
MB_X                equ 10
MB_W                equ 60
MB_ATTR             equ 0x1F
MB_ATTR_SEL         equ 0x70
%define IMG_END (HIGH_BASE + (image_end - image_blob))

%include "anim_info.inc"
ANIM_GAP            equ 128
ANIM_INF_LOOPS      equ 2
ANIM_FRAME_BYTES    equ ANIM_W * ANIM_H * 3
PIT_FRAME_CLOCKS    equ 19886
PIT_FRAME_REM       equ 22

stage2_start:
    mov [FAT_DRIVE], dl
    cli
    mov ax, 0x0003
    int 0x10
    sti

    call sysinfo_cache

    call check_memory
    jc .no_ram

    call check_cpuid
    jc .bad_cpu

    call check_long_mode
    jc .bad_cpu

    mov si, MSG_CANNOT_BOOT
    mov cx, MSG_CANNOT_BOOT_LEN
    jmp early_gate

.no_ram:
    mov si, MSG_NO_RAM
    mov cx, MSG_NO_RAM_LEN
    jmp early_gate

.bad_cpu:
    mov si, MSG_BAD_CPU
    mov cx, MSG_BAD_CPU_LEN
    jmp early_gate

early_gate:
    mov [ERR_PTR], si
    mov [ERR_LEN], cx
    push si
    push cx
    ; no hint text any more: a blinking text cursor at the top-left corner
    ; while the (hidden) T key is polled
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    mov ah, 0x02
    xor bx, bx
    xor dx, dx
    int 0x10
    mov cx, EARLY_TERM_STEPS
.poll:
    mov ah, 0x01
    int 0x16
    jz .nokey
    xor ax, ax
    int 0x16
    cmp al, 'T'
    je .term
    cmp al, 't'
    je .term
.nokey:
    call delay_150ms
    loop .poll
    pop cx
    pop si
    mov ax, 0x0003
    int 0x10
    jmp show_error
.term:
    add sp, 4
    jmp run_terminal

check_memory:
    cmp byte [RAM_DONE], 0
    jne .have
    call detect_ram
.have:
    cmp dword [SYS_RAM_KB], 3072
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
    mov [ERR_PTR], si
    mov [ERR_LEN], cx
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
    cmp al, 'T'
    je .open_term
    cmp al, 't'
    je .open_term
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
    mov al, 1
    call rm_confirm
    test al, al
    jz .wait_key
    call do_reboot
    cli
    hlt
    jmp $
.confirm_shutdown:
    mov al, 0
    call rm_confirm
    test al, al
    jz .wait_key
    call do_shutdown
    cli
    hlt
    jmp $
.open_term:
    jmp run_terminal

; ---- confirmation dialog (rm): AL = 0 shut down / 1 restart; returns AL = 1 (Yes) or 0 (No)
rm_confirm:
    mov [DLG_KIND], al
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es
    mov ax, 0xB800
    mov es, ax
    mov byte [DLG_SEL], 1
    call rm_dlg_hw_on
    call rm_dlg_save
    call rm_dlg_draw
.loop:
    call rm_dlg_buttons
    call rm_dlg_key
    cmp al, 1
    je .left
    cmp al, 2
    je .right
    cmp al, 3
    je .done
    cmp al, 4
    je .esc
    jmp .loop
.left:
    mov byte [DLG_SEL], 0
    jmp .loop
.right:
    mov byte [DLG_SEL], 1
    jmp .loop
.esc:
    mov byte [DLG_SEL], 1
.done:
    call rm_dlg_restore
    call rm_dlg_hw_off
    pop es
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    mov al, 1
    cmp byte [DLG_SEL], 0
    je .ret
    xor al, al
.ret:
    ret

rm_dlg_hw_on:
    push eax
    push edx
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    in al, dx
    mov [DLG_CUR], al
    or al, 0x20
    out dx, al
    mov dx, 0x3DA
    in al, dx
    mov dx, 0x3C0
    mov al, 0x30
    out dx, al
    inc dx
    in al, dx
    and al, 0xF7
    dec dx
    out dx, al
    pop edx
    pop eax
    ret

rm_dlg_hw_off:
    push eax
    push edx
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    mov al, [DLG_CUR]
    out dx, al
    pop edx
    pop eax
    ret

rm_dlg_save:
    mov esi, DLG_SAVE
    mov ebx, (DLG_Y * 80 + DLG_X) * 2
    mov edx, DLG_H
.row:
    mov edi, ebx
    mov ecx, DLG_W
.col:
    mov ax, [es:edi]
    mov [esi], ax
    add esi, 2
    add edi, 2
    dec ecx
    jnz .col
    add ebx, 160
    dec edx
    jnz .row
    ret

rm_dlg_restore:
    mov esi, DLG_SAVE
    mov ebx, (DLG_Y * 80 + DLG_X) * 2
    mov edx, DLG_H
.row:
    mov edi, ebx
    mov ecx, DLG_W
.col:
    mov ax, [esi]
    mov [es:edi], ax
    add esi, 2
    add edi, 2
    dec ecx
    jnz .col
    add ebx, 160
    dec edx
    jnz .row
    ret

rm_dlg_row:
    push edi
    push ecx
    mov [es:edi], al
    mov byte [es:edi+1], DLG_ATTR
    add edi, 2
    mov ecx, DLG_W - 2
.fill:
    mov [es:edi], ah
    mov byte [es:edi+1], DLG_ATTR
    add edi, 2
    dec ecx
    jnz .fill
    mov [es:edi], dl
    mov byte [es:edi+1], DLG_ATTR
    pop ecx
    pop edi
    ret

rm_dlg_draw:
    mov edi, (DLG_Y * 80 + DLG_X) * 2
    mov al, 0xC9
    mov ah, 0xCD
    mov dl, 0xBB
    call rm_dlg_row
    mov ecx, DLG_H - 2
.mid:
    add edi, 160
    mov al, 0xBA
    mov ah, ' '
    mov dl, 0xBA
    call rm_dlg_row
    dec ecx
    jnz .mid
    add edi, 160
    mov al, 0xC8
    mov ah, 0xCD
    mov dl, 0xBC
    call rm_dlg_row
    mov esi, DLG_TXT_SHUT
    cmp byte [DLG_KIND], 0
    je .txt
    mov esi, DLG_TXT_REBOOT
.txt:
    mov ebx, ((DLG_Y + 2) * 80 + DLG_X + 1) * 2
    mov edx, 2
.line:
    mov edi, ebx
    mov ecx, DLG_W - 2
.ch:
    mov al, [esi]
    mov [es:edi], al
    inc esi
    add edi, 2
    dec ecx
    jnz .ch
    add ebx, 160
    dec edx
    jnz .line
    ret

rm_dlg_btn:
    push eax
    push esi
    push edi
.next:
    mov al, [esi]
    test al, al
    jz .done
    mov [es:edi], al
    mov [es:edi+1], bl
    inc esi
    add edi, 2
    jmp .next
.done:
    pop edi
    pop esi
    pop eax
    ret

rm_dlg_buttons:
    mov bl, DLG_ATTR
    cmp byte [DLG_SEL], 0
    jne .yes
    mov bl, DLG_ATTR_SEL
.yes:
    mov esi, DLG_STR_YES
    mov edi, ((DLG_Y + DLG_H - 1) * 80 + DLG_X + 9) * 2
    call rm_dlg_btn
    mov bl, DLG_ATTR
    cmp byte [DLG_SEL], 1
    jne .no
    mov bl, DLG_ATTR_SEL
.no:
    mov esi, DLG_STR_NO
    mov edi, ((DLG_Y + DLG_H - 1) * 80 + DLG_X + 27) * 2
    call rm_dlg_btn
    ret

rm_dlg_key:
    xor ax, ax
    int 0x16
    cmp ah, 0x4B
    je .left
    cmp ah, 0x4D
    je .right
    cmp al, 0x0D
    je .enter
    cmp al, 0x1B
    je .esc
    xor al, al
    ret
.left:
    mov al, 1
    ret
.right:
    mov al, 2
    ret
.enter:
    mov al, 3
    ret
.esc:
    mov al, 4
    ret
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

sysinfo_cache:
    pushad
    call detect_ram
    mov byte [SYS_CPU64], 0
    mov byte [SYS_CANRUN], 0
    call check_cpuid
    jc .done
    call check_long_mode
    jc .done
    mov byte [SYS_CPU64], 1
    call check_memory
    jc .done
    mov byte [SYS_CANRUN], 1
.done:
    popad
    ret

; ---------------------------------------------------------------------------
; RAM detection that is not limited to 64 MB: INT 15h E820 -> E801 -> 88h.
;   SYS_RAM_KB  = usable KB above the first MB (also counts RAM above 4 GB)
;   SYS_RAM_TOP = end of the usable block that starts at 1 MB (clipped to 4 GB)
;   SYS_RAM_MB  = total usable RAM in MB (rounded)
; ---------------------------------------------------------------------------
detect_ram:
    pushad
    push es
    xor ax, ax
    mov es, ax
    mov dword [SYS_RAM_KB], 0
    mov dword [SYS_RAM_TOP], 0x100000
    mov byte [RAM_E820_OK], 0
    mov word [RAM_E820_CNT], 0
    xor ebx, ebx
.e820:
    mov dword [E820_ENT + 20], 1
    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 24
    mov di, E820_ENT
    int 0x15
    jc .e820_end
    cmp eax, 0x534D4150
    jne .e820_end
    cmp ecx, 20
    jb .e820_skip
    mov byte [RAM_E820_OK], 1
    cmp dword [E820_ENT + 16], 1
    jne .e820_skip
    cmp ecx, 20
    je .e820_use
    test byte [E820_ENT + 20], 1
    jz .e820_skip
.e820_use:
    mov eax, [E820_ENT]
    mov edx, [E820_ENT + 8]
    cmp dword [E820_ENT + 4], 0
    jne .e820_high
    cmp dword [E820_ENT + 12], 0
    je .e820_len
    mov edx, 0xFFFFFFFF
.e820_len:
    mov ecx, eax
    add ecx, edx
    jnc .e820_end_ok
    mov ecx, 0xFFFFFFFF
.e820_end_ok:
    cmp ecx, 0x100000
    jbe .e820_skip
    cmp eax, 0x100000
    jae .e820_base_ok
    mov eax, 0x100000
.e820_base_ok:
    mov edx, ecx
    sub edx, eax
    shr edx, 10
    add [SYS_RAM_KB], edx
    cmp eax, [SYS_RAM_TOP]
    ja .e820_skip
    cmp ecx, [SYS_RAM_TOP]
    jbe .e820_skip
    mov [SYS_RAM_TOP], ecx
    jmp .e820_skip
.e820_high:
    mov eax, [E820_ENT + 12]
    shl eax, 22
    mov edx, [E820_ENT + 8]
    shr edx, 10
    or eax, edx
    add [SYS_RAM_KB], eax
.e820_skip:
    inc word [RAM_E820_CNT]
    cmp word [RAM_E820_CNT], 128
    jae .e820_end
    test ebx, ebx
    jnz .e820
.e820_end:
    cmp byte [RAM_E820_OK], 0
    je .try_e801
    cmp dword [SYS_RAM_KB], 0
    jne .final
.try_e801:
    mov dword [SYS_RAM_KB], 0
    mov dword [SYS_RAM_TOP], 0x100000
    xor cx, cx
    xor dx, dx
    mov ax, 0xE801
    int 0x15
    jc .try_88
    test ax, ax
    jnz .e801_have
    mov ax, cx
    mov bx, dx
.e801_have:
    movzx eax, ax
    movzx ebx, bx
    shl ebx, 6
    add eax, ebx
    jmp .legacy_set
.try_88:
    mov ah, 0x88
    int 0x15
    jc .final
    movzx eax, ax
.legacy_set:
    mov [SYS_RAM_KB], eax
    cmp eax, 0x3FFC00
    jae .legacy_clip
    shl eax, 10
    add eax, 0x100000
    mov [SYS_RAM_TOP], eax
    jmp .final
.legacy_clip:
    mov dword [SYS_RAM_TOP], 0xFFFFFFFF
.final:
    mov eax, [SYS_RAM_KB]
    add eax, 1024 + 512
    shr eax, 10
    mov [SYS_RAM_MB], eax
    mov byte [RAM_DONE], 1
    pop es
    popad
    ret

show_sysinfo:
    pusha
    mov al, [TERM_ATTR]
    mov [SYSI_ATTR], al
    mov si, SYSI_STREAM
    call sysi_run16
    popa
    ret

; Renders a "styled stream" (see SYSI_STREAM) in real mode.
; Codes: 0 end, 1 <attr> colour, 2 RAM (MB), 3 CPU, 4 NOS verdict, 5 mode name,
; 13/10 new line (colour back to default), anything else is a plain character.
sysi_run16:
    push ax
    push bx
    push si
.next:
    lodsb
    test al, al
    jz .end
    cmp al, 1
    je .attr
    cmp al, 2
    je .ram
    cmp al, 3
    je .cpu
    cmp al, 4
    je .nos
    cmp al, 5
    je .mode
    cmp al, 13
    je .nl
    cmp al, 10
    je .nl
    call sysi_putc16
    jmp .next
.attr:
    lodsb
    mov [SYSI_ATTR], al
    jmp .next
.nl:
    push bx
    xor bx, bx
    mov ah, 0x0E
    int 0x10
    pop bx
    mov ah, [TERM_ATTR]
    mov [SYSI_ATTR], ah
    jmp .next
.ram:
    mov eax, [SYS_RAM_MB]
    call sysi_dec16
    jmp .next
.cpu:
    mov bx, SYSI_CPU64
    cmp byte [SYS_CPU64], 0
    jne .sub
    mov bx, SYSI_CPU32
    jmp .sub
.nos:
    mov bx, SYSI_NOS_OK
    cmp byte [SYS_CANRUN], 0
    jne .sub
    mov bx, SYSI_NOS_NO
    jmp .sub
.mode:
    movzx bx, byte [CUR_MODE]
    shl bx, 1
    mov bx, [SYSI_MODE_TAB + bx]
.sub:
    push si
    mov si, bx
    call sysi_run16
    pop si
    jmp .next
.end:
    pop si
    pop bx
    pop ax
    ret

; AL = character, drawn with the colour in SYSI_ATTR; the cursor moves on
sysi_putc16:
    push ax
    push bx
    push cx
    mov [SYSI_CH], al
    mov bl, [SYSI_ATTR]
    xor bh, bh
    mov cx, 1
    mov ah, 0x09
    int 0x10
    mov al, [SYSI_CH]
    mov ah, 0x0E
    int 0x10
    pop cx
    pop bx
    pop ax
    ret

; EAX = number, printed in decimal with the colour in SYSI_ATTR
sysi_dec16:
    pushad
    mov ebx, 10
    xor ecx, ecx
.div:
    xor edx, edx
    div ebx
    push dx
    inc cx
    test eax, eax
    jnz .div
.out:
    pop dx
    mov al, dl
    add al, '0'
    call sysi_putc16
    loop .out
    popad
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

    mov si, INPUT_BUF
    mov di, CMD_CD
    call match_cmd
    jc .do_cd

    mov si, INPUT_BUF
    mov di, CMD_TYPE
    call match_cmd
    jc .do_type

    mov si, INPUT_BUF
    mov di, CMD_REMODE
    call match_cmd
    jc .do_remode

    mov si, INPUT_BUF
    mov di, CMD_CLOSE
    call match_cmd
    jc .do_close

    mov si, INPUT_BUF
    mov di, CMD_COLOR
    call match_cmd
    jc .do_color

    mov si, INPUT_BUF
    mov di, CMD_MULTIBOOT
    call match_cmd
    jc .do_multiboot

    mov si, MSG_UNKNOWN
    call print_string
    ret

.do_help:
    mov si, MSG_HELP
    call print_string
    ret

.do_exit:
    mov al, 1
    call rm_confirm
    test al, al
    jz .ret
    call do_reboot
    cli
    hlt
    jmp $

.do_time:
    call show_time
    ret

.do_boot:
    call boot_cmd
    ret

.do_multiboot:
    call skip_spaces
    call multiboot_cmd
    ret

.do_shutdown:
    mov al, 0
    call rm_confirm
    test al, al
    jz .ret
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

.do_cd:
    call skip_spaces
    call fat32_cd
    ret

.do_type:
    call skip_spaces
    call fat32_type
    ret

.do_remode:
    call skip_spaces
    call remode_cmd
    ret

.do_close:
    jmp close_terminal

.do_color:
    call skip_spaces
    call color_cmd
    ret

.ret:
    ret

VBE_INFO        equ 0x6000
VBE_MODE_INFO   equ 0x6200
SPLASH_TOLERANCE equ 16

show_splash:
    pushad
    push es
    push ds
    xor ax, ax
    mov es, ax
    mov ds, ax

    mov di, VBE_INFO
    mov ax, 0x4F00
    int 0x10
    cmp ax, 0x004F
    jne .novbe
    cmp dword [VBE_INFO], 0x41534556
    jne .novbe

    mov ax, [VBE_INFO + 0x10]
    mov [SPL_LIST_SEG], ax
    mov ax, [VBE_INFO + 0x0E]
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
    mov ax, [VBE_MODE_INFO]
    and ax, 0x0091
    cmp ax, 0x0091
    jne .mode_loop
    mov ax, [VBE_MODE_INFO + 0x12]
    mov bx, [SPL_WANT_X]
    sub bx, ax
    jc .mode_loop
    cmp bx, SPLASH_TOLERANCE
    ja .mode_loop
    mov ax, [VBE_MODE_INFO + 0x14]
    mov bx, [SPL_WANT_Y]
    sub bx, ax
    jc .mode_loop
    cmp bx, SPLASH_TOLERANCE
    ja .mode_loop
    mov eax, [VBE_MODE_INFO + 0x28]
    test eax, eax
    jz .mode_loop
    mov al, [VBE_MODE_INFO + 0x19]
    cmp al, 32
    jne .mode_loop

    mov ax, [VBE_MODE_INFO + 0x12]
    mov [SPL_WANT_X], ax
    mov ax, [VBE_MODE_INFO + 0x14]
    mov [SPL_WANT_Y], ax
    mov eax, [VBE_MODE_INFO + 0x28]
    mov [SPL_LFB], eax
    mov ax, [VBE_MODE_INFO + 0x10]
    mov [SPL_PITCH], ax
    mov al, [VBE_MODE_INFO + 0x19]
    shr al, 3
    mov [SPL_BPP], al

    mov bx, [SPL_MODE]
    or bx, 0x4000
    mov ax, 0x4F02
    int 0x10
    cmp ax, 0x004F
    jne .done

    call enter_unreal

    mov esi, HIGH_BASE + (image_data - image_blob)
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
    mov al, [gs:esi]
    mov [fs:edi], al
    mov al, [gs:esi + 1]
    mov [fs:edi + 1], al
    mov al, [gs:esi + 2]
    mov [fs:edi + 2], al
    add esi, 3
    add edi, ebp
    dec cx
    jnz .pixel
    pop edi
    add edi, ebx
    dec dx
    jnz .row

    call anim_play
    jnc .done
    mov cx, 16
.wait:
    call delay_150ms
    loop .wait
.done:
    pop ds
    pop es
    popad
    ret

.novbe:
    mov si, SPL_MSG_NOVBE
    call print_string
    xor ax, ax
    int 0x16
    jmp .done

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

; ---------------------------------------------------------------------------
; Boot animation (below the splash): START once, then INFINITE x ANIM_INF_LOOPS
; 60 FPS, paced by PIT channel 0 (1193182 Hz / 60 = 19886.37 clocks per frame).
; Called from show_splash after the splash is drawn. Returns CF=0 if played,
; CF=1 if skipped (not enough RAM / not enough screen) - caller then does the
; old fixed pause.
; ---------------------------------------------------------------------------
anim_play:
    pushad

    ; enough RAM for the whole blob? (cached E820/E801 detection: no 16/64 MB limit)
    mov eax, [SYS_RAM_TOP]
    cmp eax, IMG_END
    jb .skip

    ; destination: centred horizontally, ANIM_GAP below the splash
    movzx eax, word [SPL_WANT_Y]
    sub eax, img_height
    shr eax, 1
    add eax, img_height + ANIM_GAP
    lea ecx, [eax + ANIM_H]
    movzx edx, word [SPL_WANT_Y]
    cmp ecx, edx
    ja .skip
    movzx ebx, word [SPL_PITCH]
    mul ebx
    mov edi, [SPL_LFB]
    add edi, eax
    movzx eax, word [SPL_WANT_X]
    sub eax, ANIM_W
    shr eax, 1
    shl eax, 2
    add edi, eax
    mov [ANIM_DST], edi

    ; no interrupts from here on: no ISR can touch FS/GS, and the timing is ours
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

    ; PIT channel 0 -> mode 2 (rate generator), count 65536: same 18.2 Hz IRQ
    ; rate as the BIOS default, but the counter decrements by exactly 1
    mov al, 0x34
    out 0x43, al
    xor al, al
    out 0x40, al
    out 0x40, al
    call pit_read
    mov [ANIM_LAST], ax
    mov dword [ANIM_NOW], 0
    mov dword [ANIM_DEADLINE], 0
    mov word [ANIM_REM], 0

    mov esi, HIGH_BASE + (anim_start - image_blob)
    mov ecx, ANIM_START_FRAMES
    call anim_run

    mov word [ANIM_LOOPS_LEFT], ANIM_INF_LOOPS
.inf:
    mov esi, HIGH_BASE + (anim_inf - image_blob)
    mov ecx, ANIM_INF_FRAMES
    call anim_run
    dec word [ANIM_LOOPS_LEFT]
    jnz .inf

    ; PIT back to the BIOS default (mode 3), give the BIOS tick counter the
    ; ticks it missed while interrupts were off
    mov al, 0x36
    out 0x43, al
    xor al, al
    out 0x40, al
    out 0x40, al
    call pit_update
    mov eax, [ANIM_NOW]
    shr eax, 16
    add [0x046C], eax
    sti
    popad
    clc
    ret

.skip:
    popad
    stc
    ret

; ESI = first frame (linear address), ECX = frame count (>0)
anim_run:
.frame:
    call anim_wait
    call anim_advance
    push ecx
    push esi
    call anim_draw_frame
    pop esi
    pop ecx
    add esi, ANIM_FRAME_BYTES
    dec ecx
    jnz .frame
    ret

; copy one 24bpp frame (ESI) to the 32bpp framebuffer at [ANIM_DST]
anim_draw_frame:
    push ebx
    push edi
    mov edi, [ANIM_DST]
    movzx ebx, word [SPL_PITCH]
    mov edx, ANIM_H
.row:
    push edi
    mov ecx, ANIM_W
.px:
    mov eax, [gs:esi]
    and eax, 0x00FFFFFF
    mov [fs:edi], eax
    add esi, 3
    add edi, 4
    dec ecx
    jnz .px
    pop edi
    add edi, ebx
    call pit_update
    dec edx
    jnz .row
    pop edi
    pop ebx
    ret

; AX = PIT channel 0 current count (counts down)
pit_read:
    xor al, al
    out 0x43, al
    in al, 0x40
    mov ah, al
    in al, 0x40
    xchg al, ah
    ret

; ANIM_NOW += PIT clocks since the last call (must run at least every ~50 ms)
pit_update:
    push eax
    push edx
    call pit_read
    mov dx, [ANIM_LAST]
    mov [ANIM_LAST], ax
    sub dx, ax
    movzx edx, dx
    add [ANIM_NOW], edx
    pop edx
    pop eax
    ret

anim_wait:
    push eax
.poll:
    call pit_update
    mov eax, [ANIM_NOW]
    cmp eax, [ANIM_DEADLINE]
    jb .poll
    pop eax
    ret

; next frame time = +19886.37 PIT clocks (integer part + 22/60 remainder)
anim_advance:
    push eax
    add dword [ANIM_DEADLINE], PIT_FRAME_CLOCKS
    mov ax, [ANIM_REM]
    add ax, PIT_FRAME_REM
    cmp ax, 60
    jb .keep
    sub ax, 60
    inc dword [ANIM_DEADLINE]
.keep:
    mov [ANIM_REM], ax
    pop eax
    ret

ANIM_DST            dd 0
ANIM_NOW            dd 0
ANIM_DEADLINE       dd 0
ANIM_LAST           dw 0
ANIM_REM            dw 0
ANIM_LOOPS_LEFT     dw 0


; ---------------------------------------------------------------------------
; Deferred load of the splash image + boot animation.
; Stage 1 now reads only the code part of stage 2 (LOW_SECTORS), so NXBoot
; reaches its first screen at once instead of waiting for the whole blob.
; The blob (everything after the low part of boot2.bin) is read here, the first
; time the splash is needed, straight to HIGH_BASE through a 32 KB bounce
; buffer at 0x10000. CF=0: blob is in memory, CF=1: not loaded (skip splash).
; ---------------------------------------------------------------------------
BLOB_BOUNCE_SEG     equ 0x1000
BLOB_BOUNCE_LIN     equ BLOB_BOUNCE_SEG * 16
BLOB_CHUNK          equ 64

blob_load:
    cmp byte [BLOB_LOADED], 0
    je .go
    clc
    ret
.go:
    pushad
    push ds
    push es
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ebx, image_end - image_blob
    mov eax, [SYS_RAM_TOP]
    sub eax, HIGH_BASE
    cmp eax, ebx
    jae .fits
    mov ebx, eax
    and ebx, 0xFFFFFE00
.fits:
    cmp ebx, anim_blob - image_blob
    jb .fail
    add ebx, 511
    shr ebx, 9
    mov [BLOB_LEFT], ebx
    mov [BLOB_TOTAL], ebx
    mov dword [BLOB_LBA], 1 + LOW_SECTORS
    mov dword [BLOB_DEST], HIGH_BASE

.chunk:
    mov eax, [BLOB_LEFT]
    test eax, eax
    jz .done
    cmp eax, BLOB_CHUNK
    jbe .count_ok
    mov eax, BLOB_CHUNK
.count_ok:
    mov [BLOB_DAP_COUNT], ax
    mov eax, [BLOB_LBA]
    mov [BLOB_DAP_LBA], eax
    mov byte [BLOB_TRIES], 3
.read:
    mov si, BLOB_DAP
    mov dl, [FAT_DRIVE]
    mov ah, 0x42
    int 0x13
    jnc .read_ok
    xor ax, ax
    mov dl, [FAT_DRIVE]
    int 0x13
    dec byte [BLOB_TRIES]
    jnz .read
    jmp .fail
.read_ok:
    call enter_unreal
    movzx ecx, word [BLOB_DAP_COUNT]
    mov esi, BLOB_BOUNCE_LIN
    mov edi, [BLOB_DEST]
    shl ecx, 5
.copy:
    mov eax, [gs:esi]
    mov edx, [gs:esi + 4]
    mov [fs:edi], eax
    mov [fs:edi + 4], edx
    mov eax, [gs:esi + 8]
    mov edx, [gs:esi + 12]
    mov [fs:edi + 8], eax
    mov [fs:edi + 12], edx
    add esi, 16
    add edi, 16
    dec ecx
    jnz .copy
    mov [BLOB_DEST], edi
    movzx eax, word [BLOB_DAP_COUNT]
    add [BLOB_LBA], eax
    sub [BLOB_LEFT], eax
    jmp .chunk

.done:
    mov byte [BLOB_LOADED], 1
    clc
    jmp .out
.fail:
    stc
.out:
    pop es
    pop ds
    popad
    ret

BLOB_LOADED         db 0
BLOB_TRIES          db 0
BLOB_LEFT           dd 0
BLOB_TOTAL          dd 0
BLOB_LBA            dd 0
BLOB_DEST           dd 0
BLOB_DAP            db 0x10, 0
BLOB_DAP_COUNT      dw 0
                    dw 0
                    dw BLOB_BOUNCE_SEG
BLOB_DAP_LBA        dd 0
                    dd 0


run_terminal:
    cmp byte [IMG_DAMAGED], 0
    jne .no_splash
    call blob_load
    jc .no_splash
    call show_splash
.no_splash:
    mov ax, 0x0003
    int 0x10

    mov si, MSG_WELCOME
    mov bl, 0x0F
    call print_attr

    mov si, MSG_WELCOME_HINT
    mov bl, 0x07
    call print_attr

terminal_loop:
    call apply_color
    mov si, MSG_PROMPT
    call print_string
    call read_line
    call handle_command
    call print_gap
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

FAT32_LBA           equ 8192
SECTOR_BUF          equ 0x5000
FAT_BUF             equ 0x5200
LFN_BUF             equ 0x5400

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
    xor eax, eax
    mov di, SECTOR_BUF
    call fat32_read_sector
    jc .fail
    mov dword [FAT_PART], FAT32_LBA
    cmp word [SECTOR_BUF + 510], 0xAA55
    jne .read_bpb
    mov bx, SECTOR_BUF + 446
    mov cx, 4
.part:
    mov al, [bx + 4]
    cmp al, 0x0B
    je .found_part
    cmp al, 0x0C
    je .found_part
    add bx, 16
    loop .part
    jmp .read_bpb
.found_part:
    mov eax, [bx + 8]
    test eax, eax
    jz .read_bpb
    mov [FAT_PART], eax
.read_bpb:
    mov eax, [FAT_PART]
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
    cmp dword [SECTOR_BUF + 82], 0x33544146
    jne .fail
    cmp byte [SECTOR_BUF + 86], '2'
    jne .fail
    mov al, [SECTOR_BUF + 13]
    test al, al
    jz .fail
    mov bl, al
    dec bl
    test al, bl
    jnz .fail
    mov [FAT_SPC], al
    cmp word [SECTOR_BUF + 14], 0
    je .fail
    cmp byte [SECTOR_BUF + 16], 0
    je .fail
    cmp dword [SECTOR_BUF + 36], 0
    je .fail
    mov eax, [SECTOR_BUF + 44]
    cmp eax, 2
    jb .fail
    mov [FAT_ROOT], eax
    movzx eax, word [SECTOR_BUF + 14]
    add eax, [FAT_PART]
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

fat32_ensure_mount:
    cmp byte [FAT_OK], 1
    je .ok
    call fat32_mount
    jc .fail
    mov byte [FAT_OK], 1
    mov eax, [FAT_ROOT]
    mov [FAT_CWD], eax
.ok:
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

fat32_lfn_collect:
    pusha
    mov al, [si]
    test al, 0x40
    jz .next
    and al, 0x1F
    jz .bad
    cmp al, 20
    ja .bad
    mov [LFN_SEQ], al
    mov ah, [si + 13]
    mov [LFN_CHK], ah
    mov byte [LFN_ACTIVE], 1
    mov bl, 13
    mul bl
    mov bx, ax
    mov byte [LFN_BUF + bx], 0
    jmp .store
.next:
    cmp byte [LFN_ACTIVE], 1
    jne .out
    cmp al, [LFN_SEQ]
    jne .bad
    mov ah, [si + 13]
    cmp ah, [LFN_CHK]
    jne .bad
.store:
    dec byte [LFN_SEQ]
    movzx ax, byte [LFN_SEQ]
    mov bl, 13
    mul bl
    mov di, ax
    add di, LFN_BUF
    mov bx, LFN_OFFS
    mov cx, 13
.char:
    push si
    movzx ax, byte [bx]
    add si, ax
    mov ax, [si]
    pop si
    inc bx
    test ax, ax
    jz .zero
    cmp ax, 0xFFFF
    je .zero
    cmp ax, 0x20
    jb .q
    cmp ax, 0x7F
    jb .put
.q:
    mov al, '?'
    jmp .put
.zero:
    xor al, al
.put:
    mov [di], al
    inc di
    loop .char
    jmp .out
.bad:
    mov byte [LFN_ACTIVE], 0
.out:
    popa
    ret

fat32_lfn_check:
    pusha
    mov byte [LFN_HAVE], 0
    cmp byte [LFN_ACTIVE], 1
    jne .out
    cmp byte [LFN_SEQ], 0
    jne .out
    xor al, al
    xor bx, bx
.sum:
    ror al, 1
    add al, [si + bx]
    inc bx
    cmp bx, 11
    jb .sum
    cmp al, [LFN_CHK]
    jne .out
    mov byte [LFN_HAVE], 1
.out:
    popa
    ret

fat32_lfn_match:
    push si
    push di
    push ax
    mov si, [FAT_ARG]
    mov di, LFN_BUF
.loop:
    lodsb
    call to_upper
    mov ah, al
    mov al, [di]
    inc di
    call to_upper
    cmp al, ah
    jne .no
    test al, al
    jnz .loop
    stc
    jmp .out
.no:
    clc
.out:
    pop ax
    pop di
    pop si
    ret

fat32_prepare_name:
    push ax
    push bx
    push dx
    push si
    mov [FAT_ARG], si
    mov bx, si
.end:
    cmp byte [bx], 0
    je .trim
    inc bx
    jmp .end
.trim:
    cmp bx, si
    je .scan
    cmp byte [bx - 1], ' '
    jne .scan
    dec bx
    mov byte [bx], 0
    jmp .trim
.scan:
    mov byte [FAT_SHORT_OK], 0
    xor dl, dl
    mov bx, si
.chk:
    mov al, [bx]
    test al, al
    jz .scanned
    cmp al, ' '
    jne .nospace
    mov dl, 1
.nospace:
    push si
    mov si, LFN_BAD
.bad_loop:
    mov ah, [si]
    test ah, ah
    jz .bad_done
    cmp al, ah
    je .invalid
    inc si
    jmp .bad_loop
.bad_done:
    pop si
    inc bx
    jmp .chk
.invalid:
    pop si
    stc
    jmp .out
.scanned:
    test dl, dl
    jnz .ok
    call fat32_parse_name
    jc .ok
    mov byte [FAT_SHORT_OK], 1
.ok:
    clc
.out:
    pop si
    pop dx
    pop bx
    pop ax
    ret

fat32_print_entry:
    pusha
    xor bh, bh
    mov di, si
    cmp byte [LFN_HAVE], 1
    jne .short_name
    mov si, LFN_BUF
.lfn:
    lodsb
    test al, al
    jz .no_ext
    mov ah, 0x0E
    int 0x10
    jmp .lfn
.short_name:
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
    call fat32_ensure_mount
    jc .fail
    mov byte [LFN_ACTIVE], 0
    mov eax, [FAT_CWD]
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
    je .deleted
    mov al, [si + 11]
    and al, 0x3F
    cmp al, 0x0F
    jne .notlfn
    call fat32_lfn_collect
    jmp .skip
.notlfn:
    test byte [si + 11], 0x08
    jnz .deleted
    call fat32_lfn_check
    call fat32_print_entry
.deleted:
    mov byte [LFN_ACTIVE], 0
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
    cmp eax, 0x0FFFFFF7
    jb .next_cluster
.done:
    popa
    ret
.fail:
    mov si, MSG_FAT_ERR
    call print_string
    popa
    ret

skip_spaces:
    cmp byte [si], ' '
    jne .ret
    inc si
    jmp skip_spaces
.ret:
    ret

to_upper:
    cmp al, 'a'
    jb .ret
    cmp al, 'z'
    ja .ret
    sub al, 0x20
.ret:
    ret

fat32_parse_name:
    push ax
    push cx
    push di
    push si
    mov di, FAT_NAME
    mov cx, 11
    mov al, ' '
    rep stosb
    mov di, FAT_NAME
    cmp byte [si], '.'
    jne .base_start
    cmp byte [si + 1], 0
    je .dot1
    cmp byte [si + 1], ' '
    je .dot1
    cmp byte [si + 1], '.'
    jne .bad
    cmp byte [si + 2], 0
    je .dot2
    cmp byte [si + 2], ' '
    jne .bad
.dot2:
    mov byte [FAT_NAME + 1], '.'
.dot1:
    mov byte [FAT_NAME], '.'
    jmp .good
.base_start:
    xor cx, cx
.base:
    lodsb
    test al, al
    jz .good
    cmp al, ' '
    je .good
    cmp al, '.'
    je .ext
    cmp cx, 8
    jae .bad
    call to_upper
    stosb
    inc cx
    jmp .base
.ext:
    mov di, FAT_NAME + 8
    xor cx, cx
.ext_loop:
    lodsb
    test al, al
    jz .good
    cmp al, ' '
    je .good
    cmp cx, 3
    jae .bad
    call to_upper
    stosb
    inc cx
    jmp .ext_loop
.good:
    cmp byte [FAT_NAME], ' '
    je .bad
    clc
    jmp .out
.bad:
    stc
.out:
    pop si
    pop di
    pop cx
    pop ax
    ret

fat32_find:
    pushad
    mov byte [LFN_ACTIVE], 0
    mov eax, [FAT_CWD]
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
    test al, al
    jz .fail
    cmp al, 0xE5
    je .deleted
    mov al, [si + 11]
    and al, 0x3F
    cmp al, 0x0F
    jne .notlfn
    call fat32_lfn_collect
    jmp .skip
.notlfn:
    test byte [si + 11], 0x08
    jnz .deleted
    call fat32_lfn_check
    cmp byte [FAT_SHORT_OK], 1
    jne .try_long
    push si
    push cx
    mov di, FAT_NAME
    mov cx, 11
    repe cmpsb
    pop cx
    pop si
    je .found
.try_long:
    cmp byte [LFN_HAVE], 1
    jne .deleted
    call fat32_lfn_match
    jc .found
.deleted:
    mov byte [LFN_ACTIVE], 0
.skip:
    add si, 32
    loop .entry
    inc dword [FAT_SEC]
    dec dword [FAT_LEFT]
    jnz .next_sector
    mov eax, [FAT_CUR]
    call fat32_next_cluster
    cmp eax, 2
    jb .fail
    cmp eax, 0x0FFFFFF7
    jb .next_cluster
.fail:
    popad
    stc
    ret
.found:
    mov di, FAT_ENT
    mov cx, 32
    rep movsb
    popad
    clc
    ret

fat32_entry_cluster:
    movzx eax, word [FAT_ENT + 20]
    shl eax, 16
    mov ax, [FAT_ENT + 26]
    ret

print_file_char:
    pusha
    cmp al, 13
    je .out
    cmp al, 10
    je .nl
    cmp al, 9
    je .print
    cmp al, 32
    jb .dot
    cmp al, 127
    jae .dot
    jmp .print
.dot:
    mov al, '.'
.print:
    mov ah, 0x0E
    int 0x10
    jmp .out
.nl:
    mov ax, 0x0E0D
    int 0x10
    mov ax, 0x0E0A
    int 0x10
.out:
    popa
    ret

fat32_cd:
    pushad
    cmp byte [si], 0
    je .usage
    call fat32_ensure_mount
    jc .nomount
    call fat32_prepare_name
    jc .badname
    call fat32_find
    jc .notfound
    test byte [FAT_ENT + 11], 0x10
    jz .notdir
    call fat32_entry_cluster
    cmp eax, 2
    jae .set
    mov eax, [FAT_ROOT]
.set:
    mov [FAT_CWD], eax
    mov byte [SKIP_GAP], 1
    jmp .out
.usage:
    mov si, MSG_CD_USAGE
    jmp .say
.nomount:
    mov si, MSG_FAT_ERR
    jmp .say
.badname:
    mov si, MSG_FAT_BADNAME
    jmp .say
.notfound:
    mov si, MSG_FAT_NOFILE
    jmp .say
.notdir:
    mov si, MSG_FAT_NOTDIR
.say:
    call print_string
.out:
    popad
    ret

fat32_type:
    pushad
    cmp byte [si], 0
    je .usage
    call fat32_ensure_mount
    jc .nomount
    call fat32_prepare_name
    jc .badname
    call fat32_find
    jc .notfound
    test byte [FAT_ENT + 11], 0x10
    jnz .isdir
    mov eax, [FAT_ENT + 28]
    mov [FAT_REM], eax
    call fat32_entry_cluster
    cmp eax, 2
    jb .finish
.cluster:
    mov [FAT_CUR], eax
    call fat32_cluster_lba
    mov [FAT_SEC], eax
    movzx eax, byte [FAT_SPC]
    mov [FAT_LEFT], eax
.sector:
    cmp dword [FAT_REM], 0
    je .finish
    mov eax, [FAT_SEC]
    mov di, SECTOR_BUF
    call fat32_read_sector
    jc .readerr
    mov si, SECTOR_BUF
    mov ecx, [FAT_REM]
    cmp ecx, 512
    jbe .count
    mov ecx, 512
.count:
    sub [FAT_REM], ecx
.char:
    lodsb
    call print_file_char
    loop .char
    inc dword [FAT_SEC]
    dec dword [FAT_LEFT]
    jnz .sector
    mov eax, [FAT_CUR]
    call fat32_next_cluster
    cmp eax, 2
    jb .finish
    cmp eax, 0x0FFFFFF7
    jb .cluster
.finish:
    mov si, MSG_FAT_NL
    jmp .say
.usage:
    mov si, MSG_TYPE_USAGE
    jmp .say
.nomount:
    mov si, MSG_FAT_ERR
    jmp .say
.badname:
    mov si, MSG_FAT_BADNAME
    jmp .say
.notfound:
    mov si, MSG_FAT_NOFILE
    jmp .say
.isdir:
    mov si, MSG_FAT_ISDIR
    jmp .say
.readerr:
    mov si, MSG_FAT_READERR
.say:
    call print_string
    popad
    ret

multiboot_cmd:
    pushad
    cmp byte [si], 0
    je .usage
    call fat32_ensure_mount
    jc .nomount
    call fat32_prepare_name
    jc .badname
    call fat32_find
    jc .notfound
    test byte [FAT_ENT + 11], 0x10
    jnz .isdir
    mov eax, [FAT_ENT + 28]
    test eax, eax
    jz .empty
    cmp eax, MB_FILE_MAX
    jbe .size_ok
    mov eax, MB_FILE_MAX
.size_ok:
    mov [MB_LEN], ax
    mov [RD_LEN], eax
    mov dword [RD_OFF], 0
    mov dword [RD_DST], MB_SEG * 16
    call fat32_read_range
    jc .readerr
    mov bx, [MB_LEN]
    mov ax, MB_SEG
    mov es, ax
    mov byte [es:bx], 0
    mov ds, ax
    xor si, si
    mov di, MB_TAB
    xor cx, cx
.next:
    cmp cx, MB_MAX
    jae .parsed
.lead:
    mov al, [si]
    test al, al
    jz .parsed
    cmp al, ' '
    je .lead_adv
    cmp al, 13
    je .lead_adv
    cmp al, 10
    je .lead_adv
    cmp al, 9
    jne .entry
.lead_adv:
    inc si
    jmp .lead
.entry:
    mov bx, di
    xor dx, dx
.name_loop:
    mov al, [si]
    test al, al
    jz .skip_eol
    cmp al, 13
    je .skip_eol
    cmp al, 10
    je .skip_eol
    cmp al, '='
    je .got_name
    cmp dx, MB_NAME_MAX
    jae .name_skip
    mov [bx], al
    inc bx
    inc dx
.name_skip:
    inc si
    jmp .name_loop
.got_name:
    inc si
.trim:
    cmp bx, di
    je .name_end
    cmp byte [bx - 1], ' '
    jne .name_end
    dec bx
    jmp .trim
.name_end:
    cmp bx, di
    je .skip_eol
    mov byte [bx], 0
    lea bx, [di + MB_ARGOFF]
.arg_ws:
    cmp byte [si], ' '
    jne .arg_start
    inc si
    jmp .arg_ws
.arg_start:
    xor dx, dx
.arg_loop:
    mov al, [si]
    test al, al
    jz .arg_end
    cmp al, 13
    je .arg_end
    cmp al, 10
    je .arg_end
    cmp dx, MB_ARG_MAX
    jae .arg_skip
    mov [bx], al
    inc bx
    inc dx
.arg_skip:
    inc si
    jmp .arg_loop
.arg_end:
    test dx, dx
    jz .lead
    mov byte [bx], 0
    add di, MB_ENT
    inc cx
    jmp .next
.skip_eol:
    mov al, [si]
    test al, al
    jz .parsed
    cmp al, 13
    je .lead
    cmp al, 10
    je .lead
    inc si
    jmp .skip_eol
.parsed:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov [MB_COUNT], cl
    test cl, cl
    jz .noentries
    call multiboot_menu
    mov cl, MB_ENT
    mul cl
    add ax, MB_TAB + MB_ARGOFF
    mov si, ax
    mov ax, MB_SEG
    mov ds, ax
    mov di, MB_ARG
    mov cx, MB_ARG_MAX + 1
    cld
    rep movsb
    xor ax, ax
    mov ds, ax
    mov ax, 0x0003
    int 0x10
    mov si, MB_ARG
    call boot_cmd
    jmp .done
.usage:
    mov si, MSG_MB_USAGE
    jmp .say
.nomount:
    mov si, MSG_FAT_ERR
    jmp .say
.badname:
    mov si, MSG_FAT_BADNAME
    jmp .say
.notfound:
    mov si, MSG_FAT_NOFILE
    jmp .say
.isdir:
    mov si, MSG_FAT_ISDIR
    jmp .say
.empty:
    mov si, MSG_BOOT_EMPTY
    jmp .say
.readerr:
    mov si, MSG_FAT_READERR
    jmp .say
.noentries:
    mov si, MSG_MB_NOENT
.say:
    call print_string
.done:
    popad
    ret

multiboot_menu:
    mov ax, 0x0003
    int 0x10
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10
    mov al, [MB_COUNT]
    cmp al, MB_VIS
    jbe .rows_ok
    mov al, MB_VIS
.rows_ok:
    mov [MB_ROWS], al
    mov bl, 21
    sub bl, al
    shr bl, 1
    mov [MB_Y0], bl
    mov byte [MB_SEL], 0
    mov byte [MB_TOP], 0
    call mb_frame
.redraw:
    call mb_draw
.key:
    xor ax, ax
    int 0x16
    cmp ah, 0x48
    je .up
    cmp ah, 0x50
    je .down
    cmp al, 0x0D
    je .pick
    cmp al, ' '
    je .pick
    jmp .key
.up:
    mov al, [MB_SEL]
    test al, al
    jz .key
    dec al
    mov [MB_SEL], al
    cmp al, [MB_TOP]
    jae .redraw
    mov [MB_TOP], al
    jmp .redraw
.down:
    mov al, [MB_SEL]
    inc al
    cmp al, [MB_COUNT]
    jae .key
    mov [MB_SEL], al
    mov ah, [MB_TOP]
    add ah, [MB_ROWS]
    cmp al, ah
    jb .redraw
    sub al, [MB_ROWS]
    inc al
    mov [MB_TOP], al
    jmp .redraw
.pick:
    mov al, [MB_SEL]
    ret

mb_addr:
    push ax
    mov ah, 160
    mul ah
    add ax, MB_X * 2
    mov di, ax
    pop ax
    ret

mb_line:
    push cx
    mov cx, MB_W
    mov ah, MB_ATTR
.put:
    lodsb
    stosw
    loop .put
    pop cx
    ret

mb_frame:
    pusha
    push es
    mov ax, 0xB800
    mov es, ax
    mov al, [MB_Y0]
    call mb_addr
    mov si, MB_ROW_TOP
    call mb_line
    mov al, [MB_Y0]
    inc al
    call mb_addr
    mov si, MB_ROW_SUB
    call mb_line
    mov al, [MB_Y0]
    add al, 2
    call mb_addr
    mov si, MB_ROW_SEP
    call mb_line
    mov al, [MB_Y0]
    add al, 3
    add al, [MB_ROWS]
    call mb_addr
    mov si, MB_ROW_BOT
    call mb_line
    pop es
    popa
    ret

mb_draw:
    pusha
    push ds
    push es
    cld
    mov dl, [MB_SEL]
    mov dh, [MB_COUNT]
    mov byte [MB_THUMB], 0
    cmp dh, 1
    jbe .thumb_ok
    mov al, dl
    mov ah, [MB_ROWS]
    dec ah
    mul ah
    mov bl, dh
    dec bl
    div bl
    mov [MB_THUMB], al
.thumb_ok:
    mov ax, 0xB800
    mov es, ax
    mov bl, [MB_TOP]
    xor bh, bh
.row:
    mov al, [MB_Y0]
    add al, 3
    add al, bh
    call mb_addr
    mov ax, MB_ATTR * 256 + 0xB3
    stosw
    mov ah, MB_ATTR
    cmp bl, dl
    jne .attr_ok
    mov ah, MB_ATTR_SEL
.attr_ok:
    mov al, ' '
    mov bp, di
    mov cx, MB_W - 2
    rep stosw
    push ax
    mov al, 0xB0
    mov ah, MB_ATTR
    cmp bh, [MB_THUMB]
    jne .bar
    mov al, 0xDB
.bar:
    stosw
    pop ax
    cmp bl, dh
    jae .next
    mov di, bp
    add di, 2
    mov al, bl
    inc al
    cmp al, 10
    jb .one
    mov al, '1'
    stosw
    mov al, bl
    inc al
    sub al, 10
.one:
    add al, '0'
    stosw
    mov al, '.'
    stosw
    push ax
    mov al, bl
    mov cl, MB_ENT
    mul cl
    add ax, MB_TAB
    mov si, ax
    pop ax
    push ds
    mov cx, MB_SEG
    mov ds, cx
.nm:
    lodsb
    test al, al
    jz .nm_done
    stosw
    jmp .nm
.nm_done:
    pop ds
.next:
    inc bl
    inc bh
    cmp bh, [MB_ROWS]
    jb .row
    pop es
    pop ds
    popa
    ret

SELECTED            db 0

SYS_RAM_MB          dd 0
SYS_RAM_KB          dd 0
SYS_RAM_TOP         dd 0x100000
RAM_DONE            db 0
RAM_E820_OK         db 0
RAM_E820_CNT        dw 0
E820_ENT            times 24 db 0
SYS_CPU64           db 0
SYS_CANRUN          db 0
DLG_SEL             db 0
DLG_KIND            db 0
DLG_CUR             db 0
DLG_STR_YES         db "[ Yes ]", 0
DLG_STR_NO          db "[ No ]", 0
DLG_TXT_SHUT        db "          Do you want to shut           "
                    db "             down your PC?              "
DLG_TXT_REBOOT      db "         Do you want to restart         "
                    db "                your PC?                "
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
                    db "  boot [file]   - loads and starts a kernel (ELF32, ELF64 or flat BIN)", 13, 10
                    db "                  BIN options: boot [file] [hex address] [long]", 13, 10
                    db "  dir           - lists files in the current FAT32 directory", 13, 10
                    db "  cd [dir]      - changes the current FAT32 directory", 13, 10
                    db "  type [file]   - prints the contents of a FAT32 file", 13, 10
                    db "  multiboot [file] - opens the boot menu (file lines: Name=file [address] [long])", 13, 10
                    db "  remode [mode] - changes the current mode (real, protected, long)", 13, 10
                    db "  color [c]     - changes text color (r g b y c m w d reset fcr)", 13, 10
                    db "  close         - closes the terminal and returns to the error screen", 13, 10
                    db "  exit          - reboots your machine", 13, 10
                    db "  time          - shows the current time", 13, 10
                    db "  shutdown      - shuts down your machine", 13, 10
                    db "  about         - shows info about the bootloader and the terminal", 13, 10
                    db "  sysinf        - shows your current system specification", 13, 10, 0
MSG_UNKNOWN         db "Unknown command. Type 'help' for a list of commands.", 13, 10, 0
MSG_BOOT_USAGE      db "Usage: boot [file] [hex address] [long]", 13, 10, 0
MSG_BOOT_LOAD       db "Booting from ", 0
MSG_BOOT_FMT        db "Format: ", 0
MSG_FMT_BIN         db "flat binary", 13, 10, 0
MSG_FMT_ELF32       db "ELF32", 13, 10, 0
MSG_FMT_ELF64       db "ELF64", 13, 10, 0
MSG_BOOT_ENTRY      db "Entry:  0x", 0
MSG_BOOT_IMAGE      db 13, 10, "Image:  0x", 0
MSG_BOOT_DASH       db " - 0x", 0
MSG_BOOT_START      db 13, 10, "Starting kernel...", 13, 10, 0
MSG_BOOT_EMPTY      db "File is empty.", 13, 10, 0
MSG_BOOT_INVALID    db "Invalid File, or contents", 13, 10, 0
MSG_BOOT_BADENTRY   db "Entry point is outside the kernel image.", 13, 10, 0
MSG_BOOT_LOWMEM     db "Kernel overlaps reserved memory below 1 MB.", 13, 10, 0
MSG_BOOT_NORAM      db "Not enough RAM to load the kernel.", 13, 10, 0
MSG_BOOT_MEMBAD     db "Memory at the kernel address is not writable.", 13, 10, 0
MSG_BOOT_NOA20      db "A20 line is disabled. Cannot use memory above 1 MB.", 13, 10, 0
MSG_BOOT_MODEMIS    db "Kernel is 32-bit, but Long Mode was requested.", 13, 10, 0
MSG_BOOT_DOTS      db "...", 13, 10, 0
MSG_EMPTY           db 0
MSG_RPFX_STD        db "Reason: ", 0
MSG_RPFX_EXC        db "Reason: CPU exception ", 0
MSG_LOG_ERR         db "! ", 0
MSG_EV_CANNOT       db "Cannot boot from ", 0
MSG_EV_BANG         db "!", 0
MSG_EV_TITLE        db " Error! ", 0
MSG_EV_LOGS         db " Logs ", 0
MSG_EV_OK           db "[ OK ]", 0
MSG_EV_HINT         db 0x18, 0x19, " PgUp PgDn - scroll      Enter / Space - OK", 0
MSG_LF_EXC          db "CPU exception ", 0
MSG_LF_VEC          db "  Vector:  0x", 0
MSG_LF_ERR          db "  Error:   0x", 0
MSG_LF_AT           db "  At:      ", 0
MSG_LF_FLAGS        db "  Flags:   0x", 0
MSG_LF_STACK        db "  Stack:   0x", 0
MSG_LF_CR2          db "  CR2:     0x", 0
MSG_LF_BACK         db "Returned to real mode.", 13, 10, 0
MSG_BACK_TERM       db "Returned to the terminal.", 13, 10, 0
MSG_COLOR_OK        db "Text color changed.", 13, 10, 0
MSG_COLOR_USAGE     db "Usage: color [r|g|b|y|c|m|w|d|reset|fcr]", 13, 10, 0
MSG_COLOR_BAD       db "Unknown color. Use: r red, g green, b blue, y yellow,", 13, 10
                    db "c cyan, m magenta, w white, d default, reset, fcr (full reset).", 13, 10, 0

MSG_ABOUT           db "NXBoot - a bootloader made by Nixel Tech community for NixelOS.", 13, 10
                    db 13, 10
                    db "NixelOS (c). All rights reserved!", 13, 10, 0

SYSI_STREAM:
                    db 1, 0x0B, " NN   NN   XX   XX        ", 1, 0x0B, "Build Date:", 1, 0x0F, " 30.10.2026", 13, 10
                    db 1, 0x0B, " NNN  NN    XX XX         ", 1, 0x0B, "Terminal:", 1, 0x0F, " NXBoot v0.7 BETA", 13, 10
                    db 1, 0x0B, " NN N NN     XXX          ", 1, 0x0B, "RAM:", 1, 0x0F, " ", 2, " MB", 13, 10
                    db 1, 0x0B, " NN  NNN    XX XX         ", 1, 0x0B, "CPU:", 1, 0x0F, " ", 3, 13, 10
                    db 1, 0x0B, " NN   NN   XX   XX        ", 1, 0x0B, "NOS:", 1, 0x0F, " ", 4, 13, 10
                    db 1, 0x0B, " B    O     O    T v0.7   ", 1, 0x0B, "Mode:", 1, 0x0F, " ", 5, 13, 10, 0
SYSI_CPU64          db "X64", 0
SYSI_CPU32          db "X86", 0
SYSI_NOS_OK         db 1, 0x0A, "Can run NixelOS.", 0
SYSI_NOS_NO         db 1, 0x0C, "Can't run NixelOS.", 0
SYSI_MODE_R         db "Real", 0
SYSI_MODE_P         db "Protected", 0
SYSI_MODE_L         db "Long", 0
SYSI_MODE_TAB       dw SYSI_MODE_R, SYSI_MODE_P, SYSI_MODE_L
SYSI_ATTR           db 0x07
SYSI_CH             db 0
SYSI_DEF            db 0x07

CMD_HELP            db "help", 0
CMD_EXIT            db "exit", 0
CMD_TIME            db "time", 0
CMD_BOOT            db "boot", 0
CMD_SHUTDOWN        db "shutdown", 0
CMD_ABOUT           db "about", 0
CMD_SYSINF          db "sysinf", 0
CMD_DIR             db "dir", 0
CMD_CD              db "cd", 0
CMD_TYPE            db "type", 0
CMD_REMODE          db "remode", 0
CMD_CLOSE           db "close", 0
CMD_COLOR           db "color", 0
CMD_MULTIBOOT       db "multiboot", 0
MSG_MB_USAGE        db "Usage: multiboot [file]", 13, 10, 0
MSG_MB_NOENT        db "No boot entries found. Line format: Name=file [hex address] [long]", 13, 10, 0
MB_SEL              db 0
MB_TOP              db 0
MB_COUNT            db 0
MB_ROWS             db 0
MB_Y0               db 0
MB_THUMB            db 0
MB_LEN              dw 0
MB_ARG              times 64 db 0
MB_ROW_TOP          db 0xDA
                    times 20 db 0xC4
                    db " NXBoot Multiboot "
                    times 20 db 0xC4
                    db 0xBF
MB_ROW_SUB          db 0xB3, " Select operating system."
                    times 33 db ' '
                    db 0xB3
MB_ROW_SEP          db 0xC3
                    times 58 db 0xC4
                    db 0x18
MB_ROW_BOT          db 0xC0
                    times 58 db 0xC4
                    db 0x19

FAT_DRIVE           db 0
FAT_OK              db 0
FAT_SPC             db 0
FAT_PART            dd 0
FAT_CWD             dd 0
FAT_REM             dd 0
FAT_NAME            times 11 db ' '
FAT_ENT             times 32 db 0
FAT_ROOT            dd 0
FAT_LBA             dd 0
FAT_DATA            dd 0
FAT_CUR             dd 0
FAT_SEC             dd 0
FAT_LEFT            dd 0
FAT_SHORT_OK        db 0
FAT_ARG             dw 0
LFN_ACTIVE          db 0
LFN_HAVE            db 0
LFN_SEQ             db 0
LFN_CHK             db 0
LFN_OFFS            db 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30
LFN_BAD             db '"*/:<>?\|', 0
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
MSG_FAT_NL          db 13, 10, 0
MSG_FAT_NOFILE      db "File or directory not found.", 13, 10, 0
MSG_FAT_NOTDIR      db "Not a directory.", 13, 10, 0
MSG_FAT_ISDIR       db "This is a directory, not a file.", 13, 10, 0
MSG_FAT_BADNAME     db "Invalid file name.", 13, 10, 0
MSG_FAT_READERR     db "Disk read error.", 13, 10, 0
MSG_CD_USAGE        db "Usage: cd [dir]", 13, 10, 0
MSG_TYPE_USAGE      db "Usage: type [file]", 13, 10, 0
MSG_MODE_REAL       db "Now in Real Mode (16-bit).", 13, 10, 0
MSG_MODE_PM         db "Now in Protected Mode (32-bit).", 13, 10, 0
MSG_MODE_LM         db "Now in Long Mode (64-bit).", 13, 10, 0
MSG_REMODE_USAGE    db "Usage: remode [real|protected|long]", 13, 10, 0
MSG_REMODE_BAD      db "Unknown mode. Available modes: real, protected, long.", 13, 10, 0
MSG_REMODE_SAME     db "You are already in this mode.", 13, 10, 0
MSG_REMODE_NOLONG   db "This CPU does not support Long Mode (64-bit).", 13, 10, 0
MSG_REALONLY        db "This command works only in Real Mode. Use 'remode real'.", 13, 10, 0
MSG_HELP_EXT        db "Available commands:", 13, 10
                    db "  help          - shows this help message", 13, 10
                    db "  remode [mode] - changes the current mode (real, protected, long)", 13, 10
                    db "  color [c]     - changes text color (r g b y c m w d reset fcr)", 13, 10
                    db "  close         - closes the terminal and returns to the error screen", 13, 10
                    db "  exit          - reboots your machine", 13, 10
                    db "  time          - shows the current time", 13, 10
                    db "  shutdown      - shuts down your machine", 13, 10
                    db "  about         - shows info about the bootloader and the terminal", 13, 10
                    db "  sysinf        - shows your current system specification", 13, 10
                    db "  boot, dir, cd, type, multiboot - work only in Real Mode", 13, 10, 0
ARG_REAL            db "real", 0
ARG_PROT            db "protected", 0
ARG_PROT2           db "prot", 0
ARG_LONG            db "long", 0

SPLASH_TARGETS      dw 1024, 768
                    dw 0
SPL_MSG_NOVBE       db "VBE not available. Press any key.", 13, 10, 0
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

MODE_REAL           equ 0
MODE_PROT           equ 1
MODE_LONG           equ 2
VGA_BASE            equ 0xB8000

CUR_MODE            db 0
TARGET_MODE         db 0
PENDING             db 0
LM_OK               db 0
TERM_ROW            db 0
TERM_COL            db 0
KB_SHIFT            db 0
RTC_BIN             db 0
ERR_PTR             dw 0
ERR_LEN             dw 0
REMODE_ARG          dd 0
REAL_IDT            dw 0x03FF
                    dd 0

COLOR_SET           db 0
TERM_ATTR           db 0x07
COLOR_PREV          db 0x07
SKIP_GAP            db 0
IMG_DAMAGED         db 0
BOOT_KIND           db 0
BOOT_LONG           db 0
BOOT_WANT64         db 0
BOOT_BASE           dd KERNEL_BASE_DEF
BOOT_ARGS           dw 0
BOOT_ENTRY          dq 0
BOOT_LO             dd 0
BOOT_HI             dd 0
RAM_TOP             dd 0
PH_OFF              dd 0
PH_SIZE             dw 0
PH_NUM              dw 0
PH_LEFT             dw 0
SEG_OFF             dd 0
SEG_DST             dd 0
SEG_FSZ             dd 0
SEG_MSZ             dd 0
RD_OFF              dd 0
RD_LEN              dd 0
RD_DST              dd 0
RD_POS              dd 0
RD_CLBYTES          dd 0
COLOR_ARG           dd 0
FMT_TABLE           dw MSG_FMT_BIN, MSG_FMT_ELF32, MSG_FMT_ELF64
DEST_ERR            db 0
DEST_TABLE          dw MSG_BOOT_LOWMEM, MSG_BOOT_NORAM, MSG_BOOT_MEMBAD
FLAT_MAGIC32        dd 0x46445025, 0x474E5089, 0x38464947, 0xAFBC7A37, 0x04034B50, 0x21726152, 0x6D736100, 0xBEBAFECA, 0xFEEDFACE, 0xFEEDFACF, 0xCEFAEDFE, 0xCFFAEDFE
FLAT_MAGIC32_N      equ ($ - FLAT_MAGIC32) / 4
FLAT_MAGIC16        dw 0x5A4D, 0x4B50, 0x8B1F, 0xD8FF, 0x4D42, 0x2123
FLAT_MAGIC16_N      equ ($ - FLAT_MAGIC16) / 2
LOG_LEN             dw 0
EV_TOP              dw 0
EV_LINES            dw 0
EV_T0               dw 0
EV_T1               dw 0
BOOT_REASON         dw 0
BOOT_RPFX           dw 0
FAULT_VEC           dd 0
FAULT_ERR           dd 0
FAULT_IP            dq 0
FAULT_CS            dd 0
FAULT_FLAGS         dd 0
FAULT_SP            dq 0
FAULT_CR2           dq 0
FAULT_LONG          db 0
HINT_COL            equ 17
EXC_NAMES           dw EXN00, EXN01, EXN02, EXN03, EXN04, EXN05, EXN06, EXN07, EXN08, EXN09, EXN10, EXN11, EXN12, EXN13, EXN14, EXN15, EXN16, EXN17, EXN18, EXN19, EXN20, EXN21, EXN22, EXN23, EXN24, EXN25, EXN26, EXN27, EXN28, EXN29, EXN30, EXN31
EXN00               db "#DE (Divide error)", 0
EXN01               db "#DB (Debug)", 0
EXN02               db "NMI (Non-maskable interrupt)", 0
EXN03               db "#BP (Breakpoint)", 0
EXN04               db "#OF (Overflow)", 0
EXN05               db "#BR (Bound range exceeded)", 0
EXN06               db "#UD (Invalid opcode)", 0
EXN07               db "#NM (Device not available)", 0
EXN08               db "#DF (Double fault)", 0
EXN09               db "(Coprocessor segment overrun)", 0
EXN10               db "#TS (Invalid TSS)", 0
EXN11               db "#NP (Segment not present)", 0
EXN12               db "#SS (Stack fault)", 0
EXN13               db "#GP (General protection fault)", 0
EXN14               db "#PF (Page fault)", 0
EXN15               db "(Reserved)", 0
EXN16               db "#MF (x87 floating-point error)", 0
EXN17               db "#AC (Alignment check)", 0
EXN18               db "#MC (Machine check)", 0
EXN19               db "#XM (SIMD floating-point error)", 0
EXN20               db "#VE (Virtualization exception)", 0
EXN21               db "#CP (Control protection)", 0
EXN22               db "(Reserved)", 0
EXN23               db "(Reserved)", 0
EXN24               db "(Reserved)", 0
EXN25               db "(Reserved)", 0
EXN26               db "(Reserved)", 0
EXN27               db "(Reserved)", 0
EXN28               db "#HV (Hypervisor injection)", 0
EXN29               db "#VC (VMM communication)", 0
EXN30               db "#SX (Security exception)", 0
EXN31               db "(Reserved)", 0

COL_R               db "r", 0
COL_RED             db "red", 0
COL_G               db "g", 0
COL_GREEN           db "green", 0
COL_B               db "b", 0
COL_BLUE            db "blue", 0
COL_Y               db "y", 0
COL_YELLOW          db "yellow", 0
COL_C               db "c", 0
COL_CYAN            db "cyan", 0
COL_M               db "m", 0
COL_MAGENTA         db "magenta", 0
COL_W               db "w", 0
COL_WHITE           db "white", 0
COL_D               db "d", 0
COL_DEFAULT         db "default", 0
COL_RESET           db "reset", 0
COL_FCR             db "fcr", 0

COLOR_TABLE         dw COL_R
                    db 0x0C
                    dw COL_RED
                    db 0x0C
                    dw COL_G
                    db 0x0A
                    dw COL_GREEN
                    db 0x0A
                    dw COL_B
                    db 0x09
                    dw COL_BLUE
                    db 0x09
                    dw COL_Y
                    db 0x0E
                    dw COL_YELLOW
                    db 0x0E
                    dw COL_C
                    db 0x0B
                    dw COL_CYAN
                    db 0x0B
                    dw COL_M
                    db 0x0D
                    dw COL_MAGENTA
                    db 0x0D
                    dw COL_W
                    db 0x0F
                    dw COL_WHITE
                    db 0x0F
                    dw COL_D
                    db 0x07
                    dw COL_DEFAULT
                    db 0x07
                    dw COL_RESET
                    db 0x07
                    dw COL_FCR
                    db 0x07
                    dw 0

MODE_TABLE          dw ARG_PROT
                    db MODE_PROT
                    dw ARG_PROT2
                    db MODE_PROT
                    dw ARG_REAL
                    db MODE_REAL
                    dw ARG_LONG
                    db MODE_LONG
                    dw 0

KEYMAP_LOW          db 0, 0
                    db "1234567890-=", 8, 0
                    db "qwertyuiop[]", 13, 0
                    db "asdfghjkl;'`", 0
                    db "\zxcvbnm,./", 0, '*', 0, ' '
KEYMAP_HIGH         db 0, 0
                    db "!@#$%^&*()_+", 8, 0
                    db "QWERTYUIOP{}", 13, 0
                    db 'ASDFGHJKL:"~', 0
                    db "|ZXCVBNM<>?", 0, '*', 0, ' '

remode_cmd:
    cmp byte [si], 0
    je .usage
    mov [REMODE_ARG], si
    mov bx, MODE_TABLE
.next:
    mov di, [bx]
    test di, di
    jz .bad
    mov si, [REMODE_ARG]
    call match_cmd
    jc .found
    add bx, 3
    jmp .next
.found:
    mov al, [bx + 2]
    cmp al, MODE_REAL
    je .same
    mov [TARGET_MODE], al
    mov byte [LM_OK], 0
    call check_cpuid
    jc .lm_done
    call check_long_mode
    jc .lm_done
    mov byte [LM_OK], 1
.lm_done:
    cmp byte [TARGET_MODE], MODE_LONG
    jne .go
    cmp byte [LM_OK], 1
    jne .nolong
.go:
    mov ah, 0x03
    xor bh, bh
    int 0x10
    mov [TERM_ROW], dh
    mov [TERM_COL], dl
    jmp enter_protected_mode
.usage:
    mov si, MSG_REMODE_USAGE
    jmp .say
.bad:
    mov si, MSG_REMODE_BAD
    jmp .say
.same:
    mov si, MSG_REMODE_SAME
    jmp .say
.nolong:
    mov si, MSG_REMODE_NOLONG
.say:
    call print_string
    ret

close_terminal:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov cx, CLOSE_PAUSE_STEPS
.pause:
    call delay_150ms
    loop .pause
    mov byte [FAT_OK], 0
    mov byte [CUR_MODE], MODE_REAL
    mov byte [TARGET_MODE], MODE_REAL
    mov byte [PENDING], 0
    mov byte [COLOR_SET], 0
    mov byte [TERM_ATTR], 0x07
    mov byte [COLOR_PREV], 0x07
    mov byte [SKIP_GAP], 0
    mov byte [KB_SHIFT], 0
    mov byte [TERM_ROW], 0
    mov byte [TERM_COL], 0
    mov byte [INPUT_BUF], 0
    mov dword [FAT_CWD], 0
    call kbd_flush
    mov ax, 0x0003
    int 0x10
    mov si, [ERR_PTR]
    mov cx, [ERR_LEN]
    jmp show_error

kbd_flush:
    pusha
.drain:
    in al, 0x64
    test al, 1
    jz .ready
    in al, 0x60
    jmp .drain
.ready:
    sti
    nop
    nop
    nop
    nop
.buffer:
    mov ah, 0x01
    int 0x16
    jz .done
    xor ax, ax
    int 0x16
    jmp .buffer
.done:
    popa
    ret

print_gap:
    cmp byte [SKIP_GAP], 0
    jne .skip
    cmp byte [INPUT_BUF], 0
    je .ret
    mov si, MSG_FAT_NL
    call print_string
    ret
.skip:
    mov byte [SKIP_GAP], 0
.ret:
    ret

apply_color:
    cmp byte [COLOR_SET], 0
    je .ret
    pusha
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, 1
    mov cx, 2000
    mov al, [TERM_ATTR]
    mov bl, [COLOR_PREV]
.cell:
    mov dl, [es:di]
    cmp dl, bl
    je .paint
    cmp dl, 0x07
    jne .skip
.paint:
    mov [es:di], al
.skip:
    add di, 2
    loop .cell
    mov [COLOR_PREV], al
    pop es
    popa
.ret:
    ret

color_cmd:
    cmp byte [si], 0
    je .usage
    mov [COLOR_ARG], si
    mov bx, COLOR_TABLE
.next:
    mov di, [bx]
    test di, di
    jz .bad
    mov si, [COLOR_ARG]
    call match_cmd
    jc .found
    add bx, 3
    jmp .next
.found:
    mov al, [bx + 2]
    mov [TERM_ATTR], al
    mov byte [COLOR_SET], 1
    call apply_color
    cmp byte [TERM_ATTR], 0x07
    jne .ok
    mov byte [COLOR_SET], 0
.ok:
    mov si, MSG_COLOR_OK
    jmp .say
.usage:
    mov si, MSG_COLOR_USAGE
    jmp .say
.bad:
    mov si, MSG_COLOR_BAD
.say:
    call print_string
    ret

get_ram_top:
    push eax
    cmp byte [RAM_DONE], 0
    jne .have
    call detect_ram
.have:
    mov eax, [SYS_RAM_TOP]
    mov [RAM_TOP], eax
    pop eax
    ret

print_hex32:
    pushad
    mov cx, 8
.digit:
    rol eax, 4
    mov dl, al
    and dl, 0x0F
    add dl, '0'
    cmp dl, '9'
    jbe .emit
    add dl, 7
.emit:
    push ax
    mov al, dl
    mov ah, 0x0E
    int 0x10
    pop ax
    loop .digit
    popad
    ret

parse_hex:
    push ecx
    push edx
    xor edx, edx
    xor cx, cx
    cmp byte [si], '0'
    jne .digit
    mov al, [si + 1]
    or al, 0x20
    cmp al, 'x'
    jne .digit
    add si, 2
.digit:
    mov al, [si]
    test al, al
    jz .end
    cmp al, ' '
    je .end
    cmp al, '0'
    jb .bad
    cmp al, '9'
    jbe .num
    or al, 0x20
    cmp al, 'a'
    jb .bad
    cmp al, 'f'
    ja .bad
    sub al, 'a' - 10
    jmp .acc
.num:
    sub al, '0'
.acc:
    test edx, 0xF0000000
    jnz .bad
    shl edx, 4
    movzx eax, al
    or edx, eax
    inc cx
    inc si
    jmp .digit
.end:
    test cx, cx
    jz .bad
    mov eax, edx
    pop edx
    pop ecx
    clc
    ret
.bad:
    pop edx
    pop ecx
    stc
    ret

boot_check_lm:
    pushad
    call check_cpuid
    jc .out
    call check_long_mode
.out:
    popad
    ret

boot_check_dest:
    pushad
    mov byte [DEST_ERR], 0
    cmp eax, 0x100000
    jb .bad
    mov ebx, eax
    add ebx, ecx
    jc .noram
    cmp ebx, [RAM_TOP]
    ja .noram
    call boot_probe_dest
    jc .badmem
    cmp eax, IMG_END
    jae .good
    cmp ebx, HIGH_BASE
    jbe .good
    mov byte [IMG_DAMAGED], 1
.good:
    popad
    clc
    ret
.noram:
    mov byte [DEST_ERR], 1
    jmp .bad
.badmem:
    mov byte [DEST_ERR], 2
.bad:
    popad
    stc
    ret

boot_probe_dest:
    pushad
    mov edi, eax
    mov ebx, eax
    add ebx, ecx
    dec ebx
    call enter_unreal
    call .one
    jc .out
    mov edi, ebx
    call .one
.out:
    popad
    ret
.one:
    mov dl, [fs:edi]
    mov byte [fs:edi], 0x5A
    cmp byte [fs:edi], 0x5A
    jne .no
    mov byte [fs:edi], 0xA5
    cmp byte [fs:edi], 0xA5
    jne .no
    mov [fs:edi], dl
    clc
    ret
.no:
    mov [fs:edi], dl
    stc
    ret

boot_check_a20:
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

boot_check_flat:
    pushad
    mov eax, [ELF_HDR]
    mov bx, FLAT_MAGIC32
    mov cx, FLAT_MAGIC32_N
.m32:
    cmp eax, [bx]
    je .bad
    add bx, 4
    loop .m32
    mov bx, FLAT_MAGIC16
    mov cx, FLAT_MAGIC16_N
.m16:
    cmp ax, [bx]
    je .bad
    add bx, 2
    loop .m16
    mov si, ELF_HDR
    mov ecx, [FAT_ENT + 28]
    cmp ecx, 64
    jbe .txt
    mov ecx, 64
.txt:
    lodsb
    cmp al, 9
    je .txt_ok
    cmp al, 10
    je .txt_ok
    cmp al, 13
    je .txt_ok
    cmp al, 0x20
    jb .notext
    cmp al, 0x7E
    ja .notext
.txt_ok:
    dec ecx
    jnz .txt
    jmp .bad
.notext:
    mov si, ELF_HDR
    mov cx, 64
    xor bl, bl
.zero:
    lodsb
    or bl, al
    loop .zero
    test bl, bl
    jz .bad
    popad
    clc
    ret
.bad:
    popad
    stc
    ret

copy_phys:
    pushad
    call enter_unreal
.words:
    cmp ecx, 4
    jb .bytes
    mov eax, [si]
    mov [fs:edi], eax
    add si, 4
    add edi, 4
    sub ecx, 4
    jmp .words
.bytes:
    test ecx, ecx
    jz .done
    mov al, [si]
    mov [fs:edi], al
    inc si
    inc edi
    dec ecx
    jmp .bytes
.done:
    popad
    ret

zero_phys:
    pushad
    test ecx, ecx
    jz .done
    call enter_unreal
    xor eax, eax
.words:
    cmp ecx, 4
    jb .bytes
    mov [fs:edi], eax
    add edi, 4
    sub ecx, 4
    jmp .words
.bytes:
    test ecx, ecx
    jz .done
    mov [fs:edi], al
    inc edi
    dec ecx
    jmp .bytes
.done:
    popad
    ret

fat32_read_range:
    pushad
    mov eax, [RD_OFF]
    mov ebx, [RD_LEN]
    add eax, ebx
    jc .fail
    cmp eax, [FAT_ENT + 28]
    ja .fail
    test ebx, ebx
    jz .ok
    call fat32_entry_cluster
    cmp eax, 2
    jb .fail
    mov dword [RD_POS], 0
    movzx ecx, byte [FAT_SPC]
    shl ecx, 9
    mov [RD_CLBYTES], ecx
.cluster:
    mov [FAT_CUR], eax
    mov ebx, [RD_POS]
    add ebx, [RD_CLBYTES]
    cmp ebx, [RD_OFF]
    jbe .skip_cluster
    call fat32_cluster_lba
    mov [FAT_SEC], eax
    movzx eax, byte [FAT_SPC]
    mov [FAT_LEFT], eax
.sector:
    mov eax, [RD_OFF]
    add eax, [RD_LEN]
    cmp [RD_POS], eax
    jae .ok
    mov ebx, [RD_POS]
    add ebx, 512
    cmp ebx, [RD_OFF]
    jbe .next_sector
    mov eax, [FAT_SEC]
    mov di, SECTOR_BUF
    call fat32_read_sector
    jc .fail
    xor esi, esi
    mov eax, [RD_OFF]
    cmp eax, [RD_POS]
    jbe .have_start
    mov esi, eax
    sub esi, [RD_POS]
.have_start:
    mov ecx, 512
    mov eax, [RD_OFF]
    add eax, [RD_LEN]
    sub eax, [RD_POS]
    cmp eax, ecx
    jae .have_end
    mov ecx, eax
.have_end:
    sub ecx, esi
    add esi, SECTOR_BUF
    mov edi, [RD_DST]
    call copy_phys
    add [RD_DST], ecx
.next_sector:
    add dword [RD_POS], 512
    inc dword [FAT_SEC]
    dec dword [FAT_LEFT]
    jnz .sector
    jmp .after_cluster
.skip_cluster:
    mov ebx, [RD_CLBYTES]
    add [RD_POS], ebx
.after_cluster:
    mov eax, [RD_OFF]
    add eax, [RD_LEN]
    cmp [RD_POS], eax
    jae .ok
    mov eax, [FAT_CUR]
    call fat32_next_cluster
    cmp eax, 2
    jb .fail
    cmp eax, 0x0FFFFFF7
    jae .fail
    jmp .cluster
.ok:
    popad
    clc
    ret
.fail:
    popad
    stc
    ret

boot_cmd:
    pushad
    call skip_spaces
    cmp byte [si], 0
    je .usage
    mov [BOOT_ARGS], si
    mov dword [BOOT_BASE], KERNEL_BASE_DEF
    mov byte [BOOT_WANT64], 0
.name:
    cmp byte [si], 0
    je .args
    cmp byte [si], ' '
    je .cut
    inc si
    jmp .name
.cut:
    mov byte [si], 0
    inc si
.args:
    call skip_spaces
    cmp byte [si], 0
    je .parsed
    mov bx, si
    mov di, ARG_LONG
    call match_cmd
    jnc .addr
    mov byte [BOOT_WANT64], 1
    jmp .args
.addr:
    mov si, bx
    call parse_hex
    jc .usage
    mov [BOOT_BASE], eax
    jmp .args
.parsed:
    call log_reset
    mov si, MSG_BOOT_LOAD
    call bprint
    mov si, [BOOT_ARGS]
    call bprint
    mov si, MSG_BOOT_DOTS
    call bprint
    call boot_check_a20
    jz .noa20
    call fat32_ensure_mount
    jc .nomount
    mov si, [BOOT_ARGS]
    call fat32_prepare_name
    jc .badname
    call fat32_find
    jc .notfound
    test byte [FAT_ENT + 11], 0x10
    jnz .isdir
    cmp dword [FAT_ENT + 28], 0
    je .empty
    call get_ram_top
    mov di, ELF_HDR
    mov cx, 64
    xor al, al
    rep stosb
    mov eax, [FAT_ENT + 28]
    cmp eax, 64
    jbe .hdr_len
    mov eax, 64
.hdr_len:
    mov [RD_LEN], eax
    mov dword [RD_OFF], 0
    mov dword [RD_DST], ELF_HDR
    call fat32_read_range
    jc .readerr
    cmp dword [ELF_HDR], 0x464C457F
    je .elf
    call boot_check_flat
    jc .badelf
    mov byte [BOOT_KIND], 0
    mov al, [BOOT_WANT64]
    mov [BOOT_LONG], al
    test al, al
    jz .flat_load
    call boot_check_lm
    jc .nolong
.flat_load:
    mov eax, [BOOT_BASE]
    mov ecx, [FAT_ENT + 28]
    call boot_check_dest
    jc .badaddr
    mov dword [RD_OFF], 0
    mov [RD_LEN], ecx
    mov [RD_DST], eax
    call fat32_read_range
    jc .readerr
    mov [BOOT_LO], eax
    add eax, ecx
    mov [BOOT_HI], eax
    mov eax, [BOOT_BASE]
    mov [BOOT_ENTRY], eax
    mov dword [BOOT_ENTRY + 4], 0
    jmp .launch
.elf:
    cmp byte [ELF_HDR + 5], 1
    jne .badelf
    cmp byte [ELF_HDR + 6], 1
    jne .badelf
    cmp dword [ELF_HDR + 20], 1
    jne .badelf
    mov ax, [ELF_HDR + 16]
    cmp ax, 2
    je .type_ok
    cmp ax, 3
    jne .badelf
.type_ok:
    cmp byte [ELF_HDR + 4], 1
    je .elf32
    cmp byte [ELF_HDR + 4], 2
    je .elf64
    jmp .badelf
.elf32:
    cmp dword [FAT_ENT + 28], 52
    jb .badelf
    cmp byte [BOOT_WANT64], 0
    jne .modemis
    cmp word [ELF_HDR + 18], 3
    jne .badelf
    cmp word [ELF_HDR + 42], 32
    jne .badelf
    mov byte [BOOT_KIND], 1
    mov byte [BOOT_LONG], 0
    mov eax, [ELF_HDR + 24]
    mov [BOOT_ENTRY], eax
    mov dword [BOOT_ENTRY + 4], 0
    mov eax, [ELF_HDR + 28]
    mov [PH_OFF], eax
    mov ax, [ELF_HDR + 44]
    mov [PH_NUM], ax
    mov word [PH_SIZE], 32
    jmp .ph_read
.elf64:
    cmp dword [FAT_ENT + 28], 64
    jb .badelf
    cmp word [ELF_HDR + 18], 0x3E
    jne .badelf
    cmp word [ELF_HDR + 54], 56
    jne .badelf
    cmp dword [ELF_HDR + 36], 0
    jne .badelf
    call boot_check_lm
    jc .nolong
    mov byte [BOOT_KIND], 2
    mov byte [BOOT_LONG], 1
    mov eax, [ELF_HDR + 24]
    mov [BOOT_ENTRY], eax
    mov eax, [ELF_HDR + 28]
    mov [BOOT_ENTRY + 4], eax
    mov eax, [ELF_HDR + 32]
    mov [PH_OFF], eax
    mov ax, [ELF_HDR + 56]
    mov [PH_NUM], ax
    mov word [PH_SIZE], 56
.ph_read:
    mov ax, [PH_NUM]
    test ax, ax
    jz .badelf
    cmp ax, 32
    ja .badelf
    mov [PH_LEFT], ax
    movzx eax, word [PH_NUM]
    movzx ecx, word [PH_SIZE]
    mul ecx
    mov [RD_LEN], eax
    add eax, [PH_OFF]
    jc .badelf
    cmp eax, [FAT_ENT + 28]
    ja .badelf
    mov eax, [PH_OFF]
    mov [RD_OFF], eax
    mov dword [RD_DST], ELF_PH
    call fat32_read_range
    jc .readerr
    mov dword [BOOT_LO], 0xFFFFFFFF
    mov dword [BOOT_HI], 0
    mov bx, ELF_PH
.ph_loop:
    cmp dword [bx], 1
    jne .ph_next
    cmp byte [BOOT_KIND], 1
    jne .ph64
    mov eax, [bx + 4]
    mov [SEG_OFF], eax
    mov eax, [bx + 12]
    mov [SEG_DST], eax
    mov eax, [bx + 16]
    mov [SEG_FSZ], eax
    mov eax, [bx + 20]
    mov [SEG_MSZ], eax
    jmp .seg
.ph64:
    cmp dword [bx + 12], 0
    jne .badelf
    cmp dword [bx + 28], 0
    jne .badelf
    cmp dword [bx + 36], 0
    jne .badelf
    cmp dword [bx + 44], 0
    jne .badelf
    mov eax, [bx + 8]
    mov [SEG_OFF], eax
    mov eax, [bx + 24]
    mov [SEG_DST], eax
    mov eax, [bx + 32]
    mov [SEG_FSZ], eax
    mov eax, [bx + 40]
    mov [SEG_MSZ], eax
.seg:
    mov eax, [SEG_MSZ]
    test eax, eax
    jz .ph_next
    cmp [SEG_FSZ], eax
    ja .badelf
    mov eax, [SEG_OFF]
    add eax, [SEG_FSZ]
    jc .badelf
    cmp eax, [FAT_ENT + 28]
    ja .badelf
    mov eax, [SEG_DST]
    mov ecx, [SEG_MSZ]
    call boot_check_dest
    jc .badaddr
    mov eax, [SEG_OFF]
    mov [RD_OFF], eax
    mov eax, [SEG_FSZ]
    mov [RD_LEN], eax
    mov eax, [SEG_DST]
    mov [RD_DST], eax
    call fat32_read_range
    jc .readerr
    mov edi, [SEG_DST]
    add edi, [SEG_FSZ]
    mov ecx, [SEG_MSZ]
    sub ecx, [SEG_FSZ]
    call zero_phys
    mov eax, [SEG_DST]
    cmp eax, [BOOT_LO]
    jae .lo_ok
    mov [BOOT_LO], eax
.lo_ok:
    add eax, [SEG_MSZ]
    cmp eax, [BOOT_HI]
    jbe .ph_next
    mov [BOOT_HI], eax
.ph_next:
    movzx eax, word [PH_SIZE]
    add bx, ax
    dec word [PH_LEFT]
    jnz .ph_loop
    cmp dword [BOOT_HI], 0
    je .badelf
    mov eax, [BOOT_ENTRY]
    cmp byte [BOOT_KIND], 2
    jne .ent_cmp
    mov edx, [BOOT_ENTRY + 4]
    test edx, edx
    jz .ent_cmp
    cmp edx, 0xFFFFFFFF
    jne .badentry
    cmp eax, 0x80000000
    jb .badentry
    sub eax, 0x80000000
.ent_cmp:
    cmp eax, [BOOT_LO]
    jb .badentry
    cmp eax, [BOOT_HI]
    jae .badentry
.launch:
    mov dword [BOOT_INFO], BOOT_MAGIC
    movzx eax, byte [FAT_DRIVE]
    mov [BOOT_INFO + 4], eax
    mov eax, [BOOT_ENTRY]
    mov [BOOT_INFO + 8], eax
    mov eax, [BOOT_LO]
    mov [BOOT_INFO + 12], eax
    mov eax, [BOOT_HI]
    mov [BOOT_INFO + 16], eax
    mov eax, [RAM_TOP]
    mov [BOOT_INFO + 20], eax
    mov dword [BOOT_INFO + 24], 32
    cmp byte [BOOT_LONG], 0
    je .info_done
    mov dword [BOOT_INFO + 24], 64
.info_done:
    mov si, MSG_BOOT_FMT
    call bprint
    movzx bx, byte [BOOT_KIND]
    shl bx, 1
    mov si, [FMT_TABLE + bx]
    call bprint
    mov si, MSG_BOOT_ENTRY
    call bprint
    cmp byte [BOOT_LONG], 0
    je .entry_low
    mov eax, [BOOT_ENTRY + 4]
    call bprint_hex32
.entry_low:
    mov eax, [BOOT_ENTRY]
    call bprint_hex32
    mov si, MSG_BOOT_IMAGE
    call bprint
    mov eax, [BOOT_LO]
    call bprint_hex32
    mov si, MSG_BOOT_DASH
    call bprint
    mov eax, [BOOT_HI]
    call bprint_hex32
    mov si, MSG_BOOT_START
    call bprint
    mov cx, BOOT_PAUSE_STEPS
.pause:
    call delay_150ms
    loop .pause
    jmp boot_jump
.usage:
    mov si, MSG_BOOT_USAGE
    jmp .say
.nomount:
    mov si, MSG_FAT_ERR
    jmp .fail
.badname:
    mov si, MSG_FAT_BADNAME
    jmp .fail
.notfound:
    mov si, MSG_FAT_NOFILE
    jmp .fail
.isdir:
    mov si, MSG_FAT_ISDIR
    jmp .fail
.empty:
    mov si, MSG_BOOT_EMPTY
    jmp .fail
.readerr:
    mov si, MSG_FAT_READERR
    jmp .fail
.badelf:
    mov si, MSG_BOOT_INVALID
    jmp .fail
.badaddr:
    movzx bx, byte [DEST_ERR]
    shl bx, 1
    mov si, [DEST_TABLE + bx]
    jmp .fail
.badentry:
    mov si, MSG_BOOT_BADENTRY
    jmp .fail
.modemis:
    mov si, MSG_BOOT_MODEMIS
    jmp .fail
.noa20:
    mov si, MSG_BOOT_NOA20
    jmp .fail
.nolong:
    mov si, MSG_REMODE_NOLONG
.fail:
    call boot_fail
    popad
    ret
.say:
    call print_string
    popad
    ret

boot_jump:
    cli
    lgdt [gdt32.pointer]
    cmp byte [BOOT_LONG], 0
    jne .long
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG32:kernel_pm32
.long:
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG32:kernel_long32

bprint:
    call print_string
    call log_puts
    ret

bprint_hex32:
    call print_hex32
    call log_hex32
    ret

log_reset:
    mov word [LOG_LEN], 0
    mov byte [LOG_BUF], 0
    mov word [BOOT_REASON], MSG_EMPTY
    mov word [BOOT_RPFX], MSG_RPFX_STD
    ret

log_putc:
    push bx
    mov bx, [LOG_LEN]
    cmp bx, LOG_MAX - 1
    jae .full
    mov [LOG_BUF + bx], al
    inc bx
    mov [LOG_LEN], bx
    mov byte [LOG_BUF + bx], 0
.full:
    pop bx
    ret

log_puts:
    push ax
    push si
.next:
    lodsb
    test al, al
    jz .done
    call log_putc
    jmp .next
.done:
    pop si
    pop ax
    ret

log_crlf:
    push si
    mov si, MSG_FAT_NL
    call log_puts
    pop si
    ret

log_hexn:
    push eax
    push dx
.digit:
    rol eax, 4
    mov dl, al
    and dl, 0x0F
    add dl, '0'
    cmp dl, '9'
    jbe .emit
    add dl, 7
.emit:
    push eax
    mov al, dl
    call log_putc
    pop eax
    loop .digit
    pop dx
    pop eax
    ret

log_hex32:
    push cx
    mov cx, 8
    call log_hexn
    pop cx
    ret

fault_name:
    push bx
    mov bx, [FAULT_VEC]
    and bx, 31
    shl bx, 1
    mov si, [EXC_NAMES + bx]
    pop bx
    ret

log_fault:
    pusha
    mov si, MSG_LOG_ERR
    call log_puts
    mov si, MSG_LF_EXC
    call log_puts
    call fault_name
    call log_puts
    call log_crlf
    mov si, MSG_LF_VEC
    call log_puts
    mov eax, [FAULT_VEC]
    shl eax, 24
    mov cx, 2
    call log_hexn
    call log_crlf
    mov si, MSG_LF_ERR
    call log_puts
    mov eax, [FAULT_ERR]
    call log_hex32
    call log_crlf
    mov si, MSG_LF_AT
    call log_puts
    mov eax, [FAULT_CS]
    shl eax, 16
    mov cx, 4
    call log_hexn
    mov al, ':'
    call log_putc
    cmp byte [FAULT_LONG], 0
    je .ip_low
    mov eax, [FAULT_IP + 4]
    call log_hex32
.ip_low:
    mov eax, [FAULT_IP]
    call log_hex32
    call log_crlf
    mov si, MSG_LF_FLAGS
    call log_puts
    mov eax, [FAULT_FLAGS]
    call log_hex32
    call log_crlf
    mov si, MSG_LF_STACK
    call log_puts
    cmp byte [FAULT_LONG], 0
    je .sp_low
    mov eax, [FAULT_SP + 4]
    call log_hex32
.sp_low:
    mov eax, [FAULT_SP]
    call log_hex32
    call log_crlf
    cmp byte [FAULT_LONG], 0
    je .tail
    cmp dword [FAULT_VEC], 14
    jne .tail
    mov si, MSG_LF_CR2
    call log_puts
    mov eax, [FAULT_CR2 + 4]
    call log_hex32
    mov eax, [FAULT_CR2]
    call log_hex32
    call log_crlf
.tail:
    mov si, MSG_LF_BACK
    call log_puts
    popa
    ret

boot_fail:
    mov [BOOT_REASON], si
    call print_string
    push si
    mov si, MSG_LOG_ERR
    call log_puts
    pop si
    call log_puts
    call boot_error_screen
    ret

boot_fault_entry:
    mov ax, 0x0003
    int 0x10
    call log_fault
    mov word [BOOT_RPFX], MSG_RPFX_EXC
    call fault_name
    mov [BOOT_REASON], si
    call boot_error_screen
    mov ax, 0x0003
    int 0x10
    mov si, MSG_BACK_TERM
    call print_string
    call print_gap
    jmp terminal_loop

boot_error_screen:
    pusha
    push es
    cld
    xor bh, bh
    mov ah, 0x03
    int 0x10
    push cx
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10
    mov ax, 0xB800
    mov es, ax
    call ev_count_lines
    mov ax, [EV_LINES]
    sub ax, EV_LOG_H
    jns .top_ok
    xor ax, ax
.top_ok:
    mov [EV_TOP], ax
    call ev_draw_all
    mov ax, 0x0501
    int 0x10
    call kbd_flush
.key:
    xor ax, ax
    int 0x16
    cmp al, 0x0D
    je .done
    cmp al, 0x20
    je .done
    cmp ah, 0x48
    je .up
    cmp ah, 0x50
    je .down
    cmp ah, 0x49
    je .pgup
    cmp ah, 0x51
    je .pgdn
    cmp ah, 0x47
    je .home
    cmp ah, 0x4F
    je .end
    jmp .key
.up:
    mov ax, [EV_TOP]
    test ax, ax
    jz .key
    dec ax
    jmp .set
.down:
    mov ax, [EV_TOP]
    inc ax
    jmp .set
.pgup:
    mov ax, [EV_TOP]
    sub ax, EV_LOG_H
    jns .set
    xor ax, ax
    jmp .set
.pgdn:
    mov ax, [EV_TOP]
    add ax, EV_LOG_H
    jmp .set
.home:
    xor ax, ax
    jmp .set
.end:
    mov ax, 0x7FFF
.set:
    call ev_clamp_set
    call ev_draw_log
    jmp .key
.done:
    mov ax, 0x0500
    int 0x10
    pop cx
    mov ah, 0x01
    int 0x10
    pop es
    popa
    ret

ev_clamp_set:
    push bx
    mov bx, [EV_LINES]
    sub bx, EV_LOG_H
    jns .have
    xor bx, bx
.have:
    cmp ax, bx
    jbe .ok
    mov ax, bx
.ok:
    mov [EV_TOP], ax
    pop bx
    ret

ev_pos:
    push ax
    movzx ax, dh
    mov di, ax
    shl di, 4
    shl ax, 6
    add di, ax
    movzx ax, dl
    add di, ax
    shl di, 1
    add di, EV_PAGE
    pop ax
    ret

ev_fill:
    push ax
    mov ah, bl
    rep stosw
    pop ax
    ret

ev_text:
    push ax
.next:
    test cx, cx
    jz .done
    lodsb
    test al, al
    jz .done
    cmp al, 13
    je .done
    cmp al, 10
    je .done
    mov ah, bl
    stosw
    dec cx
    jmp .next
.done:
    pop ax
    ret

ev_len:
    push si
    push ax
    xor cx, cx
.next:
    cmp cx, bx
    jae .done
    lodsb
    test al, al
    jz .done
    cmp al, 13
    je .done
    cmp al, 10
    je .done
    inc cx
    jmp .next
.done:
    pop ax
    pop si
    ret

ev_count_lines:
    push si
    push ax
    push cx
    xor ax, ax
    mov cx, [LOG_LEN]
    test cx, cx
    jz .store
    mov si, LOG_BUF
.scan:
    cmp byte [si], 10
    jne .next
    inc ax
.next:
    inc si
    loop .scan
    dec si
    cmp byte [si], 10
    je .store
    inc ax
.store:
    mov [EV_LINES], ax
    pop cx
    pop ax
    pop si
    ret

ev_line_ptr:
    push bx
    push ax
    mov si, LOG_BUF
    mov bx, LOG_BUF
    add bx, [LOG_LEN]
.skip:
    test cx, cx
    jz .found
.scan:
    cmp si, bx
    jae .none
    lodsb
    cmp al, 10
    jne .scan
    dec cx
    jmp .skip
.found:
    cmp si, bx
    jae .none
    clc
    jmp .out
.none:
    stc
.out:
    pop ax
    pop bx
    ret

ev_draw_all:
    pusha
    mov di, EV_PAGE
    mov ax, 0x0720
    mov cx, 2000
    rep stosw

    mov dh, 1
    mov dl, EV_X
    call ev_pos
    mov si, MSG_BOOT_LOAD
    mov bl, 0x07
    mov cx, 20
    call ev_text
    mov si, [BOOT_ARGS]
    mov bl, 0x0F
    mov cx, 40
    call ev_text
    mov si, MSG_BOOT_DOTS
    mov bl, 0x07
    mov cx, 3
    call ev_text

    mov dh, EV_Y
    mov dl, EV_X
    call ev_pos
    mov al, 0xC9
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    mov al, 0xCD
    mov cx, EV_W - 2
    call ev_fill
    mov al, 0xBB
    mov cx, 1
    call ev_fill

    mov dh, EV_Y
    mov dl, EV_X + 29
    call ev_pos
    mov si, MSG_EV_TITLE
    mov bl, 0x4F
    mov cx, 8
    call ev_text

    mov dh, EV_Y + 1
.mid:
    mov dl, EV_X
    call ev_pos
    mov al, 0xBA
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    mov al, ' '
    mov bl, 0x07
    mov cx, EV_W - 2
    call ev_fill
    mov al, 0xBA
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    inc dh
    cmp dh, EV_Y + EV_H - 1
    jb .mid

    mov dh, EV_Y + 5
    mov dl, EV_X
    call ev_pos
    mov al, 0xC7
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    mov al, 0xC4
    mov bl, 0x08
    mov cx, EV_W - 2
    call ev_fill
    mov al, 0xB6
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    mov dh, EV_Y + 5
    mov dl, EV_X + 2
    call ev_pos
    mov si, MSG_EV_LOGS
    mov bl, 0x0F
    mov cx, 10
    call ev_text

    mov dh, EV_Y + EV_H - 1
    mov dl, EV_X
    call ev_pos
    mov al, 0xC8
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    mov al, 0xCD
    mov cx, 28
    call ev_fill
    mov al, ' '
    mov cx, 1
    call ev_fill
    mov si, MSG_EV_OK
    mov bl, 0x70
    mov cx, 6
    call ev_text
    mov al, ' '
    mov bl, 0x0C
    mov cx, 1
    call ev_fill
    mov al, 0xCD
    mov cx, 28
    call ev_fill
    mov al, 0xBC
    mov cx, 1
    call ev_fill

    mov si, MSG_EV_CANNOT
    mov bx, 20
    call ev_len
    mov ax, cx
    mov si, [BOOT_ARGS]
    mov bx, 36
    call ev_len
    add ax, cx
    inc ax
    mov dx, EV_W
    sub dx, ax
    shr dx, 1
    add dl, EV_X
    mov dh, EV_Y + 2
    call ev_pos
    mov si, MSG_EV_CANNOT
    mov bl, 0x0F
    mov cx, 20
    call ev_text
    mov si, [BOOT_ARGS]
    mov bl, 0x0E
    mov cx, 36
    call ev_text
    mov si, MSG_EV_BANG
    mov bl, 0x0F
    mov cx, 1
    call ev_text

    mov si, [BOOT_RPFX]
    mov bx, 24
    call ev_len
    mov ax, cx
    mov si, [BOOT_REASON]
    mov bx, 54
    call ev_len
    add ax, cx
    mov dx, EV_W
    sub dx, ax
    shr dx, 1
    add dl, EV_X
    mov dh, EV_Y + 3
    call ev_pos
    mov si, [BOOT_RPFX]
    mov bl, 0x07
    mov cx, 24
    call ev_text
    mov si, [BOOT_REASON]
    mov bl, 0x0C
    mov cx, 54
    call ev_text

    mov dh, EV_Y + EV_H + 1
    mov dl, HINT_COL
    call ev_pos
    mov si, MSG_EV_HINT
    mov bl, 0x07
    mov cx, 60
    call ev_text

    call ev_draw_log
    popa
    ret

ev_draw_log:
    pusha
    xor bp, bp
.row:
    mov ax, bp
    add al, EV_LOG_Y
    mov dh, al
    mov dl, EV_LOG_X
    call ev_pos
    mov al, ' '
    mov bl, 0x07
    mov cx, EV_LOG_W
    call ev_fill
    mov cx, [EV_TOP]
    add cx, bp
    call ev_line_ptr
    jc .next
    mov bl, 0x07
    cmp byte [si], '!'
    jne .draw
    mov bl, 0x0C
.draw:
    call ev_pos
    mov cx, EV_LOG_W
    call ev_text
.next:
    inc bp
    cmp bp, EV_LOG_H
    jb .row
    call ev_draw_bar
    popa
    ret

ev_draw_bar:
    pusha
    mov bx, [EV_LINES]
    mov cx, EV_TRACK
    xor si, si
    cmp bx, EV_LOG_H
    jbe .have
    mov ax, EV_TRACK * EV_LOG_H
    xor dx, dx
    div bx
    mov cx, ax
    test cx, cx
    jnz .size_ok
    mov cx, 1
.size_ok:
    mov ax, EV_TRACK
    sub ax, cx
    mul word [EV_TOP]
    sub bx, EV_LOG_H
    div bx
    mov si, ax
.have:
    mov [EV_T0], si
    add si, cx
    mov [EV_T1], si
    xor bp, bp
.cell:
    mov ax, bp
    add al, EV_LOG_Y + 1
    mov dh, al
    mov dl, EV_BAR_X
    call ev_pos
    mov al, 0xB0
    mov bl, 0x08
    cmp bp, [EV_T0]
    jb .put
    cmp bp, [EV_T1]
    jae .put
    mov al, 0xDB
    mov bl, 0x0F
.put:
    mov cx, 1
    call ev_fill
    inc bp
    cmp bp, EV_TRACK
    jb .cell
    mov dh, EV_LOG_Y
    mov dl, EV_BAR_X
    call ev_pos
    mov al, 0x18
    mov bl, 0x08
    cmp word [EV_TOP], 0
    je .up_draw
    mov bl, 0x0E
.up_draw:
    mov cx, 1
    call ev_fill
    mov dh, EV_LOG_Y + EV_LOG_H - 1
    mov dl, EV_BAR_X
    call ev_pos
    mov bx, [EV_LINES]
    sub bx, EV_LOG_H
    jbe .dn_dim
    cmp [EV_TOP], bx
    jae .dn_dim
    mov bl, 0x0E
    jmp .dn_draw
.dn_dim:
    mov bl, 0x08
.dn_draw:
    mov al, 0x19
    mov cx, 1
    call ev_fill
    popa
    ret

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

    cmp byte [TARGET_MODE], MODE_LONG
    je setup_long_mode
    cmp byte [TARGET_MODE], MODE_REAL
    je pm_to_real
    jmp pm_terminal

pm_to_real:
    jmp CODE_SEG16:pm_to_real16

pm_scroll:
    push eax
    push ecx
    push esi
    push edi
    cld
    mov esi, VGA_BASE + 160
    mov edi, VGA_BASE
    mov ecx, 960
    rep movsd
    mov edi, VGA_BASE + 3840
    movzx eax, byte [TERM_ATTR]
    shl eax, 8
    or al, 0x20
    mov ecx, eax
    shl eax, 16
    or eax, ecx
    mov ecx, 40
    rep stosd
    pop edi
    pop esi
    pop ecx
    pop eax
    ret

pm_linefeed:
    inc byte [TERM_ROW]
    cmp byte [TERM_ROW], 25
    jb .ret
    mov byte [TERM_ROW], 24
    call pm_scroll
.ret:
    ret

pm_setcursor:
    push eax
    push ebx
    push edx
    movzx eax, byte [TERM_ROW]
    imul eax, eax, 80
    movzx ebx, byte [TERM_COL]
    add eax, ebx
    mov ebx, eax
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    dec dx
    mov al, 0x0E
    out dx, al
    inc dx
    mov al, bh
    out dx, al
    pop edx
    pop ebx
    pop eax
    ret

pm_putc:
    push eax
    push ebx
    push ecx
    cmp al, 13
    je .cr
    cmp al, 10
    je .lf
    cmp al, 8
    je .bs
    movzx ebx, byte [TERM_ROW]
    imul ebx, ebx, 80
    movzx ecx, byte [TERM_COL]
    add ebx, ecx
    mov [VGA_BASE + ebx * 2], al
    mov cl, [TERM_ATTR]
    mov [VGA_BASE + ebx * 2 + 1], cl
    inc byte [TERM_COL]
    cmp byte [TERM_COL], 80
    jb .done
    mov byte [TERM_COL], 0
    call pm_linefeed
    jmp .done
.cr:
    mov byte [TERM_COL], 0
    jmp .done
.lf:
    call pm_linefeed
    jmp .done
.bs:
    cmp byte [TERM_COL], 0
    je .done
    dec byte [TERM_COL]
.done:
    call pm_setcursor
    pop ecx
    pop ebx
    pop eax
    ret

pm_puts:
    push eax
    push esi
.next:
    mov al, [esi]
    test al, al
    jz .done
    call pm_putc
    inc esi
    jmp .next
.done:
    pop esi
    pop eax
    ret

pm_getkey:
    push ebx
.wait:
    in al, 0x64
    test al, 1
    jz .wait
    mov bl, al
    in al, 0x60
    test bl, 0x20
    jnz .wait
    cmp al, 0x2A
    je .shift_on
    cmp al, 0x36
    je .shift_on
    cmp al, 0xAA
    je .shift_off
    cmp al, 0xB6
    je .shift_off
    cmp al, 0x3A
    jae .wait
    movzx ebx, al
    cmp byte [KB_SHIFT], 0
    jne .upper
    mov al, [KEYMAP_LOW + ebx]
    jmp .have
.upper:
    mov al, [KEYMAP_HIGH + ebx]
.have:
    test al, al
    jz .wait
    pop ebx
    ret
.shift_on:
    mov byte [KB_SHIFT], 1
    jmp .wait
.shift_off:
    mov byte [KB_SHIFT], 0
    jmp .wait

pm_readline:
    push ebx
    push ecx
    push edi
    mov edi, INPUT_BUF
    xor ecx, ecx
.key:
    call pm_getkey
    cmp al, 13
    je .done
    cmp al, 8
    je .back
    cmp al, 0x20
    jb .key
    cmp ecx, 63
    jae .key
    mov [edi], al
    inc edi
    inc ecx
    call pm_putc
    jmp .key
.back:
    test ecx, ecx
    jz .key
    dec edi
    dec ecx
    mov al, 8
    call pm_putc
    mov al, ' '
    call pm_putc
    mov al, 8
    call pm_putc
    jmp .key
.done:
    mov byte [edi], 0
    mov al, 13
    call pm_putc
    mov al, 10
    call pm_putc
    pop edi
    pop ecx
    pop ebx
    ret

pm_match:
.loop:
    mov al, [esi]
    mov ah, [edi]
    test ah, ah
    jz .end
    or al, 0x20
    cmp al, ah
    jne .no
    inc esi
    inc edi
    jmp .loop
.end:
    mov al, [esi]
    cmp al, ' '
    je .yes
    test al, al
    je .yes
.no:
    clc
    ret
.yes:
    stc
    ret

pm_rtcprint:
    push ebx
    out 0x70, al
    in al, 0x71
    movzx eax, al
    cmp byte [RTC_BIN], 0
    jne .bin
    mov ah, al
    shr ah, 4
    and al, 0x0F
    jmp .out
.bin:
    mov bl, 10
    div bl
    xchg al, ah
.out:
    mov bl, al
    mov al, ah
    add al, '0'
    call pm_putc
    mov al, bl
    add al, '0'
    call pm_putc
    pop ebx
    ret

pm_time:
    mov al, 0x0A
    out 0x70, al
    in al, 0x71
    test al, 0x80
    jnz pm_time
    mov al, 0x0B
    out 0x70, al
    in al, 0x71
    shr al, 2
    and al, 1
    mov [RTC_BIN], al
    mov al, 4
    call pm_rtcprint
    mov al, ':'
    call pm_putc
    mov al, 2
    call pm_rtcprint
    mov al, ':'
    call pm_putc
    xor al, al
    call pm_rtcprint
    mov al, 13
    call pm_putc
    mov al, 10
    call pm_putc
    ret

pm_command:
    cmp byte [INPUT_BUF], 0
    je .ret

    mov esi, INPUT_BUF
    mov edi, CMD_HELP
    call pm_match
    jc .help

    mov esi, INPUT_BUF
    mov edi, CMD_ABOUT
    call pm_match
    jc .about

    mov esi, INPUT_BUF
    mov edi, CMD_TIME
    call pm_match
    jc .time

    mov esi, INPUT_BUF
    mov edi, CMD_REMODE
    call pm_match
    jc .remode

    mov esi, INPUT_BUF
    mov edi, CMD_CLOSE
    call pm_match
    jc .close

    mov esi, INPUT_BUF
    mov edi, CMD_EXIT
    call pm_match
    jc .exit

    mov esi, INPUT_BUF
    mov edi, CMD_SHUTDOWN
    call pm_match
    jc .shutdown

    mov esi, INPUT_BUF
    mov edi, CMD_BOOT
    call pm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_DIR
    call pm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_CD
    call pm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_TYPE
    call pm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_MULTIBOOT
    call pm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_SYSINF
    call pm_match
    jc .sysinf

    mov esi, INPUT_BUF
    mov edi, CMD_COLOR
    call pm_match
    jc .color

    mov esi, MSG_UNKNOWN
    call pm_puts
.ret:
    ret

.help:
    mov esi, MSG_HELP_EXT
    call pm_puts
    ret

.about:
    mov esi, MSG_ABOUT
    call pm_puts
    ret

.time:
    call pm_time
    ret

.sysinf:
    call pm_sysinf
    ret

.realonly:
    mov esi, MSG_REALONLY
    call pm_puts
    ret

.color:
    cmp byte [esi], ' '
    jne .col_have
    inc esi
    jmp .color
.col_have:
    cmp byte [esi], 0
    je .col_usage
    mov [COLOR_ARG], esi
    mov ebx, COLOR_TABLE
.col_next:
    movzx edi, word [ebx]
    test edi, edi
    jz .col_bad
    mov esi, [COLOR_ARG]
    call pm_match
    jc .col_found
    add ebx, 3
    jmp .col_next
.col_found:
    mov al, [ebx + 2]
    mov [TERM_ATTR], al
    mov byte [COLOR_SET], 1
    call pm_apply_color
    cmp byte [TERM_ATTR], 0x07
    jne .col_ok
    mov byte [COLOR_SET], 0
.col_ok:
    mov esi, MSG_COLOR_OK
    jmp .col_say
.col_usage:
    mov esi, MSG_COLOR_USAGE
    jmp .col_say
.col_bad:
    mov esi, MSG_COLOR_BAD
.col_say:
    call pm_puts
    ret

.close:
    mov byte [PENDING], 1
    jmp .to_real

.shutdown:
    mov al, 0
    call pm_confirm
    test al, al
    jz .ret
    mov byte [PENDING], 2
    jmp .to_real

.exit:
    mov al, 1
    call pm_confirm
    test al, al
    jz .ret
    mov byte [PENDING], 3

.to_real:
    mov byte [TARGET_MODE], MODE_REAL
    jmp protected_mode_main

.remode:
    cmp byte [esi], ' '
    jne .have_arg
    inc esi
    jmp .remode
.have_arg:
    cmp byte [esi], 0
    je .usage
    mov [REMODE_ARG], esi
    mov ebx, MODE_TABLE
.next:
    movzx edi, word [ebx]
    test edi, edi
    jz .bad
    mov esi, [REMODE_ARG]
    call pm_match
    jc .found
    add ebx, 3
    jmp .next
.found:
    mov al, [ebx + 2]
    cmp al, MODE_PROT
    je .same
    mov [TARGET_MODE], al
    cmp al, MODE_LONG
    jne .switch
    cmp byte [LM_OK], 1
    jne .nolong
.switch:
    jmp protected_mode_main
.usage:
    mov esi, MSG_REMODE_USAGE
    jmp .say
.bad:
    mov esi, MSG_REMODE_BAD
    jmp .say
.same:
    mov esi, MSG_REMODE_SAME
    jmp .say
.nolong:
    mov esi, MSG_REMODE_NOLONG
.say:
    call pm_puts
    ret

pm_gap:
    cmp byte [INPUT_BUF], 0
    je .ret
    push eax
    mov al, 13
    call pm_putc
    mov al, 10
    call pm_putc
    pop eax
.ret:
    ret

pm_apply_color:
    push eax
    push ebx
    push ecx
    mov al, [TERM_ATTR]
    mov bl, [COLOR_PREV]
    mov ecx, 2000
.l:
    mov bh, [VGA_BASE + ecx * 2 - 1]
    cmp bh, bl
    je .paint
    cmp bh, 0x07
    jne .skip
.paint:
    mov [VGA_BASE + ecx * 2 - 1], al
.skip:
    loop .l
    mov [COLOR_PREV], al
    pop ecx
    pop ebx
    pop eax
    ret

; ---- confirmation dialog (pm): AL = 0 shut down / 1 restart; returns AL = 1 (Yes) or 0 (No)
pm_confirm:
    mov [DLG_KIND], al
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov byte [DLG_SEL], 1
    call pm_dlg_hw_on
    call pm_dlg_save
    call pm_dlg_draw
.loop:
    call pm_dlg_buttons
    call pm_dlg_key
    cmp al, 1
    je .left
    cmp al, 2
    je .right
    cmp al, 3
    je .done
    cmp al, 4
    je .esc
    jmp .loop
.left:
    mov byte [DLG_SEL], 0
    jmp .loop
.right:
    mov byte [DLG_SEL], 1
    jmp .loop
.esc:
    mov byte [DLG_SEL], 1
.done:
    call pm_dlg_restore
    call pm_dlg_hw_off
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    mov al, 1
    cmp byte [DLG_SEL], 0
    je .ret
    xor al, al
.ret:
    ret

pm_dlg_hw_on:
    push eax
    push edx
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    in al, dx
    mov [DLG_CUR], al
    or al, 0x20
    out dx, al
    mov dx, 0x3DA
    in al, dx
    mov dx, 0x3C0
    mov al, 0x30
    out dx, al
    inc dx
    in al, dx
    and al, 0xF7
    dec dx
    out dx, al
    pop edx
    pop eax
    ret

pm_dlg_hw_off:
    push eax
    push edx
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    mov al, [DLG_CUR]
    out dx, al
    pop edx
    pop eax
    ret

pm_dlg_save:
    mov esi, DLG_SAVE
    mov ebx, (DLG_Y * 80 + DLG_X) * 2
    mov edx, DLG_H
.row:
    mov edi, ebx
    mov ecx, DLG_W
.col:
    mov ax, [VGA_BASE + edi]
    mov [esi], ax
    add esi, 2
    add edi, 2
    dec ecx
    jnz .col
    add ebx, 160
    dec edx
    jnz .row
    ret

pm_dlg_restore:
    mov esi, DLG_SAVE
    mov ebx, (DLG_Y * 80 + DLG_X) * 2
    mov edx, DLG_H
.row:
    mov edi, ebx
    mov ecx, DLG_W
.col:
    mov ax, [esi]
    mov [VGA_BASE + edi], ax
    add esi, 2
    add edi, 2
    dec ecx
    jnz .col
    add ebx, 160
    dec edx
    jnz .row
    ret

pm_dlg_row:
    push edi
    push ecx
    mov [VGA_BASE + edi], al
    mov byte [VGA_BASE + edi+1], DLG_ATTR
    add edi, 2
    mov ecx, DLG_W - 2
.fill:
    mov [VGA_BASE + edi], ah
    mov byte [VGA_BASE + edi+1], DLG_ATTR
    add edi, 2
    dec ecx
    jnz .fill
    mov [VGA_BASE + edi], dl
    mov byte [VGA_BASE + edi+1], DLG_ATTR
    pop ecx
    pop edi
    ret

pm_dlg_draw:
    mov edi, (DLG_Y * 80 + DLG_X) * 2
    mov al, 0xC9
    mov ah, 0xCD
    mov dl, 0xBB
    call pm_dlg_row
    mov ecx, DLG_H - 2
.mid:
    add edi, 160
    mov al, 0xBA
    mov ah, ' '
    mov dl, 0xBA
    call pm_dlg_row
    dec ecx
    jnz .mid
    add edi, 160
    mov al, 0xC8
    mov ah, 0xCD
    mov dl, 0xBC
    call pm_dlg_row
    mov esi, DLG_TXT_SHUT
    cmp byte [DLG_KIND], 0
    je .txt
    mov esi, DLG_TXT_REBOOT
.txt:
    mov ebx, ((DLG_Y + 2) * 80 + DLG_X + 1) * 2
    mov edx, 2
.line:
    mov edi, ebx
    mov ecx, DLG_W - 2
.ch:
    mov al, [esi]
    mov [VGA_BASE + edi], al
    inc esi
    add edi, 2
    dec ecx
    jnz .ch
    add ebx, 160
    dec edx
    jnz .line
    ret

pm_dlg_btn:
    push eax
    push esi
    push edi
.next:
    mov al, [esi]
    test al, al
    jz .done
    mov [VGA_BASE + edi], al
    mov [VGA_BASE + edi+1], bl
    inc esi
    add edi, 2
    jmp .next
.done:
    pop edi
    pop esi
    pop eax
    ret

pm_dlg_buttons:
    mov bl, DLG_ATTR
    cmp byte [DLG_SEL], 0
    jne .yes
    mov bl, DLG_ATTR_SEL
.yes:
    mov esi, DLG_STR_YES
    mov edi, ((DLG_Y + DLG_H - 1) * 80 + DLG_X + 9) * 2
    call pm_dlg_btn
    mov bl, DLG_ATTR
    cmp byte [DLG_SEL], 1
    jne .no
    mov bl, DLG_ATTR_SEL
.no:
    mov esi, DLG_STR_NO
    mov edi, ((DLG_Y + DLG_H - 1) * 80 + DLG_X + 27) * 2
    call pm_dlg_btn
    ret

pm_dlg_key:
.wait:
    in al, 0x64
    test al, 1
    jz .wait
    mov ah, al
    in al, 0x60
    test ah, 0x20
    jnz .wait
    cmp al, 0xE0
    je .wait
    cmp al, 0x4B
    je .left
    cmp al, 0x4D
    je .right
    cmp al, 0x1C
    je .enter
    cmp al, 0x01
    je .esc
    xor al, al
    ret
.left:
    mov al, 1
    ret
.right:
    mov al, 2
    ret
.enter:
    mov al, 3
    ret
.esc:
    mov al, 4
    ret
; ---- sysinf (pm)
pm_sysinf:
    push eax
    push esi
    mov al, [TERM_ATTR]
    mov [SYSI_DEF], al
    mov esi, SYSI_STREAM
    call sysi_run32
    mov al, [SYSI_DEF]
    mov [TERM_ATTR], al
    pop esi
    pop eax
    ret

; styled stream renderer (see sysi_run16); the colour lives in TERM_ATTR
sysi_run32:
    push eax
    push ebx
    push esi
.next:
    mov al, [esi]
    inc esi
    test al, al
    jz .end
    cmp al, 1
    je .attr
    cmp al, 2
    je .ram
    cmp al, 3
    je .cpu
    cmp al, 4
    je .nos
    cmp al, 5
    je .mode
    cmp al, 13
    je .nl
    cmp al, 10
    je .nl
    call pm_putc
    jmp .next
.attr:
    mov al, [esi]
    inc esi
    mov [TERM_ATTR], al
    jmp .next
.nl:
    mov ah, [SYSI_DEF]
    mov [TERM_ATTR], ah
    call pm_putc
    jmp .next
.ram:
    mov eax, [SYS_RAM_MB]
    call pm_putdec
    jmp .next
.cpu:
    mov ebx, SYSI_CPU64
    cmp byte [SYS_CPU64], 0
    jne .sub
    mov ebx, SYSI_CPU32
    jmp .sub
.nos:
    mov ebx, SYSI_NOS_OK
    cmp byte [SYS_CANRUN], 0
    jne .sub
    mov ebx, SYSI_NOS_NO
    jmp .sub
.mode:
    movzx eax, byte [CUR_MODE]
    movzx ebx, word [SYSI_MODE_TAB + eax * 2]
.sub:
    push esi
    mov esi, ebx
    call sysi_run32
    pop esi
    jmp .next
.end:
    pop esi
    pop ebx
    pop eax
    ret

pm_putdec:
    push eax
    push ebx
    push ecx
    push edx
    mov ebx, 10
    xor ecx, ecx
.div:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz .div
.out:
    pop edx
    mov al, dl
    add al, '0'
    call pm_putc
    dec ecx
    jnz .out
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

pm_terminal:
    cld
    mov byte [CUR_MODE], MODE_PROT
    mov byte [KB_SHIFT], 0
    mov esi, MSG_MODE_PM
    call pm_puts
    mov esi, MSG_FAT_NL
    call pm_puts
.loop:
    mov esi, MSG_PROMPT
    call pm_puts
    call pm_readline
    call pm_command
    call pm_gap
    jmp .loop

[BITS 16]
pm_to_real16:
    mov ax, DATA_SEG16
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov eax, cr0
    and eax, 0x7FFFFFFE
    mov cr0, eax
    jmp 0x0000:real_return

real_return:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00
    lidt [REAL_IDT]
    mov byte [CUR_MODE], MODE_REAL
    call kbd_flush
    mov ah, 0x02
    xor bh, bh
    mov dh, [TERM_ROW]
    mov dl, [TERM_COL]
    int 0x10
    mov al, [PENDING]
    mov byte [PENDING], 0
    cmp al, 1
    je close_terminal
    cmp al, 2
    je .shutdown
    cmp al, 3
    je .reboot
    cmp al, 4
    je boot_fault_entry
    mov si, MSG_MODE_REAL
    call print_string
    call print_gap
    jmp terminal_loop
.shutdown:
    call do_shutdown
    cli
    hlt
    jmp $
.reboot:
    call do_reboot
    cli
    hlt
    jmp $

[BITS 32]

PML4_ADDR equ 0x70000
PDPT_ADDR equ 0x71000
PD_ADDR   equ 0x72000

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

    mov esp, 0x90000
    jmp lm_terminal

lm_scroll:
    push rax
    push rcx
    push rsi
    push rdi
    cld
    mov esi, VGA_BASE + 160
    mov edi, VGA_BASE
    mov ecx, 960
    rep movsd
    mov edi, VGA_BASE + 3840
    movzx eax, byte [TERM_ATTR]
    shl eax, 8
    or al, 0x20
    mov ecx, eax
    shl eax, 16
    or eax, ecx
    mov ecx, 40
    rep stosd
    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret

lm_linefeed:
    inc byte [TERM_ROW]
    cmp byte [TERM_ROW], 25
    jb .ret
    mov byte [TERM_ROW], 24
    call lm_scroll
.ret:
    ret

lm_setcursor:
    push rax
    push rbx
    push rdx
    movzx eax, byte [TERM_ROW]
    imul eax, eax, 80
    movzx ebx, byte [TERM_COL]
    add eax, ebx
    mov ebx, eax
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    dec dx
    mov al, 0x0E
    out dx, al
    inc dx
    mov al, bh
    out dx, al
    pop rdx
    pop rbx
    pop rax
    ret

lm_putc:
    push rax
    push rbx
    push rcx
    cmp al, 13
    je .cr
    cmp al, 10
    je .lf
    cmp al, 8
    je .bs
    movzx ebx, byte [TERM_ROW]
    imul ebx, ebx, 80
    movzx ecx, byte [TERM_COL]
    add ebx, ecx
    mov [VGA_BASE + rbx * 2], al
    mov cl, [TERM_ATTR]
    mov [VGA_BASE + rbx * 2 + 1], cl
    inc byte [TERM_COL]
    cmp byte [TERM_COL], 80
    jb .done
    mov byte [TERM_COL], 0
    call lm_linefeed
    jmp .done
.cr:
    mov byte [TERM_COL], 0
    jmp .done
.lf:
    call lm_linefeed
    jmp .done
.bs:
    cmp byte [TERM_COL], 0
    je .done
    dec byte [TERM_COL]
.done:
    call lm_setcursor
    pop rcx
    pop rbx
    pop rax
    ret

lm_puts:
    push rax
    push rsi
.next:
    mov al, [rsi]
    test al, al
    jz .done
    call lm_putc
    inc rsi
    jmp .next
.done:
    pop rsi
    pop rax
    ret

lm_getkey:
    push rbx
.wait:
    in al, 0x64
    test al, 1
    jz .wait
    mov bl, al
    in al, 0x60
    test bl, 0x20
    jnz .wait
    cmp al, 0x2A
    je .shift_on
    cmp al, 0x36
    je .shift_on
    cmp al, 0xAA
    je .shift_off
    cmp al, 0xB6
    je .shift_off
    cmp al, 0x3A
    jae .wait
    movzx ebx, al
    cmp byte [KB_SHIFT], 0
    jne .upper
    mov al, [KEYMAP_LOW + rbx]
    jmp .have
.upper:
    mov al, [KEYMAP_HIGH + rbx]
.have:
    test al, al
    jz .wait
    pop rbx
    ret
.shift_on:
    mov byte [KB_SHIFT], 1
    jmp .wait
.shift_off:
    mov byte [KB_SHIFT], 0
    jmp .wait

lm_readline:
    push rbx
    push rcx
    push rdi
    mov edi, INPUT_BUF
    xor ecx, ecx
.key:
    call lm_getkey
    cmp al, 13
    je .done
    cmp al, 8
    je .back
    cmp al, 0x20
    jb .key
    cmp ecx, 63
    jae .key
    mov [rdi], al
    inc rdi
    inc ecx
    call lm_putc
    jmp .key
.back:
    test ecx, ecx
    jz .key
    dec rdi
    dec ecx
    mov al, 8
    call lm_putc
    mov al, ' '
    call lm_putc
    mov al, 8
    call lm_putc
    jmp .key
.done:
    mov byte [rdi], 0
    mov al, 13
    call lm_putc
    mov al, 10
    call lm_putc
    pop rdi
    pop rcx
    pop rbx
    ret

lm_match:
.loop:
    mov al, [rsi]
    mov ah, [rdi]
    test ah, ah
    jz .end
    or al, 0x20
    cmp al, ah
    jne .no
    inc rsi
    inc rdi
    jmp .loop
.end:
    mov al, [rsi]
    cmp al, ' '
    je .yes
    test al, al
    je .yes
.no:
    clc
    ret
.yes:
    stc
    ret

lm_rtcprint:
    push rbx
    out 0x70, al
    in al, 0x71
    movzx eax, al
    cmp byte [RTC_BIN], 0
    jne .bin
    mov ah, al
    shr ah, 4
    and al, 0x0F
    jmp .out
.bin:
    mov bl, 10
    div bl
    xchg al, ah
.out:
    mov bl, al
    mov al, ah
    add al, '0'
    call lm_putc
    mov al, bl
    add al, '0'
    call lm_putc
    pop rbx
    ret

lm_time:
    mov al, 0x0A
    out 0x70, al
    in al, 0x71
    test al, 0x80
    jnz lm_time
    mov al, 0x0B
    out 0x70, al
    in al, 0x71
    shr al, 2
    and al, 1
    mov [RTC_BIN], al
    mov al, 4
    call lm_rtcprint
    mov al, ':'
    call lm_putc
    mov al, 2
    call lm_rtcprint
    mov al, ':'
    call lm_putc
    xor al, al
    call lm_rtcprint
    mov al, 13
    call lm_putc
    mov al, 10
    call lm_putc
    ret

lm_command:
    cmp byte [INPUT_BUF], 0
    je .ret

    mov esi, INPUT_BUF
    mov edi, CMD_HELP
    call lm_match
    jc .help

    mov esi, INPUT_BUF
    mov edi, CMD_ABOUT
    call lm_match
    jc .about

    mov esi, INPUT_BUF
    mov edi, CMD_TIME
    call lm_match
    jc .time

    mov esi, INPUT_BUF
    mov edi, CMD_REMODE
    call lm_match
    jc .remode

    mov esi, INPUT_BUF
    mov edi, CMD_CLOSE
    call lm_match
    jc .close

    mov esi, INPUT_BUF
    mov edi, CMD_EXIT
    call lm_match
    jc .exit

    mov esi, INPUT_BUF
    mov edi, CMD_SHUTDOWN
    call lm_match
    jc .shutdown

    mov esi, INPUT_BUF
    mov edi, CMD_BOOT
    call lm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_DIR
    call lm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_CD
    call lm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_TYPE
    call lm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_MULTIBOOT
    call lm_match
    jc .realonly

    mov esi, INPUT_BUF
    mov edi, CMD_SYSINF
    call lm_match
    jc .sysinf

    mov esi, INPUT_BUF
    mov edi, CMD_COLOR
    call lm_match
    jc .color

    mov esi, MSG_UNKNOWN
    call lm_puts
.ret:
    ret

.help:
    mov esi, MSG_HELP_EXT
    call lm_puts
    ret

.about:
    mov esi, MSG_ABOUT
    call lm_puts
    ret

.time:
    call lm_time
    ret

.sysinf:
    call lm_sysinf
    ret

.realonly:
    mov esi, MSG_REALONLY
    call lm_puts
    ret

.color:
    cmp byte [rsi], ' '
    jne .col_have
    inc rsi
    jmp .color
.col_have:
    cmp byte [rsi], 0
    je .col_usage
    mov [COLOR_ARG], esi
    mov ebx, COLOR_TABLE
.col_next:
    movzx edi, word [rbx]
    test edi, edi
    jz .col_bad
    mov esi, [COLOR_ARG]
    call lm_match
    jc .col_found
    add ebx, 3
    jmp .col_next
.col_found:
    mov al, [rbx + 2]
    mov [TERM_ATTR], al
    mov byte [COLOR_SET], 1
    call lm_apply_color
    cmp byte [TERM_ATTR], 0x07
    jne .col_ok
    mov byte [COLOR_SET], 0
.col_ok:
    mov esi, MSG_COLOR_OK
    jmp .col_say
.col_usage:
    mov esi, MSG_COLOR_USAGE
    jmp .col_say
.col_bad:
    mov esi, MSG_COLOR_BAD
.col_say:
    call lm_puts
    ret

.close:
    mov byte [PENDING], 1
    jmp .to_real

.shutdown:
    mov al, 0
    call lm_confirm
    test al, al
    jz .ret
    mov byte [PENDING], 2
    jmp .to_real

.exit:
    mov al, 1
    call lm_confirm
    test al, al
    jz .ret
    mov byte [PENDING], 3

.to_real:
    mov byte [TARGET_MODE], MODE_REAL
    jmp long_leave

.remode:
    cmp byte [rsi], ' '
    jne .have_arg
    inc rsi
    jmp .remode
.have_arg:
    cmp byte [rsi], 0
    je .usage
    mov [REMODE_ARG], esi
    mov ebx, MODE_TABLE
.next:
    movzx edi, word [rbx]
    test edi, edi
    jz .bad
    mov esi, [REMODE_ARG]
    call lm_match
    jc .found
    add ebx, 3
    jmp .next
.found:
    mov al, [rbx + 2]
    cmp al, MODE_LONG
    je .same
    mov [TARGET_MODE], al
    cmp al, MODE_LONG
    jne .switch
    cmp byte [LM_OK], 1
    jne .nolong
.switch:
    jmp long_leave
.usage:
    mov esi, MSG_REMODE_USAGE
    jmp .say
.bad:
    mov esi, MSG_REMODE_BAD
    jmp .say
.same:
    mov esi, MSG_REMODE_SAME
    jmp .say
.nolong:
    mov esi, MSG_REMODE_NOLONG
.say:
    call lm_puts
    ret

lm_gap:
    cmp byte [INPUT_BUF], 0
    je .ret
    push rax
    mov al, 13
    call lm_putc
    mov al, 10
    call lm_putc
    pop rax
.ret:
    ret

lm_apply_color:
    push rax
    push rbx
    push rcx
    mov al, [TERM_ATTR]
    mov bl, [COLOR_PREV]
    mov ecx, 2000
.l:
    mov bh, [VGA_BASE + rcx * 2 - 1]
    cmp bh, bl
    je .paint
    cmp bh, 0x07
    jne .skip
.paint:
    mov [VGA_BASE + rcx * 2 - 1], al
.skip:
    loop .l
    mov [COLOR_PREV], al
    pop rcx
    pop rbx
    pop rax
    ret

; ---- confirmation dialog (lm): AL = 0 shut down / 1 restart; returns AL = 1 (Yes) or 0 (No)
lm_confirm:
    mov [DLG_KIND], al
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov byte [DLG_SEL], 1
    call lm_dlg_hw_on
    call lm_dlg_save
    call lm_dlg_draw
.loop:
    call lm_dlg_buttons
    call lm_dlg_key
    cmp al, 1
    je .left
    cmp al, 2
    je .right
    cmp al, 3
    je .done
    cmp al, 4
    je .esc
    jmp .loop
.left:
    mov byte [DLG_SEL], 0
    jmp .loop
.right:
    mov byte [DLG_SEL], 1
    jmp .loop
.esc:
    mov byte [DLG_SEL], 1
.done:
    call lm_dlg_restore
    call lm_dlg_hw_off
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov al, 1
    cmp byte [DLG_SEL], 0
    je .ret
    xor al, al
.ret:
    ret

lm_dlg_hw_on:
    push rax
    push rdx
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    in al, dx
    mov [DLG_CUR], al
    or al, 0x20
    out dx, al
    mov dx, 0x3DA
    in al, dx
    mov dx, 0x3C0
    mov al, 0x30
    out dx, al
    inc dx
    in al, dx
    and al, 0xF7
    dec dx
    out dx, al
    pop rdx
    pop rax
    ret

lm_dlg_hw_off:
    push rax
    push rdx
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    mov al, [DLG_CUR]
    out dx, al
    pop rdx
    pop rax
    ret

lm_dlg_save:
    mov esi, DLG_SAVE
    mov ebx, (DLG_Y * 80 + DLG_X) * 2
    mov edx, DLG_H
.row:
    mov rdi, rbx
    mov ecx, DLG_W
.col:
    mov ax, [VGA_BASE + rdi]
    mov [rsi], ax
    add rsi, 2
    add rdi, 2
    dec ecx
    jnz .col
    add rbx, 160
    dec edx
    jnz .row
    ret

lm_dlg_restore:
    mov esi, DLG_SAVE
    mov ebx, (DLG_Y * 80 + DLG_X) * 2
    mov edx, DLG_H
.row:
    mov rdi, rbx
    mov ecx, DLG_W
.col:
    mov ax, [rsi]
    mov [VGA_BASE + rdi], ax
    add rsi, 2
    add rdi, 2
    dec ecx
    jnz .col
    add rbx, 160
    dec edx
    jnz .row
    ret

lm_dlg_row:
    push rdi
    push rcx
    mov [VGA_BASE + rdi], al
    mov byte [VGA_BASE + rdi+1], DLG_ATTR
    add rdi, 2
    mov ecx, DLG_W - 2
.fill:
    mov [VGA_BASE + rdi], ah
    mov byte [VGA_BASE + rdi+1], DLG_ATTR
    add rdi, 2
    dec ecx
    jnz .fill
    mov [VGA_BASE + rdi], dl
    mov byte [VGA_BASE + rdi+1], DLG_ATTR
    pop rcx
    pop rdi
    ret

lm_dlg_draw:
    mov edi, (DLG_Y * 80 + DLG_X) * 2
    mov al, 0xC9
    mov ah, 0xCD
    mov dl, 0xBB
    call lm_dlg_row
    mov ecx, DLG_H - 2
.mid:
    add rdi, 160
    mov al, 0xBA
    mov ah, ' '
    mov dl, 0xBA
    call lm_dlg_row
    dec ecx
    jnz .mid
    add rdi, 160
    mov al, 0xC8
    mov ah, 0xCD
    mov dl, 0xBC
    call lm_dlg_row
    mov esi, DLG_TXT_SHUT
    cmp byte [DLG_KIND], 0
    je .txt
    mov esi, DLG_TXT_REBOOT
.txt:
    mov ebx, ((DLG_Y + 2) * 80 + DLG_X + 1) * 2
    mov edx, 2
.line:
    mov rdi, rbx
    mov ecx, DLG_W - 2
.ch:
    mov al, [rsi]
    mov [VGA_BASE + rdi], al
    inc rsi
    add rdi, 2
    dec ecx
    jnz .ch
    add rbx, 160
    dec edx
    jnz .line
    ret

lm_dlg_btn:
    push rax
    push rsi
    push rdi
.next:
    mov al, [rsi]
    test al, al
    jz .done
    mov [VGA_BASE + rdi], al
    mov [VGA_BASE + rdi+1], bl
    inc rsi
    add rdi, 2
    jmp .next
.done:
    pop rdi
    pop rsi
    pop rax
    ret

lm_dlg_buttons:
    mov bl, DLG_ATTR
    cmp byte [DLG_SEL], 0
    jne .yes
    mov bl, DLG_ATTR_SEL
.yes:
    mov esi, DLG_STR_YES
    mov edi, ((DLG_Y + DLG_H - 1) * 80 + DLG_X + 9) * 2
    call lm_dlg_btn
    mov bl, DLG_ATTR
    cmp byte [DLG_SEL], 1
    jne .no
    mov bl, DLG_ATTR_SEL
.no:
    mov esi, DLG_STR_NO
    mov edi, ((DLG_Y + DLG_H - 1) * 80 + DLG_X + 27) * 2
    call lm_dlg_btn
    ret

lm_dlg_key:
.wait:
    in al, 0x64
    test al, 1
    jz .wait
    mov ah, al
    in al, 0x60
    test ah, 0x20
    jnz .wait
    cmp al, 0xE0
    je .wait
    cmp al, 0x4B
    je .left
    cmp al, 0x4D
    je .right
    cmp al, 0x1C
    je .enter
    cmp al, 0x01
    je .esc
    xor al, al
    ret
.left:
    mov al, 1
    ret
.right:
    mov al, 2
    ret
.enter:
    mov al, 3
    ret
.esc:
    mov al, 4
    ret
; ---- sysinf (lm)
lm_sysinf:
    push rax
    push rsi
    mov al, [TERM_ATTR]
    mov [SYSI_DEF], al
    mov esi, SYSI_STREAM
    call sysi_run64
    mov al, [SYSI_DEF]
    mov [TERM_ATTR], al
    pop rsi
    pop rax
    ret

; styled stream renderer (see sysi_run16); the colour lives in TERM_ATTR
sysi_run64:
    push rax
    push rbx
    push rsi
.next:
    mov al, [rsi]
    inc rsi
    test al, al
    jz .end
    cmp al, 1
    je .attr
    cmp al, 2
    je .ram
    cmp al, 3
    je .cpu
    cmp al, 4
    je .nos
    cmp al, 5
    je .mode
    cmp al, 13
    je .nl
    cmp al, 10
    je .nl
    call lm_putc
    jmp .next
.attr:
    mov al, [rsi]
    inc rsi
    mov [TERM_ATTR], al
    jmp .next
.nl:
    mov ah, [SYSI_DEF]
    mov [TERM_ATTR], ah
    call lm_putc
    jmp .next
.ram:
    mov eax, [SYS_RAM_MB]
    call lm_putdec
    jmp .next
.cpu:
    mov ebx, SYSI_CPU64
    cmp byte [SYS_CPU64], 0
    jne .sub
    mov ebx, SYSI_CPU32
    jmp .sub
.nos:
    mov ebx, SYSI_NOS_OK
    cmp byte [SYS_CANRUN], 0
    jne .sub
    mov ebx, SYSI_NOS_NO
    jmp .sub
.mode:
    movzx eax, byte [CUR_MODE]
    movzx ebx, word [SYSI_MODE_TAB + rax * 2]
.sub:
    push rsi
    mov esi, ebx
    call sysi_run64
    pop rsi
    jmp .next
.end:
    pop rsi
    pop rbx
    pop rax
    ret

lm_putdec:
    push rax
    push rbx
    push rcx
    push rdx
    mov ebx, 10
    xor ecx, ecx
.div:
    xor edx, edx
    div ebx
    push rdx
    inc ecx
    test eax, eax
    jnz .div
.out:
    pop rdx
    mov al, dl
    add al, '0'
    call lm_putc
    dec ecx
    jnz .out
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

lm_terminal:
    cld
    mov byte [CUR_MODE], MODE_LONG
    mov byte [KB_SHIFT], 0
    mov esi, MSG_MODE_LM
    call lm_puts
    mov esi, MSG_FAT_NL
    call lm_puts
.loop:
    mov esi, MSG_PROMPT
    call lm_puts
    call lm_readline
    call lm_command
    call lm_gap
    jmp .loop

long_leave:
    cli
    mov eax, DATA_SEGC
    push rax
    mov eax, 0x90000
    push rax
    pushfq
    mov eax, CODE_SEGC
    push rax
    mov eax, long_compat
    push rax
    iretq

[BITS 32]
long_compat:
    mov ax, DATA_SEGC
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov eax, cr0
    and eax, 0x7FFFFFFF
    mov cr0, eax
    mov ecx, 0xC0000080
    rdmsr
    and eax, 0xFFFFFEFF
    wrmsr
    mov eax, cr4
    and eax, 0xFFFFFFDF
    mov cr4, eax
    lgdt [gdt32.pointer]
    jmp CODE_SEG32:protected_mode_main

[BITS 32]
kernel_pm32:
    mov ax, DATA_SEG32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, BOOT_STACK
    lidt [idt32.pointer]
    mov eax, BOOT_MAGIC
    mov ebx, BOOT_INFO
    mov ecx, [BOOT_ENTRY]
    jmp ecx

kernel_long32:
    mov ax, DATA_SEG32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, BOOT_STACK
    cld
    mov edi, PML4_ADDR
    xor eax, eax
    mov ecx, 0x6000 / 4
    rep stosd
    mov dword [PML4_ADDR], PDPT_ADDR | 3
    mov dword [PML4_ADDR + 511 * 8], PDPT_ADDR | 3
    mov edi, PDPT_ADDR
    mov eax, PD_ADDR | 3
    mov ecx, 4
.pdpt:
    mov [edi], eax
    add edi, 8
    add eax, 0x1000
    loop .pdpt
    mov dword [PDPT_ADDR + 510 * 8], PD_ADDR | 3
    mov edi, PD_ADDR
    mov eax, 0x83
    mov ecx, 2048
.pd:
    mov [edi], eax
    add edi, 8
    add eax, 0x200000
    loop .pd
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
    jmp CODE_SEG64:kernel_long64

[BITS 64]
kernel_long64:
    mov ax, DATA_SEG64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, BOOT_STACK
    lidt [idt64.pointer]
    mov eax, BOOT_MAGIC
    mov ebx, BOOT_INFO
    mov edi, BOOT_INFO
    mov rcx, [BOOT_ENTRY]
    jmp rcx

[BITS 32]

%macro EXC32 2
    align 16
%if %2 == 0
    push dword 0
%endif
    push dword %1
    jmp exc32_common
%endmacro

exc32_common:
    cli
    cld
    mov ax, DATA_SEG32
    mov ds, ax
    mov es, ax
    pop eax
    mov [FAULT_VEC], eax
    pop eax
    mov [FAULT_ERR], eax
    pop eax
    mov [FAULT_IP], eax
    mov dword [FAULT_IP + 4], 0
    pop eax
    mov [FAULT_CS], eax
    pop eax
    mov [FAULT_FLAGS], eax
    mov [FAULT_SP], esp
    mov dword [FAULT_SP + 4], 0
    mov dword [FAULT_CR2], 0
    mov dword [FAULT_CR2 + 4], 0
    mov byte [FAULT_LONG], 0
    mov byte [TARGET_MODE], MODE_REAL
    mov byte [PENDING], 4
    jmp CODE_SEG16:pm_to_real16

align 16
exc32_stubs:
%assign EXCN 0
%rep 32
%if (EXCN == 8) || (EXCN == 10) || (EXCN == 11) || (EXCN == 12) || (EXCN == 13) || (EXCN == 14) || (EXCN == 17) || (EXCN == 21) || (EXCN == 29) || (EXCN == 30)
    EXC32 EXCN, 1
%else
    EXC32 EXCN, 0
%endif
%assign EXCN EXCN + 1
%endrep
%undef EXCN

idt32:
%assign EXCN 0
%rep 32
    dw exc32_stubs + EXCN * 16
    dw CODE_SEG32
    db 0
    db 0x8E
    dw 0
%assign EXCN EXCN + 1
%endrep
%undef EXCN
.end:
.pointer:
    dw .end - idt32 - 1
    dd idt32

[BITS 64]
%macro EXC64 2
    align 16
%if %2 == 0
    push qword 0
%endif
    push qword %1
    jmp exc64_common
%endmacro

exc64_common:
    cli
    cld
    pop rax
    mov [FAULT_VEC], eax
    pop rax
    mov [FAULT_ERR], eax
    pop rax
    mov [FAULT_IP], rax
    pop rax
    mov [FAULT_CS], eax
    pop rax
    mov [FAULT_FLAGS], eax
    pop rax
    mov [FAULT_SP], rax
    mov rax, cr2
    mov [FAULT_CR2], rax
    mov byte [FAULT_LONG], 1
    mov byte [TARGET_MODE], MODE_REAL
    mov byte [PENDING], 4
    jmp long_leave

align 16
exc64_stubs:
%assign EXCN 0
%rep 32
%if (EXCN == 8) || (EXCN == 10) || (EXCN == 11) || (EXCN == 12) || (EXCN == 13) || (EXCN == 14) || (EXCN == 17) || (EXCN == 21) || (EXCN == 29) || (EXCN == 30)
    EXC64 EXCN, 1
%else
    EXC64 EXCN, 0
%endif
%assign EXCN EXCN + 1
%endrep
%undef EXCN

idt64:
%assign EXCN 0
%rep 32
    dw exc64_stubs + EXCN * 16
    dw CODE_SEG64
    db 0
    db 0x8E
    dw 0
    dd 0
    dd 0
%assign EXCN EXCN + 1
%endrep
%undef EXCN
.end:
.pointer:
    dw .end - idt64 - 1
    dq idt64

[BITS 32]

gdt32:
    dq 0x0000000000000000

    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 00000000b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 00000000b, 0x00
.pointer:
    dw $ - gdt32 - 1
    dd gdt32

CODE_SEG32 equ 0x08
DATA_SEG32 equ 0x10
CODE_SEG16 equ 0x18
DATA_SEG16 equ 0x20

gdt64:
    dq 0x0000000000000000

    dw 0x0000, 0x0000
    db 0x00, 10011010b, 00100000b, 0x00

    dw 0x0000, 0x0000
    db 0x00, 10010010b, 00000000b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

CODE_SEG64 equ 0x08
DATA_SEG64 equ 0x10
CODE_SEGC equ 0x18
DATA_SEGC equ 0x20

times LOW_SECTORS * 512 - ($ - $$) db 0

image_blob:
%include "image_data.inc"
anim_blob:
anim_start:
    incbin "anim.bin", 0, ANIM_START_FRAMES * ANIM_FRAME_BYTES
anim_inf:
    incbin "anim.bin", ANIM_START_FRAMES * ANIM_FRAME_BYTES, ANIM_INF_FRAMES * ANIM_FRAME_BYTES
image_end:

times ((512 - (($ - $$) % 512)) % 512) db 0
