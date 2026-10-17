# Deploy ke VPS — KopsisKu

Panduan ini menjadikan aplikasi **berjalan di VPS**, sehingga HP tidak lagi butuh laptop.
Banyak HP bisa mengakses data yang sama (serverpusat di VPS).

**Kasus:** VPS Ubuntu/Debian · domain sudah ada · web server belum terpasang.
**Hasil akhir:** `https://domain-anda` melayani API + upload foto, dan APK Android mengarah ke situ.

> Syarat Android: **wajib HTTPS.** Android memblokir koneksi `http://` dari aplikasi,
> jadi tanpa HTTPS foto tidak akan tampil dan API bisa gagal.

---

## Ringkasan alur

```
HP (APK)  ──HTTPS──▶  VPS
                        ├── Apache2 + PHP 8  →  backend/*.php
                        ├── MariaDB          →  database koperasi_siswa
                        └── /backend/storage/uploads/  (foto)
```

Ganti di bawah:
- `domain-anda.com` → domain Anda
- `USER_DB` / `PASS_DB` → kredensial database buatan Anda sendiri

---

## 1. Siapkan VPS (sekali saja)

Login sebagai root atau user dengan `sudo`:

```bash
apt update && apt upgrade -y
apt install -y apache2 mariadb-server php libapache2-mod-php \
               php-mysql php-xml php-mbstring php-gd php-curl unzip curl
```

Cek versi (PHP minimal 8.0):

```bash
php -v
systemctl status apache2 --no-pager
```

Aktifkan layanan supaya nyala lagi saat VPS restart:

```bash
systemctl enable --now apache2 mariadb
```

## 2. Buat database & user

```bash
sudo mariadb
```

Di prompt MariaDB, tempel ini (ganti `PASS_DB`!):

```sql
CREATE DATABASE IF NOT EXISTS koperasi_siswa
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'kopsis'@'localhost' IDENTIFIED BY 'PASS_DB';
GRANT ALL PRIVILEGES ON koperasi_siswa.* TO 'kopsis'@'localhost';
FLUSH PRIVILEGES;
QUIT;
```

Impor skema tabel (3 tabel: `pengguna`, `produk`, `transaksi`):

```bash
sudo mariadb koperasi_siswa < backend/database/schema.sql
```

Verifikasi:

```bash
sudo mariadb -u kopsis -p'PASS_DB' -e "SHOW TABLES FROM koperasi_siswa;"
```

Harus muncul `pengguna`, `produk`, `transaksi`.

## 3. Unggah kode

Dari **laptop** (bukan VPS), salin isi `backend/` ke VPS:

```bash
# dari direktori project di laptop
rsync -av --delete backend/ USER_VPS@IP_VPS:/var/www/koperasi_siswa/backend/
```

Atau cara manual:

```bash
scp -r backend/ USER_VPS@IP_VPS:/var/www/koperasi_siswa/
```

Di VPS, pastikan strukturnya benar:

```bash
sudo mkdir -p /var/www/koperasi_siswa
# hasilnya harus seperti:
# /var/www/koperasi_siswa/backend/api/*.php
# /var/www/koperasi_siswa/backend/auth/*.php
# /var/www/koperasi_siswa/backend/config/*.php
# /var/www/koperasi_siswa/backend/src/Support/*.php
# /var/www/koperasi_siswa/backend/storage/uploads/{produk,profil}/
```

## 4. Kredensial database & izin folder

Buat `/var/www/koperasi_siswa/backend/config/env.local.php`:

```bash
sudo tee /var/www/koperasi_siswa/backend/config/env.local.php >/dev/null <<'EOF'
<?php
// Kredensial produksi — JANGAN di-commit ke git.
putenv('DB_HOST=localhost');
putenv('DB_USER=kopsis');
putenv('DB_PASS=PASS_DB');
putenv('DB_NAME=koperasi_siswa');
// Opsional: paksa skema bila deteksi otomatis meleset.
// putenv('APP_SCHEME=https');
// putenv('APP_HOST=domain-anda.com');
// putenv('APP_PREFIX=/koperasi_siswa');
EOF
```

> `config/env.php` otomatis memuat `env.local.php` bila file itu ada, jadi Anda
> tidak perlu mengubah kode sama sekali. Nilai di `env.local.php` menang atas
> fallback dev, dan file ini tidak perlu di-commit ke git.

Beri izin folder upload (wajib — kalau salah, foto gagal tersimpan):

```bash
sudo chown -R www-data:www-data /var/www/koperasi_siswa/backend/storage
sudo chmod -R 775 /var/www/koperasi_siswa/backend/storage/uploads
```

> `www-data` adalah user Apache di Debian/Ubuntu. Bila `httpd` (Fedora/RHEL)
> gunakan `apache:apache`.

Uji API langsung di VPS sebelum lanjut:

```bash
curl -s http://localhost/koperasi_siswa/backend/api/dashboard.php | head -c 200
```

Harus terbalas JSON `{ "success": true, ... }`, bukan error 500.

## 5. Konfigurkan Apache + domain

```bash
sudo tee /etc/apache2/sites-available/koperasi.conf >/dev/null <<'EOF'
<VirtualHost *:80>
    ServerName domain-anda.com
    DocumentRoot /var/www/koperasi_siswa

    <Directory /var/www/koperasi_siswa>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Jangan layani file sensitif
    <DirectoryMatch "/\.(git|env)">
        Require all denied
    </DirectoryMatch>

    ErrorLog  ${APACHE_LOG_DIR}/koperasi_error.log
    CustomLog ${APACHE_LOG_DIR}/koperasi_access.log combined
</VirtualHost>
EOF

sudo a2ensite koperasi.conf
sudo a2dissite 000-default          # opsional: matikan halaman default
sudo systemctl reload apache2
```

Tambahkan juga `/var/www/koperasi_siswa/backend/.htaccess`:

```bash
sudo tee /var/www/koperasi_siswa/backend/.htaccess >/dev/null <<'EOF'
# Larang akses langsung ke file konfigurasi
<FilesMatch "\.(sql|log|md)$">
    Require all denied
</FilesMatch>
Options -Indexes
EOF
```

## 6. HTTPS dengan Let's Encrypt (wajib)

```bash
apt install -y certbot python3-certbot-apache
sudo certbot --apache -d domain-anda.com --redirect -d www.domain-anda.com
```

Ikuti prompt (isi email, setujui Terms). Selesai, sertifikat **otomatis** diperbarui.

Verifikasi:

```bash
curl -s https://domain-anda.com/koperasi_siswa/backend/api/dashboard.php | head -c 200
```

Balasan harus diawali `{ "success": true`.

> Bila tampil `ERR_SSL_PROTOCOL_ERROR`, tunggu 1–2 menit lalu coba lagi —
> propagasi DNS sering telat.

## 7. Pastikan deteksi HTTPS bekerja

Backend otomatis mendeteksi HTTPS lewat header `X-Forwarded-Proto` dari
Certbot/Apache. Bila foto tetap `http://`, paksa di `env.local.php`:

```php
putenv('APP_SCHEME=https');
putenv('APP_HOST=domain-anda.com');
```

Lalu uji — URL foto **harus** `https://`:

```bash
curl -s -X POST https://domain-anda.com/koperasi_siswa/backend/auth/login.php \
  -H 'Content-Type: application/json' \
  -d '{"username":"test","password":"test"}' | grep -o '"foto_url":"[^"]*"'
```

## 8. Build & install APK ke HP

Build dari laptop, arahkan ke VPS:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://domain-anda.com/koperasi_siswa
```

APK hasilnya: `app/build/app/outputs/flutter-apk/app-release.apk`

Kirim ke HP (WhatsApp/Google Drive/kabel), lalu buka file → **Install**.
Jika muncul "sumber tidak dikenal", izinkan dulu di Pengaturan → Keamanan.

Setelah login sekali, aplikasi **tetap terhubung VPS tanpa laptop**.

---

## Peran tiap konfigurasi

| Env (di `env.local.php`) | Fungsi | Contoh |
|---|---|---|
| `DB_HOST` | Host database | `localhost` |
| `DB_USER` | User database | `kopsis` |
| `DB_PASS` | Password database | (rahasia) |
| `DB_NAME` | Nama database | `koperasi_siswa` |
| `APP_SCHEME` | Paksa skema URL foto | `https` |
| `APP_HOST` | Paksa host pada URL foto | `domain-anda.com` |
| `APP_PREFIX` | Path dasar deploy | `/koperasi_siswa` atau `/` |

Bila deploy di **root domain** (`https://domain.com/...` tanpa `/koperasi_siswa`),
set `APP_PREFIX=/` dan ubah `API_BASE_URL` jadi `https://domain.com`.

---

## Backup (penting!)

Data kini ada di VPS, bukan HP. Jadwalkan backup otomatis:

```bash
sudo tee /usr/local/bin/backup-koperasi.sh >/dev/null <<'EOF'
#!/bin/bash
STAMP=$(date +%Y%m%d-%H%M)
mariadb-dump -u kopsis -p'PASS_DB' koperasi_siswa | gzip > /root/db-$STAMP.sql.gz
tar czf /root/uploads-$STAMP.tar.gz -C /var/www/koperasi_siswa/backend/storage uploads
find /root -name 'db-*.sql.gz' -mtime +14 -delete
find /root -name 'uploads-*.tar.gz' -mtime +14 -delete
EOF

sudo chmod +x /usr/local/bin/backup-koperasi.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-koperasi.sh") | crontab -
```

Restore:

```bash
zcat /root/db-20260101-0200.sql.gz | mariadb -u kopsis -p'PASS_DB' koperasi_siswa
```

---

## Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| `ERR_CLEARTEXT_NOT_PERMITTED` | APK memakai `http://` | Build ulang dengan `API_BASE_URL=https://...` |
| Foto tidak muncul | Skema salah / izin folder | Cek langkah 4 (izin) & 7 (skema) |
| `Upload gagal` / 500 saat pilih foto | Folder upload tidak ditulis `www-data` | `chown -R www-data:www-data .../storage` |
| `Koneksi database gagal` | Kredensial salah | Cek `env.local.php`, `mariadb -u kopsis -p` |
| 404 pada API | DocumentRoot / prefix salah | Cocokkan langkah 5; sesuaikan `APP_PREFIX` |
| 500 mendadak | `.htaccess` salah / mod_rewrite | Cek `tail -f /var/log/apache2/koperasi_error.log` |
| Login gagal padahal benar | DB masih kosong | Daftar akun dulu lewat aplikasi |
| CORS (hanya bila uji via web browser) | Origin dibatasi | Set `ALLOWED_ORIGIN` di `env.php` |

Lihat log error Apache:

```bash
sudo tail -f /var/log/apache2/koperasi_error.log
```

---

## Catatan keamanan

- `env.local.php` berisi password — **jangan** masuk git. Tambahkan ke `.gitignore`.
- Selalu HTTPS; jangan pernah port 80 saja.
- `config/db.php` mengembalikan JSON error generik — detail DB tidak bocor ke klien.
- Batasi firewall bila perlu: `ufw allow 'Apache Full' && ufw enable`.
