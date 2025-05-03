#!/bin/bash

# Script Auto Installer untuk SOCKS5 Proxy menggunakan Dante
# Dibuat pada: 2023-05-02

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan pesan
print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Periksa apakah script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    print_error "Script harus dijalankan sebagai root!"
    echo "Jalankan dengan: sudo bash $0"
    exit 1
fi

# Menampilkan banner
clear
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}       SOCKS5 Proxy Auto Installer               ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""

# Update sistem dan install paket-paket yang diperlukan
print_status "Memperbarui sistem dan menginstal paket yang diperlukan..."
apt update && apt upgrade -y
apt install -y dante-server ufw curl net-tools

# Konfigurasi file danted.conf
print_status "Mengonfigurasi SOCKS5 proxy..."

cat > /etc/danted.conf << 'EOL'
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# Alamat yang akan di-listen
internal: 0.0.0.0 port=1080

# External interface
external: eth0

# Tanpa autentikasi
socksmethod: none

# Klien yang diizinkan
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}

# Izin koneksi
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: error connect disconnect
}
EOL

# Memastikan konfigurasi interface yang benar
MAIN_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}' | head -n1)
if [ -n "$MAIN_INTERFACE" ]; then
    print_status "Interface utama terdeteksi: $MAIN_INTERFACE"
    sed -i "s/external: eth0/external: $MAIN_INTERFACE/g" /etc/danted.conf
else
    print_error "Tidak dapat mendeteksi interface utama, menggunakan default (eth0)"
fi

# Mengonfigurasi Firewall
print_status "Mengonfigurasi firewall..."
ufw allow ssh
ufw allow 1080/tcp
ufw allow 1080/udp

# Mengaktifkan firewall jika belum aktif
if ! ufw status | grep -q "Status: active"; then
    print_status "Mengaktifkan firewall..."
    echo "y" | ufw enable
fi

# Restart dan aktifkan layanan
print_status "Memulai ulang layanan Dante..."
systemctl restart danted
systemctl enable danted

# Verifikasi layanan berjalan
if systemctl is-active --quiet danted; then
    print_success "Layanan Dante berhasil dijalankan!"
else
    print_error "Layanan Dante gagal dijalankan. Periksa log dengan: systemctl status danted"
    exit 1
fi

# Mendapatkan IP publik
IP_ADDRESS=$(curl -s ifconfig.me)
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(curl -s icanhazip.com)
fi

if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS="<IP address server Anda>"
    print_status "Tidak dapat mendeteksi IP publik. Gunakan ip route atau ifconfig untuk menemukannya."
else
    print_success "IP publik terdeteksi: $IP_ADDRESS"
fi

# Menampilkan informasi proxy
echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}       SOCKS5 Proxy berhasil diinstal!           ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "Detail proxy Anda:"
echo -e "   IP Address: ${YELLOW}$IP_ADDRESS${NC}"
echo -e "   Port: ${YELLOW}1080${NC}"
echo -e "   Protocol: ${YELLOW}SOCKS5${NC}"
echo -e "   Authentication: ${YELLOW}None${NC}"
echo ""
echo -e "Cara menggunakan:"
echo -e "   - Di Chrome: Buka Settings > Advanced > System > Open proxy settings"
echo -e "   - Atau gunakan extension seperti SwitchyOmega dengan konfigurasi:"
echo -e "     Protocol: SOCKS5, Server: $IP_ADDRESS, Port: 1080"
echo -e "   - Untuk android bisa pakai aplikasi Super Proxy"
echo ""
echo -e "Perintah untuk memeriksa status: ${YELLOW}systemctl status danted${NC}"
echo -e "Perintah untuk melihat log: ${YELLOW}tail -f /var/log/syslog | grep danted${NC}"
echo ""

exit 0
