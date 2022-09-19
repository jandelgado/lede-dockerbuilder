#!/bin/bash
# run x86_64 image in qemu. 
# usage:
#   run_in_qemu.sh [path-to-combined-ext4-image]

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IMG=${1:-$SCRIPT_DIR/../output/openwrt-22.03.0-x86-64-generic-ext4-combined.img}

exec qemu-system-x86_64 \
    -enable-kvm \
    -nographic \
    -device ide-hd,drive=d0,bus=ide.0 \
    -netdev user,id=hn0 \
    -device virtio-net-pci,netdev=hn0,id=wan \
    -netdev user,id=hn1,hostfwd=tcp::5555-:22001 \
    -device virtio-net-pci,netdev=hn1,id=lan \
    -drive id=d0,if=none,file="$IMG"

