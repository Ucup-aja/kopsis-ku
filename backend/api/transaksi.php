<?php
// Transaksi Koperasi Konsumen: penjualan (stok-) dan restok (stok+).
require_once __DIR__."/../config/cors.php";
cors(["GET","POST","PUT","DELETE","OPTIONS"]);
require_once __DIR__."/../config/db.php";
require_once __DIR__."/../config/auth.php";
require_auth($conn, $authUserId);
$conn->set_charset("utf8mb4");
mysqli_report(MYSQLI_REPORT_OFF);
function respond($ok,$msg,$data=null,$code=200){http_response_code($code);echo json_encode(["success"=>$ok,"message"=>$msg,"data"=>$data], JSON_UNESCAPED_UNICODE);exit;}
function ensureTransaksiTable($conn){
  $conn->query("CREATE TABLE IF NOT EXISTS transaksi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode VARCHAR(20) NOT NULL UNIQUE,
    produk_id INT NULL,
    nama_produk VARCHAR(150) NOT NULL,
    tipe ENUM('penjualan','restok') NOT NULL DEFAULT 'penjualan',
    jumlah INT NOT NULL,
    harga_satuan DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    stok_sebelum INT NOT NULL,
    stok_sesudah INT NOT NULL,
    keterangan VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE SET NULL
  )");
}
ensureTransaksiTable($conn);
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
$raw=file_get_contents("php://input");
$json=json_decode($raw,true) ?? [];
$method=$_SERVER['REQUEST_METHOD'];
if(isset($_GET['_method'])) $method=strtoupper($_GET['_method']);
else if(isset($_POST['_method'])) $method=strtoupper($_POST['_method']);
else if(isset($json['_method'])) $method=strtoupper($json['_method']);

if($method==='GET'){
  if(isset($_GET['summary']) && $_GET['summary']=='1'){
    $today=date('Y-m-d');
    $month=date('Y-m');
    $s=[];
    $r=$conn->query("SELECT COUNT(*) c FROM transaksi");
    $s['total_transaksi']=(int)($r?$r->fetch_assoc()['c']:0);
    $r=$conn->query("SELECT COUNT(*) c, COALESCE(SUM(total),0) s FROM transaksi WHERE tipe='penjualan' AND DATE(created_at)='$today'");
    $row=$r?$r->fetch_assoc():['c'=>0,'s'=>0];
    $s['penjualan_hari_ini']=(int)$row['c']; $s['omset_hari_ini']=(float)$row['s'];
    $r=$conn->query("SELECT COUNT(*) c, COALESCE(SUM(total),0) s FROM transaksi WHERE tipe='penjualan' AND DATE_FORMAT(created_at,'%Y-%m')='$month'");
    $row=$r?$r->fetch_assoc():['c'=>0,'s'=>0];
    $s['penjualan_bulan']=(int)$row['c']; $s['omset_bulan']=(float)$row['s'];
    $r=$conn->query("SELECT COUNT(*) c, COALESCE(SUM(total),0) s FROM transaksi WHERE tipe='restok' AND DATE_FORMAT(created_at,'%Y-%m')='$month'");
    $row=$r?$r->fetch_assoc():['c'=>0,'s'=>0];
    $s['restok_bulan']=(int)$row['c']; $s['nilai_restok_bulan']=(float)$row['s'];
    $r=$conn->query("SELECT COALESCE(SUM(jumlah),0) s FROM transaksi WHERE tipe='penjualan'");
    $row=$r?$r->fetch_assoc():['s'=>0];
    $s['total_item_keluar']=(int)$row['s'];
    $s['top_produk']=[];
    $q=$conn->query("SELECT produk_id, nama_produk, SUM(jumlah) total_qty, SUM(total) total_nilai FROM transaksi WHERE tipe='penjualan' GROUP BY produk_id, nama_produk ORDER BY total_qty DESC LIMIT 5");
    if($q) while($x=$q->fetch_assoc()){ $x['total_qty']=(int)$x['total_qty']; $x['total_nilai']=(float)$x['total_nilai']; $s['top_produk'][]=$x; }
    respond(true,"OK",$s);
  }
  $id=$_GET['id']??null;
  if($id){
    $stmt=$conn->prepare("SELECT t.*, p.foto, p.kategori FROM transaksi t LEFT JOIN produk p ON p.id=t.produk_id WHERE t.id=?");
    $stmt->bind_param("i",$id); $stmt->execute(); $r=$stmt->get_result();
    if($row=$r->fetch_assoc()) respond(true,"OK",$row); else respond(false,"Transaksi tidak ditemukan",null,404);
  }
  $search=trim($_GET['search']??'');
  $tipe=trim($_GET['tipe']??'');
  if($tipe!=='' && $tipe!=='penjualan' && $tipe!=='restok') $tipe='';
  $dari=trim($_GET['dari']??'');
  $sampai=trim($_GET['sampai']??'');
  $limit=min(max((int)($_GET['limit']??50),1),200);
  $sql="SELECT t.*, p.foto, p.kategori FROM transaksi t LEFT JOIN produk p ON p.id=t.produk_id WHERE 1=1";
  $params=[]; $types="";
  if($tipe!==''){ $sql.=" AND t.tipe=?"; $params[]=$tipe; $types.="s"; }
  if($search!==''){ $sql.=" AND (t.nama_produk LIKE ? OR t.kode LIKE ? OR t.keterangan LIKE ?)"; $like="%$search%"; $params=array_merge($params,[$like,$like,$like]); $types.="sss"; }
  if($dari!==''){ $sql.=" AND DATE(t.created_at) >= ?"; $params[]=$dari; $types.="s"; }
  if($sampai!==''){ $sql.=" AND DATE(t.created_at) <= ?"; $params[]=$sampai; $types.="s"; }
  $sql.=" ORDER BY t.created_at DESC, t.id DESC LIMIT $limit";
  if($types!==""){ $stmt=$conn->prepare($sql); $stmt->bind_param($types,...$params); $stmt->execute(); $q=$stmt->get_result(); } else $q=$conn->query($sql);
  if(!$q) respond(false,$conn->error,[],500);
  $rows=[]; while($r=$q->fetch_assoc()){ $r['jumlah']=(int)$r['jumlah']; $r['harga_satuan']=(float)$r['harga_satuan']; $r['total']=(float)$r['total']; $r['stok_sebelum']=(int)$r['stok_sebelum']; $r['stok_sesudah']=(int)$r['stok_sesudah']; $rows[]=$r; }
  respond(true,"OK",$rows);
}

if($method==='POST'){
  $raw_produk=$json['produk_id']??$_POST['produk_id']??0;
  $raw_jumlah=$json['jumlah']??$_POST['jumlah']??null;
  $raw_harga=$json['harga_satuan']??$_POST['harga_satuan']??null;
  $tipe=trim($json['tipe']??$_POST['tipe']??'penjualan');
  if($tipe!=='penjualan' && $tipe!=='restok') $tipe='penjualan';
  $produk_id=(int)$raw_produk;
  $keterangan=trim($json['keterangan']??$_POST['keterangan']??'');
  if(!$produk_id) respond(false,"produk_id wajib",null,400);
  if($raw_jumlah===null || $raw_jumlah==='') respond(false,"jumlah wajib diisi",null,400);
  if(!is_numeric($raw_jumlah)) respond(false,"jumlah harus angka",null,400);
  $jumlah=(int)$raw_jumlah;
  if($jumlah<=0) respond(false,"jumlah harus >0",null,400);
  $prod=$conn->query("SELECT * FROM produk WHERE id=".(int)$produk_id)->fetch_assoc();
  if(!$prod) respond(false,"Produk tidak ditemukan",null,404);
  $harga=(float)$prod['harga'];
  if($raw_harga!==null && $raw_harga!=='' && is_numeric($raw_harga)) $harga=(float)$raw_harga;
  else if($raw_harga!==null && $raw_harga!=='' && !is_numeric($raw_harga)) respond(false,"harga_satuan harus angka",null,400);
  $stokSebelum=(int)$prod['stok'];
  if($tipe==='penjualan'){
    if($stokSebelum < $jumlah) respond(false,"Stok tidak cukup (sisa $stokSebelum)",null,400);
    $stokSesudah=$stokSebelum - $jumlah;
  } else {
    $stokSesudah=$stokSebelum + $jumlah;
  }
  $total=round($harga * $jumlah,2);
  $kode="TRX-".date('Ymd')."-".strtoupper(bin2hex(random_bytes(2)));
  $conn->begin_transaction();
  try{
    $stmt=$conn->prepare("UPDATE produk SET stok=?, status=CASE WHEN ?<=0 THEN 'habis' WHEN status='habis' AND ? >0 THEN 'tersedia' ELSE status END WHERE id=?");
    $stmt->bind_param("iiii",$stokSesudah,$stokSesudah,$stokSesudah,$produk_id);
    $stmt->execute();
    $stmt2=$conn->prepare("INSERT INTO transaksi (kode, produk_id, nama_produk, tipe, jumlah, harga_satuan, total, stok_sebelum, stok_sesudah, keterangan) VALUES (?,?,?,?,?,?,?,?,?,?)");
    $namaProd=$prod['nama'];
    $stmt2->bind_param("sissiddiis",$kode,$produk_id,$namaProd,$tipe,$jumlah,$harga,$total,$stokSebelum,$stokSesudah,$keterangan);
    $stmt2->execute();
    $nid=$conn->insert_id;
    $conn->commit();
    $row=$conn->query("SELECT t.*, p.foto, p.kategori FROM transaksi t LEFT JOIN produk p ON p.id=t.produk_id WHERE t.id=$nid")->fetch_assoc();
    $row['jumlah']=(int)$row['jumlah']; $row['harga_satuan']=(float)$row['harga_satuan']; $row['total']=(float)$row['total'];
    respond(true,$tipe==='penjualan'?"Penjualan dicatat":"Restok dicatat",$row,201);
  } catch(Throwable $e){
    $conn->rollback();
    respond(false,"Gagal: ".$e->getMessage(),null,500);
  }
}

if($method==='DELETE'){
  $id=$_GET['id']??$json['id']??$_POST['id']??null;
  if(!$id) respond(false,"ID wajib",null,400);
  $trx=$conn->query("SELECT * FROM transaksi WHERE id=".(int)$id)->fetch_assoc();
  if(!$trx) respond(false,"Transaksi tidak ditemukan",null,404);
  $conn->begin_transaction();
  try{
    if($trx['produk_id']){
      $prod=$conn->query("SELECT stok FROM produk WHERE id=".(int)$trx['produk_id'])->fetch_assoc();
      if($prod){
        // Kembalikan stok ke kondisi sebelum transaksi.
        $newStock=(int)$trx['stok_sebelum'];
        if($newStock<0) $newStock=0;
        $conn->query("UPDATE produk SET stok=$newStock, status=CASE WHEN $newStock<=0 THEN 'habis' ELSE 'tersedia' END WHERE id=".(int)$trx['produk_id']);
      }
    }
    $conn->query("DELETE FROM transaksi WHERE id=".(int)$id);
    $conn->commit();
    respond(true,"Transaksi dibatalkan & stok dipulihkan");
  } catch(Throwable $e){ $conn->rollback(); respond(false,$e->getMessage(),null,500); }
}

respond(false,"Method tidak didukung",null,405);
