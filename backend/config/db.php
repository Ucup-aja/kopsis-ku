<?php
// Koneksi DB terpusat. Kredensial TIDAK di sini — lihat config/env.php.
// Detail error koneksi sengaja tidak dibagikan ke klien.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
mysqli_report(MYSQLI_REPORT_OFF);

require_once __DIR__ . '/env.php';

$host = env_str('DB_HOST', 'localhost');
$user = env_str('DB_USER', '');
$password = env_str('DB_PASS', '');
$database = env_str('DB_NAME', 'koperasi_siswa');

$conn = @new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
  http_response_code(500);
  header('Content-Type: application/json');
  error_log('[koperasi_siswa] DB gagal: ' . $conn->connect_error);
  die(json_encode([
    'success' => false,
    'message' => 'Koneksi database gagal.',
    'error' => ['code' => 'DB_ERROR', 'fields' => new stdClass()],
    'data' => null,
  ]));
}
$conn->set_charset('utf8mb4');
