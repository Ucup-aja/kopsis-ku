import '../../core/error/result.dart';
import '../../core/error/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/session/auth_session.dart';

/// Auth repository — isolates auth data access (ARCHITECTURE.md §4).
/// UI must use this, never [ApiClient]/`http` directly.
class AuthRepository {
  final ApiClient client;
  AuthRepository(this.client);

  Future<Result<AuthUser>> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return const Err(
          AppException('Username dan password wajib diisi.', code: 'VALIDATION_ERROR'));
    }
    try {
      final d = await client.postJson(
          '/backend/auth/login.php', {'username': username.trim(), 'password': password});
      final u = (d['user'] ?? d['data']?['user'] ?? d['data'] ?? {}) as Map;
      final user = AuthUser(
        id: int.tryParse(u['id']?.toString() ?? '') ?? 0,
        name: u['name']?.toString() ?? u['username']?.toString() ?? '',
        username: u['username']?.toString() ?? username.trim(),
        email: u['email']?.toString() ?? '',
        foto: u['foto']?.toString(),
        fotoUrl: u['foto_url']?.toString(),
        token: u['token']?.toString(),
      );
      if (user.id <= 0) {
        return const Err(AppException('Respons login tidak valid.', code: 'INVALID_RESPONSE'));
      }
      client.setAuthToken(user.token);
      await AuthSession.instance.save(user);
      return Ok(user);
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<Result<Map<String, dynamic>>> register(
      String name, String username, String email, String password) async {
    try {
      final d = await client.postJson('/backend/auth/registrasi.php', {
        'name': name.trim(),
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      });
      return Ok(d);
    } on AppException catch (e) {
      return Err(e);
    }
  }

  Future<void> logout() async {
    client.setAuthToken(null);
    await AuthSession.instance.clear();
  }
}
