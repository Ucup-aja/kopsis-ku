// Model KopsisKu: produk + transaksi (penjualan/restok) + dashboard.
class Produk {
  final int id;
  final String nama;
  final String kategori;
  final double harga;
  final int stok;
  final String deskripsi;
  final String? foto;
  final String? fotoUrl;
  final String status;
  final String createdAt;
  final String updatedAt;
  Produk({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.deskripsi,
    this.foto,
    this.fotoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  factory Produk.fromJson(Map<String, dynamic> j) => Produk(
        id: int.tryParse(j['id'].toString()) ?? 0,
        nama: j['nama']?.toString() ?? '',
        kategori: j['kategori']?.toString() ?? 'lainnya',
        harga: double.tryParse(j['harga'].toString()) ?? 0,
        stok: int.tryParse(j['stok'].toString()) ?? 0,
        deskripsi: j['deskripsi']?.toString() ?? '',
        foto: j['foto']?.toString(),
        fotoUrl: j['foto_url']?.toString(),
        status: j['status']?.toString() ?? 'tersedia',
        createdAt: j['created_at']?.toString() ?? '',
        updatedAt: j['updated_at']?.toString() ?? '',
      );
  String get displayFoto =>
      (fotoUrl != null && fotoUrl!.isNotEmpty) ? fotoUrl! : (foto ?? '');
  bool get isLow => stok > 0 && stok <= 5;
  bool get isHabis => stok <= 0 || status == 'habis';
}

class DashboardData {
  final int totalProduk;
  final int produkTersedia;
  final int produkHabis;
  final int totalStok;
  final double nilaiStok;
  final List<dynamic> byKategori;
  final List<Produk> stokMenipis;
  final List<Produk> recentProduk;
  final int transaksiHari;
  final double omsetHari;
  final int transaksiBulan;
  final double omsetBulan;
  final int restokBulan;
  final List<dynamic> recentTransaksi;
  DashboardData({
    required this.totalProduk,
    required this.produkTersedia,
    required this.produkHabis,
    required this.totalStok,
    required this.nilaiStok,
    required this.byKategori,
    required this.stokMenipis,
    required this.recentProduk,
    this.transaksiHari = 0,
    this.omsetHari = 0,
    this.transaksiBulan = 0,
    this.omsetBulan = 0,
    this.restokBulan = 0,
    this.recentTransaksi = const [],
  });
  static int _i(dynamic v) =>
      int.tryParse(v?.toString() ?? '') ?? (v is num ? v.toInt() : 0);
  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '') ?? (v is num ? v.toDouble() : 0);
  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        totalProduk: _i(j['total_produk']),
        produkTersedia: _i(j['produk_tersedia']),
        produkHabis: _i(j['produk_habis']),
        totalStok: _i(j['total_stok']),
        nilaiStok: _d(j['nilai_stok']),
        byKategori: (j['by_kategori'] as List?) ?? [],
        stokMenipis: ((j['stok_menipis'] as List?) ?? [])
            .map((e) => Produk.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        recentProduk: ((j['recent_produk'] as List?) ?? [])
            .map((e) => Produk.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        transaksiHari: _i(j['transaksi_hari']),
        omsetHari: _d(j['omset_hari']),
        transaksiBulan: _i(j['transaksi_bulan']),
        omsetBulan: _d(j['omset_bulan']),
        restokBulan: _i(j['restok_bulan']),
        recentTransaksi: (j['recent_transaksi'] as List?) ?? [],
      );
}

class Transaksi {
  final int id;
  final String kode;
  final int? produkId;
  final String namaProduk;
  final String tipe; // penjualan | restok
  final int jumlah;
  final double hargaSatuan;
  final double total;
  final int stokSebelum;
  final int stokSesudah;
  final String keterangan;
  final String createdAt;
  final String? foto;
  final String? kategori;
  Transaksi({
    required this.id,
    required this.kode,
    this.produkId,
    required this.namaProduk,
    required this.tipe,
    required this.jumlah,
    required this.hargaSatuan,
    required this.total,
    required this.stokSebelum,
    required this.stokSesudah,
    required this.keterangan,
    required this.createdAt,
    this.foto,
    this.kategori,
  });
  bool get isRestok => tipe == 'restok';
  factory Transaksi.fromJson(Map<String, dynamic> j) => Transaksi(
        id: int.tryParse(j['id'].toString()) ?? 0,
        kode: j['kode']?.toString() ?? '',
        produkId: j['produk_id'] != null
            ? int.tryParse(j['produk_id'].toString())
            : null,
        namaProduk:
            j['nama_produk']?.toString() ?? j['nama']?.toString() ?? '',
        tipe: j['tipe']?.toString() ?? 'penjualan',
        jumlah: int.tryParse(j['jumlah'].toString()) ?? 0,
        hargaSatuan: double.tryParse(j['harga_satuan'].toString()) ?? 0,
        total: double.tryParse(j['total'].toString()) ?? 0,
        stokSebelum: int.tryParse(j['stok_sebelum'].toString()) ?? 0,
        stokSesudah: int.tryParse(j['stok_sesudah'].toString()) ?? 0,
        keterangan: j['keterangan']?.toString() ?? '',
        createdAt: j['created_at']?.toString() ?? '',
        foto: j['foto']?.toString(),
        kategori: j['kategori']?.toString(),
      );
}

class TransaksiSummary {
  final int totalTransaksi;
  final int penjualanHariIni;
  final double omsetHariIni;
  final int penjualanBulan;
  final double omsetBulan;
  final int restokBulan;
  final double nilaiRestokBulan;
  final List<dynamic> topProduk;
  TransaksiSummary({
    required this.totalTransaksi,
    required this.penjualanHariIni,
    required this.omsetHariIni,
    required this.penjualanBulan,
    required this.omsetBulan,
    required this.restokBulan,
    required this.nilaiRestokBulan,
    required this.topProduk,
  });
  static int _i(dynamic v) =>
      int.tryParse(v?.toString() ?? '') ?? (v is num ? v.toInt() : 0);
  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '') ?? (v is num ? v.toDouble() : 0);
  factory TransaksiSummary.fromJson(Map<String, dynamic> j) =>
      TransaksiSummary(
        totalTransaksi: _i(j['total_transaksi']),
        penjualanHariIni: _i(j['penjualan_hari_ini']),
        omsetHariIni: _d(j['omset_hari_ini']),
        penjualanBulan: _i(j['penjualan_bulan']),
        omsetBulan: _d(j['omset_bulan']),
        restokBulan: _i(j['restok_bulan']),
        nilaiRestokBulan: _d(j['nilai_restok_bulan']),
        topProduk: (j['top_produk'] as List?) ?? [],
      );
}
