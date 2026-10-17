import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_branding.dart';
import '../../core/responsive/app_responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/theme_toggle.dart';

/// Halaman Info Developer — tim siswa SMKN 1 Leuwimunding (PPLG).
/// Tiap card punya tombol menuju link portfolio masing-masing.
class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  Future<void> _openPortfolio(BuildContext context, Developer d) async {
    final url = d.portfolioUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Link portfolio belum ditambahkan'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tidak dapat membuka $url'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final devs = DeveloperData.visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Developer'),
        actions: const [ThemeToggleButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: AppResponsive.contentMaxWidth(context) + 40),
          child: ListView(
            padding: AppResponsive.pagePadding(context),
            children: [
              _hero(dark, devs.length),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Text('Tim Pengembang (${devs.length})',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: dark ? AppTheme.darkText : AppTheme.textDark)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${DeveloperData.school} • ${DeveloperData.major}',
                  style: TextStyle(
                      fontSize: 12,
                      color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth;
                if (w < 600) {
                  return Column(
                      children: devs
                          .map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _devCard(context, d, dark)))
                          .toList());
                }
                final cols = w >= 1000 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 208),
                  itemCount: devs.length,
                  itemBuilder: (_, i) => _devCard(context, devs[i], dark),
                );
              }),
              const SizedBox(height: 14),
              _aboutApp(dark),
              const SizedBox(height: 10),
              Center(
                child: Text(AppBranding.copyright,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: dark ? AppTheme.darkMuted : AppTheme.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool dark, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
      ),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.groups_rounded,
                color: Colors.white, size: 30)),
        const SizedBox(width: 13),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dibangun oleh siswa',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(DeveloperData.school,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.3)),
            Text(DeveloperData.major,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$count Developer',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary))),
          ]),
        ),
      ]),
    );
  }

  Widget _devCard(BuildContext context, Developer d, bool dark) {
    final accent = dark ? AppTheme.darkPrimary : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            d.hasPhoto
                ? ClipOval(
                    child: Image.asset(
                      d.photoAsset,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            accent.withValues(alpha: dark ? 0.18 : 0.12),
                        child: Text(
                            d.name.isNotEmpty
                                ? d.name.trim()[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 20)),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        accent.withValues(alpha: dark ? 0.18 : 0.12),
                    child: Text(
                        d.name.isNotEmpty
                            ? d.name.trim()[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 20)),
                  ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(d.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: accent,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: dark ? AppTheme.darkCard2 : AppTheme.bg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(d.kelas,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: dark
                                    ? AppTheme.darkMuted
                                    : AppTheme.textMuted))),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed:
                  d.hasPortfolio ? () => _openPortfolio(context, d) : null,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text(d.hasPortfolio ? 'Lihat Portfolio' : 'Link menyusul',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutApp(bool dark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: dark ? AppTheme.darkCard2 : AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.storefront_rounded,
                  size: 16, color: AppTheme.primary)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Tentang Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ),
        ]),
        const SizedBox(height: 10),
        _aboutRow('Aplikasi', AppBranding.appFullName, dark),
        _aboutRow('Versi', AppBranding.version, dark),
        _aboutRow('Fungsi',
            'Kelola produk, stok, penjualan & restok koperasi siswa', dark),
        _aboutRow('Sekolah', '${DeveloperData.school} • ${DeveloperData.major}',
            dark),
      ]),
    );
  }

  Widget _aboutRow(String k, String v, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 74,
              child: Text(k,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: dark ? AppTheme.darkMuted : AppTheme.textMuted))),
          const Text(':  ',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(v,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: dark ? AppTheme.darkText : AppTheme.textDark))),
        ]),
      );
}
