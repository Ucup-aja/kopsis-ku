<?php
// URL helper — deteksi skema http/https di balik reverse proxy (nginx/certbot).
// Android menolak konten http: dari app https:, jadi skema wajib akurat.

/// Baca env fleksibel: getenv() (CLI/nginx) lalu $_SERVER (Apache SetEnv).
function app_env(string $key): ?string {
  $v = getenv($key);
  if ($v !== false && $v !== '') return (string)$v;
  if (isset($_SERVER[$key]) && $_SERVER[$key] !== '') return (string)$_SERVER[$key];
  return null;
}

function app_scheme(): string {
  // 1. Explicit override (Apache SetEnv / nginx fastcgi_param).
  $forced = app_env('APP_SCHEME');
  if ($forced === 'https' || $forced === 'http') return $forced;

  // 2. PHP di belakang proxy sering tidak mengisi HTTPS, tapi menaruh
  //    header standar X-Forwarded-Proto dari nginx/Apache.
  $xfp = $_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '';
  if (stripos($xfp, 'https') !== false) return 'https';

  // 3. Deteksi langsung.
  if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') return 'https';
  if (($_SERVER['SERVER_PORT'] ?? 80) == 443) return 'https';

  return 'http';
}

function app_host(): string {
  return app_env('APP_HOST') ?? ($_SERVER['HTTP_HOST'] ?? 'localhost');
}

/// Base URL absolut untuk file yang di-upload.
/// Contoh: upload_base('produk') → https://domain/backend/storage/uploads/produk
function upload_base(string $kind = 'produk'): string {
  $prefix = rtrim(app_env('APP_PREFIX') ?: '/koperasi_siswa', '/');
  return app_scheme() . '://' . app_host() . "$prefix/backend/storage/uploads/$kind";
}

/// Bangun URL foto, lewati bila sudah absolut.
function foto_url(?string $foto, string $base): ?string {
  if (!$foto) return null;
  if (strpos($foto, 'http') === 0) return $foto;
  return rtrim($base, '/') . '/' . ltrim($foto, '/');
}
