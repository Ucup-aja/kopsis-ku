import 'package:intl/intl.dart';

/// Single-source formatting helpers (DESIGN.md §7).
///
/// Previously `rupiah()` was copy-pasted in dashboard/produk/transaksi screens.
/// Use these everywhere instead.
String rupiah(num v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(v);

String tglPanjang(String iso) {
  try {
    final d = DateTime.parse(iso);
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}

String tglPendek(String iso) {
  try {
    final d = DateTime.parse(iso);
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}
