#!/bin/bash

# Setup TAP interface
ip tuntap add dev tap0 mode tap
ip addr add 10.0.0.1/24 dev tap0
ip link set tap0 up

# Forward trafik dari Container (172.18.0.2) ke VM (10.0.0.2)
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -i eth0 -j DNAT --to-destination 10.0.0.2
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Generate Cloud-Init
cloud-localds -N network-config seed.img user-data

# Jalankan KVM dengan RAM 1024MB (1GB)
echo "Starting Debian 12 KVM..."
exec qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -smp 2 \
  -cpu host \
  -drive file=debian12.qcow2,format=qcow2,if=virtio \
  -drive file=seed.img,format=raw,if=virtio \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56 \
  -display none \
  -serial stdio