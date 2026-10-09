#!/bin/bash
set -e
nasm -f bin boot1.asm -o boot1.bin
nasm -f bin boot2.asm -o boot2.bin
cat boot1.bin boot2.bin > disk.img
truncate -s 32M disk.img
