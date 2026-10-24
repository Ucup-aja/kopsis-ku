# Deploy ke VPS — panduan langkah demi langkah

Alur: clone repo GitHub ke VPS → pasang PHP + MariaDB + Apache → expose lewat
Cloudflare Tunnel → build APK menunjuk URL publik.

Hasil akhir: URL `https://<domain>/koperasi_siswa` yang bisa dipakai aplikasi di
semua device; data sinkron karena satu database yang sama.

> Asumsi: **Ubuntu/24.04** (atau Debian 12). Baris Fedora disertakan di mana berbeda.

---

## Cara A — Docker (rekomendasi)

Persiapan VPS: Docker + Docker Compose (`sudo apt install docker.io docker-compose-v2`).

```bash
cd /var/www/html
sudo git clone https://github.com/Ucup-aja/kopsis-ku.git koperasi_siswa
cd koperasi_siswa
cp .env.example .env          # lalu isi DB_PASS & DB_ROOT_PASS
docker compose up -d --build
php backend/check.php http://localhost:8080/koperasi_siswa   # harus SEMUA LULUS
```

Tunnel (pilih salah satu):

```bash
# tunnel cepat (uji) — URL acak *.trycloudflare.com, lihat di log
docker run -d --rm --network koperasi_siswa_default \
  cloudflare/cloudflared:latest tunnel --url http://backend:80
docker logs -f $(docker ps -qf ancestor=cloudflare/cloudflared)

# tunnel bernama (permanen) — isi TUNNEL_TOKEN di .env
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d
```

Build APK menunjuk URL tunnel:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<host-tunnel>/koperasi_siswa
```

Keuntungan: DB, folder upload, dan versi PHP terkurung dalam image. Upgrade cukup
`docker compose build --no-cache && docker compose up -d`.

---

## Cara B — manual (tanpa Docker)

### 1. Siapkan

- VPS dengan akses `root`/`sudo`
- Domain (boleh subdomain) yang bisa diatur DNS-nya — untuk Cloudflare Tunnel
- Repo publik: https://github.com/Ucup-aja/kopsis-ku

### 2. Pasang stack dasar

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y apache2 php php-mysqli php-mbstring php-curl php-fileinfo mariadb-server git
sudo systemctl enable --now apache2 mariadb
```

Fedora:

```bash
sudo dnf install -y httpd php php-mysqli php-mbstring php-curl php-fileinfo mariadb-server git
sudo systemctl enable --now httpd mariadb
```

### 3. Clone repo

```bash
cd /var/www/html
sudo git clone https://github.com/Ucup-aja/kopsis-ku.git koperasi_siswa
cd koperasi_siswa
sudo chown -R www-data:www-data backend/storage/uploads     # Fedora: apache:apache
sudo chmod -R 775 backend/storage/uploads
```

Kalau SELinux aktif (Fedora):

```bash
sudo chcon -R -t httpd_sys_rw_content_t backend/storage/uploads
```

### 4. Database

```bash
sudo mysql < backend/database/schema.sql

sudo mysql -e "CREATE USER 'koperasi'@'localhost' IDENTIFIED BY 'PASSWORD_KUAT'; \
  GRANT ALL PRIVILEGES ON koperasi_siswa.* TO 'koperasi'@'localhost'; FLUSH PRIVILEGES;"
```

Ganti `PASSWORD_KUAT` dengan password kuat.

### 5. Kredensial aplikasi

Buat `backend/config/env.local.php` (file ini **tidak** di-commit):

```php
<?php
putenv('DB_HOST=localhost');
putenv('DB_USER=koperasi');
putenv('DB_PASS=PASSWORD_KUAT');
putenv('DB_NAME=koperasi_siswa');
putenv('APP_PREFIX=/koperasi_siswa');   // sesuaikan lokasi clone
```

### 6. Apache

- Pastikan `AllowOverride All` pada docroot (agar `backend/.htaccess` aktif —
  memblokir `.sql`/`.env`/`*.local.php`).
  - Ubuntu: di `/etc/apache2/apache2.conf`, blok `<Directory /var/www/>`
  - Fedora: di `/etc/httpd/conf/httpd.conf`, blok `<Directory "/var/www/html">`
- `sudo systemctl reload apache2` (Ubuntu) / `sudo systemctl reload httpd` (Fedora)

### 7. Uji lokal di server

```bash
php backend/check.php http://localhost/koperasi_siswa
```

Harus `SEMUA LULUS`. Kalau belum, selesaikan dulu sebelum lanjut ke tunnel.

### 8. Cloudflare Tunnel

Pasang `cloudflared`:

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
sudo install -m 755 cloudflared /usr/local/bin/cloudflared
```

### 8a. Tunnel cepat (uji sementara, URL acak)

```bash
cloudflared tunnel --url http://localhost:80
```

Catat URL `https://xxxx.trycloudflare.com`. Cukup untuk uji; URL berubah tiap restart.

### 8b. Tunnel bernama (permanen, butuh domain di Cloudflare)

```bash
cloudflared tunnel login
cloudflared tunnel create koperasi
cloudflared tunnel route dns koperasi koperasi.domainmu.com
```

Buat `/root/.cloudflared/config.yml`:

```yaml
tunnel: <ID_TUNNEL>
credentials-file: /root/.cloudflared/<ID_TUNNEL>.json
ingress:
  - hostname: koperasi.domainmu.com
    service: http://localhost:80
  - service: http_status:404
```

Jalankan sebagai service:

```bash
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

### 9. Build APK menunjuk URL publik

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://koperasi.domainmu.com/koperasi_siswa
```

### 10. Uji akhir

```bash
php backend/check.php https://koperasi.domainmu.com/koperasi_siswa
```

Lalu install APK → daftar akun → login. Buka dari dua device, cek data muncul di keduanya.

---

## Masalah umum

| Gejala | Penyebab | Perbaikan |
|---|---|---|
| `Koneksi database gagal` | `env.local.php` salah/kosong | Cek `DB_USER`/`DB_PASS` |
| Foto gagal upload | folder `uploads` tidak bisa ditulis | `chmod`/`chown` + SELinux |
| API balik HTML/404 | Apache tidak serve docroot, atau tunnel salah target | Cek `APP_PREFIX` & URL tunnel |
| JSON rusak (ada teks di depan) | `display_errors=On` | Sudah di matikan di `config/db.php` |
