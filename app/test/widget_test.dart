import 'package:flutter_test/flutter_test.dart';
import 'package:koperasi_siswa/src/app/app.dart';
import 'package:koperasi_siswa/src/core/error/app_exception.dart';
import 'package:koperasi_siswa/src/core/error/result.dart';
import 'package:koperasi_siswa/src/data/local/app_database.dart';
import 'package:koperasi_siswa/src/data/repositories/produk_repository.dart';

void main() {
  testWidgets('App loads ke login koperasi konsumen', (tester) async {
    await tester.pumpWidget(const KopsisApp());
    await tester.pump(Duration(milliseconds: 300));
    expect(find.text('Masuk Pengelola'), findsOneWidget);
  });

  group('ProdukRepository.validateForm', () {
    ProdukRepository make() => ProdukRepository(AppDatabase());
    test('rejects empty name', () {
      final r = make().validateForm(nama: '', harga: 1000, stok: 1);
      expect(r, isA<Err<void>>());
    });
    test('rejects negative price/stock', () {
      final repo = make();
      expect(
          repo.validateForm(nama: 'A', harga: -1, stok: 1), isA<Err<void>>());
      expect(
          repo.validateForm(nama: 'A', harga: 1, stok: -1), isA<Err<void>>());
    });
    test('accepts valid form', () {
      expect(make().validateForm(nama: 'Buku', harga: 2000, stok: 5),
          isA<Ok<void>>());
    });
  });

  test('AppException maps messages', () {
    expect(const AppException('x').toString(), 'x');
  });
}
