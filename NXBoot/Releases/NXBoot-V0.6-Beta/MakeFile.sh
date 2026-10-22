#!/bin/bash
set -e
nasm -f bin boot1.asm -o boot1.bin
nasm -f bin boot2.asm -o boot2.bin

# boot1 reads 192 sectors (96 KB) of stage 2; make sure boot2 fits
MAX=$((192 * 512))
SIZE=$(stat -c%s boot2.bin)
if [ "$SIZE" -gt "$MAX" ]; then
    echo "boot2.bin is too big: $SIZE > $MAX bytes (raise CHUNK_COUNT in boot1.asm)"
    exit 1
fi

cat boot1.bin boot2.bin > disk.img
truncate -s 64M disk.img
mkfs.fat -F 32 --offset 2048 disk.img 64512
printf 'NixelOS FAT32 test\n' | MTOOLS_SKIP_CHECK=1 mcopy -i disk.img@@1048576 - ::TEST.TXT
