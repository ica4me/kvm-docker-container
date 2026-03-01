#!/bin/bash

echo "================================================="
echo " Memulai Setup Otomatis Host VPS (Debian/Ubuntu) "
echo "================================================="

# 1. Menambahkan/Mengubah Port SSH ke 2026
echo "[1/5] Mengatur Port SSH ke 2026..."
# Mengubah port 22 menjadi 2026 jika ada
sed -i 's/^#*Port 22/Port 2026/' /etc/ssh/sshd_config
# Memastikan Port 2026 benar-benar tertulis di konfigurasi
if ! grep -q "^Port 2026" /etc/ssh/sshd_config; then
    echo "Port 2026" >> /etc/ssh/sshd_config
fi
# Restart service SSH
systemctl restart ssh || systemctl restart sshd
echo "✅ Port SSH host berhasil disetel ke 2026."

# 2. Mendeteksi Interface Internet Utama Otomatis
echo "[2/5] Mendeteksi interface internet utama..."
MAIN_IFACE=$(ip route show default | awk '/default/ {print $5}' | head -1)
if [ -z "$MAIN_IFACE" ]; then
    echo "❌ Gagal mendeteksi interface! Script dihentikan."
    exit 1
fi
echo "✅ Interface utama terdeteksi: $MAIN_IFACE"

# 3. Mengaktifkan IP Forwarding
echo "[3/5] Mengaktifkan IP Forwarding di Kernel..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
sysctl -p /etc/sysctl.d/99-ipforward.conf > /dev/null
echo "✅ IP Forwarding aktif."

# 4. Menerapkan Aturan Iptables (NAT)
echo "[4/5] Mengatur pembelokan trafik via iptables..."
# Hapus aturan NAT lama agar tidak bertumpuk jika script dijalankan berkali-kali
iptables -t nat -F PREROUTING

# Belokkan SEMUA trafik TCP (kecuali port 2026) ke IP Container Docker (172.18.0.2)
iptables -t nat -A PREROUTING -i $MAIN_IFACE -p tcp ! --dport 2026 -j DNAT --to-destination 172.18.0.2

# Belokkan SEMUA trafik UDP ke IP Container Docker (172.18.0.2)
iptables -t nat -A PREROUTING -i $MAIN_IFACE -p udp -j DNAT --to-destination 172.18.0.2

# Pastikan trafik dari Container bisa merespons keluar (Masquerade)
# Cek dulu apakah rule sudah ada, jika belum tambahkan
iptables -t nat -C POSTROUTING -s 172.18.0.2 -o $MAIN_IFACE -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 172.18.0.2 -o $MAIN_IFACE -j MASQUERADE
echo "✅ Aturan iptables berhasil diterapkan."

# 5. Menyimpan Aturan Secara Permanen
echo "[5/5] Menyimpan aturan secara permanen (iptables-persistent)..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -yq iptables-persistent curl
netfilter-persistent save > /dev/null
echo "✅ Aturan berhasil disimpan dan aman dari reboot."

# Mengambil IP Public VPS
PUBLIC_IP=$(curl -s -4 ifconfig.me)

echo "================================================="
echo " SETUP SELESAI! "
echo "================================================="
echo "⚠️ PENTING: JANGAN TUTUP TERMINAL INI DULU!"
echo "Silakan buka terminal baru di komputer Anda, dan copy-paste perintah ini untuk tes login:"
echo ""
echo "    ssh root@$PUBLIC_IP -p 2026"
echo ""
echo "Jika berhasil masuk, barulah terminal ini boleh ditutup."
echo "================================================="