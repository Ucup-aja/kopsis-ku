import 'dart:io';
import '../../core/error/result.dart';
import '../../core/error/app_exception.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

/// Product repository — business-adjacent logic lives here, not in widgets.
class ProdukRepository {
  final ApiClient client;
  ProdukRepository(this.client);

  Future<Result<List<Produk>>> list(
      {String search = '', String kategori = '', String status = ''}) async {
    try {
      final q = <String, String>{};
      if (search.isNotEmpty) q['search'] = search;
      if (kategori.isNotEmpty) q['kategori'] = kategori;
      if (status.isNotEmpty) q['status'] = status;
      final d = await client.getJson('/backend/api/produk.php', query: q);
      final items = (d['data'] as List)
          .map((e) => Produk.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Ok(items);
    } on AppException catch (e) {
      return Err(e);
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
      final d = await client.postMultipart('/backend/api/produk.php',
          fields: {
            'nama': nama,
            'kategori': kategori,
            'harga': harga.toString(),
            'stok': stok.toString(),
            'deskripsi': deskripsi,
            'status': status,
          },
          fileField: foto != null ? 'foto' : null,
          file: foto);
      return Ok(Produk.fromJson(Map<String, dynamic>.from(d['data'] as Map)));
    } on AppException catch (e) {
      return Err(e);
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
      final fields = {
        '_method': 'PUT',
        'nama': nama,
        'kategori': kategori,
        'harga': harga.toString(),
        'stok': stok.toString(),
        'deskripsi': deskripsi,
        'status': status,
      };
      if (hapusFoto) fields['foto_hapus'] = '1';
      final d = await client.postMultipart('/backend/api/produk.php',
          query: {'id': id.toString()},
          fields: fields,
          fileField: foto != null ? 'foto' : null,
          file: foto);
      return Ok(Produk.fromJson(Map<String, dynamic>.from(d['data'] as Map)));
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      // Prefer explicit DELETE-override endpoint (legacy compat).
      await client.postJson('/backend/api/produk.php?id=$id&_method=DELETE',
          {'_method': 'DELETE', 'id': id});
      return const Ok(null);
    } on AppException catch (e) {
      return Err(e);
    }
  }
}
