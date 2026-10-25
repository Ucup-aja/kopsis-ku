<?php
/**
 * Autentikasi token Bearer — satu-satunya pintu masuk API.
 *
 * Alur:
 *   1. login.php menerbitkan token acak (32 byte) → disimpan di tabel `sesi`.
 *   2. Client mengirim `Authorization: Bearer <token>` pada setiap request API.
 *   3. require_auth() memvalidasi token; gagal → HTTP 401.
 *
 * Tabel dibuat malas (CREATE TABLE IF NOT EXISTS) agar database lama
 * yang sudah berisi data tidak perlu migrasi manual.
 */
require_once __DIR__ . '/db.php';

const AUTH_TOKEN_TTL_DAYS = 30;

/// Pastikan tabel sesi tersedia.
function auth_ensure_table(mysqli $conn): void {
  $conn->query(
    'CREATE TABLE IF NOT EXISTS sesi (
      token VARCHAR(64) NOT NULL PRIMARY KEY,
      pengguna_id INT NOT NULL,
      dibuat_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      expired_at TIMESTAMP NOT NULL,
      INDEX idx_sesi_pengguna (pengguna_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
  );
}

/// Ambil token dari header `Authorization: Bearer <token>`.
function auth_token(): ?string {
  $h = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
  if (!is_string($h) || $h === '') return null;
  if (stripos($h, 'Bearer ') !== 0) return null;
  $t = trim(substr($h, 7));
  return $t === '' ? null : $t;
}

/// Wajibkan login. Mengisi $authUserId; keluar HTTP 401 bila gagal.
function require_auth(mysqli $conn, ?int &$authUserId): void {
  $authUserId = null;
  auth_ensure_table($conn);
  $token = auth_token();
  if ($token === null) auth_fail('Token tidak ada.');
  $stmt = $conn->prepare(
    'SELECT pengguna_id FROM sesi WHERE token = ? AND expired_at > NOW() LIMIT 1');
  $stmt->bind_param('s', $token);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  if (!$row) auth_fail('Token tidak valid atau sudah kedaluwarsa.');
  $authUserId = (int) $row['pengguna_id'];
}

/// Terbitkan token baru untuk pengguna dan simpan ke tabel sesi.
function auth_issue(mysqli $conn, int $userId): string {
  auth_ensure_table($conn);
  $token = bin2hex(random_bytes(32));
  $stmt = $conn->prepare(
    'INSERT INTO sesi (token, pengguna_id, expired_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))');
  $ttl = AUTH_TOKEN_TTL_DAYS;
  $stmt->bind_param('sii', $token, $userId, $ttl);
  $stmt->execute();
  return $token;
}

/// Cabut semua token milik pengguna (mis. saat logout).
function auth_revoke(mysqli $conn, int $userId): void {
  auth_ensure_table($conn);
  $stmt = $conn->prepare('DELETE FROM sesi WHERE pengguna_id = ?');
  $stmt->bind_param('i', $userId);
  $stmt->execute();
}

function auth_fail(string $msg): void {
  http_response_code(401);
  header('Content-Type: application/json');
  echo json_encode([
    'success' => false,
    'message' => $msg,
    'error' => ['code' => 'UNAUTHORIZED', 'fields' => new stdClass()],
    'data' => null,
  ], JSON_UNESCAPED_UNICODE);
  exit;
}
