#!/bin/bash
set -e
nasm -f bin boot1.asm -o boot1.bin
nasm -f bin boot2.asm -o boot2.bin
cat boot1.bin boot2.bin > disk.img
truncate -s 64M disk.img
mkfs.fat -F 32 --offset 2048 disk.img 64512
printf 'NixelOS FAT32 test\n' | MTOOLS_SKIP_CHECK=1 mcopy -i disk.img@@1048576 - ::TEST.TXT
