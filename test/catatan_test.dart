import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/siswa_model.dart';
import 'package:digital_book_connect/models/user_model.dart';
import 'package:digital_book_connect/screens/catatan/detail_catatan_page.dart';
import 'package:digital_book_connect/screens/catatan/riwayat_catatan_page.dart';
import 'package:digital_book_connect/screens/notifikasi/notifikasi_page.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/session_manager.dart';

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

  group('Balas Pesan di DetailCatatanPage', () {
    Catatan buatCatatan({int? idCatatan = 10}) => Catatan(
          idCatatan: idCatatan,
          penulis: 'Bapak Ahmad',
          peranPenulis: 'Guru Kelas 7A',
          siswa: const Siswa(idSiswa: 9, nama: 'Rafa Aditya Saputra', kelas: '7A'),
          kategori: 'Akademik',
          tanggal: DateTime(2026, 11, 25),
          isi: 'Ananda Rafa sangat aktif hari ini.',
        );

    CatatanModel buatBalasanModel(String isi) => CatatanModel(
          idCatatan: 11,
          idSiswa: 9,
          idPengirim: 15,
          idPenerima: 14,
          penulis: 'Bapak Andi Saputra',
          peranPenulis: 'Orang Tua',
          kategori: 'Akademik',
          isi: isi,
          tanggal: DateTime(2026, 11, 25),
          tanggalLabel: '25 Nov 2026',
          siswa: const SiswaModel(
            idSiswa: 9,
            nis: '1001',
            nama: 'Rafa Aditya Saputra',
            jenisKelamin: 'L',
            perempuan: false,
            idKelas: 1,
            kelas: '7A',
          ),
        );

    Future<void> bukaSheetBalas(WidgetTester tester) async {
      final tombolBalas = find.text('Balas Pesan');
      await tester.ensureVisible(tombolBalas);
      await tester.tap(tombolBalas);
      await tester.pumpAndSettle();
    }

    testWidgets('balasan gagal -> sheet tetap terbuka, input dipertahankan, tidak muncul pesan berhasil', (tester) async {
      var panggilan = 0;
      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: buatCatatan(),
          kirimBalasan: ({required idCatatan, required isi}) async {
            panggilan++;
            if (panggilan == 1) {
              return const ApiResponse(
                success: false,
                message: 'Tidak dapat terhubung ke server.',
                statusCode: 0,
              );
            }
            return ApiResponse(
              success: true,
              message: 'Balasan berhasil dikirim',
              data: buatBalasanModel(isi),
              statusCode: 201,
            );
          },
        ),
      ));

      await bukaSheetBalas(tester);
      await tester.enterText(find.byKey(const Key('input-balasan')), 'Terima kasih Pak Guru');
      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();

      // Sheet tetap terbuka, teks tetap ada, pesan gagal tampil, pesan berhasil tidak tampil
      expect(panggilan, 1);
      expect(find.byKey(const Key('input-balasan')), findsOneWidget);
      expect(find.text('Terima kasih Pak Guru'), findsOneWidget);
      expect(find.byKey(const Key('pesan-gagal-balasan')), findsOneWidget);
      expect(find.textContaining('Balasan gagal dikirim. Tidak dapat terhubung ke server.'), findsOneWidget);
      expect(find.text('Balasan berhasil dikirim'), findsNothing);

      // Coba kirim ulang -> berhasil, sheet tertutup dan SnackBar sukses muncul
      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();

      expect(panggilan, 2);
      expect(find.byKey(const Key('input-balasan')), findsNothing);
      expect(find.text('Balasan berhasil dikirim'), findsOneWidget);
    });

    testWidgets('menampilkan status Mengirim... saat request berjalan lalu menutup sheet saat sukses', (tester) async {
      final completer = Completer<ApiResponse<CatatanModel>>();
      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: buatCatatan(),
          kirimBalasan: ({required idCatatan, required isi}) => completer.future,
        ),
      ));

      await bukaSheetBalas(tester);
      await tester.enterText(find.byKey(const Key('input-balasan')), 'Baik Pak, akan kami dampingi');
      await tester.tap(find.text('Kirim'));
      await tester.pump();

      expect(find.text('Mengirim...'), findsOneWidget);
      expect(find.text('Balasan berhasil dikirim'), findsNothing);

      completer.complete(ApiResponse(
        success: true,
        message: 'Balasan berhasil dikirim',
        data: buatBalasanModel('Baik Pak, akan kami dampingi'),
        statusCode: 201,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input-balasan')), findsNothing);
      expect(find.text('Balasan berhasil dikirim'), findsOneWidget);
    });

    testWidgets('input kosong atau hanya spasi menampilkan validasi tanpa memanggil server', (tester) async {
      var dipanggil = false;
      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: buatCatatan(),
          kirimBalasan: ({required idCatatan, required isi}) async {
            dipanggil = true;
            return ApiResponse(success: true, message: 'OK', data: buatBalasanModel(isi), statusCode: 201);
          },
        ),
      ));

      await bukaSheetBalas(tester);
      await tester.enterText(find.byKey(const Key('input-balasan')), '   ');
      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();

      expect(dipanggil, isFalse);
      expect(find.text('Isi balasan tidak boleh kosong.'), findsOneWidget);
      expect(find.byKey(const Key('input-balasan')), findsOneWidget);
    });

    testWidgets('idCatatan tidak valid menampilkan error tanpa mengklaim berhasil', (tester) async {
      var dipanggil = false;
      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: buatCatatan(idCatatan: null),
          kirimBalasan: ({required idCatatan, required isi}) async {
            dipanggil = true;
            return ApiResponse(success: true, message: 'OK', data: buatBalasanModel(isi), statusCode: 201);
          },
        ),
      ));

      await bukaSheetBalas(tester);
      await tester.enterText(find.byKey(const Key('input-balasan')), 'Halo Pak');
      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();

      expect(dipanggil, isFalse);
      expect(find.textContaining('Data catatan tidak valid'), findsOneWidget);
      expect(find.text('Balasan berhasil dikirim'), findsNothing);
    });

    testWidgets('membuka DetailCatatanPage memanggil GET /api/catatan/{id} dan memperbarui data terbaru', (tester) async {
      Uri? requestedUri;
      String? requestedMethod;

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: DetailCatatanPage(catatan: buatCatatan(idCatatan: 10)),
        ));
        await tester.pumpAndSettle();

        expect(requestedMethod, 'GET');
        expect(requestedUri?.path, endsWith('/catatan/10'));
        expect(find.text('Isi terbaru dari server setelah dibaca.'), findsOneWidget);
        expect(find.text('Laporan_Harian.pdf'), findsOneWidget);
      }, () => MockClient((req) async {
            requestedMethod = req.method;
            requestedUri = req.url;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Detail catatan berhasil dimuat',
                'data': {
                  'id_catatan': 10,
                  'id_siswa': 9,
                  'id_pengirim': 14,
                  'id_penerima': 15,
                  'penulis': 'Bapak Ahmad',
                  'peran_penulis': 'Guru Kelas 7A',
                  'kategori': 'Akademik',
                  'isi_catatan': 'Isi terbaru dari server setelah dibaca.',
                  'isi': 'Isi terbaru dari server setelah dibaca.',
                  'tanggal': '2026-11-25 09:00:00',
                  'tanggal_label': '25 Nov 2026',
                  'status_dibaca': 'dibaca',
                  'siswa': {'id_siswa': 9, 'nama': 'Rafa Aditya Saputra', 'kelas': '7A', 'jenis_kelamin': 'L'},
                  'lampiran': {'nama_file': 'Laporan_Harian.pdf', 'ukuran': '0.5 MB'},
                },
              }),
              200,
            );
          }));
    });

    testWidgets('gagal memuat detail tetap menampilkan data awal tanpa error layar kosong', (tester) async {
      var dipanggilDengan = 0;
      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: buatCatatan(idCatatan: 10),
          muatDetail: (id) async {
            dipanggilDengan = id;
            return const ApiResponse(success: false, message: 'Server error', statusCode: 500);
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(dipanggilDengan, 10);
      expect(find.text('Ananda Rafa sangat aktif hari ini.'), findsOneWidget);
    });

    testWidgets('idCatatan null tidak memanggil muatDetail', (tester) async {
      var dipanggil = false;
      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: buatCatatan(idCatatan: null),
          muatDetail: (_) async {
            dipanggil = true;
            return ApiResponse(success: true, message: 'OK', data: buatBalasanModel('x'), statusCode: 200);
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(dipanggil, isFalse);
    });

    testWidgets('membuka pesan milik sendiri menampilkan tombol Tulis Pesan Lanjutan', (tester) async {
      addTearDown(SessionManager.clearSession);
      await SessionManager.saveSession(
        token: 'dummy-token',
        user: const UserModel(
          idUser: 15,
          nama: 'Bapak Andi Saputra',
          username: 'ortu_andi',
          role: 'orang_tua',
          status: 'aktif',
          peranLabel: 'Orang Tua',
        ),
      );

      final pesanSendiri = Catatan(
        idCatatan: 20,
        idPengirim: 15,
        penulis: 'Bapak Andi Saputra',
        peranPenulis: 'Orang Tua',
        siswa: const Siswa(idSiswa: 9, nama: 'Rafa Aditya Saputra', kelas: '7A'),
        kategori: 'Akademik',
        tanggal: DateTime(2026, 11, 25),
        isi: 'Terima kasih Pak Guru.',
      );

      await tester.pumpWidget(MaterialApp(
        home: DetailCatatanPage(
          catatan: pesanSendiri,
          muatDetail: (_) async => const ApiResponse(success: false, message: 'skip', statusCode: 200),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tulis Pesan Lanjutan'), findsOneWidget);
      expect(find.text('Balas Pesan'), findsNothing);

      final tombol = find.text('Tulis Pesan Lanjutan');
      await tester.ensureVisible(tombol);
      await tester.tap(tombol);
      await tester.pumpAndSettle();

      expect(find.text('Pesan lanjutan untuk Rafa Aditya Saputra'), findsOneWidget);
      expect(find.text('Balas ke Bapak Andi Saputra'), findsNothing);
    });
  });
}
