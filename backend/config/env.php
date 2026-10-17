<?php
// Central env loader — SECURITY.md §1, ARCHITECTURE.md §7.
// Production secrets via environment / Apache SetEnv, never committed.
// Falls back to existing dev credentials for local parity.
//
// Opsional: muat kredensial produksi dari env.local.php (tidak di-commit).
// Nilai di file ini menang, jadi taruh DB_HOST/DB_USER/DB_PASS/APP_* di sana.
if (is_file(__DIR__ . '/env.local.php')) {
  require_once __DIR__ . '/env.local.php';
}

function env_str(string $key, string $fallback): string {
  $v = getenv($key);
  if ($v === false || $v === '') {
    if (isset($_SERVER[$key]) && $_SERVER[$key] !== '') return (string)$_SERVER[$key];
    return $fallback;
  }
  return (string)$v;
}
