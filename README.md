# Koperasi Siswa

Aplikasi **koperasi konsumen** sekolah untuk mengelola **produk, penjualan, dan restok** — mobile-first, minimalis.

> **Cakupan aplikasi:** hanya koperasi **konsumen** (jual-beli barang).
> Modul **anggota, simpanan, dan pinjaman TIDAK ada** dan memang tidak direncanakan.
> Lihat [docs/API.md](docs/API.md) untuk rincian cakupan.

**Stack:** PHP 8.5 + MariaDB 11.8 (backend) · Flutter 3.44 (app) · Apache `DocumentRoot` = `/var/www/html/koperasi_siswa`

---

## Struktur

```
koperasi_siswa/
├── backend/
│   ├── config/
│   │   ├── db.php              # koneksi → database `koperasi_siswa`
│   │   └── cors.php
│   ├── auth/
│   │   ├── login.php           # POST username+password
│   │   └── registrasi.php      # POST name+username+email+password
│   ├── api/
│   │   ├── dashboard.php       # GET ringkasan stok/kategori/omset
│   │   ├── produk.php          # CRUD produk + upload foto
│   │   ├── transaksi.php       # penjualan & restok (+summary)
│   │   └── profil.php          # GET/POST foto profil pengguna
│   ├── src/Support/
│   │   ├── response.php        # envelope {success,message,data,error}
│   │   ├── validation.php      # validasi input
│   │   └── upload.php          # simpan file foto
│   ├── database/
│   │   └── schema.sql          # CREATE DATABASE + 3 tabel
│   └── storage/uploads/
│       ├── produk/             # foto produk (writable)
│       └── profil/             # foto profil (writable)
├── app/                        # Flutter app `koperasi_siswa`
│   ├── lib/
│   │   ├── main.dart
│   │   └── src/
│   │       ├── app/            # composition root (AppScope, router)
│   │       ├── core/{config,error,network,session,theme,utils}
│   │       ├── data/{models,repositories}
│   │       ├── features/{auth,dashboard,produk,transaksi,shell,developer}
│   │       └── shared/widgets
│   ├── android/ ios/ linux/ macos/ web/ windows/
│   └── pubspec.yaml
├── docs/
│   ├── API.md
│   └── SETUP.md
└── README.md
```

## Database

- **DB:** `koperasi_siswa` (kredensial `flutter_app` / `ucup1211` di `backend/config/db.php`, bisa di-override via env `DB_HOST/DB_USER/DB_PASS/DB_NAME`)
- **Tabel (3):** `pengguna` (auth), `produk`, `transaksi` (penjualan & restok) — lihat `backend/database/schema.sql`.

> Tidak ada tabel `anggota` / `simpanan` / `pinjaman` — aplikasi ini murni koperasi konsumen.

## Prasyarat

- PHP 8.5, MariaDB 11.8, Apache (`httpd`), Flutter 3.44 + Dart 3.x
- Linux (Fedora), Android Studio / Xcode untuk build mobile

## Setup Backend

```bash
# 1. MariaDB
sudo systemctl enable --now mariadb
sudo mariadb < backend/database/schema.sql
# atau: mariadb -u flutter_app -p'ucup1211' < backend/database/schema.sql

# Cek
mariadb -u flutter_app -p'ucup1211' -e "SHOW TABLES FROM koperasi_siswa;"

# 2. Apache
# Pastikan DocumentRoot mengarah ke /var/www/html/koperasi_siswa
sudo systemctl enable --now httpd
sudo chown -R apache:apache backend/storage/uploads
sudo chmod -R 775 backend/storage/uploads

# 3. Test di browser
# http://localhost/koperasi_siswa/backend/api/dashboard.php
# http://localhost/koperasi_siswa/backend/auth/login.php (POST)
```

> Jika Apache pakai SELinux, jalankan `sudo restorecon -Rv /var/www/html/koperasi_siswa` bila upload gagal.

## Setup Flutter

```bash
cd app
flutter pub get
flutter analyze
flutter test

# Desktop / Web
flutter run -d linux      # Fedora
flutter run -d chrome
flutter run -d web-server --web-port 8080

# Build
flutter build linux
flutter build web
flutter build apk --release
```

Konfigurasi base URL ada di `app/lib/src/core/config/env.dart`:

```dart
class Env {
  // Override saat build: --dart-define=API_BASE_URL=http://192.168.1.5/koperasi_siswa
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/koperasi_siswa',
  );
}
```

Untuk akses dari HP, ganti `localhost` → IP laptop via `--dart-define` (lihat [docs/SETUP.md](docs/SETUP.md)).

## Menjalankan di HP

Ringkas:

1. Satu Wi-Fi antara laptop & HP
2. Build dengan IP laptopmu, contoh:
   `flutter build apk --release --dart-define=API_BASE_URL=http://192.168.100.12/koperasi_siswa`
3. `flutter run` pilih device HP, atau install APK hasil build manual

Detail instalasi & reset data: [docs/SETUP.md](docs/SETUP.md)

## API

Dokumentasi endpoint: [docs/API.md](docs/API.md)

## Troubleshooting

| Masalah                                            | Solusi                                                                                                                            |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `Koneksi database gagal`                           | Cek `backend/config/db.php`, `systemctl status mariadb`, `mariadb -u flutter_app -p'ucup1211' -e "SELECT 1"`                      |
| `file INSTALL cannot find .../native_assets/linux` | `cd app && rm -rf build .dart_tool/flutter_build && flutter clean && flutter pub get && flutter run -d linux`                     |
| Foto tidak ter-upload                              | `chmod 775 backend/storage/uploads/{produk,profil}` + `restorecon` (SELinux)                                                      |
| `CORS` / `404` di Flutter Web                      | Pastikan Apache DocumentRoot benar & `backend/config/cors.php` aktif                                                              |
| HP tidak bisa akses `localhost`                    | Ganti `localhost` → IP LAN laptop, buka firewall `sudo firewall-cmd --add-service=http --permanent && sudo firewall-cmd --reload` |

## Lisensi

Internal — Koperasi Siswa.
