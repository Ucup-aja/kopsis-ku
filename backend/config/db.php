<?php
require_once __DIR__ . '/env.php';
// Kredensial TIDAK disimpan di sini. Isi lewat backend/config/env.local.php
// (tidak di-commit) atau environment variable DB_HOST/DB_USER/DB_PASS/DB_NAME.
// Lihat docs/DEPLOY_VPS.md §4.
$host = env_str('DB_HOST', 'localhost');
$user = env_str('DB_USER', '');
$password = env_str('DB_PASS', '');
$database = env_str('DB_NAME', 'koperasi_siswa');
$conn = @new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
  http_response_code(500);
  header('Content-Type: application/json');
  // Detail koneksi sengaja tidak dibagikan ke klien.
  error_log("[koperasi_siswa] DB gagal: " . $conn->connect_error);
  die(json_encode(["success"=>false,"message"=>"Koneksi database gagal.","error"=>["code"=>"DB_ERROR","fields"=>new stdClass()],"data"=>null]));
}
$conn->set_charset("utf8mb4");
