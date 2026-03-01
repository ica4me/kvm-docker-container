# Debian KVM Docker Container Setup Guide

Panduan ini menjelaskan langkah-langkah menjalankan Debian VM menggunakan KVM di dalam Docker container.

---

## 1. Clone Repository

Clone semua isi repository ke direktori kerja saat ini:

```bash
git clone https://github.com/ica4me/kvm-docker-container.git .
```

---

## 2. Persiapan Direktori

```bash
mkdir -p /root/debian-kvm
cd /root/debian-kvm
```

---

## 3. Jalankan Setup Routing

```bash
chmod +x setup-routing.sh && ./setup-routing.sh
```

---

## 4. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker
```

---

## 5. Cek Resource Host

Cek jumlah CPU Core:

```bash
nproc
```

Cek total RAM dalam Megabyte (MB):

```bash
free -m
```

---

## 6. Konfigurasi start.sh (QEMU)

Sesuaikan RAM dan CPU berdasarkan resource host.

```bash
exec qemu-system-x86_64 \
  -enable-kvm \
  -m 3072 \      <-- Ubah angka ini (Total RAM Host dikurangi 512 atau 1024)
  -smp 4 \       <-- Ubah angka ini sesuai hasil perintah 'nproc'
```

---

## 7. Build dan Jalankan Container

```bash
docker compose up -d --build
```

Cek log VM:

```bash
docker logs -f debian-vm
```

---

## 8. Setup NAT dan Forwarding Jaringan

```bash
MAIN_IFACE=$(ip route show default | awk '/default/ {print $5}' | head -1)

iptables -I FORWARD 1 -i $MAIN_IFACE -d 172.18.0.2 -j ACCEPT

iptables -t nat -I PREROUTING 1 -i $MAIN_IFACE -p tcp ! --dport 2026 -j DNAT --to-destination 172.18.0.2
iptables -t nat -I PREROUTING 1 -i $MAIN_IFACE -p udp -j DNAT --to-destination 172.18.0.2

netfilter-persistent save
```

---

## 9. Akses Console VM

Masuk console:

```bash
docker attach debian-vm
```

Keluar console (HARUS berurutan):

```
Ctrl + P
Ctrl + Q
```

---

## 10. Rebuild Container Jika Diperlukan

```bash
docker rm -f debian-vm
docker compose build --no-cache
docker compose up -d
```

Atau force recreate:

```bash
cd /root/debian-kvm
docker compose up -d --build --force-recreate
```

---

## 11. Akses VM via SSH

Dari luar server:

```bash
ssh root@$PUBLIC_IP
```

Dari host langsung:

```bash
ssh root@172.18.0.2
```

---

## Selesai

VM Debian berbasis KVM sekarang berjalan di dalam Docker container dan dapat diakses melalui console maupun SSH.
