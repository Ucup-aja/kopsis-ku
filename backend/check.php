<?php
/**
 * Cek backend KopsisKu — autentikasi + aturan stok.
 * Skrip CLI (diblokir dari HTTP lewat .htaccess).
 *
 * Jalankan: php backend/check.php [base_url] [username] [password]
 * Contoh:
 *   php backend/check.php http://localhost/koperasi_siswa                  # DB kosong → buat akun uji
 *   php backend/check.php http://localhost/koperasi_siswa budi rahasia123   # pakai akun yang ada
 *
 * Keluar 0 bila semua lulus, 1 bila ada gagal.
 */

$baseUrl = rtrim($argv[1] ?? 'http://localhost/koperasi_siswa', '/');
$loginUser = $argv[2] ?? null;
$loginPass = $argv[3] ?? null;
$fail = 0;
$token = null;

function check(string $label, bool $ok): void {
  global $fail;
  echo ($ok ? '[PASS] ' : '[FAIL] ') . $label . "\n";
  if (!$ok) $fail++;
}

/** @return array{0:int,1:array} [status HTTP, body terdekode] */
function req(string $method, string $url, ?array $body = null, ?string $token = null): array {
  $ch = curl_init($url);
  $headers = ['Content-Type: application/json'];
  if ($token !== null) $headers[] = 'Authorization: Bearer ' . $token;
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_TIMEOUT => 15,
    CURLOPT_HTTPHEADER => $headers,
  ]);
  if ($body !== null) {
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
  }
  $raw = curl_exec($ch);
  $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  return [$status, json_decode((string)$raw, true) ?: ['_raw' => $raw]];
}

// ── Autentikasi: dapatkan token ─────────────────────────────────────
if ($loginUser !== null && $loginPass !== null) {
  [$st, $r] = req('POST', "$baseUrl/backend/auth/login.php",
    ['username' => $loginUser, 'password' => $loginPass]);
  $token = $r['user']['token'] ?? null;
  check('login dengan kredensial yang diberikan', $st === 200 && $token !== null);
} else {
  $user = 'cek_' . substr((string)microtime(true), -6);
  $pass = 'rahasia123';
  [$st, $r] = req('POST', "$baseUrl/backend/auth/registrasi.php", [
    'name' => 'Cek Otomatis', 'username' => $user,
    'email' => "$user@example.com", 'password' => $pass,
  ]);
  if ($st !== 200 || ($r['success'] ?? false) !== true) {
    // Database sudah berisi akun → registrasi ditutup ( memang dirancang begitu).
    echo "[INFO] Registrasi ditutup (database sudah punya akun).\n";
    echo "       Jalankan: php backend/check.php $baseUrl <username> <password>\n";
    exit(1);
  }
  [$st, $r] = req('POST', "$baseUrl/backend/auth/login.php",
    ['username' => $user, 'password' => $pass]);
  $token = $r['user']['token'] ?? null;
  check('registrasi akun uji + login', $st === 200 && $token !== null);
}

// ── Penjaga API: tanpa token harus 401 ─────────────────────────────
[$st] = req('GET', "$baseUrl/backend/api/produk.php");
check('API menolak request tanpa token (401)', $st === 401);

// ── Produk: tambah stok 5 ──────────────────────────────────────────
[$st, $r] = req('POST', "$baseUrl/backend/api/produk.php", [
  'nama' => 'Produk Cek', 'kategori' => 'cek',
  'harga' => 1000, 'stok' => 5, 'deskripsi' => 'uji aturan stok',
], $token);
$produkId = (int)($r['data']['id'] ?? 0);
check('tambah produk (stok 5)', $st === 201 && $produkId > 0);

// ── Aturan stok: jual melebihi sisa ditolak ────────────────────────
[$st, $r] = req('POST', "$baseUrl/backend/api/transaksi.php", [
  'produk_id' => $produkId, 'tipe' => 'penjualan', 'jumlah' => 10,
], $token);
check('jual 10 ditolak (sisa 5)', $st === 400 && str_contains((string)($r['message'] ?? ''), 'Stok tidak cukup'));

// ── Jual 3 sah → stok 2 ────────────────────────────────────────────
[$st, $r] = req('POST', "$baseUrl/backend/api/transaksi.php", [
  'produk_id' => $produkId, 'tipe' => 'penjualan', 'jumlah' => 3,
], $token);
$trxId = (int)($r['data']['id'] ?? 0);
check('jual 3 dicatat (stok→2)', $st === 201 && $trxId > 0 && (int)($r['data']['stok_sesudah'] ?? -1) === 2);

// ── Restok 4 → stok 6 ──────────────────────────────────────────────
[$st, $r] = req('POST', "$baseUrl/backend/api/transaksi.php", [
  'produk_id' => $produkId, 'tipe' => 'restok', 'jumlah' => 4,
], $token);
check('restok 4 (stok→6)', $st === 201 && (int)($r['data']['stok_sesudah'] ?? -1) === 6);

// ── Hapus transaksi → stok pulih ───────────────────────────────────
[$st, $r] = req('POST', "$baseUrl/backend/api/transaksi.php?id=$trxId&_method=DELETE", [
  '_method' => 'DELETE', 'id' => $trxId,
], $token);
check('hapus transaksi → stok pulih', $st === 200 && ($r['success'] ?? false) === true);

[$st, $r] = req('GET', "$baseUrl/backend/api/produk.php?id=$produkId", null, $token);
check('verifikasi stok akhir = 5', (int)($r['data']['stok'] ?? -1) === 5);

// ── Bersihkan produk uji ───────────────────────────────────────────
[$st, $r] = req('POST', "$baseUrl/backend/api/produk.php?id=$produkId&_method=DELETE", [
  '_method' => 'DELETE', 'id' => $produkId,
], $token);
check('bersihkan produk uji', $st === 200 && ($r['success'] ?? false) === true);

// ── Dashboard ──────────────────────────────────────────────────────
[$st, $r] = req('GET', "$baseUrl/backend/api/dashboard.php", null, $token);
check('dashboard OK', $st === 200 && ($r['success'] ?? false) === true);

echo "\n" . ($fail === 0 ? 'SEMUA LULUS' : "$fail GAGAL") . "\n";
exit($fail === 0 ? 0 : 1);
