# Koperasi Siswa (KopsisKu)

Aplikasi **koperasi konsumen** sekolah untuk mengelola **produk, penjualan, dan restok** — mobile-first, minimalis.

> **Cakupan:** hanya koperasi konsumen (jual-beli barang). Modul anggota, simpanan, dan pinjaman tidak ada.

**Online:** aplikasi Flutter (APK) berbicara ke **backend PHP** (`backend/`) lewat REST API; data di **MariaDB**. Semua perangkat yang terhubung ke server yang sama otomatis membaca data yang sama — sinkron.

## Struktur

```
koperasi_siswa/
├── app/                          # Flutter (client)
│   ├── lib/src/
│   │   ├── core/config/env.dart  # API_BASE_URL via --dart-define
│   │   ├── core/network/         # ApiClient (HTTP)
│   │   └── data/repositories/   # auth, produk, transaksi, dashboard, profil
│   └── pubspec.yaml
└── backend/                      # PHP API + skema DB
    ├── api/ auth/ config/ src/Support/
    ├── database/schema.sql
    ├── check.php                 # cek aturan stok (CLI)
    ├── .htaccess                 # blokir .sql/.env/.local.php
    └── storage/uploads/{produk,profil}/
```

## Menjalankan

### 1. Backend + database

App dijalankan dari docroot Apache (`/var/www/html`) lewat subpath — akses:
`http://localhost/koperasi_siswa` (ganti `koperasi_siswa` sesuai nama folder).

```bash
# hapus vhost lain agar docroot utama terpakai (sekali)
sudo rm /etc/httpd/conf.d/pjj.conf
sudo systemctl reload httpd

# folder upload bisa ditulis server
chmod -R 777 backend/storage/uploads
```

> `backend/.htaccess` baru berlaku bila `AllowOverride All` pada blok
> `<Directory "/var/www/html">` di `/etc/httpd/conf/httpd.conf`.

Database `koperasi_siswa` + user diatur lewat `backend/config/env.local.php` (**tidak di-commit**).
Untuk instalasi baru, impor `backend/database/schema.sql`.

### 2. Cek backend

```bash
php backend/check.php http://localhost/koperasi_siswa
```

### 3. Aplikasi

```bash
cd app
flutter pub get
flutter test                       # 29 tes
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-PC>/koperasi_siswa
```

Pertama kali buka app: daftar lewat layar **Registrasi**.

## Skema DB (MariaDB)

- `pengguna` — name, username, email, password (`password_hash()` PHP), foto
- `produk` — nama, kategori, harga, stok, deskripsi, foto, status (tersedia/habis/arsip)
- `transaksi` — kode `TRX-…`, penjualan & restok; stok berubah otomatis, hapus transaksi memulihkan stok

## Deploy VPS

1. **Stack**: PHP 8 + MariaDB/MySQL + Apache/Nginx.
2. **Upload** `backend/` ke VPS (mis. `/var/www/html/koperasi_siswa`).
3. **Database**:
   ```bash
   mysql -uroot -p < backend/database/schema.sql
   mysql -uroot -p -e "CREATE USER 'koperasi'@'localhost' IDENTIFIED BY 'PASSWORD_KUAT'; \
     GRANT ALL ON koperasi_siswa.* TO 'koperasi'@'localhost'; FLUSH PRIVILEGES;"
   ```
4. **Kredensial** — isi `backend/config/env.local.php` di VPS (jangan commit):
   ```php
   <?php
   putenv('DB_HOST=localhost');
   putenv('DB_USER=koperasi');
   putenv('DB_PASS=PASSWORD_KUAT');
   putenv('DB_NAME=koperasi_siswa');
   putenv('APP_PREFIX=/koperasi_siswa');   // atau '/' bila app di root domain
   ```
5. **HTTPS** (Let's Encrypt): `sudo certbot --apache` — lalu `APP_SCHEME=https` (otomatis ke-detect).
6. **Upload bisa ditulis**:
   ```bash
   chmod -R 775 backend/storage/uploads
   # Debian/Ubuntu:  sudo chown -R www-data:www-data backend/storage/uploads
   # Fedora:        sudo chcon -R -t httpd_sys_rw_content_t backend/storage/uploads
   ```
7. **Build APK** menunjuk domain VPS:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://domain/koperasi_siswa
   ```

## Keamanan

- Kredensial DB hanya di `backend/config/env.local.php` (gitignored). Jangan pernah commit.
- `backend/.htaccess` memblokir `.sql`, `.env`, `*.local.php`, dan menonaktifkan index direktori.
