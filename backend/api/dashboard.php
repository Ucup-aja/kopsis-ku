<?php
// Dashboard Koperasi Konsumen: produk + penjualan/restok.
require_once __DIR__."/../config/cors.php";
cors();
require_once __DIR__ . "/../config/db.php";
require_once __DIR__."/../config/auth.php";
require_auth($conn, $authUserId);
mysqli_report(MYSQLI_REPORT_OFF);
function tryQuery($conn, $sql) {
  try {
    $res = $conn->query($sql);
    if (!$res) return ['c' => 0, 's' => 0];
    return $res->fetch_assoc() ?: ['c' => 0, 's' => 0];
  } catch (Throwable $e) { return ['c' => 0, 's' => 0]; }
}
function safeQuery($conn, $sql) {
  try { return $conn->query($sql); } catch (Throwable $e) { return null; }
}
try {
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
require_once __DIR__ . "/../src/Support/url.php";
$baseUrl = upload_base('produk');
$data = [];
$data['total_produk'] = (int)(tryQuery($conn, "SELECT COUNT(*) as c FROM produk")['c'] ?? 0);
$data['produk_tersedia'] = (int)(tryQuery($conn, "SELECT COUNT(*) as c FROM produk WHERE status='tersedia'")['c'] ?? 0);
$data['produk_habis'] = (int)(tryQuery($conn, "SELECT COUNT(*) as c FROM produk WHERE stok<=0 OR status='habis'")['c'] ?? 0);
$data['total_stok'] = (int)(tryQuery($conn, "SELECT COALESCE(SUM(stok),0) as s FROM produk")['s'] ?? 0);
$data['nilai_stok'] = (float)(tryQuery($conn, "SELECT COALESCE(SUM(harga*stok),0) as s FROM produk")['s'] ?? 0);
$data['by_kategori'] = [];
$q = safeQuery($conn, "SELECT kategori, COUNT(*) as c, COALESCE(SUM(stok),0) as stok FROM produk GROUP BY kategori");
if($q) while($r=$q->fetch_assoc()){ $r['c']=(int)$r['c']; $r['stok']=(int)$r['stok']; $data['by_kategori'][]=$r; }
$data['stok_menipis']=[];
$q2=safeQuery($conn, "SELECT * FROM produk WHERE stok>0 AND stok<=5 AND status!='arsip' ORDER BY stok ASC LIMIT 5");
if($q2) while($r=$q2->fetch_assoc()){ $r['harga']=(float)$r['harga']; $r['stok']=(int)$r['stok']; $r['foto_url']=foto_url($r['foto'],$baseUrl); $data['stok_menipis'][]=$r; }
$data['recent_produk']=[];
$q3=safeQuery($conn, "SELECT * FROM produk ORDER BY updated_at DESC, id DESC LIMIT 6");
if($q3) while($r=$q3->fetch_assoc()){ $r['harga']=(float)$r['harga']; $r['stok']=(int)$r['stok']; $r['foto_url']=foto_url($r['foto'],$baseUrl); $data['recent_produk'][]=$r; }
try{ $conn->query("CREATE TABLE IF NOT EXISTS transaksi (id INT AUTO_INCREMENT PRIMARY KEY, kode VARCHAR(20) NOT NULL UNIQUE, produk_id INT NULL, nama_produk VARCHAR(150) NOT NULL, tipe ENUM('penjualan','restok') NOT NULL DEFAULT 'penjualan', jumlah INT NOT NULL, harga_satuan DECIMAL(12,2) NOT NULL DEFAULT 0, total DECIMAL(12,2) NOT NULL DEFAULT 0, stok_sebelum INT NOT NULL, stok_sesudah INT NOT NULL, keterangan VARCHAR(255) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE SET NULL)"); } catch(Throwable $e){}
$data['transaksi_hari'] = (int)(tryQuery($conn, "SELECT COUNT(*) c FROM transaksi WHERE tipe='penjualan' AND DATE(created_at)=CURDATE()")['c'] ?? 0);
$data['omset_hari'] = (float)(tryQuery($conn, "SELECT COALESCE(SUM(total),0) s FROM transaksi WHERE tipe='penjualan' AND DATE(created_at)=CURDATE()")['s'] ?? 0);
$data['transaksi_bulan'] = (int)(tryQuery($conn, "SELECT COUNT(*) c FROM transaksi WHERE tipe='penjualan' AND DATE_FORMAT(created_at,'%Y-%m')=DATE_FORMAT(CURDATE(),'%Y-%m')")['c'] ?? 0);
$data['omset_bulan'] = (float)(tryQuery($conn, "SELECT COALESCE(SUM(total),0) s FROM transaksi WHERE tipe='penjualan' AND DATE_FORMAT(created_at,'%Y-%m')=DATE_FORMAT(CURDATE(),'%Y-%m')")['s'] ?? 0);
$data['restok_bulan'] = (int)(tryQuery($conn, "SELECT COUNT(*) c FROM transaksi WHERE tipe='restok' AND DATE_FORMAT(created_at,'%Y-%m')=DATE_FORMAT(CURDATE(),'%Y-%m')")['c'] ?? 0);
$data['recent_transaksi'] = [];
$q4=safeQuery($conn, "SELECT * FROM transaksi ORDER BY created_at DESC, id DESC LIMIT 5");
if($q4) while($r=$q4->fetch_assoc()){ $r['jumlah']=(int)$r['jumlah']; $r['total']=(float)$r['total']; $data['recent_transaksi'][]=$r; }
echo json_encode(["success"=>true,"data"=>$data]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["success"=>false,"message"=>$e->getMessage(),"data"=>null]);
}
$conn->close();
