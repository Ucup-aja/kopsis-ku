import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/result.dart';
import '../local/app_database.dart';
import '../models/models.dart';

/// Product repository — logika bisnis produk ada di sini, bukan di widget.
/// Implementasi SQLite lokal (pengganti `/backend/api/produk.php`).
class ProdukRepository {
  final AppDatabase db;
  ProdukRepository(this.db);

  static const _statusSah = ['tersedia', 'habis', 'arsip'];

  Future<Result<List<Produk>>> list(
      {String search = '', String kategori = '', String status = ''}) async {
    try {
      final where = <String>[];
      final args = <Object?>[];
      if (search.isNotEmpty) {
        where.add('(nama LIKE ? OR deskripsi LIKE ? OR kategori LIKE ?)');
        final like = '%$search%';
        args..add(like)..add(like)..add(like);
      }
      if (kategori.isNotEmpty) {
        where.add('kategori = ?');
        args.add(kategori);
      }
      if (_statusSah.contains(status)) {
        where.add('status = ?');
        args.add(status);
      }
      final d = await db.database;
      final rows = await d.query('produk',
          where: where.isEmpty ? null : where.join(' AND '),
          whereArgs: args,
          orderBy: 'updated_at DESC, id DESC');
      return Ok(rows.map(_row).toList());
    } catch (e) {
      return Err(AppException('Gagal memuat produk.', code: 'DB_ERROR'));
    }
  }

  Result<void> validateForm(
      {required String nama, required double harga, required int stok}) {
    if (nama.trim().isEmpty) {
      return const Err(AppException('Nama produk wajib diisi.',
          code: 'VALIDATION_ERROR'));
    }
    if (harga < 0) {
      return const Err(AppException('Harga tidak boleh negatif.',
          code: 'VALIDATION_ERROR'));
    }
    if (stok < 0) {
      return const Err(AppException('Stok tidak boleh negatif.',
          code: 'VALIDATION_ERROR'));
    }
    return const Ok(null);
  }

  Future<Result<Produk>> create({
    required String nama,
    required String kategori,
    required double harga,
    required int stok,
    String deskripsi = '',
    String status = 'tersedia',
    File? foto,
  }) async {
    final v = validateForm(nama: nama, harga: harga, stok: stok);
    if (v is Err<void>) return Err((v as Err).error);
    try {
      final d = await db.database;
      final id = await d.insert('produk', {
        'nama': nama.trim(),
        'kategori': kategori,
        'harga': harga,
        'stok': stok,
        'deskripsi': deskripsi,
        'foto': foto != null ? await db.simpanFoto(foto, 'prod') : null,
        'status': _statusSah.contains(status) ? status : 'tersedia',
      });
      return Ok(await _get(d, id));
    } catch (e) {
      return Err(AppException('Gagal menyimpan produk.', code: 'DB_ERROR'));
    }
  }

  Future<Result<Produk>> update(int id,
      {required String nama,
      required String kategori,
      required double harga,
      required int stok,
      String deskripsi = '',
      String status = 'tersedia',
      File? foto,
      bool hapusFoto = false}) async {
    final v = validateForm(nama: nama, harga: harga, stok: stok);
    if (v is Err<void>) return Err((v as Err).error);
    try {
      final d = await db.database;
      final lama = await d.query('produk', where: 'id = ?', whereArgs: [id], limit: 1);
      if (lama.isEmpty) {
        return const Err(AppException('Produk tidak ditemukan.', code: 'NOT_FOUND'));
      }
      String? fotoBaru = lama.first['foto'] as String?;
      if (foto != null) {
        await db.hapusFotoFile(fotoBaru);
        fotoBaru = await db.simpanFoto(foto, 'prod');
      } else if (hapusFoto) {
        await db.hapusFotoFile(fotoBaru);
        fotoBaru = null;
      }
      await d.update(
        'produk',
        {
          'nama': nama.trim(),
          'kategori': kategori,
          'harga': harga,
          'stok': stok,
          'deskripsi': deskripsi,
          'foto': fotoBaru,
          'status': _statusSah.contains(status) ? status : 'tersedia',
          'updated_at': DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' '),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return Ok(await _get(d, id));
    } catch (e) {
      return Err(AppException('Gagal memperbarui produk.', code: 'DB_ERROR'));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      final d = await db.database;
      final lama = await d.query('produk', where: 'id = ?', whereArgs: [id], limit: 1);
      if (lama.isEmpty) return const Ok(null);
      await d.delete('produk', where: 'id = ?', whereArgs: [id]);
      await db.hapusFotoFile(lama.first['foto'] as String?);
      return const Ok(null);
    } catch (e) {
      return Err(AppException('Gagal menghapus produk.', code: 'DB_ERROR'));
    }
  }

  Future<Produk> _get(Database d, int id) async {
    final r = await d.query('produk', where: 'id = ?', whereArgs: [id], limit: 1);
    return _row(r.first);
  }

  static Produk _row(Map<String, Object?> r) =>
      Produk.fromJson(Map<String, dynamic>.from(r));
}
