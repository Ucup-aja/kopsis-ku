# KopsisKu (app)

Flutter app koperasi konsumen — **offline penuh**. Data di SQLite lokal
(`lib/src/data/local/app_database.dart`), foto di dokumen app.

## Perintah

```bash
flutter pub get
flutter run -d android           # jalankan di HP/emulator
flutter build apk --release      # → build/app/outputs/flutter-apk/app-release.apk
flutter test
```

Tanpa konfigurasi apa pun — tidak ada URL backend, tidak ada `--dart-define`.

## Arsitektur data

UI → repository (`lib/src/data/repositories/`) → `AppDatabase` (sqflite) + berkas foto.
Widget tidak menyentuh database langsung.

- Auth lokal: register/login di HP; password SHA-256+salt.
- Aturan stok: penjualan menolak stok kurang ("Stok tidak cukup (sisa N)"), hapus transaksi
  memulihkan stok sebelumnya, status `habis`/`tersedia` berganti otomatis.
- Foto disalin dari image_picker ke `<dokumen app>/foto/`; path absolut tersimpan di kolom `foto`.

## Catatan pengembang

Branding per-developer (foto, nama, URL portfolio) di
`lib/src/core/config/app_branding.dart`.
