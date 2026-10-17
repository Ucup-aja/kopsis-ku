<?php
require_once __DIR__."/../config/cors.php";
cors();
require_once __DIR__."/../config/db.php";
$uploadDir = realpath(__DIR__."/../storage/uploads/profil") ?: (__DIR__."/../storage/uploads/profil");
if(!is_dir($uploadDir)) mkdir($uploadDir,0777,true);
require_once __DIR__."/../src/Support/url.php";
$base = upload_base('profil');
function respond($ok,$msg,$data=null,$code=200){http_response_code($code);echo json_encode(["success"=>$ok,"message"=>$msg,"data"=>$data]);exit;}
$method=$_SERVER['REQUEST_METHOD'];
if(isset($_GET['_method'])) $method=strtoupper($_GET['_method']);
if($method==='GET'){
  $id=$_GET['id']??null;
  $username=$_GET['username']??null;
  if(!$id && !$username) respond(false,"id atau username wajib",null,400);
  if($id){
    $stmt=$conn->prepare("SELECT id,name,username,email,foto FROM pengguna WHERE id=?");
    $stmt->bind_param("i",$id);
  } else {
    $stmt=$conn->prepare("SELECT id,name,username,email,foto FROM pengguna WHERE username=?");
    $stmt->bind_param("s",$username);
  }
  $stmt->execute(); $r=$stmt->get_result();
  if($row=$r->fetch_assoc()){
    $row['foto_url']=$row['foto']?"$base/".$row['foto']:null;
    respond(true,"OK",$row);
  } else respond(false,"User tidak ditemukan",null,404);
}
if($method==='POST'){
  $id=$_POST['id']??$_GET['id']??null;
  $isJson = strpos($_SERVER['CONTENT_TYPE']??'','application/json')!==false;
  if($isJson){
    $in=json_decode(file_get_contents("php://input"),true)??[];
    $id=$in['id']??$id;
    $hapus=$in['foto_hapus']??false;
    if(!$id) respond(false,"id wajib",null,400);
    if($hapus){
      $old=$conn->query("SELECT foto FROM pengguna WHERE id=".(int)$id)->fetch_assoc();
      $conn->query("UPDATE pengguna SET foto=NULL WHERE id=".(int)$id);
      if($old&&$old['foto']&&file_exists("$uploadDir/".$old['foto'])) @unlink("$uploadDir/".$old['foto']);
      respond(true,"Foto profil dihapus");
    }
    respond(false,"Gunakan multipart untuk upload",null,400);
  }
  if(!$id) respond(false,"id wajib",null,400);
  $old=$conn->query("SELECT foto FROM pengguna WHERE id=".(int)$id)->fetch_assoc();
  if(!$old) respond(false,"User tidak ditemukan",null,404);
  if(isset($_POST['foto_hapus']) && $_POST['foto_hapus']=='1'){
    $conn->query("UPDATE pengguna SET foto=NULL WHERE id=".(int)$id);
    if($old['foto']&&file_exists("$uploadDir/".$old['foto'])) @unlink("$uploadDir/".$old['foto']);
    $row=$conn->query("SELECT id,name,username,email,foto FROM pengguna WHERE id=".(int)$id)->fetch_assoc();
    $row['foto_url']=$row['foto']?"$base/".$row['foto']:null;
    respond(true,"Foto dihapus",$row);
  }
  if(!isset($_FILES['foto']) || $_FILES['foto']['error']==4) respond(false,"Pilih foto terlebih dahulu",null,400);
  $f=$_FILES['foto'];
  if($f['error']!==0) respond(false,"Upload error ".$f['error'],null,400);
  if($f['size']>5*1024*1024) respond(false,"Foto maksimal 5MB",null,400);
  $ext=strtolower(pathinfo($f['name'],PATHINFO_EXTENSION));
  if(!in_array($ext,['jpg','jpeg','png','webp'])) $ext='jpg';
  $name="profil_".(int)$id."_".time()."_".bin2hex(random_bytes(3)).".$ext";
  $dest="$uploadDir/$name";
  if(!move_uploaded_file($f['tmp_name'],$dest)) respond(false,"Gagal simpan foto",null,500);
  if($old['foto']&&file_exists("$uploadDir/".$old['foto'])) @unlink("$uploadDir/".$old['foto']);
  $stmt=$conn->prepare("UPDATE pengguna SET foto=? WHERE id=?");
  $stmt->bind_param("si",$name,$id);
  $stmt->execute();
  $row=$conn->query("SELECT id,name,username,email,foto FROM pengguna WHERE id=".(int)$id)->fetch_assoc();
  $row['foto_url']=$row['foto']?"$base/".$row['foto']:null;
  respond(true,"Foto profil diperbarui",$row);
}
respond(false,"Method tidak didukung",null,405);
