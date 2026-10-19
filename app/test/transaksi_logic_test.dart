import 'package:flutter_test/flutter_test.dart';
import 'package:koperasi_siswa/src/core/error/result.dart';
import 'package:koperasi_siswa/src/core/session/auth_session.dart';
import 'package:koperasi_siswa/src/data/local/app_database.dart';
import 'package:koperasi_siswa/src/data/repositories/auth_repository.dart';
import 'package:koperasi_siswa/src/data/models/models.dart';
import 'package:koperasi_siswa/src/data/repositories/produk_repository.dart';
import 'package:koperasi_siswa/src/data/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Aturan stok + agregasi dashboard + auth lokal — jalankan: flutter test
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  late AppDatabase db;
  late ProdukRepository produk;
  late TransaksiRepository transaksi;
  late DashboardRepository dashboard;
  late AuthRepository auth;

  setUp(() async {
    db = AppDatabase(path: inMemoryDatabasePath);
    produk = ProdukRepository(db);
    transaksi = TransaksiRepository(db);
    dashboard = DashboardRepository(db);
    auth = AuthRepository(db);
    await db.database; // paksa skema dibuat
  });

  tearDown(() async {
    // sqflite mem-cache DB per path — tanpa close, ':memory:' bocor antar tes.
    await (await db.database).close();
  });

  Future<int> buatProduk({int stok = 5, String status = 'tersedia'}) async {
    final r = await produk.create(
        nama: 'Buku', kategori: 'alat tulis', harga: 5000, stok: stok, status: status);
    expect(r, isA<Ok<Produk>>());
    return (r as Ok).data.id;
  }

  group('aturan stok transaksi', () {
    test('penjualan mengurangi stok & menolak stok kurang', () async {
      final id = await buatProduk(stok: 5);

      final ok = await transaksi.create(produkId: id, tipe: 'penjualan', jumlah: 3);
      expect(ok, isA<Ok>());

      final kurang = await transaksi.create(produkId: id, tipe: 'penjualan', jumlah: 4);
      expect(kurang, isA<Err>());
      expect((kurang as Err).error.message, 'Stok tidak cukup (sisa 2)');
    });

    test('restok menambah & status ikut bereaksi', () async {
      final id = await buatProduk(stok: 1);

      final habis = await transaksi.create(produkId: id, tipe: 'penjualan', jumlah: 1);
      expect(habis, isA<Ok>());

      final d = await db.database;
      var row = (await d.query('produk', where: 'id = ?', whereArgs: [id])).first;
      expect(row['stok'], 0);
      expect(row['status'], 'habis');

      final isi = await transaksi.create(produkId: id, tipe: 'restok', jumlah: 10);
      expect(isi, isA<Ok>());
      row = (await d.query('produk', where: 'id = ?', whereArgs: [id])).first;
      expect(row['stok'], 10);
      expect(row['status'], 'tersedia');
    });

    test('hapus transaksi memulihkan stok sebelumnya', () async {
      final id = await buatProduk(stok: 5);
      final t = await transaksi.create(produkId: id, tipe: 'penjualan', jumlah: 3);
      final trxId = (t as Ok).data.id;

      expect(await transaksi.delete(trxId), isA<Ok>());
      final d = await db.database;
      final row = (await d.query('produk', where: 'id = ?', whereArgs: [id])).first;
      expect(row['stok'], 5);
    });
  });

  test('dashboard menghitung agregat dari data lokal', () async {
    final id = await buatProduk(stok: 5, status: 'tersedia');
    await transaksi.create(produkId: id, tipe: 'penjualan', jumlah: 2);
    await transaksi.create(produkId: id, tipe: 'restok', jumlah: 1);

    final r = await dashboard.fetch();
    expect(r, isA<Ok<DashboardData>>());
    final data = (r as Ok).data;
    expect(data.totalProduk, 1);
    expect(data.totalStok, 4);
    expect(data.nilaiStok, 20000); // 4 x 5000
    expect(data.transaksiHari, 1);
    expect(data.omsetHari, 10000); // 2 x 5000
    expect(data.restokBulan, 1);
    expect(data.recentTransaksi, hasLength(2));
  });

  group('auth lokal', () {
    test('registrasi valid → login sukses; duplikat & password salah ditolak', () async {
      final reg = await auth.register('Ucup', 'ucup', 'u@mail.com', 'rahasia123');
      expect((reg as Ok).data['success'], true);

      final dup = await auth.register('Lain', 'ucup', 'u@mail.com', 'rahasia123');
      expect((dup as Ok).data['success'], false);

      final salah = await auth.login('ucup', 'salah');
      expect(salah, isA<Err>());

      final ok = await auth.login('ucup', 'rahasia123');
      final u = (ok as Ok<AuthUser>).data;
      expect(u.id, greaterThan(0));
      expect(u.username, 'ucup');
    });
  });
}
