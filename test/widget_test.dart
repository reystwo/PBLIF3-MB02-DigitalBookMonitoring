import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/screens/home/home_page.dart';
import 'package:digital_book_connect/screens/auth/login_page.dart';

void main() {
  group('Smoke & Navigation Widget Tests', () {
    testWidgets('Smoke Test: HomePage berhasil dirender tanpa exception', (WidgetTester tester) async {
      // 1. Render root widget aplikasi (MyApp)
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 2. Verifikasi HomePage hadir di pohon widget
      expect(find.byType(HomePage), findsOneWidget);

      // 3. Verifikasi teks judul utama dan tombol aksi
      expect(find.text('Buku Penghubung\nDigital'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);
      expect(find.text('Pelajari selanjutnya >'), findsOneWidget);
    });

    testWidgets('Navigation Test: Navigasi dari HomePage ke LoginPage', (WidgetTester tester) async {
      // 1. Render root widget aplikasi
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 2. Cari tombol 'Mulai Sekarang' dan pastikan terlihat di layar
      final tombolMulai = find.text('Mulai Sekarang');
      expect(tombolMulai, findsOneWidget);
      await tester.ensureVisible(tombolMulai);
      await tester.pumpAndSettle();

      // 3. Ketuk tombol 'Mulai Sekarang'
      await tester.tap(tombolMulai);
      await tester.pumpAndSettle();

      // 4. Verifikasi navigasi berhasil ke LoginPage
      expect(find.byType(LoginPage), findsOneWidget);

      // 5. Verifikasi komponen form login, teks header, dan tombol masuk
      expect(find.text('Selamat Datang Kembali'), findsOneWidget);
      expect(find.text('Pilih Peran / Role'), findsOneWidget);
      expect(find.text('Guru'), findsOneWidget);
      expect(find.text('Orang Tua / Wali'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });
  });

  group('Unit Test Serialisasi Model JSON (DAT-01)', () {
    test('Siswa.fromJson parsing jenis_kelamin L dan P dengan benar', () {
      final jsonPerempuan = {
        'id_siswa': 2,
        'nis': '1002',
        'nama': 'Aisyah Putri',
        'jenis_kelamin': 'P',
        'kelas': '5A',
      };
      final siswaP = Siswa.fromJson(jsonPerempuan);
      expect(siswaP.idSiswa, equals(2));
      expect(siswaP.nama, equals('Aisyah Putri'));
      expect(siswaP.kelas, equals('5A'));
      expect(siswaP.perempuan, isTrue, reason: 'jenis_kelamin P harus menghasilkan perempuan == true');

      final jsonLaki = {
        'id_siswa': 1,
        'nis': '1001',
        'nama': 'Ahmad Rizki',
        'jenis_kelamin': 'L',
        'kelas': '5A',
      };
      final siswaL = Siswa.fromJson(jsonLaki);
      expect(siswaL.idSiswa, equals(1));
      expect(siswaL.nama, equals('Ahmad Rizki'));
      expect(siswaL.perempuan, isFalse, reason: 'jenis_kelamin L harus menghasilkan perempuan == false');
    });

    test('Catatan.fromJson parsing lengkap dengan nested siswa dan lampiran', () {
      final jsonCatatan = {
        'id_catatan': 15,
        'id_siswa': 1,
        'id_pengirim': 2,
        'id_penerima': 4,
        'penulis': 'Bapak Ahmad',
        'peran_penulis': 'Guru Kelas 5A',
        'penulis_perempuan': false,
        'kategori': 'Perilaku',
        'isi': 'Ahmad Rizki sangat sopan dan membantu teman di kelas.',
        'tanggal': '2026-10-14T09:00:00.000Z',
        'tanggal_label': '14 Okt 2026',
        'status_dibaca': 'belum_dibaca',
        'siswa': {
          'id_siswa': 1,
          'nama': 'Ahmad Rizki',
          'kelas': '5A',
          'jenis_kelamin': 'L',
          'perempuan': false,
        },
        'lampiran': {
          'nama_file': 'foto_kegiatan.jpg',
          'ukuran': '850 KB',
        },
      };

      final catatan = Catatan.fromJson(jsonCatatan);
      expect(catatan.idCatatan, equals(15));
      expect(catatan.penulis, equals('Bapak Ahmad'));
      expect(catatan.peranPenulis, equals('Guru Kelas 5A'));
      expect(catatan.kategori, equals('Perilaku'));
      expect(catatan.isi, equals('Ahmad Rizki sangat sopan dan membantu teman di kelas.'));
      expect(catatan.siswa.nama, equals('Ahmad Rizki'));
      expect(catatan.siswa.kelas, equals('5A'));
      expect(catatan.lampiran, isNotNull);
      expect(catatan.lampiran?.namaFile, equals('foto_kegiatan.jpg'));
      expect(catatan.lampiran?.ukuran, equals('850 KB'));
    });

    test('Aktivitas.fromJson parsing aktivitas notifikasi', () {
      final jsonAktivitas = {
        'id_catatan': 8,
        'id_siswa': 2,
        'nama': 'Aisyah Putri',
        'keterangan': 'Menerima catatan perkembangan baru',
        'waktu': 'Hari ini, 09:15',
        'perempuan': true,
      };

      final aktivitas = Aktivitas.fromJson(jsonAktivitas);
      expect(aktivitas.idCatatan, equals(8));
      expect(aktivitas.nama, equals('Aisyah Putri'));
      expect(aktivitas.keterangan, equals('Menerima catatan perkembangan baru'));
      expect(aktivitas.waktu, equals('Hari ini, 09:15'));
      expect(aktivitas.perempuan, isTrue);
    });
  });

  group('Widget Test Validasi Form Login (LoginPage)', () {
    testWidgets('Form validation menahan login saat input username & password kosong', (WidgetTester tester) async {
      // 1. Render halaman LoginPage dalam MaterialApp
      await tester.pumpWidget(const MaterialApp(
        home: LoginPage(),
      ));
      await tester.pumpAndSettle();

      // 2. Pastikan field form terlihat
      expect(find.text('Selamat Datang Kembali'), findsOneWidget);

      // 3. Cari tombol Masuk dan ketuk saat field masih kosong
      final tombolMasuk = find.widgetWithText(ElevatedButton, 'Masuk');
      expect(tombolMasuk, findsOneWidget);
      await tester.ensureVisible(tombolMasuk);
      await tester.pumpAndSettle();

      await tester.tap(tombolMasuk);
      await tester.pumpAndSettle();

      // 4. Verifikasi pesan validasi field kosong muncul di layar
      expect(find.text('Username tidak boleh kosong'), findsOneWidget);
      expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);

      // 5. Pastikan tetap berada di LoginPage (tidak terjadi navigasi)
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
