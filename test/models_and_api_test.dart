import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_book_connect/config/api_config.dart';
import 'package:digital_book_connect/models/user_model.dart';
import 'package:digital_book_connect/models/siswa_model.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/data/dummy_data.dart';

void main() {
  group('Data Models & JSON Serialization Tests (DAT-01 & SEC-01)', () {
    test('UserModel deserializes correctly with role and profile getters', () {
      final json = {
        'id_user': 2,
        'nama': 'Bapak Ahmad S.Pd',
        'username': 'guru1',
        'role': 'guru',
        'status': 'aktif',
        'peran_label': 'Guru Kelas',
        'guru': {
          'id_guru': 1,
          'nip': '198501012010011001',
          'nama_guru': 'Ahmad Dahlan, S.Pd',
        },
        'orang_tua': null,
      };

      final user = UserModel.fromJson(json);
      expect(user.idUser, equals(2));
      expect(user.nama, equals('Bapak Ahmad S.Pd'));
      expect(user.username, equals('guru1'));
      expect(user.role, equals('guru'));
      expect(user.namaGuru, equals('Ahmad Dahlan, S.Pd'));
      expect(user.namaOrangTua, isNull);

      final outJson = user.toJson();
      expect(outJson['id_user'], equals(2));
      expect(outJson['role'], equals('guru'));
    });

    test('SiswaModel and KelasModel deserialization & dummy data bridge', () {
      final json = {
        'id_siswa': 1,
        'nis': '1001',
        'nama': 'Ahmad Rizki',
        'jenis_kelamin': 'L',
        'perempuan': false,
        'id_kelas': 1,
        'kelas': '5A',
        'orang_tua': [],
      };

      final siswaModel = SiswaModel.fromJson(json);
      expect(siswaModel.idSiswa, equals(1));
      expect(siswaModel.nama, equals('Ahmad Rizki'));
      expect(siswaModel.kelas, equals('5A'));
      expect(siswaModel.perempuan, isFalse);

      final dummySiswa = Siswa.fromModel(siswaModel);
      expect(dummySiswa.idSiswa, equals(1));
      expect(dummySiswa.nama, equals('Ahmad Rizki'));
      expect(dummySiswa.kelas, equals('5A'));
      expect(dummySiswa.perempuan, isFalse);

      final backToModel = dummySiswa.toModel();
      expect(backToModel.nama, equals('Ahmad Rizki'));
    });

    test('CatatanModel and LampiranModel deserialization', () {
      final json = {
        'id_catatan': 10,
        'id_siswa': 1,
        'id_pengirim': 2,
        'id_penerima': 3,
        'penulis': 'Bapak Ahmad',
        'peran_penulis': 'Guru Kelas 5A',
        'penulis_perempuan': false,
        'kategori': 'Akademik',
        'isi': 'Perkembangan membaca sangat baik.',
        'tanggal': '2026-10-14T08:00:00.000Z',
        'tanggal_label': '14 Okt 2026',
        'status_dibaca': 'dibaca',
        'siswa': {
          'id_siswa': 1,
          'nis': '1001',
          'nama': 'Ahmad Rizki',
          'kelas': '5A',
        },
        'lampiran': {
          'nama_file': 'catatan.pdf',
          'ukuran': '1.2 MB',
        },
      };

      final catatan = CatatanModel.fromJson(json);
      expect(catatan.idCatatan, equals(10));
      expect(catatan.penulis, equals('Bapak Ahmad'));
      expect(catatan.isi, equals('Perkembangan membaca sangat baik.'));
      expect(catatan.lampiran?.namaFile, equals('catatan.pdf'));
      expect(catatan.siswa.nama, equals('Ahmad Rizki'));

      final dummyCatatan = Catatan.fromModel(catatan);
      expect(dummyCatatan.idCatatan, equals(10));
      expect(dummyCatatan.penulis, equals('Bapak Ahmad'));
      expect(dummyCatatan.lampiran?.namaFile, equals('catatan.pdf'));
    });

    test('ApiResponse isSuccess getter returns true for successful response', () {
      const resp = ApiResponse<String>(
        success: true,
        message: 'OK',
        data: 'Halo',
        statusCode: 200,
      );
      expect(resp.isSuccess, isTrue);
      expect(resp.data, equals('Halo'));
    });
  });

  group('ApiConfig Smart Fallback & Base URL Tests', () {
    setUp(() {
      // Mock SharedPreferences memory store for unit testing
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
    });

    test('ApiConfig default candidates contains local USB, LAN IP, and Emulator URLs', () {
      expect(ApiConfig.candidateUrls, contains('http://127.0.0.1:8000/api'));
      expect(ApiConfig.candidateUrls, contains('http://192.168.1.7:8000/api'));
      expect(ApiConfig.candidateUrls, contains('http://10.0.2.2:8000/api'));
    });

    test('ApiConfig custom base URL setter and reset mechanism', () async {
      await ApiConfig.setCustomBaseUrl('http://192.168.1.100:8000/api');
      expect(ApiConfig.baseUrl, equals('http://192.168.1.100:8000/api'));
      expect(ApiConfig.hasCustomBaseUrl, isTrue);

      await ApiConfig.resetBaseUrl();
      expect(ApiConfig.hasCustomBaseUrl, isFalse);
    });
  });
}
