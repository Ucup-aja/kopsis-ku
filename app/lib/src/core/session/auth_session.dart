import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth session — persists logged-in user so restart doesn't force re-login.
///
/// Stores only non-sensitive identity (id, name, username, email, fotoUrl).
/// Passwords/tokens must never be stored here.
class AuthUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? foto;
  final String? fotoUrl;

  /// Token sesi (Bearer) — dipakai untuk request API berikutnya.
  final String? token;

  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.foto,
    this.fotoUrl,
    this.token,
  });

  Map<String, String> toPrefs() => {
        'id': id.toString(),
        'name': name,
        'username': username,
        'email': email,
        'foto': foto ?? '',
        'fotoUrl': fotoUrl ?? '',
        'token': token ?? '',
      };

  static AuthUser? fromPrefs(Map<String, String?> m) {
    final id = int.tryParse(m['id'] ?? '') ?? 0;
    if (id <= 0) return null;
    return AuthUser(
      id: id,
      name: m['name'] ?? '',
      username: m['username'] ?? '',
      email: m['email'] ?? '',
      foto: (m['foto'] ?? '').isEmpty ? null : m['foto'],
      fotoUrl: (m['fotoUrl'] ?? '').isEmpty ? null : m['fotoUrl'],
      token: (m['token'] ?? '').isEmpty ? null : m['token'],
    );
  }

  AuthUser copyWith({String? fotoUrl, String? foto}) => AuthUser(
        id: id,
        name: name,
        username: username,
        email: email,
        foto: foto ?? this.foto,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );
}

class AuthSession extends ChangeNotifier {
  static final AuthSession instance = AuthSession._();
  AuthSession._();

  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;

  static const _pId = 'auth_id';
  static const _pName = 'auth_name';
  static const _pUsername = 'auth_username';
  static const _pEmail = 'auth_email';
  static const _pFoto = 'auth_foto';
  static const _pFotoUrl = 'auth_foto_url';
  static const _pToken = 'auth_token';

  /// Token sesi aktif (null bila belum login).
  String? get token => _user?.token;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _user = AuthUser.fromPrefs({
      'id': p.getString(_pId),
      'name': p.getString(_pName),
      'username': p.getString(_pUsername),
      'email': p.getString(_pEmail),
      'foto': p.getString(_pFoto),
      'fotoUrl': p.getString(_pFotoUrl),
      'token': p.getString(_pToken),
    });
    notifyListeners();
  }

  Future<void> save(AuthUser u) async {
    _user = u;
    final p = await SharedPreferences.getInstance();
    await p.setString(_pId, u.id.toString());
    await p.setString(_pName, u.name);
    await p.setString(_pUsername, u.username);
    await p.setString(_pEmail, u.email);
    await p.setString(_pFoto, u.foto ?? '');
    await p.setString(_pFotoUrl, u.fotoUrl ?? '');
    await p.setString(_pToken, u.token ?? '');
    notifyListeners();
  }

  Future<void> updateFoto(String? fotoUrl) async {
    if (_user == null) return;
    _user = _user!.copyWith(fotoUrl: fotoUrl, foto: fotoUrl);
    final p = await SharedPreferences.getInstance();
    await p.setString(_pFotoUrl, fotoUrl ?? '');
    notifyListeners();
  }

  Future<void> clear() async {
    _user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_pId);
    await p.remove(_pName);
    await p.remove(_pUsername);
    await p.remove(_pEmail);
    await p.remove(_pFoto);
    await p.remove(_pFotoUrl);
    await p.remove(_pToken);
    notifyListeners();
  }
}
