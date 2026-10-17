import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/app_responsive.dart';
import '../../core/utils/format.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/fields.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/stat_card.dart';

/// Layar transaksi koperasi konsumen: penjualan (stok-) & restok (stok+).
class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});
  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  List<Transaksi> list = [];
  TransaksiSummary? summary;
  List<Produk> produkCache = [];
  bool loading = true;
  String search = '';
  String tipeF = ''; // '' | penjualan | restok
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() => loading = true);
    final scope = AppScope.maybeOf(context);
    if (scope == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    final sRes = await scope.transaksi.summary();
    final lRes = await scope.transaksi
        .list(search: search, tipe: tipeF, limit: 80);
    final pRes = produkCache.isEmpty
        ? await scope.produk.list()
        : const Ok<List<Produk>>([]);
    if (!mounted) return;
    switch (sRes) {
      case Ok(:final data):
        summary = data;
      case Err(:final error):
        showAppMessage(context, error.message, isError: true);
    }
    switch (lRes) {
      case Ok(:final data):
        list = data;
      case Err(:final error):
        showAppMessage(context, error.message, isError: true);
    }
    switch (pRes) {
      case Ok(:final data):
        if (data.isNotEmpty) produkCache = data;
      case Err():
        break;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _refreshProduk() async {
    final res = await AppScope.of(context).produk.list();
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        setState(() => produkCache = data);
      case Err():
        break;
    }
  }

  void _openForm({String initialTipe = 'penjualan', Produk? initial}) {
    if (produkCache.isEmpty) {
      showAppMessage(context, 'Memuat produk…');
      _refreshProduk();
      return;
    }
    Produk? selected = initial ??
        (() {
          try {
            return produkCache.firstWhere((p) => p.stok > 0);
          } catch (_) {
            return produkCache.first;
          }
        })();
    String tipe = initialTipe;
    final jumlahC = TextEditingController(text: '1');
    final hargaC =
        TextEditingController(text: selected.harga.toStringAsFixed(0));
    final ketC = TextEditingController();
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.rLg))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) {
          final dark = Theme.of(c).brightness == Brightness.dark;
          final isJual = tipe == 'penjualan';
          final maxStok = selected?.stok ?? 0;
          final jml = int.tryParse(jumlahC.text.trim()) ?? 0;
          final exceed = isJual && selected != null && jml > maxStok;
          final total =
              (double.tryParse(hargaC.text.trim()) ?? selected?.harga ?? 0) *
                  jml;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(c).viewInsets.bottom,
                left: 18,
                right: 18,
                top: 14),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                        child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                                color: dark
                                    ? AppTheme.darkBorder
                                    : AppTheme.border,
                                borderRadius:
                                    BorderRadius.circular(4)))),
                    const SizedBox(height: 14),
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              gradient: isJual
                                  ? AppTheme.heroGradient
                                  : const LinearGradient(colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFFA78BFA)
                                    ]),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                              isJual
                                  ? Icons.point_of_sale_rounded
                                  : Icons.inventory_rounded,
                              color: Colors.white,
                              size: 18)),
                      const SizedBox(width: 11),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(isJual
                                ? 'Penjualan Baru'
                                : 'Restok Baru',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5)),
                            Text(
                                isJual
                                    ? 'Stok berkurang otomatis'
                                    : 'Stok bertambah otomatis',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: dark
                                        ? AppTheme.darkMuted
                                        : AppTheme.textMuted))
                          ])),
                      const SizedBox(width: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'penjualan',
                              icon: Icon(Icons.sell_rounded,
                                  size: 14),
                              label: Text('Jual',
                                  style: TextStyle(fontSize: 11))),
                          ButtonSegment(
                              value: 'restok',
                              icon:
                                  Icon(Icons.add_box_rounded, size: 14),
                              label: Text('Restok',
                                  style: TextStyle(fontSize: 11))),
                        ],
                        selected: {tipe},
                        onSelectionChanged: (s) => setS(() {
                          tipe = s.first;
                        }),
                        showSelectedIcon: false,
                        style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<Produk>(
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Produk *',
                          prefixIcon:
                              Icon(Icons.inventory_2_outlined)),
                      items: produkCache
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                  '${p.nama} — stok ${p.stok} • ${rupiah(p.harga)}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        setS(() {
                          selected = v;
                          hargaC.text =
                              v!.harga.toStringAsFixed(0);
                        });
                      },
                    ),
                    if (selected != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(
                              color: dark
                                  ? AppTheme.darkCard2
                                  : AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(11)),
                          child: Row(children: [
                            Icon(
                                selected!.stok <= 0
                                    ? Icons.block_rounded
                                    : Icons.layers_rounded,
                                size: 15,
                                color: selected!.stok <= 0
                                    ? AppTheme.danger
                                    : AppTheme.primary),
                            const SizedBox(width: 7),
                            Expanded(
                                child: Text(
                                    'Stok saat ini: ${selected!.stok} • ${selected!.status}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700))),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: jumlahC,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setS(() {}),
                          decoration: InputDecoration(
                            labelText:
                                isJual ? 'Jumlah jual *' : 'Jumlah restok *',
                            prefixIcon:
                                const Icon(Icons.numbers_rounded),
                            errorText: exceed
                                ? 'Melebihi stok ($maxStok)'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: hargaC,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setS(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Harga/satuan',
                              prefixText: 'Rp ',
                              prefixIcon:
                                  Icon(Icons.payments_outlined)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    TextField(
                        controller: ketC,
                        decoration: const InputDecoration(
                            labelText: 'Keterangan (opsional)',
                            hintText: 'contoh: jual ke kelas 10A',
                            prefixIcon: Icon(Icons.note_outlined)),
                        maxLines: 1),
                    const SizedBox(height: 8),
                    Text('Estimasi total: ${rupiah(total)}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isJual
                                ? AppTheme.primary
                                : AppTheme.restok)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: isJual
                                ? AppTheme.primary
                                : AppTheme.restok),
                        onPressed: saving || exceed
                            ? null
                            : () async {
                                final j = int.tryParse(
                                        jumlahC.text.trim()) ??
                                    0;
                                final sel = selected;
                                if (sel == null || j <= 0) {
                                  ScaffoldMessenger.of(c).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Produk & jumlah wajib benar')));
                                  return;
                                }
                                if (isJual && j > sel.stok) {
                                  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                                      content: Text(
                                          'Stok tidak cukup (sisa ${sel.stok})')));
                                  return;
                                }
                                setS(() => saving = true);
                                final res = await AppScope.of(
                                        context)
                                    .transaksi
                                    .create(
                                        produkId: sel.id,
                                        tipe: tipe,
                                        jumlah: j,
                                        hargaSatuan: double.tryParse(
                                            hargaC.text.trim()),
                                        keterangan:
                                            ketC.text.trim());
                                if (!mounted) return;
                                switch (res) {
                                  case Ok():
                                    if (c.mounted) {
                                      Navigator.pop(c);
                                    }
                                    await load();
                                    if (mounted) {
                                      showAppMessage(context,
                                          isJual
                                              ? 'Penjualan dicatat'
                                              : 'Restok dicatat');
                                    }
                                  case Err(:final error):
                                    if (c.mounted) {
                                      ScaffoldMessenger.of(c)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  error.message)));
                                    }
                                }
                                setS(() => saving = false);
                              },
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text(isJual
                                ? 'CATAT PENJUALAN'
                                : 'CATAT RESTOK'),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _batalkan(Transaksi t) async {
    final ok = await confirmDestructive(context,
        title: t.isRestok ? 'Batalkan restok?' : 'Batalkan penjualan?',
        message:
            'Stok "${t.namaProduk}" dikembalikan ke ${t.stokSebelum}. Lanjut?',
        confirmLabel: 'Batalkan');
    if (ok != true || !mounted) return;
    final scope = AppScope.of(context);
    final res = await scope.transaksi.delete(t.id);
    if (!mounted) return;
    switch (res) {
      case Ok():
        await load();
        // ignore: use_build_context_synchronously
        showAppMessage(context, 'Transaksi dibatalkan & stok dipulihkan');
      case Err(:final error):
        showAppMessage(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: AppResponsive.contentMaxWidth(context) + 40),
        child: Column(children: [
          _toolbar(dark),
          _tipeFilter(dark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: load,
              child: loading
                  ? const LoadingList()
                  : ListView(
                      padding:
                          const EdgeInsets.fromLTRB(14, 8, 14, 18),
                      children: [
                        if (summary != null) ...[
                          _summaryGrid(dark),
                          const SizedBox(height: 12),
                          if (summary!.topProduk.isNotEmpty)
                            _topProduk(dark),
                          if (summary!.topProduk.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        Row(children: [
                          StatusBadge(
                              label:
                                  '${list.length} ${tipeF.isEmpty ? 'transaksi' : tipeF}',
                              color: dark
                                  ? AppTheme.darkMuted
                                  : AppTheme.textMuted,
                              icon: Icons.receipt_long_rounded),
                          const Spacer(),
                          TextButton.icon(
                              onPressed: load,
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 15),
                              label: const Text('Refresh',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 6),
                        if (list.isEmpty)
                          EmptyState(
                            icon: Icons.point_of_sale_outlined,
                            title: 'Belum ada transaksi',
                            subtitle:
                                'Catat penjualan untuk mengurangi stok, atau restok untuk menambah stok.',
                            actionLabel: 'Catat Transaksi',
                            onAction: () => _openForm(),
                          ),
                        ...list.map((t) => _trxTile(t, dark)),
                      ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _toolbar(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(children: [
        Expanded(
          child: SearchField(
            controller: searchCtrl,
            hint: 'Cari kode, produk...',
            onSubmitted: (v) {
              search = v.trim();
              load();
            },
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Catat'),
        ),
      ]),
    );
  }

  Widget _tipeFilter(bool dark) {
    Widget chip(String label, String v, IconData icon) {
      final sel = tipeF == v;
      final color = v == ''
          ? AppTheme.primary
          : v == 'penjualan'
              ? AppTheme.primary
              : AppTheme.restok;
      return GestureDetector(
        onTap: () {
          setState(() => tipeF = v);
          load();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? color : (dark ? AppTheme.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: sel
                      ? color
                      : (dark ? AppTheme.darkBorder : AppTheme.border))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 13,
                color: sel
                    ? Colors.white
                    : (dark ? AppTheme.darkMuted : AppTheme.textMuted)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel
                        ? Colors.white
                        : (dark
                            ? AppTheme.darkMuted
                            : AppTheme.textMuted))),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(children: [
        chip('Semua', '', Icons.receipt_long_rounded),
        const SizedBox(width: 7),
        chip('Penjualan', 'penjualan', Icons.point_of_sale_rounded),
        const SizedBox(width: 7),
        chip('Restok', 'restok', Icons.inventory_rounded),
      ]),
    );
  }

  Widget _summaryGrid(bool dark) {
    final s = summary!;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 900 ? 4 : 2;
      const gap = 10.0;
      final cw = (w - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        SizedBox(
            width: cw,
            child: StatCard(
                title: 'JUAL HARI INI',
                value: '${s.penjualanHariIni} trx',
                subtitle: rupiah(s.omsetHariIni),
                icon: Icons.today_rounded,
                color: AppTheme.primary)),
        SizedBox(
            width: cw,
            child: StatCard(
                title: 'JUAL BULAN INI',
                value: '${s.penjualanBulan} trx',
                subtitle: rupiah(s.omsetBulan),
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF2563EB))),
        SizedBox(
            width: cw,
            child: StatCard(
                title: 'RESTOK BULAN',
                value: '${s.restokBulan} kali',
                subtitle: rupiah(s.nilaiRestokBulan),
                icon: Icons.inventory_rounded,
                color: AppTheme.restok)),
        SizedBox(
            width: cw,
            child: StatCard(
                title: 'TOTAL TRANSAKSI',
                value: '${s.totalTransaksi}',
                subtitle: '${s.topProduk.length} produk laris',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.success)),
      ]);
    });
  }

  Widget _topProduk(bool dark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.leaderboard_rounded,
              size: 16, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Terlaris',
              style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        ]),
        const SizedBox(height: 10),
        ...summary!.topProduk.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Expanded(
                  child: Text(m['nama_produk']?.toString() ?? '-',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              StatusBadge(
                  label: '${m['total_qty']} terjual',
                  color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(rupiah((m['total_nilai'] as num?) ?? 0),
                  style: TextStyle(
                      fontSize: 11.5,
                      color: dark
                          ? AppTheme.darkMuted
                          : AppTheme.textMuted)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _trxTile(Transaksi t, bool dark) {
    final isRestok = t.isRestok;
    final color = isRestok ? AppTheme.restok : AppTheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                isRestok
                    ? Icons.inventory_rounded
                    : Icons.point_of_sale_rounded,
                size: 18,
                color: color)),
        title: Row(children: [
          Expanded(
              child: Text(t.namaProduk,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 6),
          StatusBadge(
              label: isRestok ? 'RESTOK' : 'JUAL', color: color),
        ]),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 3),
          Text('${t.kode} • ${tglPanjang(t.createdAt)}',
              style: TextStyle(
                  fontSize: 11,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
          const SizedBox(height: 5),
          Wrap(spacing: 6, runSpacing: 4, children: [
            StatusBadge(
                label: '${t.jumlah} pcs',
                color: dark ? AppTheme.darkMuted : AppTheme.textMuted),
            StatusBadge(
                label: rupiah(t.total),
                color: color,
                icon: Icons.payments_outlined),
            StatusBadge(
                label: 'Stok ${t.stokSebelum} → ${t.stokSesudah}',
                color: dark ? AppTheme.darkMuted : AppTheme.textMuted,
                icon: isRestok
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded),
          ]),
          if (t.keterangan.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t.keterangan,
                    style: TextStyle(
                        fontSize: 11.5,
                        color:
                            dark ? AppTheme.darkMuted : AppTheme.textMuted,
                        fontStyle: FontStyle.italic))),
        ]),
        trailing: IconButton(
          icon: Icon(Icons.more_vert_rounded,
              size: 18,
              color: dark ? AppTheme.darkMuted : AppTheme.textMuted),
          onPressed: () => _batalkan(t),
          tooltip: 'Batalkan & pulihkan stok',
        ),
      ),
    );
  }
}
