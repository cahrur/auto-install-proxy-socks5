# Auto Install SOCKS5 Proxy

Script otomatis untuk menginstal dan mengkonfigurasi SOCKS5 proxy menggunakan Dante Server di sistem Ubuntu/Debian.

## Cara Menggunakan

### Metode 1: Langsung dari GitHub

```bash
# Jalankan perintah ini di server Linux Anda
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/cahrur/auto-install-proxy-socks5/main/install_socks5_proxy.sh)"
```

### Metode 2: Clone Repository

```bash
# Clone repository
git clone https://github.com/cahrur/auto-install-proxy-socks5.git

# Pindah ke direktori
cd auto-install-proxy-socks5

# Berikan izin eksekusi
chmod +x install_socks5_proxy.sh

# Jalankan script
sudo ./install_socks5_proxy.sh
```

## Fitur

- Instalasi otomatis Dante Server
- Konfigurasi SOCKS5 proxy tanpa autentikasi
- Deteksi otomatis interface jaringan utama
- Konfigurasi firewall (UFW)
- Pengaktifan layanan otomatis saat boot
- Deteksi IP publik untuk memudahkan konfigurasi klien

## Persyaratan Sistem

- Ubuntu 22.04
- Hak akses root/sudo
- Koneksi internet

## Konfigurasi Klien

Setelah instalasi, Anda dapat menggunakan proxy SOCKS5 dengan detail berikut:

- **IP**: IP server Anda
- **Port**: 1080
- **Protocol**: SOCKS5
- **Authentication**: None

### Konfigurasi di Chrome:
1. Pasang ekstensi seperti SwitchyOmega
2. Buat profil baru dengan konfigurasi:
   - Protocol: SOCKS5
   - Server: IP server Anda
   - Port: 1080

## Pemecahan Masalah

Jika mengalami masalah, periksa:
- Restart layanan: `sudo systemctl restart danted`
- Status layanan: `sudo systemctl status danted`
- Log: `sudo tail -f /var/log/syslog | grep danted`
- Port terbuka: `sudo netstat -tulpn | grep 1080`

## License

MIT
