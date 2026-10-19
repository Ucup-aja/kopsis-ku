# Koperasi Siswa (KopsisKu)

Aplikasi **koperasi konsumen** sekolah untuk mengelola **produk, penjualan, dan restok** — mobile-first, minimalis.

> **Cakupan:** hanya koperasi konsumen (jual-beli barang). Modul anggota, simpanan, dan pinjaman tidak ada.

**Murni offline:** seluruh data (akun, produk, transaksi, foto) disimpan di HP lewat **SQLite** (`sqflite`). Tidak ada server, tidak perlu internet.

## Struktur

```
koperasi_siswa/
└── app/                        # Flutter — satu-satunya bagian yang dipakai
    ├── lib/src/
    │   ├── app/                # composition root (AppScope, router)
    │   ├── core/               # theme, session, error, utils, responsive
    │   ├── data/
    │   │   ├── local/          # AppDatabase (SQLite) + penyimpanan foto
    │   │   ├── models/
    │   │   └── repositories/   # auth, produk, transaksi, dashboard, profil
    │   ├── features/           # login, register, dashboard, produk, transaksi, shell
    │   └── shared/widgets/
    └── pubspec.yaml
```

## Menjalankan

```bash
cd app
flutter pub get
flutter test                       # tes aturan stok, agregasi dashboard, auth lokal
flutter build apk --release        # → build/app/outputs/flutter-apk/app-release.apk
```

Pertama kali buka app: daftar lewat layar **Registrasi** — akun disimpan di HP.

## Skema SQLite (dibuat otomatis saat pertama buka)

- `pengguna` — name, username, email, password (SHA-256+salt), foto
- `produk` — nama, kategori, harga, stok, deskripsi, foto, status (tersedia/habis/arsip)
- `transaksi` — kode `TRX-…`, penjualan & restok; stok berkurang/bertambah otomatis
