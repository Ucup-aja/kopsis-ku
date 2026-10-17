<?php
require_once __DIR__."/../config/db.php";
require_once __DIR__."/../config/cors.php";
cors(["POST","OPTIONS"]);
$conn->query("CREATE TABLE IF NOT EXISTS pengguna (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL, username VARCHAR(50) DEFAULT NULL UNIQUE, email VARCHAR(100) NOT NULL UNIQUE, password VARCHAR(255) NOT NULL, foto VARCHAR(255) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
$conn->query("ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS username VARCHAR(50) AFTER name");
$conn->query("ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS foto VARCHAR(255) DEFAULT NULL");
$data = json_decode(file_get_contents("php://input"), true);
$name = trim($data["name"] ?? "");
$username = trim($data["username"] ?? "");
$email = trim($data["email"] ?? "");
$password = $data["password"] ?? "";
if ($name === "" || $username === "" || $email === "" || $password === "") { echo json_encode(["success"=>false,"message"=>"Nama, username, email, password wajib diisi"]); exit; }
if (!preg_match('/^[a-zA-Z0-9._]{3,30}$/', $username)) { echo json_encode(["success"=>false,"message"=>"Username 3-30 karakter, huruf/angka/._ saja"]); exit; }
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) { echo json_encode(["success"=>false,"message"=>"Format email tidak valid"]); exit; }
if (strlen($password) < 6) { echo json_encode(["success"=>false,"message"=>"Password minimal 6 karakter"]); exit; }
$stmt = $conn->prepare("SELECT id FROM pengguna WHERE username=? OR email=?");
$stmt->bind_param("ss", $username, $email);
$stmt->execute(); $r=$stmt->get_result();
if ($r->num_rows>0){ echo json_encode(["success"=>false,"message"=>"Username atau email sudah terdaftar"]); exit; }
$hash=password_hash($password, PASSWORD_DEFAULT);
$stmt=$conn->prepare("INSERT INTO pengguna (name, username, email, password) VALUES (?,?,?,?)");
$stmt->bind_param("ssss", $name, $username, $email, $hash);
if($stmt->execute()){ echo json_encode(["success"=>true,"message"=>"Registrasi berhasil, silakan login dengan username"]); } else { echo json_encode(["success"=>false,"message"=>"Registrasi gagal: ".$conn->error]); }
