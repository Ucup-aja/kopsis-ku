import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/theme_toggle.dart';

/// Registrasi akun pengelola koperasi konsumen.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameC = TextEditingController();
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> register() async {
    if (nameC.text.trim().isEmpty ||
        usernameC.text.trim().isEmpty ||
        emailC.text.trim().isEmpty ||
        passC.text.isEmpty) {
      snack('Nama, username, email, password wajib diisi');
      return;
    }
    setState(() => loading = true);
    final res = await AppScope.of(context).auth.register(
        nameC.text.trim(),
        usernameC.text.trim(),
        emailC.text.trim(),
        passC.text);
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        snack(data['message']?.toString() ?? 'Berhasil daftar');
        if (data['success'] == true && mounted) Navigator.pop(context);
      case Err(:final error):
        snack(error.message);
    }
    if (mounted) setState(() => loading = false);
  }

  void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: dark ? AppTheme.darkBg : AppTheme.bg,
      appBar: AppBar(
        title: const Text('Daftar Akun Pengelola'),
        actions: const [ThemeToggleButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 880 : 500),
            child: wide ? _wide(dark) : _narrow(dark),
          ),
        ),
      ),
    );
  }

  Widget _narrow(bool dark) => Container(
        padding: const EdgeInsets.all(22),
        decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
        child: _form(dark),
      );

  Widget _wide(bool dark) => Container(
        decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rXl),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      gradient: dark
                          ? AppTheme.heroGradientDark
                          : AppTheme.heroGradient),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_alt_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                      const Text('Gabung KopsisKu\nsebagai pengelola',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.2)),
                      SizedBox(height: 10),
                      Text(
                          'Satu akun untuk mengelola produk, stok, penjualan, dan restok.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: _form(dark),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _form(bool dark) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 16)),
            const SizedBox(width: 8),
            const Text('KopsisKu',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3)),
          ]),
          const SizedBox(height: 12),
          Text('Buat akun baru',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: dark ? AppTheme.darkText : AppTheme.textDark)),
          Text('Masuk cukup dengan username setelah daftar',
              style: TextStyle(
                  fontSize: 12,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
          const SizedBox(height: 18),
          TextField(
              controller: nameC,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: usernameC,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon:
                            Icon(Icons.alternate_email_rounded)))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded)))),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: passC,
            obscureText: obscure,
            onSubmitted: (_) => register(),
            decoration: InputDecoration(
                labelText: 'Password (min 6)',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: () => setState(() => obscure = !obscure))),
          ),
          const SizedBox(height: 20),
          SizedBox(
              height: 50,
              child: FilledButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('DAFTAR'))),
          const SizedBox(height: 8),
          Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Sudah punya akun?',
                    style: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? AppTheme.darkMuted
                            : AppTheme.textMuted)),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(0, 32)),
                    child: const Text('Masuk',
                        style:
                            TextStyle(fontWeight: FontWeight.w800)))
              ]),
        ],
      );
}
