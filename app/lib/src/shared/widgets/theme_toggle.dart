import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

/// Tombol ganti dark / light mode. Tinggal taruh di AppBar halaman mana pun:
/// ```dart
/// appBar: AppBar(
///   title: const Text('Judul'),
///   actions: const [ThemeToggleButton()],
/// )
/// ```
/// Ikon otomatis mengikuti warna AppBar (putih di AppBar berwarna).
/// Untuk AppBar pink Azzahra, pakai `ThemeToggleButton(color: Colors.white)`.
class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, dark, __) => IconButton(
        tooltip: dark ? 'Mode Terang' : 'Mode Gelap',
        color: color,
        icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
        onPressed: () => ThemeController.instance.toggle(),
      ),
    );
  }
}
