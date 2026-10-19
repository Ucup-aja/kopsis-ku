import 'package:flutter/material.dart';
import '../core/session/auth_session.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../data/local/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/produk_repository.dart';
import '../data/repositories/repositories.dart';
import '../features/auth/login_page.dart';
import '../features/shell/main_shell.dart';

/// Composition root: database lokal SQLite + repository koperasi konsumen.
class AppScope extends InheritedWidget {
  final AppDatabase db;
  late final AuthRepository auth;
  late final DashboardRepository dashboard;
  late final ProdukRepository produk;
  late final TransaksiRepository transaksi;
  late final ProfilRepository profil;

  AppScope({super.key, required super.child, AppDatabase? database})
      : db = database ?? AppDatabase.instance {
    auth = AuthRepository(db);
    dashboard = DashboardRepository(db);
    produk = ProdukRepository(db);
    transaksi = TransaksiRepository(db);
    profil = ProfilRepository(db);
  }

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) => db != oldWidget.db;
}

class AppRouter {
  static Widget initial() {
    return ListenableBuilder(
      listenable: AuthSession.instance,
      builder: (_, __) {
        final u = AuthSession.instance.user;
        if (u == null) return const LoginPage();
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
