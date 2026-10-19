import 'dart:io';
import 'dart:math';

import '../../core/error/app_exception.dart';
import '../../core/error/result.dart';
import '../local/app_database.dart';
import '../models/models.dart';

/// Dashboard lokal — agregasi dihitung dari SQLite, pengganti `/backend/api/dashboard.php`.
class DashboardRepository {
  final AppDatabase db;
  DashboardRepository(this.db);

  Future<Result<DashboardData>> fetch() async {
    try {
      final d = await db.database;
      Future<Map<String, Object?>> satu(String sql) async =>
          (await d.rawQuery(sql)).first;
      int i(Object? v) => (v is num) ? v.toInt() : 0;
      double r(Object? v) => (v is num) ? v.toDouble() : 0;

      final total = await satu('SELECT COUNT(*) c, '
          "SUM(CASE WHEN status='tersedia' THEN 1 ELSE 0 END) tersedia, "
          "SUM(CASE WHEN stok<=0 OR status='habis' THEN 1 ELSE 0 END) habis, "
          'COALESCE(SUM(stok),0) stok, COALESCE(SUM(harga*stok),0) nilai FROM produk');

      final byKategori = (await d.rawQuery(
              'SELECT kategori, COUNT(*) c, COALESCE(SUM(stok),0) stok '
              'FROM produk GROUP BY kategori'))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final menipis = (await d.query('produk',
              where: "stok>0 AND stok<=5 AND status!='arsip'",
              orderBy: 'stok ASC',
              limit: 5))
          .map(_produk)
          .toList();

      final recentProduk = (await d.query('produk',
              orderBy: 'updated_at DESC, id DESC', limit: 6))
          .map(_produk)
          .toList();

      final hari = "date('now','localtime')";
      final bulan = "strftime('%Y-%m',datetime('now','localtime'))";
      Future<Map<String, Object?>> trx(String where) => satu(
          'SELECT COUNT(*) c, COALESCE(SUM(total),0) s FROM transaksi '
          "WHERE tipe='penjualan' AND $where");
      final th = await trx('date(created_at) = $hari');
      final tb = await trx("substr(created_at,1,7) = $bulan");
      final rb = await satu(
          "SELECT COUNT(*) c FROM transaksi WHERE tipe='restok' AND substr(created_at,1,7) = $bulan");

      final recentTransaksi = (await d.query('transaksi',
              orderBy: 'created_at DESC, id DESC', limit: 5))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return Ok(DashboardData(
        totalProduk: i(total['c']),
        produkTersedia: i(total['tersedia']),
        produkHabis: i(total['habis']),
        totalStok: i(total['stok']),
        nilaiStok: r(total['nilai']),
        byKategori: byKategori,
        stokMenipis: menipis,
        recentProduk: recentProduk,
        transaksiHari: i(th['c']),
        omsetHari: r(th['s']),
        transaksiBulan: i(tb['c']),
        omsetBulan: r(tb['s']),
        restokBulan: i(rb['c']),
        recentTransaksi: recentTransaksi,
      ));
    } catch (e) {
      return Err(AppException('Gagal memuat dashboard.', code: 'DB_ERROR'));
    }
  }

  static Produk _produk(Map<String, Object?> r) =>
      Produk.fromJson(Map<String, dynamic>.from(r));
}

/// Transaksi lokal — aturan stok identik dengan `/backend/api/transaksi.php`.
class TransaksiRepository {
  final AppDatabase db;
  TransaksiRepository(this.db);

  static final Random _rng = Random.secure();

  Future<Result<List<Transaksi>>> list({
    String search = '',
    String tipe = '',
    String dari = '',
    String sampai = '',
    int limit = 50,
  }) async {
    try {
      final where = <String>[];
      final args = <Object?>[];
      if (tipe == 'penjualan' || tipe == 'restok') {
        where.add('t.tipe = ?');
        args.add(tipe);
      }
      if (search.isNotEmpty) {
        where.add('(t.nama_produk LIKE ? OR t.kode LIKE ? OR t.keterangan LIKE ?)');
        final like = '%$search%';
        args..add(like)..add(like)..add(like);
      }
      if (dari.isNotEmpty) {
        where.add('date(t.created_at) >= ?');
        args.add(dari);
      }
      if (sampai.isNotEmpty) {
        where.add('date(t.created_at) <= ?');
        args.add(sampai);
      }
      final batas = limit.clamp(1, 200);
      final d = await db.database;
      final rows = await d.rawQuery(
          'SELECT t.*, p.foto, p.kategori FROM transaksi t '
          'LEFT JOIN produk p ON p.id = t.produk_id '
          '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
          'ORDER BY t.created_at DESC, t.id DESC LIMIT $batas',
          args);
      return Ok(rows
          .map((e) => Transaksi.fromJson(Map<String, dynamic>.from(e)))
          .toList());
    } catch (e) {
      return Err(AppException('Gagal memuat transaksi.', code: 'DB_ERROR'));
    }
  }

  Future<Result<TransaksiSummary>> summary() async {
    try {
      final d = await db.database;
      Future<Map<String, Object?>> satu(String sql) async =>
          (await d.rawQuery(sql)).first;
      int i(Object? v) => (v is num) ? v.toInt() : 0;
      double r(Object? v) => (v is num) ? v.toDouble() : 0;

      final total = await satu('SELECT COUNT(*) c FROM transaksi');
      final hari = await satu("SELECT COUNT(*) c, COALESCE(SUM(total),0) s "
          "FROM transaksi WHERE tipe='penjualan' AND date(created_at)=date('now','localtime')");
      final bulan = await satu("SELECT COUNT(*) c, COALESCE(SUM(total),0) s "
          "FROM transaksi WHERE tipe='penjualan' AND substr(created_at,1,7)=strftime('%Y-%m',datetime('now','localtime'))");
      final restok = await satu("SELECT COUNT(*) c, COALESCE(SUM(total),0) s "
          "FROM transaksi WHERE tipe='restok' AND substr(created_at,1,7)=strftime('%Y-%m',datetime('now','localtime'))");
      final top = (await d.rawQuery(
              'SELECT produk_id, nama_produk, SUM(jumlah) total_qty, SUM(total) total_nilai '
              "FROM transaksi WHERE tipe='penjualan' GROUP BY produk_id, nama_produk "
              'ORDER BY total_qty DESC LIMIT 5'))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return Ok(TransaksiSummary(
        totalTransaksi: i(total['c']),
        penjualanHariIni: i(hari['c']),
        omsetHariIni: r(hari['s']),
        penjualanBulan: i(bulan['c']),
        omsetBulan: r(bulan['s']),
        restokBulan: i(restok['c']),
        nilaiRestokBulan: r(restok['s']),
        topProduk: top,
      ));
    } catch (e) {
      return Err(AppException('Gagal memuat ringkasan.', code: 'DB_ERROR'));
    }
  }

  Future<Result<Transaksi>> create({
    required int produkId,
    required String tipe, // penjualan | restok
    required int jumlah,
    double? hargaSatuan,
    String keterangan = '',
  }) async {
    if (jumlah <= 0) {
      return const Err(AppException('Jumlah harus lebih dari 0.',
          code: 'VALIDATION_ERROR'));
    }
    if (tipe != 'penjualan' && tipe != 'restok') {
      return const Err(AppException('Tipe tidak valid.',
          code: 'VALIDATION_ERROR'));
    }
    try {
      final d = await db.database;
      final prod = await d.query('produk', where: 'id = ?', whereArgs: [produkId], limit: 1);
      if (prod.isEmpty) {
        return const Err(
            AppException('Produk tidak ditemukan', code: 'NOT_FOUND'));
      }
      final stokSebelum = (prod.first['stok'] as num).toInt();
      final stokSesudah = tipe == 'penjualan'
          ? stokSebelum - jumlah
          : stokSebelum + jumlah;
      if (tipe == 'penjualan' && stokSebelum < jumlah) {
        return Err(AppException('Stok tidak cukup (sisa $stokSebelum)',
            code: 'VALIDATION_ERROR'));
      }
      final harga = hargaSatuan ?? (prod.first['harga'] as num).toDouble();
      final total = double.parse((harga * jumlah).toStringAsFixed(2));
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final kode = 'TRX-${now.year}${two(now.month)}${two(now.day)}-'
          '${List.generate(4, (_) => _rng.nextInt(16).toRadixString(16)).join().toUpperCase()}';

      int id = 0;
      await d.transaction((txn) async {
        // Samakan perilaku MySQL: stok berubah → updated_at ikut terbarui.
        await txn.rawUpdate(
            "UPDATE produk SET stok=?, status=CASE WHEN ?<=0 THEN 'habis' "
            "WHEN status='habis' AND ?>0 THEN 'tersedia' ELSE status END, "
            "updated_at=datetime('now','localtime') WHERE id=?",
            [stokSesudah, stokSesudah, stokSesudah, produkId]);
        id = await txn.insert('transaksi', {
          'kode': kode,
          'produk_id': produkId,
          'nama_produk': prod.first['nama'],
          'tipe': tipe,
          'jumlah': jumlah,
          'harga_satuan': harga,
          'total': total,
          'stok_sebelum': stokSebelum,
          'stok_sesudah': stokSesudah,
          'keterangan': keterangan,
        });
      });
      final row = await d.rawQuery(
          'SELECT t.*, p.foto, p.kategori FROM transaksi t '
          'LEFT JOIN produk p ON p.id = t.produk_id WHERE t.id = ?',
          [id]);
      return Ok(Transaksi.fromJson(Map<String, dynamic>.from(row.first)));
    } catch (e) {
      return Err(AppException('Gagal mencatat transaksi.', code: 'DB_ERROR'));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      final d = await db.database;
      final trx = await d.query('transaksi', where: 'id = ?', whereArgs: [id], limit: 1);
      if (trx.isEmpty) {
        return const Err(
            AppException('Transaksi tidak ditemukan', code: 'NOT_FOUND'));
      }
      await d.transaction((txn) async {
        final produkId = trx.first['produk_id'];
        if (produkId != null) {
          // Kembalikan stok ke kondisi sebelum transaksi (sama seperti backend).
          final sebelum = ((trx.first['stok_sebelum'] as num).toInt()).clamp(0, 1 << 30);
          await txn.rawUpdate(
              "UPDATE produk SET stok=?, status=CASE WHEN ?<=0 THEN 'habis' ELSE 'tersedia' END, "
              "updated_at=datetime('now','localtime') WHERE id=?",
              [sebelum, sebelum, produkId]);
        }
        await txn.delete('transaksi', where: 'id = ?', whereArgs: [id]);
      });
      return const Ok(null);
    } catch (e) {
      return Err(AppException('Gagal menghapus transaksi.', code: 'DB_ERROR'));
    }
  }
}

/// Profil lokal — pengganti `/backend/api/profil.php` (foto disimpan di penyimpanan app).
class ProfilRepository {
  final AppDatabase db;
  ProfilRepository(this.db);

  Future<Result<Map<String, dynamic>>> get({int? id, String? username}) async {
    try {
      final d = await db.database;
      final rows = await d.query('pengguna',
          where: id != null ? 'id = ?' : 'username = ?',
          whereArgs: [id ?? username],
          limit: 1);
      if (rows.isEmpty) {
        return const Err(
            AppException('Pengguna tidak ditemukan', code: 'NOT_FOUND'));
      }
      final r = rows.first;
      return Ok({
        'id': r['id'],
        'name': r['name'],
        'username': r['username'],
        'email': r['email'],
        'foto_url': r['foto'],
      });
    } catch (e) {
      return Err(AppException('Gagal memuat profil.', code: 'DB_ERROR'));
    }
  }

  Future<Result<Map<String, dynamic>>> uploadFoto(int id, File foto) async {
    try {
      final d = await db.database;
      final lama = await d.query('pengguna', where: 'id = ?', whereArgs: [id], limit: 1);
      if (lama.isEmpty) {
        return const Err(
            AppException('Pengguna tidak ditemukan', code: 'NOT_FOUND'));
      }
      await db.hapusFotoFile(lama.first['foto'] as String?);
      final path = await db.simpanFoto(foto, 'user');
      await d.update('pengguna', {'foto': path}, where: 'id = ?', whereArgs: [id]);
      return Ok({'foto_url': path});
    } catch (e) {
      return Err(AppException('Gagal menyimpan foto.', code: 'DB_ERROR'));
    }
  }

  Future<Result<Map<String, dynamic>>> hapusFoto(int id) async {
    try {
      final d = await db.database;
      final lama = await d.query('pengguna', where: 'id = ?', whereArgs: [id], limit: 1);
      if (lama.isNotEmpty) {
        await db.hapusFotoFile(lama.first['foto'] as String?);
        await d.update('pengguna', {'foto': null}, where: 'id = ?', whereArgs: [id]);
      }
      return Ok({'foto_url': null});
    } catch (e) {
      return Err(AppException('Gagal menghapus foto.', code: 'DB_ERROR'));
    }
  }
}
