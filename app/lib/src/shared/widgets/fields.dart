import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Gambar dari path file di penyimpanan app — foto disimpan lokal, bukan URL.
Widget buildFoto(String src,
    {double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    required Widget Function() onError}) {
  return Image.file(File(src), width: width, height: height, fit: fit,
      errorBuilder: (_, __, ___) => onError());
}

/// Field pencarian konsisten di semua layar.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  const SearchField({
    super.key,
    required this.controller,
    this.hint = 'Cari...',
    required this.onSubmitted,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onSubmitted('');
                },
              ),
      ),
    );
  }
}

/// Badge status kecil (tersedia/habis/penjualan/restok).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const StatusBadge({super.key, required this.label, this.color, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: dark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 4),
          ],
          Text(label,
              style:
                  TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

/// Avatar dengan foto / inisial.
class AvatarView extends StatelessWidget {
  final String? fotoUrl;
  final String fallbackLetter;
  final double radius;
  const AvatarView({
    super.key,
    required this.fotoUrl,
    required this.fallbackLetter,
    this.radius = 20,
  });
  @override
  Widget build(BuildContext context) {
    final url = fotoUrl ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: buildFoto(
          url,
          width: radius * 2,
          height: radius * 2,
          onError: _fallback,
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primary,
        child: Text(
          fallbackLetter.isNotEmpty ? fallbackLetter[0].toUpperCase() : 'U',
          style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.85,
              fontWeight: FontWeight.w800),
        ),
      );
}

/// Gambar produk dengan placeholder konsisten.
class ProductImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double iconSize;
  const ProductImage(
      {super.key,
      required this.url,
      this.width,
      this.height,
      this.iconSize = 26});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (url.isEmpty) return _placeholder(dark);
    return buildFoto(url,
        width: width,
        height: height,
        onError: () => _placeholder(dark));
  }

  Widget _placeholder(bool dark) => Container(
        width: width,
        height: height,
        color: dark ? AppTheme.darkCard2 : AppTheme.primarySoft,
        child: Icon(Icons.inventory_2_rounded,
            color: (dark ? AppTheme.darkPrimary : AppTheme.primary)
                .withValues(alpha: 0.6),
            size: iconSize),
      );
}
