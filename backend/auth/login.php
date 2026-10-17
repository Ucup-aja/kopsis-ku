<?php
require_once __DIR__."/../config/db.php";
require_once __DIR__."/../config/cors.php";
cors(["POST","OPTIONS"]);
$conn->query("CREATE TABLE IF NOT EXISTS pengguna (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL, username VARCHAR(50) DEFAULT NULL UNIQUE, email VARCHAR(100) NOT NULL UNIQUE, password VARCHAR(255) NOT NULL, foto VARCHAR(255) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
$conn->query("ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS username VARCHAR(50) AFTER name");
$conn->query("ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS foto VARCHAR(255) DEFAULT NULL");
$data = json_decode(file_get_contents("php://input"), true);
$username = trim($data["username"] ?? "");
$password = $data["password"] ?? "";
if ($username === "" || $password === "") { echo json_encode(["success"=>false,"message"=>"Username dan password wajib diisi"]); exit; }
$stmt=$conn->prepare("SELECT id, name, username, email, password, foto FROM pengguna WHERE username=?");
$stmt->bind_param("s",$username);
$stmt->execute(); $r=$stmt->get_result();
if($r->num_rows===0){ echo json_encode(["success"=>false,"message"=>"Username atau password salah"]); exit; }
$user=$r->fetch_assoc();
if(!password_verify($password,$user["password"])){ echo json_encode(["success"=>false,"message"=>"Username atau password salah"]); exit; }
require_once __DIR__."/../src/Support/url.php";
$fotoUrl = foto_url($user['foto'], upload_base('profil'));
echo json_encode(["success"=>true,"message"=>"Login berhasil","user"=>[
  "id"=>(int)$user["id"],"name"=>$user["name"],"username"=>$user["username"],"email"=>$user["email"],"foto"=>$user["foto"],"foto_url"=>$fotoUrl
]]);
