import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/error/result.dart';
import '../../core/config/app_branding.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../shell/main_shell.dart';
import 'register_page.dart';

/// Login modern: split-view di desktop, kartu tengah di mobile.
/// Tema biru-abu + dark mode penuh.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    if (usernameC.text.trim().isEmpty || passC.text.isEmpty) {
      snack('Username dan password wajib diisi');
      return;
    }
    setState(() => loading = true);
    final res = await AppScope.of(context)
        .auth
        .login(usernameC.text.trim(), passC.text);
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        if (!mounted) break;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainShell(
              userId: data.id,
              name: data.name,
              username: data.username,
              email: data.email,
              foto: data.foto,
              fotoUrl: data.fotoUrl,
            ),
          ),
        );
      case Err(:final error):
        snack(error.message);
    }
    if (mounted) setState(() => loading = false);
  }

  void snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: dark ? AppTheme.darkBg : AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 860 : 440),
              child: wide ? _wideCard(dark) : _narrowCard(dark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _narrowCard(bool dark) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
              alignment: Alignment.centerRight, child: ThemeToggleButton()),
          const SizedBox(height: 6),
          _logo(),
          const SizedBox(height: 16),
          _formCard(dark),
          const SizedBox(height: 12),
          _hintBar(dark),
        ],
      );

  Widget _wideCard(bool dark) => Container(
        decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rXl),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _sidePanel(dark)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                          alignment: Alignment.centerRight,
                          child: ThemeToggleButton()),
                      const SizedBox(height: 8),
                      _formInner(dark, showLogo: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sidePanel(bool dark) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(AppBranding.appIcon,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('KOPSIS KU',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            const Text('Koperasi Siswa',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(AppBranding.appTagline,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 20),
            for (final t in [
              (Icons.inventory_2_rounded, 'Kelola produk & stok'),
              (Icons.point_of_sale_rounded, 'Catat penjualan & restok'),
              (Icons.dark_mode_rounded, 'Dark mode + responsif penuh'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(t.$1, size: 15, color: Colors.white)),
                  const SizedBox(width: 10),
                  Text(t.$2,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ],
        ),
      );

  Widget _logo() => Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: const Icon(AppBranding.appIcon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        const Text('KopsisKu',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4)),
        Text(AppBranding.appTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
      ]);

  Widget _formCard(bool dark) => Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
        child: _formInner(dark, showLogo: false),
      );

  Widget _formInner(bool dark, {required bool showLogo}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Masuk',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text('Kelola produk, penjualan & restok koperasi',
              style: TextStyle(
                  fontSize: 12.5,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
          const SizedBox(height: 18),
          TextField(
            controller: usernameC,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'cth: admin_koperasi',
                prefixIcon: Icon(Icons.alternate_email_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passC,
            obscureText: obscure,
            onSubmitted: (_) => login(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                  icon: Icon(obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => obscure = !obscure)),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('MASUK'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Belum punya akun?',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
              TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterPage())),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 32)),
                  child: const Text('Daftar',
                      style: TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
        ],
      );

  Widget _hintBar(bool dark) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: dark ? AppTheme.darkCard : AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(
                color: dark ? AppTheme.darkBorder : AppTheme.primaryLight)),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: dark ? AppTheme.darkCard2 : Colors.white,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.storefront_rounded,
                  size: 15, color: AppTheme.primary)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Penjualan mengurangi stok • restok menambah stok otomatis',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? AppTheme.darkMuted : AppTheme.textBody,
                      fontWeight: FontWeight.w600,
                      height: 1.4)))
        ]),
      );
}
