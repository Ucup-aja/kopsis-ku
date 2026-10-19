import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/app.dart';
import '../../core/error/result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/app_responsive.dart';
import '../../core/utils/format.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/fields.dart';
import '../../shared/widgets/app_states.dart';

/// Katalog produk koperasi konsumen: cari, filter, tambah/edit,
/// jual (stok-) & restok (stok+) cepat.
class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});
  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  List<Produk> list = [];
  bool loading = true;
  String search = '';
  String kategoriF = '';
  String statusF = '';
  final searchCtrl = TextEditingController();
  final picker = ImagePicker();
  bool gridView = true;

  static const kategoris = [
    'alat_tulis',
    'seragam',
    'makanan',
    'minuman',
    'buku',
    'lainnya'
  ];

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
    final res = await scope.produk.list(
        search: search, kategori: kategoriF, status: statusF);
    if (!mounted) return;
    switch (res) {
      case Ok(:final data):
        setState(() {
          list = data;
          loading = false;
        });
      case Err(:final error):
        setState(() => loading = false);
        showAppMessage(context, error.message, isError: true);
    }
  }

  // ---------- form tambah/edit ----------

  void openForm({Produk? p}) {
    final nama = TextEditingController(text: p?.nama ?? '');
    final harga = TextEditingController(
        text: p != null ? p.harga.toStringAsFixed(0) : '');
    final stok =
        TextEditingController(text: p != null ? p.stok.toString() : '');
    final desk = TextEditingController(text: p?.deskripsi ?? '');
    String kategori = p?.kategori ?? kategoris.first;
    String status = p?.status ?? 'tersedia';
    File? fotoFile;
    bool hapusFoto = false;
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
          final fotoUrl = p?.displayFoto ?? '';
          final hasExisting =
              fotoUrl.isNotEmpty && !hapusFoto && fotoFile == null;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(c).viewInsets.bottom,
                left: 18,
                right: 18,
                top: 14),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 560),
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
                                borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 14),
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              gradient: AppTheme.heroGradient,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                              p == null
                                  ? Icons.add_box_rounded
                                  : Icons.edit_rounded,
                              color: Colors.white,
                              size: 18)),
                      const SizedBox(width: 11),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(p == null ? 'Tambah Produk' : 'Edit Produk',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text(
                                'KopsisKu • foto opsional',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: dark
                                        ? AppTheme.darkMuted
                                        : AppTheme.textMuted)),
                          ])),
                    ]),
                    const SizedBox(height: 16),
                    _fotoPicker(c, setS, dark, fotoFile, hasExisting,
                        fotoUrl, (f, h) {
                      fotoFile = f;
                      hapusFoto = h;
                    }),
                    const SizedBox(height: 14),
                    TextField(
                        controller: nama,
                        decoration: const InputDecoration(
                            labelText: 'Nama produk *',
                            hintText: 'Contoh: Buku Tulis 58 lembar',
                            prefixIcon:
                                Icon(Icons.inventory_2_outlined))),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: kategori,
                      decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(Icons.category_outlined)),
                      items: kategoris
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (v) => setS(() => kategori = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: harga,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Harga *',
                                  prefixText: 'Rp ',
                                  prefixIcon:
                                      Icon(Icons.payments_outlined)))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: stok,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Stok awal *',
                                  prefixIcon:
                                      Icon(Icons.layers_outlined)))),
                    ]),
                    const SizedBox(height: 10),
                    TextField(
                        controller: desk,
                        decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            hintText: 'Keterangan singkat',
                            prefixIcon:
                                Icon(Icons.description_outlined)),
                        maxLines: 2),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.toggle_on_outlined)),
                      items: const [
                        DropdownMenuItem(
                            value: 'tersedia', child: Text('Tersedia')),
                        DropdownMenuItem(
                            value: 'habis', child: Text('Habis')),
                        DropdownMenuItem(
                            value: 'arsip', child: Text('Arsip'))
                      ],
                      onChanged: (v) => setS(() => status = v!),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () => _save(p, nama.text, kategori,
                                harga.text, stok.text, desk.text,
                                status, fotoFile, hapusFoto, c, setS,
                                (v) => setS(() => saving = v)),
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text(p == null
                                ? 'SIMPAN PRODUK'
                                : 'PERBARUI PRODUK'),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fotoPicker(
      BuildContext c,
      StateSetter setS,
      bool dark,
      File? fotoFile,
      bool hasExisting,
      String fotoUrl,
      void Function(File?, bool) onChange) {
    Future<void> pick() async {
      final src = await showModalBottomSheet<String>(
        context: c,
        builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(c, 'gallery')),
          ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(c, 'camera'))
        ])),
      );
      if (src == null) return;
      final x = await picker.pickImage(
          source:
              src == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1200);
      if (x != null) setS(() => onChange(File(x.path), false));
    }

    return GestureDetector(
      onTap: pick,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
            color: dark ? AppTheme.darkCard2 : AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(
                color: dark ? AppTheme.darkBorder : AppTheme.border)),
        clipBehavior: Clip.antiAlias,
        child: fotoFile != null
            ? Stack(children: [
                Image.file(fotoFile,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover),
                Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                        onTap: () => setS(() => onChange(null, false)),
                        child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white))))
              ])
            : hasExisting
                ? Stack(children: [
                    buildFoto(fotoUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        onError: _placeholder),
                    Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                            onTap: () =>
                                setS(() => onChange(null, true)),
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                child: const Text('Hapus foto',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))))),
                    const Positioned(
                        bottom: 8,
                        left: 8,
                        child: _TapHint()),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.add_a_photo_rounded,
                            size: 28,
                            color: AppTheme.primary
                                .withValues(alpha: 0.85)),
                        const SizedBox(height: 6),
                        Text('Tap untuk tambah foto produk',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark
                                    ? AppTheme.darkMuted
                                    : AppTheme.textMuted)),
                        const Text('JPG / PNG / WEBP • max 5MB',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted))
                      ]),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: AppTheme.primarySoft,
      child: Icon(Icons.image_rounded,
          color: AppTheme.primary.withValues(alpha: 0.6), size: 26));

  Future<void> _save(
      Produk? p,
      String nama,
      String kategori,
      String hargaS,
      String stokS,
      String desk,
      String status,
      File? fotoFile,
      bool hapusFoto,
      BuildContext c,
      StateSetter setS,
      void Function(bool) setSaving) async {
    if (nama.trim().isEmpty || hargaS.trim().isEmpty || stokS.trim().isEmpty) {
      ScaffoldMessenger.of(c).showSnackBar(
          const SnackBar(content: Text('Nama, harga, stok wajib diisi')));
      return;
    }
    setSaving(true);
    try {
      final h = double.tryParse(hargaS) ?? 0;
      final s = int.tryParse(stokS) ?? 0;
      final repo = AppScope.of(context).produk;
      final res = p == null
          ? await repo.create(
              nama: nama.trim(),
              kategori: kategori,
              harga: h,
              stok: s,
              deskripsi: desk.trim(),
              status: status,
              foto: fotoFile)
          : await repo.update(p.id,
              nama: nama.trim(),
              kategori: kategori,
              harga: h,
              stok: s,
              deskripsi: desk.trim(),
              status: status,
              foto: fotoFile,
              hapusFoto: hapusFoto);
      if (!mounted) return;
      switch (res) {
        case Ok():
          if (c.mounted) Navigator.pop(c);
          await load();
          if (mounted) {
            showAppMessage(context,
                p == null ? 'Produk ditambahkan' : 'Produk diperbarui');
          }
        case Err(:final error):
          if (c.mounted) {
            ScaffoldMessenger.of(c)
                .showSnackBar(SnackBar(content: Text(error.message)));
          }
      }
    } finally {
      setSaving(false);
    }
  }

  Future<void> _confirmDelete(Produk p) async {
    final ok = await confirmDestructive(context,
        title: 'Hapus produk?',
        message: '"${p.nama}" akan dihapus permanen dari katalog.');
    if (ok != true || !mounted) return;
    final scope = AppScope.of(context);
    final res = await scope.produk.delete(p.id);
    if (!mounted) return;
    switch (res) {
      case Ok():
        await load();
        // ignore: use_build_context_synchronously
        showAppMessage(context, 'Produk dihapus');
      case Err(:final error):
        showAppMessage(context, error.message, isError: true);
    }
  }

  // ---------- jual / restok cepat ----------

  void _quickStock(Produk p, String tipe) {
    final jC = TextEditingController(text: '1');
    final hC = TextEditingController(text: p.harga.toStringAsFixed(0));
    final kC = TextEditingController();
    final isJual = tipe == 'penjualan';
    bool saving = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.rLg))),
      builder: (ctx) => StatefulBuilder(builder: (c, setS) {
        final dark = Theme.of(c).brightness == Brightness.dark;
        final jml = int.tryParse(jC.text.trim()) ?? 0;
        final exceed = isJual && jml > p.stok;
        final total = (double.tryParse(hC.text.trim()) ?? p.harga) * jml;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 18,
              right: 18,
              top: 14),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                            color:
                                dark ? AppTheme.darkBorder : AppTheme.border,
                            borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: (isJual
                                  ? AppTheme.primary
                                  : AppTheme.restok)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                          isJual
                              ? Icons.point_of_sale_rounded
                              : Icons.inventory_rounded,
                          color: isJual
                              ? AppTheme.primary
                              : AppTheme.restok,
                          size: 18)),
                  const SizedBox(width: 11),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(isJual ? 'Jual Cepat' : 'Restok Cepat',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        Text(
                            '${p.nama} • stok ${p.stok}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? AppTheme.darkMuted
                                    : AppTheme.textMuted))
                      ]))
                ]),
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(
                        color: dark
                            ? AppTheme.darkCard2
                            : AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(11)),
                    child: Text(
                        isJual
                            ? 'Penjualan mengurangi stok otomatis'
                            : 'Restok menambah stok otomatis',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? AppTheme.darkText
                                : AppTheme.textDark))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: jC,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setS(() {}),
                          decoration: InputDecoration(
                              labelText:
                                  isJual ? 'Jumlah jual *' : 'Jumlah restok *',
                              prefixIcon:
                                  const Icon(Icons.numbers_rounded),
                              errorText: exceed
                                  ? 'Melebihi stok (${p.stok})'
                                  : null))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: hC,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setS(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Harga/satuan',
                              prefixText: 'Rp ',
                              prefixIcon:
                                  Icon(Icons.payments_outlined))))
                ]),
                const SizedBox(height: 10),
                TextField(
                    controller: kC,
                    decoration: const InputDecoration(
                        labelText: 'Keterangan (opsional)',
                        prefixIcon: Icon(Icons.note_outlined)),
                    maxLines: 1),
                const SizedBox(height: 8),
                Text('Estimasi total: ${rupiah(total)}',
                    style: TextStyle(
                        fontSize: 12.5,
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
                        onPressed: saving || exceed || jml <= 0
                            ? null
                            : () async {
                                setS(() => saving = true);
                                final res = await AppScope.of(context)
                                    .transaksi
                                    .create(
                                        produkId: p.id,
                                        tipe: tipe,
                                        jumlah: jml,
                                        hargaSatuan: double.tryParse(
                                            hC.text.trim()),
                                        keterangan: kC.text.trim());
                                if (!mounted) return;
                                switch (res) {
                                  case Ok():
                                    if (c.mounted) Navigator.pop(c);
                                    await load();
                                    if (mounted) {
                                      showAppMessage(context,
                                          isJual
                                              ? 'Penjualan dicatat'
                                              : 'Restok dicatat');
                                    }
                                  case Err(:final error):
                                    if (c.mounted) {
                                      ScaffoldMessenger.of(c).showSnackBar(
                                          SnackBar(
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
                                : 'CATAT RESTOK'))),
                const SizedBox(height: 22),
              ]),
        );
      }),
    );
  }

  // ---------- layout ----------

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
          _filterRow(dark),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(children: [
                StatusBadge(
                    label: '${list.length} produk',
                    color:
                        dark ? AppTheme.darkMuted : AppTheme.textMuted),
                const Spacer(),
                if (!loading)
                  TextButton.icon(
                      onPressed: load,
                      icon: const Icon(Icons.refresh_rounded, size: 15),
                      label: const Text('Refresh',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700)))
              ])),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: load,
              child: loading
                  ? const LoadingList()
                  : list.isEmpty
                      ? ListView(children: [
                          EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'Belum ada produk',
                            subtitle:
                                'Tambahkan produk pertama koperasi konsumen dengan foto, harga, dan stok.',
                            actionLabel: 'Tambah Produk',
                            onAction: () => openForm(),
                          )
                        ])
                      : gridView
                          ? _grid(dark)
                          : _list(dark),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _toolbar(bool dark) {
    return LayoutBuilder(builder: (context, cons) {
      final narrow = cons.maxWidth < 400;
      final searchField = SearchField(
        controller: searchCtrl,
        hint: 'Cari produk...',
        onSubmitted: (v) {
          search = v.trim();
          load();
        },
      );
      final toggle = Container(
        decoration: BoxDecoration(
            color: dark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: dark ? AppTheme.darkBorder : AppTheme.border)),
        child: IconButton(
            onPressed: () => setState(() => gridView = !gridView),
            icon: Icon(
                gridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                size: 20,
                color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
      );
      if (narrow) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Column(children: [
            Row(children: [
              Expanded(child: searchField),
              const SizedBox(width: 8),
              toggle
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => openForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Produk'),
              ),
            ),
          ]),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Row(children: [
          Expanded(child: searchField),
          const SizedBox(width: 8),
          FilledButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah')),
          const SizedBox(width: 8),
          toggle,
        ]),
      );
    });
  }

  Widget _filterRow(bool dark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(children: [
        _chip('Semua', kategoriF == '', () {
          setState(() => kategoriF = '');
          load();
        }, dark),
        ...kategoris.map((k) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _chip(k.replaceAll('_', ' '), kategoriF == k, () {
              setState(() => kategoriF = k);
              load();
            }, dark))),
        const SizedBox(width: 8),
        Container(
            height: 22,
            width: 1,
            color: dark ? AppTheme.darkBorder : AppTheme.border),
        const SizedBox(width: 8),
        _chip('Tersedia', statusF == 'tersedia', () {
          setState(
              () => statusF = statusF == 'tersedia' ? '' : 'tersedia');
          load();
        }, dark, activeColor: AppTheme.success),
        const SizedBox(width: 6),
        _chip('Habis', statusF == 'habis', () {
          setState(() => statusF = statusF == 'habis' ? '' : 'habis');
          load();
        }, dark, activeColor: AppTheme.danger),
      ]),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap, bool dark,
      {Color? activeColor}) {
    final c = activeColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? c : (dark ? AppTheme.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: sel
                    ? c
                    : (dark ? AppTheme.darkBorder : AppTheme.border))),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel
                    ? Colors.white
                    : (dark ? AppTheme.darkMuted : AppTheme.textMuted))),
      ),
    );
  }

  Widget _grid(bool dark) {
    return LayoutBuilder(builder: (context, cons) {
      final cols = AppResponsive.gridCols(context,
          mobileCols: 2, tabletCols: 3, desktopCols: 4);
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.68),
        itemCount: list.length,
        itemBuilder: (_, i) => _gridCard(list[i], dark),
      );
    });
  }

  Widget _gridCard(Produk p, bool dark) {
    return GestureDetector(
      onTap: () => openForm(p: p),
      child: Container(
        decoration:
            AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                  child: ProductImage(url: p.displayFoto)),
              Positioned(
                  top: 8,
                  left: 8,
                  child: StatusBadge(
                      label: p.status.toUpperCase(),
                      color: p.status == 'tersedia'
                          ? AppTheme.success
                          : p.status == 'habis'
                              ? AppTheme.danger
                              : AppTheme.textMuted)),
              Positioned(
                  bottom: 8,
                  right: 8,
                  child: StatusBadge(
                      label: 'stok ${p.stok}',
                      color: p.isHabis
                          ? AppTheme.danger
                          : p.isLow
                              ? AppTheme.warning
                              : AppTheme.textMuted)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text(p.kategori.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          dark ? AppTheme.darkMuted : AppTheme.textMuted)),
              const SizedBox(height: 3),
              Text(rupiah(p.harga),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: AppTheme.primary)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => openForm(p: p),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 7),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10))),
                        child: const Text('Edit',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700)))),
                const SizedBox(width: 6),
                _iconBtn(Icons.remove_shopping_cart_rounded,
                    AppTheme.primary, AppTheme.primarySoft,
                    () => _quickStock(p, 'penjualan'), dark),
                const SizedBox(width: 6),
                _iconBtn(Icons.add_box_rounded, AppTheme.restok,
                    AppTheme.restok.withValues(alpha: 0.12),
                    () => _quickStock(p, 'restok'), dark),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(p),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 14, color: AppTheme.danger),
                  label: const Text('Hapus',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color fg, Color bg, VoidCallback onTap,
      bool dark) {
    return SizedBox(
        height: 33,
        width: 33,
        child: IconButton.filledTonal(
            onPressed: onTap,
            icon: Icon(icon, size: 15),
            style: IconButton.styleFrom(
                backgroundColor: dark ? AppTheme.darkCard2 : bg,
                foregroundColor: fg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)))));
  }

  Widget _list(bool dark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _listCard(list[i], dark),
    );
  }

  Widget _listCard(Produk p, bool dark) {
    return GestureDetector(
      onTap: () => openForm(p: p),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: AppTheme.cardDecoration(dark: dark),
        child: Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ProductImage(url: p.displayFoto))),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(p.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                StatusBadge(
                    label: p.status,
                    color: p.status == 'tersedia'
                        ? AppTheme.success
                        : AppTheme.danger)
              ]),
              const SizedBox(height: 2),
              Text(
                  '${p.kategori.replaceAll('_', ' ')} • ${rupiah(p.harga)} • Stok ${p.stok}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      color:
                          dark ? AppTheme.darkMuted : AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _miniAction('Edit', Icons.edit_outlined,
                    () => openForm(p: p), dark),
                _miniAction('Jual', Icons.point_of_sale_rounded,
                    () => _quickStock(p, 'penjualan'), dark,
                    color: AppTheme.primary),
                _miniAction('Restok', Icons.add_box_rounded,
                    () => _quickStock(p, 'restok'), dark,
                    color: AppTheme.restok),
                _miniAction('Hapus', Icons.delete_outline_rounded,
                    () => _confirmDelete(p), dark,
                    color: AppTheme.danger),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _miniAction(String label, IconData icon, VoidCallback onTap,
      bool dark,
      {Color? color}) {
    final c = color ?? (dark ? AppTheme.darkMuted : AppTheme.textMuted);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.textMuted)
              .withValues(alpha: dark ? 0.15 : 0.09),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ]),
      ),
    );
  }
}

class _TapHint extends StatelessWidget {
  const _TapHint();
  @override
  Widget build(BuildContext context) {
    return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: const Text('Tap ganti foto',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700)));
  }
}
