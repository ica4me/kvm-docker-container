# Debian 12 Cloud Slim VM via KVM inside Docker

Panduan ini menjelaskan cara membuat **Virtual Machine Debian 12 Cloud Slim** menggunakan **KVM + QEMU yang dijalankan di dalam Docker container**.

Host Linux akan bertindak sebagai hypervisor KVM, sedangkan Docker hanya sebagai wrapper untuk menjalankan VM.

---

# 0. Tujuan Setup

Environment ini digunakan untuk:

✔ Menjalankan **Debian 12 Cloud Slim** sebagai VM  
✔ Virtualisasi hardware acceleration via **KVM**  
✔ Menjalankan VM di dalam Docker container  
✔ Akses VM via console atau SSH

---

# 1. Persiapan Host Linux

Update package index dan install tool dasar:

```bash
apt update
apt install -y \
  git \
  curl \
  wget \
  iptables \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release
```

Tool ini dibutuhkan untuk:

- clone repository
- download script
- konfigurasi network
- instal docker

---

# 2. Pastikan Host Support KVM (WAJIB)

KVM membutuhkan **hardware virtualization extension** dari CPU.

Jenis extension:

| Vendor CPU | Extension        |
| ---------- | ---------------- |
| Intel      | VT-x (flag vmx)  |
| AMD        | AMD-V (flag svm) |

Jika CPU tidak punya extension ini → KVM tidak bisa dipakai.

Referensi:

- Linux KVM documentation
- Red Hat virtualization guide

---

## 2.1 Cek CPU support virtualization

```bash
grep -E 'vmx|svm' /proc/cpuinfo
```

Interpretasi:

| Output  | Arti                |
| ------- | ------------------- |
| ada vmx | Intel VT-x tersedia |
| ada svm | AMD-V tersedia      |
| kosong  | CPU tidak support   |

Virtualization juga harus aktif di BIOS/UEFI.

---

## 2.2 Cek jenis virtualization dengan lscpu

```bash
lscpu | grep Virtualization
```

Output contoh:

```
Virtualization: VT-x
```

atau

```
Virtualization: AMD-V
```

---

## 2.3 Cek modul kernel KVM

```bash
lsmod | grep kvm
```

Output normal:

```
kvm_intel
atau
kvm_amd
```

Jika kosong → load manual:

```bash
modprobe kvm
modprobe kvm_intel   # intel
modprobe kvm_amd     # amd
```

---

## 2.4 Cek device KVM

```bash
ls -l /dev/kvm
```

Harus ada device.

---

## 2.5 Cek readiness penuh (opsional)

Install tool check:

```bash
apt install -y cpu-checker
kvm-ok
```

Output ideal:

```
KVM acceleration can be used
```

---

# 3. Clone Repository

Clone semua isi repo ke working directory saat ini:

```bash
git clone https://github.com/ica4me/kvm-docker-container.git .
```

---

# 4. Persiapan Direktori Kerja

```bash
mkdir -p /root/debian-kvm
cd /root/debian-kvm
```

---

# 5. Setup Routing Host

```bash
chmod +x setup-routing.sh && ./setup-routing.sh
```

---

# 6. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker
```

---

# 7. Cek Resource Host

Jumlah CPU:

```bash
nproc
```

Total RAM MB:

```bash
free -m
```

---

# 8. Konfigurasi start.sh (QEMU)

Sesuaikan resource VM.

```bash
nano start.sh
```

Rekomendasi:

RAM VM = total RAM host dikurangi 512MB–1GB  
CPU VM = jumlah core host

```bash
exec qemu-system-x86_64 \
  -enable-kvm \
  -m 3072 \      <-- ubah sesuai RAM host
  -smp 4 \       <-- ubah sesuai nproc
```

---

# 9. Build dan Jalankan VM Container

```bash
docker compose up -d --build
```

Cek log boot:

```bash
docker logs -f debian-vm
```

---

# 10. Setup NAT dan Forwarding Network

```bash
MAIN_IFACE=$(ip route show default | awk '/default/ {print $5}' | head -1)

iptables -I FORWARD 1 -i $MAIN_IFACE -d 172.18.0.2 -j ACCEPT

iptables -t nat -I PREROUTING 1 -i $MAIN_IFACE -p tcp ! --dport 2026 -j DNAT --to-destination 172.18.0.2
iptables -t nat -I PREROUTING 1 -i $MAIN_IFACE -p udp -j DNAT --to-destination 172.18.0.2

netfilter-persistent save
```

---

# 11. Akses Console VM

Masuk console:

```bash
docker attach debian-vm
```

Keluar console:

```
Ctrl + P
Ctrl + Q
```

---

# 12. Rebuild Container Jika Perlu

```bash
docker rm -f debian-vm
docker compose build --no-cache
docker compose up -d
```

Force recreate:

```bash
cd /root/debian-kvm
docker compose up -d --build --force-recreate
```

---

# 13. Akses SSH ke VM

Dari luar host:

```bash
ssh root@$PUBLIC_IP
```

Dari host langsung:

```bash
ssh root@172.18.0.2
```

---

# 14. Akses SSH ke HOST-VM

Hanya lewat port 2026:

```bash
ssh root@$PUBLIC_IP -p 2026
```

---

# Selesai

VM Debian 12 Cloud Slim berjalan di atas:

HOST → KVM → QEMU → Docker → Debian VM

Akses tersedia via console atau SSH.
