#!/bin/bash
set -e
LOW_SECTORS=$(awk '$1=="LOW_SECTORS" {print $3}' boot2.asm)
HIGH_BASE=$(awk '$1=="HIGH_BASE" {print $3}' boot2.asm)
PART_LBA=$(awk '$1=="FAT32_LBA" {print $3}' boot2.asm)
CHUNK_SECTORS=$(awk '$1=="CHUNK_SECTORS" {print $3}' boot1.asm)

if [ -f mkanim.py ] && [ -d START ] && [ -d INFINITE ]; then python3 mkanim.py; fi

nasm -f bin boot2.asm -o boot2.bin || { echo "boot2.asm failed to assemble (if it says TIMES value is negative: the code part of stage 2 no longer fits into LOW_SECTORS * 512 bytes)"; exit 1; }

SIZE=$(stat -c%s boot2.bin)
STAGE2_SECTORS=$(( (SIZE + 511) / 512 ))
READ_SECTORS=$(( (STAGE2_SECTORS + CHUNK_SECTORS - 1) / CHUNK_SECTORS * CHUNK_SECTORS ))
if [ $((READ_SECTORS + 1)) -gt "$PART_LBA" ]; then
    echo "boot2.bin is too big: $SIZE bytes does not fit before the FAT32 partition (raise FAT32_LBA in boot2.asm)"
    exit 1
fi

# Stage 1 loads only the code part of stage 2 (LOW_SECTORS) - NXBoot starts right away.
# The image + animation blob behind it is read by stage 2 itself, when the splash is needed.
nasm -f bin boot1.asm -DSTAGE2_SECTORS=$LOW_SECTORS -DLOW_SECTORS=$LOW_SECTORS -DHIGH_BASE=$HIGH_BASE -o boot1.bin

cat boot1.bin boot2.bin > disk.img
truncate -s 64M disk.img
mkfs.fat -F 32 --offset $PART_LBA disk.img $(( (131072 - PART_LBA) / 2 ))
printf 'NixelOS FAT32 test\n' | MTOOLS_SKIP_CHECK=1 mcopy -i disk.img@@$((PART_LBA * 512)) - ::TEST.TXT
for K in kernel.elf kernel.bin boot.cfg; do
    if [ -f "$K" ]; then
        MTOOLS_SKIP_CHECK=1 mcopy -i disk.img@@$((PART_LBA * 512)) "$K" "::$K"
    fi
done
