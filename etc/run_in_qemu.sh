#!/bin/bash
# run x86_64 image in qemu. 
# usage:
#   run_in_qemu.sh [path-to-combined-ext4-image]

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IMG=${1:-$SCRIPT_DIR/../output/openwrt-22.03.0-x86-64-generic-ext4-combined.img}

# configure 2 NICs:
#   1. LAN , with port forwardings of 1122 -> 22 (ssh) and 8443 -> 443 (luci)
#   2. WAN
exec qemu-system-x86_64 \
    -enable-kvm \
    -nographic \
    -device ide-hd,drive=d0,bus=ide.0 \
    -device virtio-net-pci,netdev=hn0,id=lan \
    -netdev user,id=hn0,net=192.168.1.0/24,host=192.168.1.2,hostfwd=tcp::1122-192.168.1.1:22,hostfwd=tcp::8443-192.168.1.1:443\
    -device virtio-net-pci,netdev=hn1,id=wan \
    -netdev user,id=hn1\
    -drive id=d0,if=none,file="$IMG"

