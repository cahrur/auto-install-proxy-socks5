#!/bin/bash

# Script Auto Installer untuk SOCKS5 Proxy menggunakan Dante
# Update: Menambahkan Autentikasi Username/Password

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${YELLOW}[*] $1${NC}"; }
print_success() { echo -e "${GREEN}[+] $1${NC}"; }
print_error() { echo -e "${RED}[-] $1${NC}"; }

if [ "$EUID" -ne 0 ]; then
    print_error "Script harus dijalankan sebagai root!"
    echo "Jalankan dengan: sudo bash $0"
    exit 1
fi

clear
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}     SOCKS5 Proxy Installer with Auth            ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""

# Update dan install dependensi
print_status "Memperbarui sistem dan menginstal paket..."
apt update && apt upgrade -y
apt install -y dante-server ufw curl net-tools

# Buat user proxy
USERNAME="proxyjos"
PASSWORD="mantap22"
print_status "Membuat user untuk autentikasi: $USERNAME"
useradd -m -s /usr/sbin/nologin "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Buat file konfigurasi danted
print_status "Membuat file konfigurasi /etc/danted.conf..."

cat > /etc/danted.conf <<EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody

internal: 0.0.0.0 port=1080
external: eth0

socksmethod: username
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: connect
    log: connect disconnect error
    socksmethod: username
}
EOF

# Deteksi dan set interface eksternal
MAIN_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}' | head -n1)
if [ -n "$MAIN_INTERFACE" ]; then
    print_status "Interface utama terdeteksi: $MAIN_INTERFACE"
    sed -i "s/external: eth0/external: $MAIN_INTERFACE/g" /etc/danted.conf
else
    print_error "Gagal mendeteksi interface, tetap gunakan eth0"
fi

# Atur firewall
print_status "Mengatur firewall..."
ufw allow ssh
ufw allow 1080/tcp
ufw allow 1080/udp
if ! ufw status | grep -q "Status: active"; then
    echo "y" | ufw enable
fi

# Restart dan aktifkan Dante
print_status "Memulai ulang layanan Proxy..."
systemctl restart danted
systemctl enable danted

if systemctl is-active --quiet danted; then
    print_success "Layanan Proxy berhasil dijalankan!"
else
    print_error "Layanan Proxy gagal dijalankan!"
    exit 1
fi

# Ambil IP publik
IP_ADDRESS=$(curl -s ifconfig.me || curl -s icanhazip.com)
[ -z "$IP_ADDRESS" ] && IP_ADDRESS="<IP Anda>"

# Info akhir
echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}      SOCKS5 Proxy dengan Username Aktif         ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "   IP Address: ${YELLOW}$IP_ADDRESS${NC}"
echo -e "   Port: ${YELLOW}1080${NC}"
echo -e "   Protocol: ${YELLOW}SOCKS5${NC}"
echo -e "   Username: ${YELLOW}$USERNAME${NC}"
echo -e "   Password: ${YELLOW}$PASSWORD${NC}"
echo ""
echo -e "Gunakan di browser / aplikasi dengan SOCKS5 auth."
echo -e "Cek status: ${YELLOW}systemctl status danted${NC}"
echo -e "Log: ${YELLOW}tail -f /var/log/syslog | grep danted${NC}"
echo ""

exit 0
