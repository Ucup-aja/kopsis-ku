import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koperasi_siswa/src/shared/widgets/stat_card.dart';
import 'package:koperasi_siswa/src/features/dashboard/dashboard_screen.dart';
import 'package:koperasi_siswa/src/features/developer/developer_page.dart';
import 'package:koperasi_siswa/src/app/app.dart';

void main() {
  for (final size in [
    Size(280, 600),
    Size(320, 600),
    Size(360, 640),
    Size(375, 812),
    Size(414, 896),
    Size(280, 800)
  ]) {
    testWidgets('no overflow dashboard $size', (t) async {
      final errors = [];
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().toLowerCase().contains('overflowed')) {
          errors.add(d.toString().split('\n').first);
        }
        if (old != null) old(d);
      };
      await t.binding.setSurfaceSize(size);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(size: size),
              child: Scaffold(body: DashboardScreen()))));
      await t.pump(Duration(milliseconds: 400));
      await t.pump(Duration(milliseconds: 400));
      await t.pumpAndSettle(Duration(milliseconds: 300));
      expect(errors, isEmpty, reason: 'overflow at $size: $errors');
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
        FlutterError.onError = old;
      });
    });
    testWidgets('statcard long $size', (t) async {
      final errors = [];
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().toLowerCase().contains('overflowed')) {
          errors.add(d.toString().split('\n').first);
        }
      };
      await t.binding.setSurfaceSize(size);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: size.width,
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: StatCard(
                          title: "NILAI STOK SUPER PANJANG SEKALI",
                          value: "Rp 999.999.999.999",
                          subtitle:
                              "harga × stok omset panjang banget biar test overflow di layar kecil",
                          icon: Icons.wallet,
                          color: Colors.green))))));
      await t.pumpAndSettle();
      expect(errors, isEmpty, reason: 'statcard overflow at $size: $errors');
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
        FlutterError.onError = old;
      });
    });
    testWidgets('no overflow developer $size', (t) async {
      final errors = [];
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().toLowerCase().contains('overflowed')) {
          errors.add(d.toString().split('\n').first);
        }
      };
      await t.binding.setSurfaceSize(size);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const DeveloperPage())));
      await t.pump(Duration(milliseconds: 400));
      await t.pumpAndSettle(Duration(milliseconds: 300));
      expect(errors, isEmpty, reason: 'developer overflow at $size: $errors');
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
        FlutterError.onError = old;
      });
    });
    testWidgets('app boots to login $size', (t) async {
      await t.binding.setSurfaceSize(size);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(const KopsisApp());
      await t.pump(Duration(milliseconds: 300));
      expect(find.text('MASUK'), findsOneWidget);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
    });
  }
}
