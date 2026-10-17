import 'package:flutter/material.dart';

/// Branding KopsisKu — Koperasi Konsumen Siswa.
class AppBranding {
  static const String appName = 'KopsisKu';
  static const String appFullName = 'KopsisKu — Koperasi Siswa';
  static const String appTagline = 'Kelola koperasi jadi lebih mudah';
  static const String version = 'v1.0';
  static const String copyright = '© 2026 KopsisKu • SMKN 1 Leuwimunding';
  static const IconData appIcon = Icons.storefront_rounded;
}

/// Data satu developer (siswa SMKN 1 Leuwimunding, jurusan PPLG).
class Developer {
  final String name;
  final String role;
  final String kelas;

  /// URL portfolio eksternal (https://...).
  /// Kosongkan ('') bila belum ada — tombol otomatis nonaktif.
  final String portfolioUrl;

  /// Path asset foto lokal, contoh 'assets/developers/yusuf.jpg'.
  /// Kosongkan ('') untuk tampilkan inisial.
  final String photoAsset;

  const Developer({
    required this.name,
    required this.role,
    required this.kelas,
    this.portfolioUrl = '',
    this.photoAsset = '',
  });

  bool get hasPortfolio => portfolioUrl.trim().isNotEmpty;
  bool get hasPhoto => photoAsset.trim().isNotEmpty;
  bool get isFilled => name.trim().isNotEmpty;
}

class DeveloperData {
  static const String school = 'SMKN 1 Leuwimunding';
  static const String major = 'PPLG — Pengembangan Perangkat Lunak dan Gim';
  static const String infoKelas = 'Siswa jurusan PPLG';

  // ── CARA MENAMBAHKAN / MENGUBAH DATA ─────────────────────────────
  // 1. Isi `portfolioUrl` tiap developer dengan link portfolio-nya,
  //    contoh: portfolioUrl: 'https://portofolio-anda.vercel.app'
  // 2. Isi nama developer ke-5 pada entri terakhir di bawah.
  // 3. Entri dengan nama kosong otomatis disembunyikan dari halaman.
  // ─────────────────────────────────────────────────────────────────
  static const List<Developer> list = [
    Developer(
      name: 'Ahmad Yusuf Firdaus',
      role: 'Project Leader',
      kelas: 'XII PPLG 1',
      portfolioUrl: 'https://cv.cnp.my.id/src/yusuf/',
      photoAsset: 'assets/developers/yusuf.jpg',
    ),
    Developer(
      name: 'Azzahra Meita Putri',
      role: 'Dev Member',
      kelas: 'XII PPLG 1',
      portfolioUrl: 'https://cv.cnp.my.id/src/zahraa/cvzahra.php',
      photoAsset: 'assets/developers/azzahra.jpg',
    ),
    Developer(
      name: 'Alya Nur Fauziah',
      role: 'Dev Member',
      kelas: 'XII PPLG 1',
      portfolioUrl: 'https://cv.cnp.my.id/src/alya/',
      photoAsset: 'assets/developers/alya.jpg',
    ),
    Developer(
      name: 'Ridho Firmansyah',
      role: 'Dev Member',
      kelas: 'XII PPLG 1',
      portfolioUrl: 'https://cv.cnp.my.id/src/ridho/',
      photoAsset: 'assets/developers/ridho.jpg',
    ),
    Developer(
      name: 'Alsyah',
      role: 'Dev Member',
      kelas: 'XII PPLG 1',
      portfolioUrl: 'https://cv.cnp.my.id/src/alsa/indexx.php',
      photoAsset: 'assets/developers/alsyah.jpg',
    ),
  ];

  /// Hanya entri bernamalah yang tampil sebagai card.
  static List<Developer> get visible => list.where((d) => d.isFilled).toList();
}
