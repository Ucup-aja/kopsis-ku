import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/app.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/responsive/app_responsive.dart';
import '../../core/config/app_branding.dart';
import '../../shared/widgets/fields.dart';
import '../dashboard/dashboard_screen.dart';
import '../produk/produk_screen.dart';
import '../transaksi/transaksi_screen.dart';
import '../developer/developer_page.dart';

/// Shell utama koperasi konsumen: Beranda • Produk • Transaksi • Akun.
/// Mobile: NavigationBar. Tablet/Desktop: NavigationRail + topbar.
class MainShell extends StatefulWidget {
  final int userId;
  final String name;
  final String username;
  final String email;
  final String? foto;
  final String? fotoUrl;
  const MainShell({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    required this.email,
    this.foto,
    this.fotoUrl,
  });
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = 0;
  late String? fotoUrl;
  final picker = ImagePicker();
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    fotoUrl = widget.fotoUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfil());
  }

  Future<void> _refreshProfil() async {
    final scope = AppScope.maybeOf(context);
    if (scope == null) return;
    final res = await scope.profil.get(id: widget.userId);
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        setState(() => fotoUrl = data['foto_url']?.toString());
      case Err():
        break;
    }
  }

  Future<void> _pickFoto() async {
    final scope = AppScope.of(context);
    final src = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Galeri'),
            onTap: () => Navigator.pop(context, 'gallery')),
        ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(context, 'camera'))
      ])),
    );
    if (src == null) return;
    final x = await picker.pickImage(
        source: src == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800);
    if (x == null) return;
    setState(() => uploading = true);
    final res = await scope.profil.uploadFoto(widget.userId, File(x.path));
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        setState(() => fotoUrl = data['foto_url']?.toString());
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil diperbarui')));
      case Err(:final error):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
    if (mounted) setState(() => uploading = false);
  }

  Future<void> _hapusFoto() async {
    if (fotoUrl == null || fotoUrl!.isEmpty) return;
    setState(() => uploading = true);
    final res = await AppScope.of(context).profil.hapusFoto(widget.userId);
    if (!mounted) return;
    switch (res) {
      case Ok():
        setState(() => fotoUrl = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto profil dihapus')));
      case Err(:final error):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
    if (mounted) setState(() => uploading = false);
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.danger),
          SizedBox(width: 8),
          Text('Keluar?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))
        ]),
        content: const Text('Yakin ingin keluar dari akun pengelola?',
            style: TextStyle(fontSize: 13.5)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rLg)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Keluar'))
        ],
      ),
    );
    if (ok == true && mounted) AppRouter.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, dark, __) {
        final wide = MediaQuery.of(context).size.width >= AppResponsive.tablet;
        final pages = const [
          DashboardScreen(),
          ProdukScreen(),
          TransaksiScreen(),
        ];
        final body = idx < 3 ? pages[idx] : _profile(dark);
        if (wide) return _buildWide(dark, body);
        return _buildNarrow(dark, body);
      },
    );
  }

  static const _titles = ['Beranda', 'Produk', 'Transaksi', 'Akun'];

  Widget _buildNarrow(bool dark, Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(AppBranding.appIcon,
                  color: Colors.white, size: 17)),
          const SizedBox(width: 10),
          Text(_titles[idx]),
        ]),
        actions: [
          IconButton(
              tooltip: dark ? 'Mode Terang' : 'Mode Gelap',
              icon: Icon(
                  dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: () => ThemeController.instance.toggle()),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => idx = 3),
              child: AvatarView(
                  fotoUrl: fotoUrl, fallbackLetter: widget.name, radius: 16),
            ),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => setState(() => idx = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Produk'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Akun')
        ],
      ),
    );
  }

  Widget _buildWide(bool dark, Widget body) {
    final extended = MediaQuery.of(context).size.width >= 1100;
    return Scaffold(
      backgroundColor: dark ? AppTheme.darkBg : AppTheme.bg,
      body: Row(children: [
        NavigationRail(
          extended: extended,
          selectedIndex: idx,
          onDestinationSelected: (v) => setState(() => idx = v),
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(13)),
                  child: const Icon(AppBranding.appIcon,
                      color: Colors.white, size: 22)),
              if (extended) ...[
                const SizedBox(width: 10),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('KOPSIS KU',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.1)),
                      Text('Koperasi Siswa',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppTheme.textMuted)),
                    ]),
              ],
            ]),
          ),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AvatarView(
                      fotoUrl: fotoUrl,
                      fallbackLetter: widget.name,
                      radius: 22),
                  if (extended) ...[
                    const SizedBox(height: 8),
                    Text(widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    Text('@${widget.username}',
                        style: TextStyle(
                            fontSize: 11,
                            color: dark
                                ? AppTheme.darkMuted
                                : AppTheme.textMuted)),
                  ],
                  const SizedBox(height: 8),
                  IconButton(
                      tooltip: dark ? 'Mode Terang' : 'Mode Gelap',
                      onPressed: () => ThemeController.instance.toggle(),
                      icon: Icon(
                          dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20)),
                  IconButton(
                      tooltip: 'Keluar',
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded,
                          size: 20, color: AppTheme.danger)),
                ]),
              ),
            ),
          ),
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Beranda')),
            NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: Text('Produk')),
            NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: Text('Transaksi')),
            NavigationRailDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: Text('Akun')),
          ],
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: Column(children: [
            _topbar(dark),
            Expanded(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth:
                                AppResponsive.contentMaxWidth(context) + 40),
                        child: body))),
          ]),
        ),
      ]),
    );
  }

  Widget _topbar(bool dark) {
    const titles = [
      'Dashboard',
      'Kelola Produk',
      'Penjualan & Restok',
      'Akun Pengelola'
    ];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
          color: dark ? AppTheme.darkCard : Colors.white,
          border: Border(
              bottom: BorderSide(
                  color: dark ? AppTheme.darkBorder : AppTheme.border))),
      child: Row(children: [
        Text(titles[idx],
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const Spacer(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E3A5F) : AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(Icons.verified_rounded,
                  size: 14,
                  color: dark ? AppTheme.darkPrimary : AppTheme.primary),
              const SizedBox(width: 6),
              Text('Pengelola',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: dark ? AppTheme.darkPrimary : AppTheme.primary))
            ])),
      ]),
    );
  }

  Widget _profile(bool dark) {
    return ListView(padding: AppResponsive.pagePadding(context), children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
        child: Column(children: [
          Stack(alignment: Alignment.bottomRight, children: [
            AvatarView(
                fotoUrl: fotoUrl, fallbackLetter: widget.name, radius: 46),
            if (uploading)
              const Positioned.fill(
                  child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)))),
            Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                    onTap: uploading ? null : _pickFoto,
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: AppTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white)))),
          ]),
          const SizedBox(height: 14),
          Text(widget.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          Text('@${widget.username}',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(widget.email,
              style: TextStyle(
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted,
                  fontSize: 12)),
          const SizedBox(height: 10),
          StatusBadge(
              label: 'Pengelola KopsisKu',
              color: dark ? AppTheme.darkPrimary : AppTheme.primary,
              icon: Icons.verified_rounded),
          const SizedBox(height: 14),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                    icon: const Icon(Icons.photo_rounded, size: 16),
                    label: const Text('Ganti Foto',
                        style: TextStyle(fontSize: 13)),
                    onPressed: uploading ? null : _pickFoto),
                if (fotoUrl != null && fotoUrl!.isNotEmpty)
                  OutlinedButton(
                      onPressed: uploading ? null : _hapusFoto,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger),
                      child:
                          const Text('Hapus', style: TextStyle(fontSize: 13))),
              ]),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        decoration: AppTheme.cardDecoration(dark: dark),
        child: SwitchListTile(
          secondary: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: dark ? AppTheme.darkCard2 : AppTheme.bg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 18)),
          title: const Text('Mode Gelap',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
              dark ? 'Aktif — tema slate malam' : 'Mati — tema biru abu terang',
              style: const TextStyle(fontSize: 12)),
          value: dark,
          onChanged: (v) => ThemeController.instance.setDark(v),
        ),
      ),
      const SizedBox(height: 12),
      _tile(Icons.point_of_sale_rounded, 'Penjualan & Restok',
          'Penjualan mengurangi stok, restok menambah stok otomatis', dark),
      _tile(Icons.inventory_2_rounded, 'Katalog Produk',
          'Kelola nama, harga, stok, foto, dan status produk', dark),
      _tile(Icons.groups_rounded, 'Info Developer',
          'Tim siswa PPLG • SMKN 1 Leuwimunding + portfolio', dark,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DeveloperPage()))),
      _tile(Icons.info_outline_rounded, 'Tentang',
          '${AppBranding.version} • ${AppBranding.appFullName}', dark),
      const SizedBox(height: 16),
      SizedBox(
          height: 48,
          child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(
                      color: dark ? AppTheme.darkBorder : AppTheme.border)),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar',
                  style: TextStyle(fontWeight: FontWeight.w700)))),
    ]);
  }

  Widget _tile(IconData icon, String title, String sub, bool dark,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.rMd)),
          leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: dark ? AppTheme.darkCard2 : AppTheme.bg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18)),
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
          trailing: onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
    );
  }
}
