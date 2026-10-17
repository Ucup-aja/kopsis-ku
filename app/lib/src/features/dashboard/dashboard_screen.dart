import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/app_responsive.dart';
import '../../core/utils/format.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/fields.dart';
import '../developer/developer_page.dart';

/// Dashboard koperasi konsumen: ringkasan toko + penjualan/restok.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final scope = AppScope.maybeOf(context);
    if (scope == null) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Layanan tidak tersedia.';
        });
      }
      return;
    }
    final res = await scope.dashboard.fetch();
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        setState(() {
          this.data = data;
          loading = false;
        });
      case Err(:final error):
        setState(() {
          this.error = error.message;
          loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: AppResponsive.contentMaxWidth(context) + 40),
          child: ListView(
            padding: AppResponsive.pagePadding(context),
            children: [
              _hero(dark),
              const SizedBox(height: 12),
              _developerMenu(dark),
              const SizedBox(height: 16),
              if (loading) const LoadingList(rows: 4),
              if (error != null) ErrorState(message: error!, onRetry: load),
              if (!loading && data != null) ...[
                _statsGrid(),
                const SizedBox(height: 16),
                if (data!.recentTransaksi.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Aktivitas Terbaru',
                    subtitle: 'Penjualan & restok terakhir',
                    action: 'Lihat semua',
                    onAction: () => _goTransaksi(),
                  ),
                  const SizedBox(height: 10),
                  _recentTransaksi(dark),
                  const SizedBox(height: 16),
                ],
                if (data!.byKategori.isNotEmpty) ...[
                  const SectionHeader(
                      title: 'Kategori', subtitle: 'Sebaran produk toko'),
                  const SizedBox(height: 10),
                  _kategoriChips(dark),
                  const SizedBox(height: 16),
                ],
                if (data!.stokMenipis.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Stok Menipis',
                    subtitle: 'Sisa ≤ 5 — segera restok',
                    action: '${data!.stokMenipis.length} produk',
                  ),
                  const SizedBox(height: 10),
                  ...data!.stokMenipis.map((p) => _lowStockTile(p, dark)),
                  const SizedBox(height: 16),
                ],
                const SectionHeader(
                    title: 'Produk Terbaru', subtitle: 'Terakhir diperbarui'),
                const SizedBox(height: 10),
                if (data!.recentProduk.isEmpty)
                  EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada produk',
                    subtitle: 'Tambahkan produk pertama toko koperasi.',
                    actionLabel: 'Kelola Produk',
                    onAction: () => _goProduk(),
                  )
                else
                  _recentGrid(dark),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _goTransaksi() {
    // MainShell memakai index; sederhananya tampilkan info.
    // Navigasi antar-tab dilakukan via shell — di sini cukup refresh.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Buka tab Transaksi untuk detail'),
        behavior: SnackBarBehavior.floating));
  }

  void _goProduk() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Buka tab Produk untuk menambah'),
        behavior: SnackBarBehavior.floating));
  }

  Widget _developerMenu(bool dark) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const DeveloperPage())),
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(dark: dark),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.groups_rounded,
                  color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tim Developer',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: dark ? AppTheme.darkText : AppTheme.textDark)),
              const SizedBox(height: 2),
              Text('Siswa PPLG • SMKN 1 Leuwimunding',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? AppTheme.darkMuted : AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: dark ? AppTheme.darkCard2 : AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Lihat',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: dark ? AppTheme.darkPrimary : AppTheme.primary)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 14,
                    color: dark ? AppTheme.darkPrimary : AppTheme.primary)
              ])),
        ]),
      ),
    );
  }

  // ---------- sections ----------

  Widget _hero(bool dark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
      ),
      child: LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 360;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('KOPSIS KU',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 10),
                  Text('Koperasi kebutuhan siswa\nSMKN 1 Leuwimunding',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: narrow ? 19 : 23,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  Text(
                      data == null
                          ? 'Memuat ringkasan toko…'
                          : '${data!.totalProduk} produk • ${data!.totalStok} stok • ${rupiah(data!.omsetHari)} hari ini',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _heroBtn(Icons.refresh_rounded, 'Refresh', load),
                    _heroBtn(
                        Icons.receipt_long_rounded,
                        'Transaksi Hari Ini: ${data?.transaksiHari ?? 0}',
                        () => _goTransaksi(),
                        ghost: true),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: const Icon(Icons.storefront_rounded,
                  color: Colors.white, size: 38),
            ),
          ],
        );
      }),
    );
  }

  Widget _heroBtn(IconData icon, String label, VoidCallback onTap,
      {bool ghost = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: ghost ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: ghost
                ? Border.all(color: Colors.white.withValues(alpha: 0.5))
                : null),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: ghost ? Colors.white : AppTheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: ghost ? Colors.white : AppTheme.primary)),
          ),
        ]),
      ),
    );
  }

  Widget _statsGrid() {
    final d = data!;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 900 ? 4 : 2;
      const gap = 10.0;
      final cw = (w - gap * (cols - 1)) / cols;
      final cards = [
        StatCard(
            title: 'TOTAL PRODUK',
            value: '${d.totalProduk}',
            subtitle: '${d.produkTersedia} tersedia',
            icon: Icons.inventory_2_rounded,
            color: AppTheme.primary),
        StatCard(
            title: 'TOTAL STOK',
            value: '${d.totalStok}',
            subtitle: 'item di toko',
            icon: Icons.layers_rounded,
            color: AppTheme.success),
        StatCard(
            title: 'NILAI STOK',
            value: rupiah(d.nilaiStok),
            subtitle: 'harga × stok',
            icon: Icons.account_balance_wallet_rounded,
            color: AppTheme.warning),
        StatCard(
            title: 'PERLU RESTOK',
            value: '${d.produkHabis}',
            subtitle: 'habis / stok 0',
            icon: Icons.warning_amber_rounded,
            color: d.produkHabis > 0 ? AppTheme.danger : AppTheme.success),
        StatCard(
            title: 'JUAL HARI INI',
            value: '${d.transaksiHari}',
            subtitle: rupiah(d.omsetHari),
            icon: Icons.point_of_sale_rounded,
            color: const Color(0xFF2563EB)),
        StatCard(
            title: 'OMSET BULAN',
            value: rupiah(d.omsetBulan),
            subtitle: '${d.transaksiBulan} penjualan',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF7C3AED)),
        StatCard(
            title: 'RESTOK BULAN',
            value: '${d.restokBulan}',
            subtitle: 'penambahan stok',
            icon: Icons.inventory_rounded,
            color: AppTheme.restok),
        StatCard(
            title: 'KATEGORI',
            value: '${d.byKategori.length}',
            subtitle: 'jenis produk',
            icon: Icons.category_rounded,
            color: AppTheme.textMuted),
      ];
      return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((e) => SizedBox(width: cw, child: e)).toList());
    });
  }

  Widget _recentTransaksi(bool dark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: Column(
        children: data!.recentTransaksi.take(5).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final tipe = m['tipe']?.toString() ?? 'penjualan';
          final isRestok = tipe == 'restok';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: (isRestok ? AppTheme.restok : AppTheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(isRestok ? 'RESTOK' : 'JUAL',
                    style: TextStyle(
                        color: isRestok ? AppTheme.restok : AppTheme.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(m['nama_produk']?.toString() ?? '-',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('${m['jumlah']} • ${rupiah((m['total'] as num?) ?? 0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _kategoriChips(bool dark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data!.byKategori.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final k = m['kategori']?.toString() ?? 'lainnya';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: AppTheme.cardDecoration(dark: dark, radius: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.category_rounded,
                size: 14, color: AppTheme.primary),
            const SizedBox(width: 7),
            Text(k.replaceAll('_', ' '),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppTheme.darkText : AppTheme.textDark)),
            Text('  ${m['c']} • ${m['stok']} stok',
                style: TextStyle(
                    fontSize: 11.5,
                    color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _lowStockTile(Produk p, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rSm),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
              width: 48, height: 48, child: ProductImage(url: p.displayFoto)),
        ),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${p.kategori.replaceAll('_', ' ')} • ${rupiah(p.harga)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted))
        ])),
        StatusBadge(
            label: 'Sisa ${p.stok}',
            color: AppTheme.danger,
            icon: Icons.warning_amber_rounded),
      ]),
    );
  }

  Widget _recentGrid(bool dark) {
    return LayoutBuilder(builder: (context, c) {
      final cols = AppResponsive.gridCols(context,
          mobileCols: 2, tabletCols: 3, desktopCols: 4);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.76),
        itemCount: data!.recentProduk.length,
        itemBuilder: (_, i) => _productCard(data!.recentProduk[i], dark),
      );
    });
  }

  Widget _productCard(Produk p, bool dark) {
    return Container(
      decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: ProductImage(url: p.displayFoto)),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5)),
            Text(p.kategori.replaceAll('_', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                  child: Text(rupiah(p.harga),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: AppTheme.primary))),
              StatusBadge(
                  label: 'stok ${p.stok}',
                  color: p.isHabis
                      ? AppTheme.danger
                      : p.isLow
                          ? AppTheme.warning
                          : AppTheme.success),
            ]),
          ]),
        ),
      ]),
    );
  }
}
