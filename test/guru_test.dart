import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/guru_models.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/screens/catatan/tambah_catatan_page.dart';
import 'package:digital_book_connect/screens/siswa/daftar_siswa_page.dart';
import 'package:digital_book_connect/screens/siswa/detail_siswa_page.dart';

const _siswaJson = {
  'id_siswa': 1,
  'nis': '1001',
  'nama': 'Ahmad Rizki',
  'jenis_kelamin': 'L',
  'perempuan': false,
  'id_kelas': 1,
  'kelas': '5A',
  'tahun_ajaran': '2026/2027',
  'jumlah_catatan': 2,
  'wali_kelas': 'Bapak Ahmad',
  'orang_tua': [
    {'id_orang_tua': 1, 'nama': 'Ibu Siti Nurhaliza', 'no_hp': '081298765432', 'hubungan': 'Ibu'},
  ],
};

CatatanModel _catatan(int id, String isi, String dibuat, {String penulis = 'Bapak Ahmad'}) => CatatanModel.fromJson({
      'id_catatan': id,
      'id_siswa': 1,
      'penulis': penulis,
      'peran_penulis': penulis == 'Bapak Ahmad' ? 'Guru Kelas 5A' : 'Orang Tua',
      'kategori': 'Akademik',
      'isi_catatan': isi,
      'tanggal': dibuat,
      'created_at': dibuat,
      'siswa': {'id_siswa': 1, 'nama': 'Ahmad Rizki', 'kelas': '5A'},
    });

ApiResponse<PagedResult<CatatanModel>> _halaman(List<CatatanModel> items, {int page = 1, int lastPage = 1, int? total}) =>
    ApiResponse(
      success: true,
      message: 'ok',
      statusCode: 200,
      data: PagedResult(
        items: items,
        meta: PageMeta(currentPage: page, lastPage: lastPage, perPage: 10, total: total ?? items.length),
      ),
    );

void main() {
  group('Model fitur Guru', () {
    test('SiswaGuru.fromJson membaca detail siswa beserta orang tua', () {
      final s = SiswaGuru.fromJson(_siswaJson);
      expect(s.idSiswa, 1);
      expect(s.labelKelas, 'Kelas 5A (2026/2027)');
      expect(s.waliKelas, 'Bapak Ahmad');
      expect(s.jumlahCatatan, 2);
      expect(s.orangTua.single.hubungan, 'Ibu');
      expect(s.toSiswa().idSiswa, 1);
    });

    test('CatatanModel membaca waktu pembuatan (created_at)', () {
      final c = _catatan(5, 'Isi', '2026-10-24 09:15:00');
      expect(c.dibuatPada, DateTime(2026, 10, 24, 9, 15));
      expect(KartuRiwayatCatatan.formatWaktu(c.dibuatPada!), '24 Okt 2026, 09:15');
    });
  });

  group('Daftar siswa Guru', () {
    testWidgets('menampilkan siswa tanggung jawab tanpa tombol tambah', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DaftarSiswaPage(
          fetcher: (page, search) async => ApiResponse(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: PagedResult(items: [SiswaGuru.fromJson(_siswaJson)], meta: const PageMeta(total: 1)),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ahmad Rizki'), findsOneWidget);
      expect(find.text('NIS 1001 · Kelas 5A'), findsOneWidget);
      expect(find.text('2 catatan'), findsOneWidget);
      expect(find.text('1 data ditemukan'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('menampilkan pesan kosong bila belum ada siswa', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DaftarSiswaPage(
          fetcher: (page, search) async => const ApiResponse(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: PagedResult<SiswaGuru>(items: [], meta: PageMeta()),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada siswa di kelas Anda'), findsOneWidget);
      expect(
        find.text('Siswa akan tampil setelah Anda ditetapkan sebagai wali kelas oleh Administrator.'),
        findsOneWidget,
      );
    });
  });

  group('Detail siswa & riwayat catatan', () {
    testWidgets('menampilkan info siswa, orang tua, dan riwayat terbaru di atas', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DetailSiswaGuruPage(
          idSiswa: 1,
          muatDetail: (id) async =>
              ApiResponse(success: true, message: 'ok', statusCode: 200, data: SiswaGuru.fromJson(_siswaJson)),
          muatCatatan: (id, page) async => _halaman([
            _catatan(3, 'Catatan terbaru', '2026-10-24 09:15:00'),
            _catatan(2, 'Catatan lama', '2025-09-10 16:45:00', penulis: 'Ibu Siti Nurhaliza'),
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ahmad Rizki'), findsOneWidget);
      expect(find.text('Bapak Ahmad'), findsWidgets);
      expect(find.text('Ibu Siti Nurhaliza\n081298765432'), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Catatan lama'), 200);
      final atas = tester.getTopLeft(find.text('Catatan terbaru')).dy;
      final bawah = tester.getTopLeft(find.text('Catatan lama')).dy;
      expect(atas, lessThan(bawah));
      expect(find.text('Dibuat 24 Okt 2026, 09:15'), findsOneWidget);
      expect(find.text('Orang Tua'), findsOneWidget);
    });

    testWidgets('riwayat kosong menampilkan ajakan menambah catatan', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DetailSiswaGuruPage(
          idSiswa: 1,
          muatDetail: (id) async =>
              ApiResponse(success: true, message: 'ok', statusCode: 200, data: SiswaGuru.fromJson(_siswaJson)),
          muatCatatan: (id, page) async => _halaman([]),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Belum ada catatan'), 200);

      expect(find.text('Belum ada catatan'), findsOneWidget);
    });

    testWidgets('memuat halaman riwayat berikutnya', (tester) async {
      final halamanDiminta = <int>[];
      await tester.pumpWidget(MaterialApp(
        home: DetailSiswaGuruPage(
          idSiswa: 1,
          muatDetail: (id) async =>
              ApiResponse(success: true, message: 'ok', statusCode: 200, data: SiswaGuru.fromJson(_siswaJson)),
          muatCatatan: (id, page) async {
            halamanDiminta.add(page);
            return page == 1
                ? _halaman([_catatan(3, 'Halaman satu', '2026-10-24 09:15:00')], lastPage: 2, total: 2)
                : _halaman([_catatan(1, 'Halaman dua', '2025-09-12 09:00:00')], page: 2, lastPage: 2, total: 2);
          },
        ),
      ));
      await tester.pumpAndSettle();

      final tombol = find.text('Muat catatan sebelumnya');
      await tester.scrollUntilVisible(tombol, 200);
      await tester.ensureVisible(tombol);
      await tester.pumpAndSettle();
      await tester.tap(tombol);
      await tester.pumpAndSettle();

      expect(halamanDiminta, [1, 2]);
      expect(find.text('Halaman dua', skipOffstage: false), findsOneWidget);
      expect(find.text('Muat catatan sebelumnya', skipOffstage: false), findsNothing);
    });

    testWidgets('akses ditolak backend ditampilkan sebagai pesan gagal', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DetailSiswaGuruPage(
          idSiswa: 4,
          muatDetail: (id) async => const ApiResponse(
            success: false,
            message: 'Akses ditolak. Siswa ini bukan tanggung jawab Anda.',
            statusCode: 403,
          ),
          muatCatatan: (id, page) async => const ApiResponse(success: false, message: 'Akses ditolak.', statusCode: 403),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat data siswa'), findsOneWidget);
      expect(find.text('Akses ditolak. Siswa ini bukan tanggung jawab Anda.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('isi catatan berupa HTML ditampilkan sebagai teks biasa', (tester) async {
      const isi = '<script>alert("x")</script><b>tebal</b>';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: KartuRiwayatCatatan(catatan: _catatan(9, isi, '2026-10-24 09:15:00'))),
      ));
      expect(find.text(isi), findsOneWidget);
    });
  });

  group('Form tambah catatan', () {
    const siswa = Siswa(idSiswa: 1, nama: 'Ahmad Rizki', kelas: '5A');

    Future<Future<bool?>> bukaForm(WidgetTester tester, KirimCatatan kirim) async {
      late Future<bool?> hasil;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => hasil = Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => TambahCatatanPage(siswa: siswa, kirim: kirim)),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
      return hasil;
    }

    Future<void> simpan(WidgetTester tester) async {
      // Scrollable pertama = ListView halaman (TextField multi-baris juga Scrollable)
      await tester.scrollUntilVisible(find.text('Simpan Catatan'), 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Simpan Catatan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Catatan'));
      await tester.pumpAndSettle();
    }

    testWidgets('menolak isi kosong atau hanya spasi tanpa mengirim request', (tester) async {
      var dipanggil = 0;
      await bukaForm(tester, ({required idSiswa, required isi, kategori, tanggal, lampiranNama, lampiranUkuran}) async {
        dipanggil++;
        return const ApiResponse(success: true, message: 'ok', statusCode: 201);
      });

      await simpan(tester);
      expect(find.text('Isi catatan wajib diisi dan tidak boleh hanya berisi spasi.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('isi-catatan')), '   \n  ');
      await simpan(tester);
      expect(find.text('Isi catatan wajib diisi dan tidak boleh hanya berisi spasi.'), findsOneWidget);
      expect(dipanggil, 0);
    });

    testWidgets('validasi server ditampilkan dan input dipertahankan', (tester) async {
      await bukaForm(tester, ({required idSiswa, required isi, kategori, tanggal, lampiranNama, lampiranUkuran}) async {
        return const ApiResponse(
          success: false,
          message: 'Isi catatan maksimal 500 karakter.',
          statusCode: 422,
          errors: {
            'isi_catatan': ['Isi catatan maksimal 500 karakter.'],
          },
        );
      });

      await tester.enterText(find.byKey(const Key('isi-catatan')), 'Catatan yang ditolak server');
      await simpan(tester);

      expect(find.text('Tambah Catatan'), findsOneWidget, reason: 'halaman tidak ditutup');
      expect(find.text('Catatan yang ditolak server'), findsOneWidget, reason: 'input dipertahankan');
      expect(find.text('Isi catatan maksimal 500 karakter.'), findsOneWidget);
      expect(find.text('Catatan gagal disimpan. Isi catatan maksimal 500 karakter.'), findsOneWidget);
    });

    testWidgets('berhasil menyimpan: mengirim isi yang dirapikan lalu menutup halaman', (tester) async {
      int? idDikirim;
      String? isiDikirim;
      final hasil = await bukaForm(tester, (
          {required idSiswa, required isi, kategori, tanggal, lampiranNama, lampiranUkuran}) async {
        idDikirim = idSiswa;
        isiDikirim = isi;
        return ApiResponse(
          success: true,
          message: 'Catatan untuk Ahmad Rizki berhasil disimpan',
          statusCode: 201,
          data: _catatan(10, isi, '2026-10-24 10:00:00'),
        );
      });

      await tester.enterText(find.byKey(const Key('isi-catatan')), '  Rizki rajin hari ini.  ');
      await simpan(tester);

      expect(idDikirim, 1);
      expect(isiDikirim, 'Rizki rajin hari ini.');
      expect(await hasil, isTrue);
      expect(find.byType(TambahCatatanPage), findsNothing);
      expect(find.text('Catatan untuk Ahmad Rizki berhasil disimpan'), findsOneWidget);
    });
  });
}
