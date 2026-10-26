import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/config/env.dart';
import '../core/session/auth_session.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/produk_repository.dart';
import '../data/repositories/repositories.dart';
import '../features/auth/login_page.dart';
import '../features/shell/main_shell.dart';

/// Composition root: ApiClient + repository koperasi konsumen.
class AppScope extends InheritedWidget {
  final ApiClient api;
  late final AuthRepository auth;
  late final DashboardRepository dashboard;
  late final ProdukRepository produk;
  late final TransaksiRepository transaksi;
  late final ProfilRepository profil;

  AppScope({super.key, required super.child, ApiClient? apiClient})
      : api = apiClient ?? ApiClient(baseUrl: Env.apiBaseUrl) {
    // Token sesi dibaca ulang tiap AppScope dibuat (mis. setelah login/logout).
    final token = AuthSession.instance.token;
    if (token != null) api.setAuthToken(token);
    auth = AuthRepository(api);
    dashboard = DashboardRepository(api);
    produk = ProdukRepository(api);
    transaksi = TransaksiRepository(api);
    profil = ProfilRepository(api);
  }

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) => api != oldWidget.api;
}

class AppRouter {
  static Widget initial() {
    return ListenableBuilder(
      listenable: AuthSession.instance,
      builder: (_, __) {
        final u = AuthSession.instance.user;
        if (u == null || u.token == null) return const LoginPage();
        return MainShell(
          userId: u.id,
          name: u.name,
          username: u.username,
          email: u.email,
          foto: u.foto,
          fotoUrl: u.fotoUrl,
        );
      },
    );
  }

  static Future<void> logout(BuildContext context) async {
    await AuthSession.instance.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}

class KopsisApp extends StatelessWidget {
  const KopsisApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AppScope(
      child: ValueListenableBuilder<bool>(
        valueListenable: ThemeController.instance.isDark,
        builder: (_, isDark, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'KopsisKu',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: AppRouter.initial(),
          );
        },
      ),
    );
  }
}
