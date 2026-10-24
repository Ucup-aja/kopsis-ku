<?php
require_once __DIR__."/../config/cors.php";
cors(["GET","POST","PUT","DELETE","OPTIONS"]);
require_once __DIR__."/../config/db.php";
$conn->set_charset("utf8mb4");

function respond($ok,$msg,$data=null,$code=200,$errCode="REQUEST_FAILED"){http_response_code($code);$out=["success"=>$ok,"message"=>$msg,"data"=>$data];if(!$ok)$out["error"]=["code"=>$code===422?"VALIDATION_ERROR":($code===404?"NOT_FOUND":$errCode),"fields"=>new stdClass()];echo json_encode($out,JSON_UNESCAPED_UNICODE);exit;}
function ensureProdukTable($conn){
  $conn->query("CREATE TABLE IF NOT EXISTS produk (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(150) NOT NULL,
    kategori VARCHAR(50) NOT NULL DEFAULT 'lainnya',
    harga DECIMAL(12,2) NOT NULL,
    stok INT NOT NULL DEFAULT 0,
    deskripsi TEXT,
    foto VARCHAR(255) DEFAULT NULL,
    status ENUM('tersedia','habis','arsip') DEFAULT 'tersedia',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  )");
}
ensureProdukTable($conn);

$uploadDir = realpath(__DIR__."/../storage/uploads/produk") ?: (__DIR__."/../storage/uploads/produk");
if(!is_dir($uploadDir)) mkdir($uploadDir,0755,true);
require_once __DIR__ . "/../src/Support/url.php";
$baseUrl = upload_base('produk');
function saveFoto($file){
  global $uploadDir;
  if(!isset($file['tmp_name'])||!is_uploaded_file($file['tmp_name'])) return [false,"File tidak valid"];
  $err=$file['error']??0; if($err!==0) return [false,"Upload error $err"];
  $size=$file['size']??0; if($size>5*1024*1024) return [false,"Foto maksimal 5MB"];
  $ext=strtolower(pathinfo($file['name']??'',PATHINFO_EXTENSION));
  if(!in_array($ext,['jpg','jpeg','png','webp'])) return [false,"Format foto harus jpg, png, atau webp"];
  $finfo=new finfo(FILEINFO_MIME_TYPE); $mime=$finfo->file($file['tmp_name']);
  if(!in_array($mime,['image/jpeg','image/png','image/webp'])) return [false,"File bukan gambar yang valid"];
  if($ext==='jpeg') $ext='jpg';
  $name="prod_".time()."_".bin2hex(random_bytes(6)).".".$ext;
  $dest="$uploadDir/$name";
  if(!move_uploaded_file($file['tmp_name'],$dest)) return [false,"Gagal simpan foto"];
  return [true,$name];
}
function fetchProdukById($conn,$id){
  $stmt=$conn->prepare("SELECT * FROM produk WHERE id=?");
  $stmt->bind_param("i",$id); $stmt->execute();
  return $stmt->get_result()->fetch_assoc();
}
function isJsonReq(){ $ct=$_SERVER['CONTENT_TYPE']??''; return strpos($ct,'application/json')!==false; }

$rawInput = file_get_contents("php://input");
$jsonInput = json_decode($rawInput,true) ?? [];
$method=$_SERVER['REQUEST_METHOD'];
if(isset($_GET['_method'])) $method=strtoupper($_GET['_method']);
else if(isset($_POST['_method'])) $method=strtoupper($_POST['_method']);
else if(isset($jsonInput['_method'])) $method=strtoupper($jsonInput['_method']);

if($method==='GET'){
  $id=$_GET['id']??null;
  $search=trim($_GET['search']??'');
  $kategori=$_GET['kategori']??'';
  $status=$_GET['status']??'';
  if($id){
    $stmt=$conn->prepare("SELECT * FROM produk WHERE id=?");
    $stmt->bind_param("i",$id);$stmt->execute();$r=$stmt->get_result();
    if($row=$r->fetch_assoc()){
      $row['foto_url']=foto_url($row['foto'],$baseUrl);
      respond(true,"OK",$row);
    } else respond(false,"Produk tidak ditemukan",null,404);
  }
  $sql="SELECT * FROM produk WHERE 1=1"; $params=[]; $types="";
  if($search!==''){ $sql.=" AND (nama LIKE ? OR deskripsi LIKE ? OR kategori LIKE ?)"; $like="%$search%"; $params=array_merge($params,[$like,$like,$like]); $types.="sss"; }
  if($kategori!=='' && $kategori!=='semua'){ $sql.=" AND kategori=?"; $params[]=$kategori; $types.="s"; }
  if($status!=='' && in_array($status,['tersedia','habis','arsip'])){ $sql.=" AND status=?"; $params[]=$status; $types.="s"; }
  $sql.=" ORDER BY updated_at DESC, id DESC";
  if($types!==""){ $stmt=$conn->prepare($sql); $stmt->bind_param($types,...$params); $stmt->execute(); $q=$stmt->get_result(); } else $q=$conn->query($sql);
  if(!$q) respond(false,$conn->error,[],500);
  $rows=[]; while($r=$q->fetch_assoc()){ $r['foto_url']=foto_url($r['foto'],$baseUrl); $rows[]=$r; }
  respond(true,"OK",$rows);
}

if($method==='DELETE'){
  $id=$_GET['id']??$_POST['id']??$jsonInput['id']??null;
  if(!$id) respond(false,"ID wajib",null,400);
  $iid=(int)$id;
  $row=fetchProdukById($conn,$iid);
  if(!$row) respond(false,"Produk tidak ditemukan",null,404);
  $stmt=$conn->prepare("DELETE FROM produk WHERE id=?"); $stmt->bind_param("i",$id); $stmt->execute();
  if($stmt->affected_rows>0){ if($row['foto']&&file_exists("$uploadDir/".$row['foto'])) @unlink("$uploadDir/".$row['foto']); respond(true,"Produk dihapus"); }
  respond(false,"Gagal hapus",null,500);
}

if($method==='PUT'){
  $id=$_GET['id']??$_POST['id']??$jsonInput['id']??null;
  if(!$id) respond(false,"ID wajib",null,400);
  $isJson=isJsonReq();
  if($isJson){
    $nama=trim($jsonInput['nama']??''); $kategori=trim($jsonInput['kategori']??'lainnya'); $harga=$jsonInput['harga']??0; $stok=$jsonInput['stok']??0; $deskripsi=trim($jsonInput['deskripsi']??''); $status=$jsonInput['status']??'tersedia'; $foto=$jsonInput['foto']??null; $fotoHapus=$jsonInput['foto_hapus']??null;
    if($nama==='') respond(false,"Nama wajib",null,422);
    if(!is_numeric($harga)||((float)$harga)<0) respond(false,"Harga tidak boleh negatif",null,422);
    if(!is_numeric($stok)||((int)$stok)<0) respond(false,"Stok tidak boleh negatif",null,422);
    if(!in_array($status,['tersedia','habis','arsip'])) $status='tersedia';
    $iid=(int)$id;
    $old=fetchProdukById($conn,$iid); if(!$old) respond(false,"Produk tidak ditemukan",null,404);
    $fotoName=$old['foto']; if($fotoHapus) $fotoName=null; if($foto!==null) $fotoName=$foto;
    $stmt=$conn->prepare("UPDATE produk SET nama=?,kategori=?,harga=?,stok=?,deskripsi=?,foto=?,status=? WHERE id=?");
    $stmt->bind_param("ssdssssi",$nama,$kategori,$harga,$stok,$deskripsi,$fotoName,$status,$id);
    if($stmt->execute()){ $row=fetchProdukById($conn,$iid); $row['foto_url']=foto_url($row['foto'],$baseUrl); respond(true,"Produk diperbarui",$row); }
    respond(false,"Gagal memperbarui produk",null,500);
  } else {
    $nama=trim($_POST['nama']??''); $kategori=trim($_POST['kategori']??'lainnya'); $harga=$_POST['harga']??0; $stok=$_POST['stok']??0; $deskripsi=trim($_POST['deskripsi']??''); $status=$_POST['status']??'tersedia';
    if($nama==='') respond(false,"Nama wajib",null,422);
    if(!is_numeric($harga)||((float)$harga)<0) respond(false,"Harga tidak boleh negatif",null,422);
    if(!is_numeric($stok)||((int)$stok)<0) respond(false,"Stok tidak boleh negatif",null,422);
    if(!in_array($status,['tersedia','habis','arsip'])) $status='tersedia';
    $iid=(int)$id;
    $old=fetchProdukById($conn,$iid);
    if(!$old) respond(false,"Produk tidak ditemukan",null,404);
    $fotoName=$old['foto'];
    if(isset($_FILES['foto']) && $_FILES['foto']['error']!==4){
      [$ok,$res]=saveFoto($_FILES['foto']);
      if(!$ok) respond(false,$res,null,400);
      if($fotoName && file_exists("$uploadDir/$fotoName")) @unlink("$uploadDir/$fotoName");
      $fotoName=$res;
    } else if(isset($_POST['foto_hapus']) && $_POST['foto_hapus']=='1'){
      if($fotoName && file_exists("$uploadDir/$fotoName")) @unlink("$uploadDir/$fotoName");
      $fotoName=null;
    }
    $stmt=$conn->prepare("UPDATE produk SET nama=?,kategori=?,harga=?,stok=?,deskripsi=?,foto=?,status=? WHERE id=?");
    $stmt->bind_param("ssdssssi",$nama,$kategori,$harga,$stok,$deskripsi,$fotoName,$status,$id);
    if($stmt->execute()){ $row=fetchProdukById($conn,$iid); $row['foto_url']=foto_url($row['foto'],$baseUrl); respond(true,"Produk diperbarui",$row); }
    respond(false,"Gagal memperbarui produk",null,500);
  }
}

if($method==='POST'){
  $isJson=isJsonReq();
  if($isJson){
    $nama=trim($jsonInput['nama']??''); $kategori=trim($jsonInput['kategori']??'lainnya'); $harga=$jsonInput['harga']??0; $stok=$jsonInput['stok']??0; $deskripsi=trim($jsonInput['deskripsi']??''); $status=$jsonInput['status']??'tersedia'; $foto=$jsonInput['foto']??null;
    if($nama===''||$harga==='') respond(false,"Nama & harga wajib",null,422);
    if(!is_numeric($harga)||((float)$harga)<0) respond(false,"Harga tidak boleh negatif",null,422);
    if(!is_numeric($stok)||((int)$stok)<0) respond(false,"Stok tidak boleh negatif",null,422);
    if(!in_array($status,['tersedia','habis','arsip'])) $status='tersedia';
    $stmt=$conn->prepare("INSERT INTO produk (nama,kategori,harga,stok,deskripsi,foto,status) VALUES (?,?,?,?,?,?,?)");
    $stmt->bind_param("ssdssss",$nama,$kategori,$harga,$stok,$deskripsi,$foto,$status);
    if($stmt->execute()){ $nid=$conn->insert_id; $row=fetchProdukById($conn,(int)$nid); $row['foto_url']=foto_url($row['foto'],$baseUrl); respond(true,"Produk ditambahkan",$row,201); }
    respond(false,"Gagal menambah produk",null,500);
  } else {
    $nama=trim($_POST['nama']??''); $kategori=trim($_POST['kategori']??'lainnya'); $harga=$_POST['harga']??0; $stok=$_POST['stok']??0; $deskripsi=trim($_POST['deskripsi']??''); $status=$_POST['status']??'tersedia';
    if($nama===''||$harga==='') respond(false,"Nama & harga wajib",null,422);
    if(!is_numeric($harga)||((float)$harga)<0) respond(false,"Harga tidak boleh negatif",null,422);
    if(!is_numeric($stok)||((int)$stok)<0) respond(false,"Stok tidak boleh negatif",null,422);
    if(!in_array($status,['tersedia','habis','arsip'])) $status='tersedia';
    $fotoName=null;
    if(isset($_FILES['foto']) && $_FILES['foto']['error']!==4){
      [$ok,$res]=saveFoto($_FILES['foto']);
      if(!$ok) respond(false,$res,null,400);
      $fotoName=$res;
    }
    $stmt=$conn->prepare("INSERT INTO produk (nama,kategori,harga,stok,deskripsi,foto,status) VALUES (?,?,?,?,?,?,?)");
    $stmt->bind_param("ssdssss",$nama,$kategori,$harga,$stok,$deskripsi,$fotoName,$status);
    if($stmt->execute()){ $nid=$conn->insert_id; $row=fetchProdukById($conn,(int)$nid); $row['foto_url']=foto_url($row['foto'],$baseUrl); respond(true,"Produk ditambahkan",$row,201); }
    respond(false,"Gagal menambah produk",null,500);
  }
}

respond(false,"Method tidak didukung",null,405);
