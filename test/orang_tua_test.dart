import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:digital_book_connect/models/orang_tua_models.dart';
import 'package:digital_book_connect/screens/orang_tua/orang_tua_main_page.dart';
import 'package:digital_book_connect/screens/orang_tua/profil_anak_page.dart';
import 'package:digital_book_connect/services/api_service.dart';

const _rafaJson = {
  'id_siswa': 9,
  'nis': '1001',
  'nama': 'Rafa Aditya Saputra',
  'jenis_kelamin': 'L',
  'perempuan': false,
  'id_kelas': 1,
  'kelas': '7A',
  'tahun_ajaran': '2026/2027',
  'wali_kelas': 'Bapak Ahmad Fauzi, S.Pd',
  'hubungan': 'Ayah',
};

const _kaylaJson = {
  'id_siswa': 10,
  'nis': '1002',
  'nama': 'Kayla Putri Saputra',
  'jenis_kelamin': 'P',
  'perempuan': true,
  'id_kelas': 1,
  'kelas': '7A',
  'tahun_ajaran': '2026/2027',
  'wali_kelas': 'Bapak Ahmad Fauzi, S.Pd',
  'hubungan': 'Ayah',
};

ApiResponse<List<AnakOrangTua>> _sukses(List<Map<String, dynamic>> data) => ApiResponse(
      success: true,
      message: 'Daftar anak berhasil dimuat',
      statusCode: 200,
      data: data.map(AnakOrangTua.fromJson).toList(),
    );

ApiResponse<List<AnakOrangTua>> _gagal([String pesan = 'Tidak dapat terhubung ke server.']) =>
    ApiResponse(success: false, message: pesan, statusCode: 0);

ApiResponse<Map<String, dynamic>> _dashboardKosong() => const ApiResponse(
      success: true,
      message: 'ok',
      statusCode: 200,
      data: {'catatan_terbaru': []},
    );

Widget _halaman({required MuatAnak muat}) => MaterialApp(home: ProfilAnakPage(muat: muat));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Model AnakOrangTua', () {
    test('fromJson membaca seluruh field endpoint /api/orang-tua/anak', () {
      final a = AnakOrangTua.fromJson(_kaylaJson);
      expect(a.idSiswa, 10);
      expect(a.nis, '1002');
      expect(a.jenisKelamin, 'P');
      expect(a.perempuan, isTrue);
      expect(a.labelJenisKelamin, 'Perempuan');
      expect(a.labelKelas, 'Kelas 7A (2026/2027)');
      expect(a.waliKelas, 'Bapak Ahmad Fauzi, S.Pd');
      expect(a.hubungan, 'Ayah');
      expect(a.namaDepan, 'Kayla');
    });

    test('fromJson toleran terhadap data ringkas (tanpa jenis_kelamin & kelas kosong)', () {
      final a = AnakOrangTua.fromJson({'id_siswa': '7', 'nama': 'Budi', 'perempuan': false});
      expect(a.idSiswa, 7);
      expect(a.jenisKelamin, 'L');
      expect(a.labelJenisKelamin, 'Laki-laki');
      expect(a.labelKelas, 'Belum ada kelas');
      expect(a.nis, '');
    });
  });

  group('Halaman Profil Anak', () {
    testWidgets('menampilkan loading lalu data satu anak', (tester) async {
      final selesai = Completer<ApiResponse<List<AnakOrangTua>>>();
      await tester.pumpWidget(_halaman(muat: () => selesai.future));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      selesai.complete(_sukses([_rafaJson]));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Rafa Aditya Saputra'), findsOneWidget);
      expect(find.text('Kelas 7A (2026/2027)'), findsOneWidget);
      expect(find.text('1001'), findsOneWidget);
      expect(find.text('Laki-laki'), findsOneWidget);
      expect(find.text('Bapak Ahmad Fauzi, S.Pd'), findsOneWidget);
      expect(find.text('Ayah'), findsOneWidget);
      expect(find.text('1 anak terhubung dengan akun Anda'), findsOneWidget);
    });

    testWidgets('menampilkan seluruh anak bila lebih dari satu', (tester) async {
      await tester.pumpWidget(_halaman(muat: () async => _sukses([_rafaJson, _kaylaJson])));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kartu-anak-9')), findsOneWidget);
      expect(find.text('Rafa Aditya Saputra'), findsOneWidget);
      expect(find.text('2 anak terhubung dengan akun Anda'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Kayla Putri Saputra'), 300);
      expect(find.byKey(const Key('kartu-anak-10')), findsOneWidget);
      expect(find.text('Kayla Putri Saputra'), findsOneWidget);
    });

    testWidgets('menampilkan empty state bila belum ada anak terhubung', (tester) async {
      await tester.pumpWidget(_halaman(muat: () async => _sukses([])));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada anak terhubung'), findsOneWidget);
      expect(find.textContaining('Administrator sekolah'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('menampilkan error state dan tombol Coba Lagi memuat ulang data', (tester) async {
      var panggilan = 0;
      await tester.pumpWidget(_halaman(muat: () async {
        panggilan++;
        return panggilan == 1 ? _gagal('Server tidak merespons.') : _sukses([_rafaJson]);
      }));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat data anak'), findsOneWidget);
      expect(find.text('Server tidak merespons.'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(panggilan, 2);
      expect(find.text('Gagal memuat data anak'), findsNothing);
      expect(find.text('Rafa Aditya Saputra'), findsOneWidget);
    });

    testWidgets('pull-to-refresh memuat ulang data dari server', (tester) async {
      var panggilan = 0;
      await tester.pumpWidget(_halaman(muat: () async {
        panggilan++;
        return _sukses(panggilan == 1 ? [_rafaJson] : [_rafaJson, _kaylaJson]);
      }));
      await tester.pumpAndSettle();
      expect(panggilan, 1);
      expect(find.text('1 anak terhubung dengan akun Anda'), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(panggilan, 2);
      expect(find.text('2 anak terhubung dengan akun Anda'), findsOneWidget);
    });

    testWidgets('gagal memuat ulang tetap mempertahankan data lama', (tester) async {
      var panggilan = 0;
      await tester.pumpWidget(_halaman(muat: () async {
        panggilan++;
        return panggilan == 1 ? _sukses([_rafaJson]) : _gagal('Koneksi terputus.');
      }));
      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(panggilan, 2);
      expect(find.text('Rafa Aditya Saputra'), findsOneWidget);
      expect(find.textContaining('Koneksi terputus.'), findsOneWidget);
    });
  });

  group('Dashboard Orang Tua', () {
    Widget dashboard({required MuatAnak muatAnak}) => MaterialApp(
          home: OrangTuaMainPage(muatAnak: muatAnak, muatDashboard: () async => _dashboardKosong()),
        );

    testWidgets('satu anak: kartu menampilkan anak dari server (bukan data dummy)', (tester) async {
      await tester.pumpWidget(dashboard(muatAnak: () async => _sukses([_rafaJson])));
      await tester.pumpAndSettle();

      expect(find.text('Ananda Rafa'), findsOneWidget);
      expect(find.text('Kelas 7A'), findsOneWidget);
      expect(find.textContaining('Ahmad Rizki'), findsNothing);
    });

    testWidgets('dua anak: kartu merangkum jumlah dan nama anak', (tester) async {
      await tester.pumpWidget(dashboard(muatAnak: () async => _sukses([_rafaJson, _kaylaJson])));
      await tester.pumpAndSettle();

      expect(find.text('2 Anak Terhubung'), findsOneWidget);
      expect(find.text('Rafa, Kayla'), findsOneWidget);
    });

    testWidgets('tanpa anak: kartu menampilkan keterangan belum ada anak terhubung', (tester) async {
      await tester.pumpWidget(dashboard(muatAnak: () async => _sukses([])));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada anak terhubung'), findsOneWidget);
      expect(find.textContaining('Ahmad Rizki'), findsNothing);
    });

    testWidgets('gagal memuat: kartu dapat diketuk untuk mencoba lagi', (tester) async {
      var panggilan = 0;
      await tester.pumpWidget(dashboard(muatAnak: () async {
        panggilan++;
        return panggilan == 1 ? _gagal() : _sukses([_kaylaJson]);
      }));
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat data anak'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kartu-anak-dashboard')));
      await tester.pumpAndSettle();

      expect(panggilan, 2);
      expect(find.text('Ananda Kayla'), findsOneWidget);
    });

    testWidgets('tab Anak membuka halaman Profil Anak berisi data server', (tester) async {
      await tester.pumpWidget(dashboard(muatAnak: () async => _sukses([_rafaJson, _kaylaJson])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anak'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilAnakPage), findsOneWidget);
      expect(find.text('Rafa Aditya Saputra'), findsOneWidget);
    });
  });
}
