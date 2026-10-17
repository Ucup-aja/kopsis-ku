import 'dart:io';
import '../../core/error/result.dart';
import '../../core/error/app_exception.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class DashboardRepository {
  final ApiClient client;
  DashboardRepository(this.client);

  Future<Result<DashboardData>> fetch() async {
    try {
      final d = await client.getJson('/backend/api/dashboard.php');
      return Ok(DashboardData.fromJson(
          Map<String, dynamic>.from(d['data'] as Map)));
    } on AppException catch (e) {
      return Err(e);
    }
  }
}

class TransaksiRepository {
  final ApiClient client;
  TransaksiRepository(this.client);

  Future<Result<List<Transaksi>>> list({
    String search = '',
    String tipe = '',
    String dari = '',
    String sampai = '',
    int limit = 50,
  }) async {
    try {
      final q = <String, String>{'limit': limit.toString()};
      if (search.isNotEmpty) q['search'] = search;
      if (tipe.isNotEmpty) q['tipe'] = tipe;
      if (dari.isNotEmpty) q['dari'] = dari;
      if (sampai.isNotEmpty) q['sampai'] = sampai;
      final d = await client.getJson('/backend/api/transaksi.php', query: q);
      final items = (d['data'] as List)
          .map((e) => Transaksi.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Ok(items);
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<Result<TransaksiSummary>> summary() async {
    try {
      final d = await client.getJson('/backend/api/transaksi.php',
          query: {'summary': '1'});
      return Ok(TransaksiSummary.fromJson(
          Map<String, dynamic>.from(d['data'] as Map)));
    } on AppException catch (e) {
      return Err(e);
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
      final body = <String, dynamic>{
        'produk_id': produkId,
        'tipe': tipe,
        'jumlah': jumlah,
        'keterangan': keterangan,
      };
      if (hargaSatuan != null) body['harga_satuan'] = hargaSatuan;
      final d = await client.postJson('/backend/api/transaksi.php', body);
      return Ok(
          Transaksi.fromJson(Map<String, dynamic>.from(d['data'] as Map)));
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await client.postJson('/backend/api/transaksi.php?id=$id&_method=DELETE',
          {'_method': 'DELETE', 'id': id});
      return const Ok(null);
    } on AppException catch (e) {
      return Err(e);
    }
  }
}

class ProfilRepository {
  final ApiClient client;
  ProfilRepository(this.client);

  Future<Result<Map<String, dynamic>>> get({int? id, String? username}) async {
    try {
      final q = <String, String>{};
      if (id != null) q['id'] = id.toString();
      if (username != null) q['username'] = username;
      final d = await client.getJson('/backend/api/profil.php', query: q);
      return Ok(Map<String, dynamic>.from(d['data'] as Map));
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<Result<Map<String, dynamic>>> uploadFoto(int id, File foto) async {
    try {
      final d = await client.postMultipart('/backend/api/profil.php',
          query: {'id': id.toString()}, fileField: 'foto', file: foto);
      return Ok(Map<String, dynamic>.from(d['data'] as Map));
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<Result<Map<String, dynamic>>> hapusFoto(int id) async {
    try {
      final d = await client.postMultipart('/backend/api/profil.php',
          query: {'id': id.toString()}, fields: {'foto_hapus': '1'});
      return Ok(Map<String, dynamic>.from(d['data'] as Map));
    } on AppException catch (e) {
      return Err(e);
    }
  }
}
