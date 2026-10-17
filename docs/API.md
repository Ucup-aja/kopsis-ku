# API — Koperasi Konsumen Siswa

Base: `http://localhost/koperasi_siswa` · `Content-Type: application/json` kecuali upload foto (`multipart/form-data`)

Semua response: `{ "success": bool, "message": string, "data": ... }` · Error HTTP 4xx/5xx + `success: false`.

Cakupan: **koperasi konsumen** — produk, penjualan, dan restok. Tidak ada anggota/simpanan/pinjaman.

## Auth

### POST /backend/auth/registrasi.php

```json
{ "name": "Ahmad Yusuf", "username": "yusuf1211", "email": "yusuf@example.com", "password": "secret123" }
```

Validasi: `username` 3–30 `a-zA-Z0-9._`, `email` valid, `password` ≥6. Response `201` bila sukses, `409` bila username/email duplikat.

### POST /backend/auth/login.php

```json
{ "username": "yusuf1211", "password": "secret123" }
```

Response `data.user`: `{ id, name, username, email, foto, foto_url }` — `foto_url` = `http://HOST/koperasi_siswa/backend/storage/uploads/profil/<file>`.

## Profil

### GET /backend/api/profil.php?id=1  atau  ?username=yusuf1211

### POST /backend/api/profil.php?id=1  (multipart)

- Upload: field `foto` (jpg/png/webp ≤5MB)
- Hapus: field `foto_hapus=1` atau JSON `{ "id": 1, "foto_hapus": true }`

## Dashboard

### GET /backend/api/dashboard.php

```json
{
  "total_produk": 12,
  "produk_tersedia": 10,
  "produk_habis": 2,
  "total_stok": 140,
  "nilai_stok": 2500000,
  "by_kategori": [{ "kategori": "alat_tulis", "c": 5, "stok": 60 }],
  "stok_menipis": [ { "id": 1, "nama": "...", "foto_url": "..." } ],
  "recent_produk": [ ... ],
  "transaksi_hari": 3,
  "omset_hari": 45000,
  "transaksi_bulan": 40,
  "omset_bulan": 800000,
  "restok_bulan": 5,
  "recent_transaksi": [ ... ]
}
```

## Produk

### GET /backend/api/produk.php[?id=1&search=&kategori=&status=]

List / detail. Filter `kategori` (`lainnya` default), `status` (`tersedia|habis|arsip`), `search` (nama/deskripsi/kategori). `foto_url` otomatis.

### POST /backend/api/produk.php

- **JSON** (tanpa foto): `{ "nama": "...", "kategori": "snack", "harga": 2000, "stok": 12, "deskripsi": "...", "status": "tersedia" }`
- **Multipart** (pakai foto): fields `nama,harga` wajib + `kategori,stok,deskripsi,status` + file `foto`

Keduanya: `201` + `data` produk baru.

### PUT (via POST _method=PUT)

`POST /backend/api/produk.php?id=1` dengan `fields: _method=PUT, nama, kategori, harga, stok, ...` + opsional `foto` / `foto_hapus=1`. Juga support JSON `{ "_method": "PUT", "id": 1, ... }`.

### DELETE

`POST /backend/api/produk.php?id=1&_method=DELETE` (atau JSON `{ "_method": "DELETE", "id": 1 }`) — hapus file foto di server bila ada.

## Transaksi (penjualan & restok)

Tipe hanya `penjualan` (stok berkurang) dan `restok` (stok bertambah).

### GET /backend/api/transaksi.php[?search=&tipe=penjualan|restok&dari=YYYY-MM-DD&sampai=YYYY-MM-DD&limit=50]

### GET /backend/api/transaksi.php?summary=1

```json
{
  "total_transaksi": 100,
  "penjualan_hari_ini": 5,
  "omset_hari_ini": 75000,
  "penjualan_bulan": 40,
  "omset_bulan": 800000,
  "restok_bulan": 5,
  "nilai_restok_bulan": 500000,
  "top_produk": [{ "nama_produk": "...", "total_qty": 20, "total_nilai": 400000 }]
}
```

### POST /backend/api/transaksi.php

```json
{ "produk_id": 1, "tipe": "penjualan", "jumlah": 2, "harga_satuan": 5000, "keterangan": "jual ke kelas 10A" }
```

`harga_satuan` opsional (default harga produk). Validasi stok untuk `penjualan`.

### DELETE (batalkan & pulihkan stok)

`POST /backend/api/transaksi.php?id=1&_method=DELETE` — stok produk dikembalikan ke `stok_sebelum`.

## cURL

```bash
curl -s http://localhost/koperasi_siswa/backend/auth/registrasi.php \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test","username":"test1","email":"test1@example.com","password":"123456"}' | jq

curl -s http://localhost/koperasi_siswa/backend/auth/login.php \
  -H 'Content-Type: application/json' \
  -d '{"username":"test1","password":"123456"}' | jq

curl -s http://localhost/koperasi_siswa/backend/api/dashboard.php | jq
curl -s 'http://localhost/koperasi_siswa/backend/api/produk.php?search=buku' | jq
curl -s 'http://localhost/koperasi_siswa/backend/api/transaksi.php?tipe=penjualan&limit=10' | jq
curl -s 'http://localhost/koperasi_siswa/backend/api/transaksi.php?summary=1' | jq
```
