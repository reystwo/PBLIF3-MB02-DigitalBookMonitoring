import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/screens/catatan/riwayat_catatan_page.dart';
import 'package:digital_book_connect/screens/notifikasi/notifikasi_page.dart';

/// Layar catatan & notifikasi hanya menampilkan data dari server,
/// tidak pernah jatuh kembali ke data dummy (mis. setelah catatan dihapus Admin).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  MockClient server(int status, Object body) =>
      MockClient((_) async => http.Response(jsonEncode(body), status));

  testWidgets('Riwayat Catatan kosong di server -> "Belum ada catatan", bukan data dummy', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: RiwayatCatatanPage()));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada catatan'), findsOneWidget);
      expect(find.textContaining(daftarCatatan.first.isi), findsNothing);
      expect(find.byType(CatatanTile), findsNothing);
    }, () => server(200, {'success': true, 'message': 'OK', 'data': []}));
  });

  testWidgets('Riwayat Catatan gagal dimuat -> pesan gagal, bukan data dummy', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: RiwayatCatatanPage()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal memuat catatan.'), findsOneWidget);
      expect(find.byType(CatatanTile), findsNothing);
    }, () => server(500, {'success': false, 'message': 'Server error'}));
  });

  testWidgets('Notifikasi kosong di server -> "Belum ada notifikasi", bukan data dummy', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: NotifikasiPage()));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada notifikasi'), findsOneWidget);
      expect(find.text(aktivitasTerbaru.first.nama), findsNothing);
    }, () => server(200, {'success': true, 'message': 'OK', 'data': []}));
  });
}
