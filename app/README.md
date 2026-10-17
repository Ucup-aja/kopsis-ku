# KopsisKu — Koperasi Siswa Digital (Flutter App)

Aplikasi mobile & desktop untuk **Koperasi Siswa SMKN 1 Leuwimunding (PPLG)**.
Kelola **produk, stok, foto, transaksi penjualan/restock, profil pengguna, dan info developer** dalam satu aplikasi yang modern, cepat, dan responsif.

> Backend: PHP 8.5 + MariaDB 11.8 · Folder root server: `/var/www/html/koperasi_siswa`
> Repo root: `../README.md` · API: `../docs/API.md` · Mobile: `../docs/MOBILE.md` · Setup: `../docs/SETUP.md`
> Rebuild spec: `~/Downloads/koperasi_siswa_rebuild_docs/koperasi_siswa_docs/` (PRD, ARCHITECTURE, DESIGN, API_CONTRACT, DATABASE, SECURITY, QA, DEPLOYMENT)

---

## Daftar Isi

- [Fitur](#fitur)
- [Tech Stack](#tech-stack)
- [Struktur Proyek](#struktur-proyek)
- [Prasyarat](#prasyarat)
- [Instalasi Cepat](#instalasi-cepat)
- [Konfigurasi API](#konfigurasi-api)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Build Release](#build-release)
- [Akun & Alur Pakai](#akun--alur-pakai)
- [Tema & Responsif](#tema--responsif)
- [Troubleshooting](#troubleshooting)
- [Tim Developer](#tim-developer)
- [Lisensi](#lisensi)

---

## Fitur

### 1. Auth (Login / Register)
- `lib/src/features/auth/login_page.dart` — login dengan **username + password**.
- `lib/src/features/auth/register_page.dart` — registrasi **nama, username, email, password** (validasi: username 3–30 karakter `a-zA-Z0-9._`, email valid, password ≥ 6).
- Error koneksi ditampilkan jelas + tombol show/hide password.
- Setelah login → `src/features/shell/main_shell.dart` dengan data `userId, name, username, email, foto, foto_url`.

### 2. Shell / Navigasi Utama (`main_shell.dart`)
- **Mobile (< 860px):** `NavigationBar` 4 tab — **Beranda, Produk, Transaksi, Akun**.
- **Desktop/Tablet (≥ 860px):** `NavigationRail` (+ extended ≥ 1100px), header + badge `Pengelola`.
- **Akun:** avatar + ganti foto (galeri/kamera via `image_picker`), hapus foto, toggle dark mode, info app, logout dengan dialog konfirmasi.

### 3. Dashboard (`dashboard_screen.dart`)
- Hero gradient “Kelola produk kebutuhan siswa”.
- Shortcut **Info Developer** → `developer_page.dart` + portfolio in-app.
- Stat cards: **Total Produk, Total Stok, Nilai Stok (Rp), Perlu Restock, Penjualan Hari Ini + Omset, Penjualan Bulan**.
- **Penjualan Terbaru**, **Kategori** (chip + jumlah produk & stok), **Stok Menipis (≤ 5)**, **Produk Terbaru** (grid responsif / list di layar sangat kecil).
- Pull-to-refresh (`RefreshIndicator`).

### 4. Produk (`produk_screen.dart`)
- List + grid view, **search** (nama/deskripsi/kategori), filter **kategori** (`alat_tulis, seragam, makanan, minuman, buku, lainnya`) & **status** (`tersedia, habis, arsip`).
- **CRUD penuh:** tambah (multipart + foto), edit (`_method=PUT` + ganti/hapus foto), hapus (DELETE + fallback `_method=DELETE`).
- Upload foto: `jpg/png/webp ≤ 5MB`, preview, `foto_url` otomatis dari server.
- Shortcut **Jual / Restock** langsung dari kartu produk → `transaksi_screen.dart`.
- Format harga Rupiah via `intl`.

### 5. Transaksi (`transaksi_screen.dart`)
- Riwayat transaksi (search, filter `tipe`, `produk_id`, rentang tanggal `dari–sampai`, `limit`).
- Ringkasan: **total transaksi, penjualan & omset hari ini, penjualan & omset bulan berjalan, restock bulan, top produk**.
- Buat transaksi: `produk_id, tipe (penjualan/restock), jumlah, harga_satuan, keterangan` — stok produk otomatis bertambah/berkurang di server, kode transaksi & snapshot `stok_sebelum/sesudah` tersimpan.
- Hapus transaksi.

### 6. Profil & Foto
- `GET profil.php?id= / ?username=` untuk refresh avatar.
- `POST multipart field foto` untuk upload, `foto_hapus=1` untuk hapus.
- Avatar fallback inisial nama bila tidak ada foto / gagal load.

### 7. Developer & Portfolio
- `developer_page.dart` — daftar tim + info sekolah.
- `portfolio_page.dart` + `portfolios/portfolio_{alya,azzahra,ridho,yusuf}_page.dart` — dibuka **in-app** via `portfolioKey` (tanpa browser).
- Assets lokal: `assets/poto.jpeg, SSS.jpeg, azzahra.jpeg, yusuf.jpeg, smartBK.png, pplg1.png, portfolios/alya.jpeg`.

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter 3.44+ (Dart 3.x), Material 3 |
| State | `StatefulWidget` + `ValueListenableBuilder` (`ThemeController`) |
| Network | `http: ^1.2.2` (JSON + Multipart) |
| Local | `shared_preferences: ^2.2.2` (tema gelap/terang) |
| Media | `image_picker: ^1.0.7` (galeri/kamera, compress `maxWidth: 800, quality: 85`) |
| Format | `intl: ^0.19.0` (Rupiah `id_ID`, tanggal) |
| Link | `url_launcher: ^6.2.5` |
| Backend | PHP 8.5 + MariaDB 11.8 + Apache (`../backend/`) |

---

## Struktur Proyek

```
app/
├── lib/
│   ├── main.dart                          # entry → ThemeController.load() → LoginPage
│   └── src/
│       ├── core/
│       │   ├── config/api_config.dart     # baseUrl + semua endpoint
│       │   ├── config/app_branding.dart   # nama app, versi, DeveloperData
│       │   ├── theme/app_theme.dart       # warna, radius, shadow, light/dark ThemeData
│       │   ├── theme/theme_controller.dart# ValueNotifier<bool> isDark (persisted)
│       │   └── responsive/app_responsive.dart # breakpoint, padding, gridCols
│       ├── data/
│       │   ├── models/models.dart         # Produk, DashboardData, Anggota, Simpanan, Pinjaman, Transaksi, TransaksiSummary
│       │   └── services/api_service.dart  # login, register, profil, dashboard, produk, anggota, simpanan, pinjaman, transaksi
│       ├── features/
│       │   ├── auth/login_page.dart
│       │   ├── auth/register_page.dart
│       │   ├── shell/main_shell.dart      # Beranda/Produk/Transaksi/Akun
│       │   ├── dashboard/dashboard_screen.dart
│       │   ├── produk/produk_screen.dart
│       │   ├── transaksi/transaksi_screen.dart
│       │   └── developer/                 # developer_page, portfolio_page, portfolios/
│       └── shared/widgets/                # stat_card, theme_toggle
├── assets/                                # foto tim + portfolios/
├── android/ ios/ linux/ macos/ web/ windows/
├── pubspec.yaml
└── README.md (file ini)
```

---

## Prasyarat

- **Flutter 3.44+** + Dart 3.x — cek `flutter --version`, `flutter doctor`
- **Backend jalan** di `http://localhost/koperasi_siswa` (Apache + MariaDB):
  ```bash
  curl -s http://localhost/koperasi_siswa/backend/api/dashboard.php | head -c 300
  ```
  Jika belum setup, ikuti `../README.md` atau `../docs/SETUP.md`.
- Linux (Fedora): toolchain desktop untuk `flutter run -d linux`
- Android: Android Studio + SDK + `adb` · iOS: macOS + Xcode

---

## Instalasi Cepat

```bash
cd /var/www/html/koperasi_siswa/app

flutter pub get
flutter analyze
flutter test
```

---

## Konfigurasi API

> ARCHITECTURE.md §7: tidak ada hard-coded URL di business code.
> Base URL dibaca dari `--dart-define=API_BASE_URL` (`lib/src/core/config/env.dart`).
> `ApiConfig` hanya accessor kompatibilitas — kode baru memakai `AppScope` repositories.

```bash
# Dev (default localhost bila tanpa flag)
flutter run -d linux

# HP fisik — ganti dengan IP laptop (tanpa edit file)
flutter run -d android --dart-define=API_BASE_URL=http://192.168.100.12/koperasi_siswa

# Produksi
flutter build apk --release --dart-define=API_BASE_URL=https://koperasi.sekolah.id --dart-define=APP_ENV=prod
```

Backend secrets via environment (`backend/config/env.php` → `DB_HOST/DB_USER/DB_PASS/DB_NAME`, `ALLOWED_ORIGIN`, `APP_ENV`):

```bash
export DB_HOST=localhost DB_USER=flutter_app DB_PASS='***' DB_NAME=koperasi_siswa
export ALLOWED_ORIGIN='https://koperasi.sekolah.id' APP_ENV=prod
```

---

## Arsitektur (Rebuild)

```
Flutter UI → Repository → ApiClient → PHP API → MariaDB
```

- `lib/src/app/app.dart` — `AppScope` (DI: ApiClient + repositories) + `AppRouter` (auth guard via `AuthSession`)
- `lib/main.dart` — bootstrap: load theme + session sebelum first frame
- `lib/src/core/config/env.dart` — base URL via `--dart-define`
- `lib/src/core/error/` — `AppException` + `Result<T>` (pengganti `throw Exception(string)`)
- `lib/src/core/network/api_client.dart` — **satu-satunya** file yang memakai `package:http`
- `lib/src/core/session/auth_session.dart` — sesi persisten (restart tidak logout)
- `lib/src/data/repositories/` — `AuthRepository`, `ProdukRepository` (+validasi harga/stok ≥ 0), `DashboardRepository`, `TransaksiRepository`, `ProfilRepository`
- `lib/src/core/utils/format.dart` — `rupiah()`, `tglPanjang()` tunggal (hapus duplikasi)
- `lib/src/shared/widgets/app_states.dart` — `LoadingSkeleton`, `EmptyState`, `ErrorState`, `confirmDestructive()`, `showAppMessage()`
- `lib/src/shared/widgets/fields.dart` — `SearchField`, `StatusBadge`, `AvatarView`
- Backend: `backend/config/env.php`, `backend/src/Support/{response,validation,upload}.php` — envelope `{success,message,data,error{code,fields}}`, validasi non-negatif, MIME check via `finfo`, `mkdir 0755`, prepared statements, `ALLOWED_ORIGIN` + `Authorization` header

Belum dikerjakan (TBD sesuai rebuild docs): RBAC/role matrix, JWT/session expiry + refresh, pagination `meta`, migrasi versioned `database/migrations/`, audit log finansial.

## Menjalankan Aplikasi

```bash
# Desktop Fedora
flutter run -d linux

# Web
flutter run -d chrome
flutter run -d web-server --web-port 8080

# Android (HP via USB / wireless)
flutter devices
flutter run -d android
# atau spesifik: flutter run -d <deviceId>

# iOS (butuh macOS + Xcode)
flutter run -d ios
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`.

---

## Build Release

```bash
# Android APK (→ build/app/outputs/flutter-apk/)
flutter build apk --release
flutter build apk --split-per-abi   # 3 APK per ABI, lebih kecil

# Install via adb
adb install build/app/outputs/flutter-apk/app-release.apk

# iOS (butuh Xcode)
flutter build ios --release

# Desktop & Web
flutter build linux
flutter build web
```

Checklist sebelum release:
- [ ] `ApiConfig.baseUrl` sudah IP/domain produksi (bukan `localhost`)
- [ ] Kredensial DB produksi di `backend/config/db.php`
- [ ] `backend/storage/uploads/{produk,profil}` writable (`775`, owner `apache`)
- [ ] Test: login → dashboard → tambah produk + foto → jual/restock → cek stok berubah

---

## Akun & Alur Pakai

1. **Daftar** di halaman Register (atau pakai akun yang sudah ada).
2. **Masuk** dengan username + password.
3. **Beranda:** pantau stok, omset, stok menipis.
4. **Produk:** tambah produk + foto → edit stok/harga → filter/search.
5. **Transaksi:** catat **penjualan** (stok −) atau **restock** (stok +), lihat ringkasan & top produk.
6. **Akun:** ganti foto profil, toggle dark mode, logout.

---

## Tema & Responsif

- **Tema:** `AppTheme.light` / `AppTheme.dark` (seed `primary #0E7C6B`), toggle di AppBar / halaman Akun, tersimpan via `ThemeController` + `shared_preferences`.
- **Responsif:** breakpoint `≥ 860px` → `NavigationRail`, `≥ 1100px` → extended; grid produk & stat cards menyesuaikan lebar (`AppResponsive.gridCols`, `contentMaxWidth`, `pagePadding`); layar < 340px otomatis jadi list agar tidak overflow.

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| `Tidak dapat terhubung ke server` di Login | Pastikan backend hidup: `curl http://localhost/koperasi_siswa/backend/api/dashboard.php` · cek `ApiConfig.baseUrl` · HP fisik jangan pakai `localhost` |
| `native_assets/linux — file INSTALL cannot find` | `rm -rf build .dart_tool/flutter_build && flutter clean && flutter pub get && flutter run -d linux` |
| Foto tidak ter-upload | `sudo chown -R apache:apache ../backend/storage/uploads && sudo chmod -R 775 ../backend/storage/uploads` · SELinux: `sudo restorecon -Rv /var/www/html/koperasi_siswa` · maks 5MB, jpg/png/webp |
| `CORS` / `404` di Flutter Web | Pastikan Apache `DocumentRoot=/var/www/html/koperasi_siswa` & `backend/config/cors.php` aktif |
| HP tidak bisa akses server (`Unable to connect`) | Satu Wi-Fi · firewall: `sudo firewall-cmd --add-service=http --permanent && sudo firewall-cmd --reload` · test dari browser HP: `http://IP_LAPTOP/koperasi_siswa/backend/api/dashboard.php` |
| `flutter devices` offline / tidak muncul | `adb kill-server && adb start-server`, cabut-colok USB, allow USB debugging ulang |
| APK `App not installed` | Uninstall versi lama dulu, atau `flutter clean && flutter build apk --release` |
| Stok tidak berubah setelah transaksi | Refresh (pull-to-refresh) · cek response `stok_sebelum/sesudah` di API transaksi |

---

## Tim Developer

**SMKN 1 Leuwimunding — PPLG · Kelas XII PPLG 1 · T.A. 2025/2026**
Pembimbing: Bapak Dede Arif Nugraha, S.Kom.

| Nama | Kelas | NIS |
|---|---|---|
| Ahmad Yusuf Firdaus | XII PPLG 1 | 242510109 |
| Azzahra Meita Putri | XII PPLG 1 | NIS 002 |
| Alya Nur Fauziah | XII PPLG 1 | NIS 001 |
| Ridho Firmansyah | XII PPLG 1 | NIS 003 |

Lihat juga halaman **Info Developer** di aplikasi (Beranda → Info Developer) untuk portfolio masing-masing.

---

## Lisensi

Internal — Koperasi Siswa SMKN 1 Leuwimunding.
App: **KopsisKu v1.2** — `© 2026 KopsisKu • SMKN 1 Leuwimunding PPLG`.
