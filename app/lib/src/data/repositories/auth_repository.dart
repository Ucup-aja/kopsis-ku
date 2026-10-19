import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/result.dart';
import '../../core/session/auth_session.dart';
import '../local/app_database.dart';

/// Auth lokal (SQLite) — pengganti `/backend/auth` tanpa server.
/// UI memakai ini, tidak boleh menyentuh database langsung.
class AuthRepository {
  final AppDatabase db;
  AuthRepository(this.db);

  static final Random _rng = Random.secure();

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  Future<Result<AuthUser>> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return const Err(
          AppException('Username dan password wajib diisi.', code: 'VALIDATION_ERROR'));
    }
    final d = await db.database;
    final rows = await d.query('pengguna',
        where: 'username = ?', whereArgs: [username.trim()], limit: 1);
    if (rows.isEmpty ||
        rows.first['password'] !=
            _hash(rows.first['salt'] as String, password)) {
      return const Err(
          AppException('Username atau password salah', code: 'INVALID_CREDENTIALS'));
    }
    final r = rows.first;
    final user = AuthUser(
      id: r['id'] as int,
      name: (r['name'] ?? '') as String,
      username: (r['username'] ?? '') as String,
      email: (r['email'] ?? '') as String,
      foto: r['foto'] as String?,
      fotoUrl: r['foto'] as String?,
    );
    await AuthSession.instance.save(user);
    return Ok(user);
  }

  Future<Result<Map<String, dynamic>>> register(
      String name, String username, String email, String password) async {
    name = name.trim();
    username = username.trim();
    email = email.trim();
    // Bentuk respons identik dengan backend: {success, message}.
    Map<String, dynamic> res(bool ok, String msg) =>
        {'success': ok, 'message': msg};

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      return Ok(res(false, 'Nama, username, email, password wajib diisi'));
    }
    if (!RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(username)) {
      return Ok(res(false, 'Username 3-30 karakter, huruf/angka/._ saja'));
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return Ok(res(false, 'Format email tidak valid'));
    }
    if (password.length < 6) {
      return Ok(res(false, 'Password minimal 6 karakter'));
    }
    final d = await db.database;
    final bentrok = await d.query('pengguna',
        where: 'username = ? OR email = ?', whereArgs: [username, email], limit: 1);
    if (bentrok.isNotEmpty) {
      return Ok(res(false, 'Username atau email sudah terdaftar'));
    }
    final salt = List.generate(
            16, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    await d.insert('pengguna', {
      'name': name,
      'username': username,
      'email': email,
      'password': _hash(salt, password),
      'salt': salt,
    });
    return Ok(res(true, 'Registrasi berhasil, silakan login dengan username'));
  }

  Future<void> logout() => AuthSession.instance.clear();
}
