import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_main_page.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';
import 'package:digital_book_connect/screens/admin/kelola_guru_page.dart';
import 'package:digital_book_connect/screens/admin/kelola_kelas_page.dart';

void main() {
  group('Model Kelola Data Admin', () {
    test('GuruAdmin.fromJson membaca profil, status, dan kelas wali', () {
      final guru = GuruAdmin.fromJson({
        'id_guru': 1,
        'id_user': 2,
        'nama': 'Bapak Ahmad',
        'username': 'guru',
        'status': 'nonaktif',
        'nip': '198501152010011002',
        'no_hp': null,
        'kelas_wali': [
          {'id_kelas': 1, 'nama_kelas': '5A', 'tahun_ajaran': '2026/2027'},
        ],
        'jumlah_catatan': 3,
      });

      expect(guru.nama, 'Bapak Ahmad');
      expect(guru.aktif, isFalse);
      expect(guru.noHp, isNull);
      expect(guru.kelasWali.single.namaKelas, '5A');
      expect(guru.jumlahCatatan, 3);
    });

    test('OrangTuaAdmin.fromJson membaca daftar anak beserta hubungan', () {
      final ortu = OrangTuaAdmin.fromJson({
        'id_orang_tua': '4',
        'id_user': 5,
        'nama': 'Ibu Siti Nurhaliza',
        'username': 'ortu',
        'status': 'aktif',
        'no_hp': '081298765432',
        'alamat': '',
        'anak': [
          {'id_siswa': 1, 'nis': '1001', 'nama': 'Ahmad Rizki', 'kelas': '5A', 'perempuan': false, 'hubungan': 'Ibu'},
        ],
      });

      expect(ortu.idOrangTua, 4);
      expect(ortu.alamat, isNull, reason: 'string kosong diperlakukan sebagai tidak ada');
      expect(ortu.anak.single.hubungan, 'Ibu');
    });

    test('SiswaAdmin.fromJson & OrangTuaSiswa.toRequest sesuai format backend', () {
      final siswa = SiswaAdmin.fromJson({
        'id_siswa': 7,
        'nis': '1007',
        'nama': 'Siti Aisyah',
        'jenis_kelamin': 'P',
        'id_kelas': 1,
        'kelas': '5A',
        'tahun_ajaran': '2026/2027',
        'orang_tua': [
          {'id_orang_tua': 9, 'nama': 'Ibu Fatimah', 'no_hp': '0812', 'hubungan': 'Ibu'},
        ],
      });

      expect(siswa.perempuan, isTrue);
      expect(siswa.orangTua.single.toRequest(), {'id_orang_tua': 9, 'hubungan': 'Ibu'});
      expect(siswa.orangTua.single.copyWith(hubungan: 'Wali').hubungan, 'Wali');
    });

    test('KelasAdmin.fromJson & PageMeta', () {
      final kelas = KelasAdmin.fromJson({
        'id_kelas': 2,
        'nama_kelas': '5B',
        'tingkat': '5',
        'tahun_ajaran': '2026/2027',
        'id_wali_guru': 2,
        'wali_guru': 'Ibu Nurul Hidayah',
        'total_siswa': 3,
        'siswa': [
          {'id_siswa': 4, 'nis': '1004', 'nama': 'Citra Lestari', 'perempuan': true},
        ],
      });
      expect(kelas.waliGuru, 'Ibu Nurul Hidayah');
      expect(kelas.siswa.single.perempuan, isTrue);

      final meta = PageMeta.fromJson({'current_page': 2, 'last_page': 3, 'per_page': 10, 'total': 25});
      expect(meta.adaSebelumnya, isTrue);
      expect(meta.adaBerikutnya, isTrue);
      expect(PageMeta.fromJson(const {}).lastPage, 1);
    });

    test('ApiResponse.errorFor mengambil pesan validasi pertama', () {
      const res = ApiResponse<void>(
        success: false,
        message: 'Username sudah digunakan.',
        statusCode: 422,
        errors: {'username': ['Username sudah digunakan.']},
      );
      expect(res.errorFor('username'), 'Username sudah digunakan.');
      expect(res.errorFor('nama'), isNull);
      expect(errorPerField(res), {'username': 'Username sudah digunakan.'});
    });
  });

  group('AdminListPage (daftar + pencarian + pagination)', () {
    // Data palsu: 12 item, 5 per halaman
    final semua = List.generate(12, (i) => 'Guru ${i + 1}');
    late List<(int, String)> panggilan;

    Future<ApiResponse<PagedResult<String>>> fetcher(int page, String search) async {
      panggilan.add((page, search));
      final cocok = semua.where((n) => n.contains(search)).toList();
      final lastPage = cocok.isEmpty ? 1 : ((cocok.length - 1) ~/ 5) + 1;
      final items = cocok.skip((page - 1) * 5).take(5).toList();
      return ApiResponse(
        success: true,
        message: 'ok',
        statusCode: 200,
        data: PagedResult(
          items: items,
          meta: PageMeta(currentPage: page, lastPage: lastPage, perPage: 5, total: cocok.length),
        ),
      );
    }

    Widget halaman(PageFetcher<String> f) => MaterialApp(
          home: AdminListPage<String>(
            key: UniqueKey(),
            judul: 'Kelola Guru',
            hintCari: 'Cari...',
            labelTambah: 'Tambah Guru',
            teksKosong: 'Belum ada data guru',
            fetcher: f,
            itemBuilder: (nama, onTap) => ListItemTile(judul: Text(nama), onTap: onTap),
            onBukaDetail: (_, _) async {},
            onTambah: (_) async => false,
          ),
        );

    setUp(() => panggilan = []);

    testWidgets('menampilkan halaman pertama dan berpindah halaman', (tester) async {
      await tester.pumpWidget(halaman(fetcher));
      await tester.pumpAndSettle();

      expect(find.text('Guru 1'), findsOneWidget);
      expect(find.text('Guru 6'), findsNothing);
      expect(find.text('12 data ditemukan'), findsOneWidget);
      expect(find.text('Halaman 1 dari 3'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('halaman-berikutnya')));
      await tester.tap(find.byKey(const Key('halaman-berikutnya')));
      await tester.pumpAndSettle();

      expect(panggilan.last, (2, ''));
      expect(find.text('Guru 6'), findsOneWidget);
      expect(find.text('Halaman 2 dari 3'), findsOneWidget);
    });

    testWidgets('pencarian mengirim kata kunci & menampilkan hasil kosong', (tester) async {
      await tester.pumpWidget(halaman(fetcher));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Guru 12');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(panggilan.last, (1, 'Guru 12'));
      expect(find.text('Guru 12'), findsWidgets);
      expect(find.text('1 data ditemukan'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Tidak Ada');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada hasil untuk "Tidak Ada"'), findsOneWidget);
    });

    testWidgets('menampilkan pesan kosong & pesan gagal beserta tombol coba lagi', (tester) async {
      await tester.pumpWidget(halaman((page, search) async => const ApiResponse(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: PagedResult<String>(items: [], meta: PageMeta()),
          )));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada data guru'), findsOneWidget);

      var percobaan = 0;
      await tester.pumpWidget(halaman((page, search) async {
        percobaan++;
        return const ApiResponse(success: false, message: 'Akses ditolak untuk peran Anda.', statusCode: 403);
      }));
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat data'), findsOneWidget);
      expect(find.text('Akses ditolak untuk peran Anda.'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(percobaan, 2);
    });
  });

  group('Navigasi & Form Admin', () {
    testWidgets('Tab Data menampilkan keempat menu kelola data', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminDataPage()));
      for (final label in ['Kelola Guru', 'Kelola Orang Tua', 'Kelola Siswa', 'Kelola Kelas']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('Form Tambah Guru menahan simpan saat field wajib kosong', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FormGuruPage()));
      await tester.ensureVisible(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Nama wajib diisi'), findsOneWidget);
      expect(find.text('Username wajib diisi'), findsOneWidget);
      expect(find.text('NIP wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
      // Status akun hanya muncul saat mengubah data
      expect(find.text('Akun aktif'), findsNothing);
    });

    testWidgets('Form Ubah Guru: kata sandi opsional dan status akun tampil', (tester) async {
      const guru = GuruAdmin(idGuru: 1, idUser: 2, nama: 'Bapak Ahmad', username: 'guru', status: 'aktif', nip: '1985');
      await tester.pumpWidget(const MaterialApp(home: FormGuruPage(guru: guru)));

      expect(find.text('Ubah Guru'), findsOneWidget);
      expect(find.text('Bapak Ahmad'), findsOneWidget);
      expect(find.text('Kosongkan jika kata sandi tidak diubah.'), findsOneWidget);
      expect(find.text('Akun aktif'), findsOneWidget);
    });

    testWidgets('Form Kelas memvalidasi format tahun ajaran & wali kelas', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FormKelasPage()));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '6A');
      await tester.enterText(fields.at(1), '6');
      await tester.enterText(fields.at(2), '2026-2027');
      await tester.ensureVisible(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Format tahun ajaran harus YYYY/YYYY, contoh: 2026/2027'), findsOneWidget);
      expect(find.text('Wali kelas wajib dipilih'), findsOneWidget);
    });
  });
}
