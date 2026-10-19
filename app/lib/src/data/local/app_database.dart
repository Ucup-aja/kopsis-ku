import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Database lokal SQLite — seluruh data tinggal di HP, tanpa server.
class AppDatabase {
  AppDatabase({String? path}) : _path = path;
  static final AppDatabase instance = AppDatabase();

  final String? _path;
  Database? _db;
  Directory? _fotoDir;

  Future<Database> get database async {
    return _db ??= await openDatabase(
      _path ?? p.join(await getDatabasesPath(), 'koperasi.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pengguna (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            salt TEXT NOT NULL,
            foto TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
          )''');
        await db.execute('''
          CREATE TABLE produk (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            kategori TEXT NOT NULL DEFAULT 'lainnya',
            harga REAL NOT NULL,
            stok INTEGER NOT NULL DEFAULT 0,
            deskripsi TEXT,
            foto TEXT,
            status TEXT NOT NULL DEFAULT 'tersedia',
            created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
          )''');
        await db.execute('''
          CREATE TABLE transaksi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kode TEXT NOT NULL UNIQUE,
            produk_id INTEGER,
            nama_produk TEXT NOT NULL,
            tipe TEXT NOT NULL CHECK (tipe IN ('penjualan','restok')),
            jumlah INTEGER NOT NULL,
            harga_satuan REAL NOT NULL DEFAULT 0,
            total REAL NOT NULL DEFAULT 0,
            stok_sebelum INTEGER NOT NULL,
            stok_sesudah INTEGER NOT NULL,
            keterangan TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
            FOREIGN KEY (produk_id) REFERENCES produk (id) ON DELETE SET NULL
          )''');
      },
    );
  }

  /// Salin foto pilihan (image_picker) ke penyimpanan permanen; kembalikan path absolut.
  Future<String> simpanFoto(File sumber, String prefix) async {
    final dir = await fotoDir();
    final ekstensi = p.extension(sumber.path).toLowerCase().isEmpty
        ? '.jpg'
        : p.extension(sumber.path).toLowerCase();
    final nama =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ekstensi';
    final dest = '$dir/$nama';
    await sumber.copy(dest);
    return dest;
  }

  Future<void> hapusFotoFile(String? path) async {
    if (path == null || path.isEmpty) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<Directory> fotoDir() async {
    if (_fotoDir != null) return _fotoDir!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'foto'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _fotoDir = dir;
    return dir;
  }
}
