# KopsisKu (app)

Flutter app koperasi konsumen — **online**. Data di server lewat backend PHP + MariaDB.

## Perintah

```bash
flutter pub get
flutter test                       # 29 tes
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-PC>/koperasi_siswa
```

`API_BASE_URL` wajib diberikan saat build — menunjuk ke server, contoh
`http://192.168.100.12/koperasi_siswa` (ganti dengan IP/domain server).

## Arsitektur data

UI → repository (`lib/src/data/repositories/`) → `ApiClient` (HTTP) → backend PHP.
Widget tidak menyentuh HTTP langsung.

- Auth: register/login ke server; password `password_hash()` PHP.
- Aturan stok di server: penjualan menolak stok kurang ("Stok tidak cukup (sisa N)"),
  hapus transaksi memulihkan stok, status `habis`/`tersedia` berganti otomatis.
- Foto diunggah ke `backend/storage/uploads/`; URL absolut dikembalikan server dan
  ditampilkan dengan `Image.network`.

## Catatan pengembang

Branding per-developer (foto, nama, URL portfolio) di
`lib/src/core/config/app_branding.dart`.
