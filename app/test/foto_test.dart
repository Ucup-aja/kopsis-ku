import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koperasi_siswa/src/core/error/result.dart';
import 'package:koperasi_siswa/src/data/local/app_database.dart';
import 'package:koperasi_siswa/src/data/models/models.dart';
import 'package:koperasi_siswa/src/data/repositories/auth_repository.dart';
import 'package:koperasi_siswa/src/data/repositories/produk_repository.dart';
import 'package:koperasi_siswa/src/data/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regresi bug upload foto: interpolasi `'$dir'` menghasilkan "Directory: '...'"
/// → `copy()` gagal → "Gagal menyimpan foto/produk". Jalankan: flutter test
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  late Directory temp;
  late Directory sumberDir;
  late AppDatabase db;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('kopsis_foto');
    sumberDir = await Directory.systemTemp.createTemp('kopsis_sumber');
    db = AppDatabase(path: inMemoryDatabasePath, fotoDirPath: temp.path);
    await db.database;
  });

  tearDown(() async {
    await (await db.database).close();
    if (await temp.exists()) await temp.delete(recursive: true);
    if (await sumberDir.exists()) await sumberDir.delete(recursive: true);
  });

  File sumber(String nama) =>
      File('${sumberDir.path}/$nama')..writeAsStringSync('isi-gambar');

  test('input produk dengan foto → file tersimpan, kolom foto path valid', () async {
    final r = await ProdukRepository(db).create(
        nama: 'Buku', kategori: 'alat tulis', harga: 5000, stok: 2,
        foto: sumber('sumber.jpg'));
    expect(r, isA<Ok<Produk>>(),
        reason: r is Err ? (r as Err).error.message : 'ok');
    final foto = (r as Ok<Produk>).data.foto;
    expect(foto, isNotNull);
    expect(File(foto!).existsSync(), isTrue, reason: 'foto harus berupa file nyata');
    expect(foto, startsWith(temp.path));
    expect(foto, isNot(contains('Directory:')));
  });

  test('upload foto profil → file tersimpan & foto_url terisi', () async {
    final auth = AuthRepository(db);
    await auth.register('Ucup', 'ucup', 'u@mail.com', 'rahasia123');

    final r = await ProfilRepository(db).uploadFoto(1, sumber('avatar.jpg'));
    expect(r, isA<Ok<Map<String, dynamic>>>());
    final foto = (r as Ok<Map<String, dynamic>>).data['foto_url'] as String;
    expect(File(foto).existsSync(), isTrue);
    expect(foto, isNot(contains('Directory:')));

    // Ganti foto sekali lagi → file lama ikut terhapus, hanya 1 file tersisa.
    await ProfilRepository(db).uploadFoto(1, sumber('avatar2.jpg'));
    final files = temp.listSync().whereType<File>().length;
    expect(files, 1, reason: 'foto lama harus dibersihkan');
  });
}
