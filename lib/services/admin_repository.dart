import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/api_service.dart';

/// Service layer endpoint kelola data Admin (/api/admin/*).
/// Hak akses ditegakkan oleh backend (middleware role:admin).
class AdminRepository {
  // ==================== GURU ====================

  static Future<ApiResponse<PagedResult<GuruAdmin>>> getGuru({int page = 1, int perPage = 10, String? search}) =>
      _daftar('/admin/guru', GuruAdmin.fromJson, page: page, perPage: perPage, search: search);

  static Future<ApiResponse<GuruAdmin>> getDetailGuru(int idGuru) async =>
      _objek(await ApiService.get('/admin/guru/$idGuru'), GuruAdmin.fromJson);

  /// Tambah (idGuru null) atau ubah data guru.
  static Future<ApiResponse<GuruAdmin>> simpanGuru(Map<String, dynamic> data, {int? idGuru}) async => _objek(
        idGuru == null
            ? await ApiService.post('/admin/guru', body: data)
            : await ApiService.put('/admin/guru/$idGuru', body: data),
        GuruAdmin.fromJson,
      );

  /// [hapusCatatan]: jumlah catatan penghubung yang dikonfirmasi Admin untuk ikut terhapus.
  static Future<ApiResponse<int>> hapusGuru(int idGuru, {int hapusCatatan = 0}) =>
      _hapus('/admin/guru/$idGuru', hapusCatatan: hapusCatatan);

  // ==================== ORANG TUA ====================

  static Future<ApiResponse<PagedResult<OrangTuaAdmin>>> getOrangTua({int page = 1, int perPage = 10, String? search}) =>
      _daftar('/admin/orang-tua', OrangTuaAdmin.fromJson, page: page, perPage: perPage, search: search);

  static Future<ApiResponse<OrangTuaAdmin>> getDetailOrangTua(int idOrangTua) async =>
      _objek(await ApiService.get('/admin/orang-tua/$idOrangTua'), OrangTuaAdmin.fromJson);

  static Future<ApiResponse<OrangTuaAdmin>> simpanOrangTua(Map<String, dynamic> data, {int? idOrangTua}) async =>
      _objek(
        idOrangTua == null
            ? await ApiService.post('/admin/orang-tua', body: data)
            : await ApiService.put('/admin/orang-tua/$idOrangTua', body: data),
        OrangTuaAdmin.fromJson,
      );

  /// [hapusCatatan]: jumlah catatan penghubung yang dikonfirmasi Admin untuk ikut terhapus.
  static Future<ApiResponse<int>> hapusOrangTua(int idOrangTua, {int hapusCatatan = 0}) =>
      _hapus('/admin/orang-tua/$idOrangTua', hapusCatatan: hapusCatatan);

  // ==================== SISWA ====================

  static Future<ApiResponse<PagedResult<SiswaAdmin>>> getSiswa({
    int page = 1,
    int perPage = 10,
    String? search,
    int? idKelas,
  }) =>
      _daftar('/admin/siswa', SiswaAdmin.fromJson,
          page: page, perPage: perPage, search: search, filter: {if (idKelas != null) 'id_kelas': '$idKelas'});

  static Future<ApiResponse<SiswaAdmin>> getDetailSiswa(int idSiswa) async =>
      _objek(await ApiService.get('/admin/siswa/$idSiswa'), SiswaAdmin.fromJson);

  static Future<ApiResponse<SiswaAdmin>> simpanSiswa(Map<String, dynamic> data, {int? idSiswa}) async => _objek(
        idSiswa == null
            ? await ApiService.post('/admin/siswa', body: data)
            : await ApiService.put('/admin/siswa/$idSiswa', body: data),
        SiswaAdmin.fromJson,
      );

  /// [hapusCatatan]: jumlah catatan penghubung yang dikonfirmasi Admin untuk ikut terhapus.
  static Future<ApiResponse<int>> hapusSiswa(int idSiswa, {int hapusCatatan = 0}) =>
      _hapus('/admin/siswa/$idSiswa', hapusCatatan: hapusCatatan);

  // ==================== KELAS ====================

  static Future<ApiResponse<PagedResult<KelasAdmin>>> getKelas({int page = 1, int perPage = 10, String? search}) =>
      _daftar('/admin/kelas', KelasAdmin.fromJson, page: page, perPage: perPage, search: search);

  static Future<ApiResponse<KelasAdmin>> getDetailKelas(int idKelas) async =>
      _objek(await ApiService.get('/admin/kelas/$idKelas'), KelasAdmin.fromJson);

  static Future<ApiResponse<KelasAdmin>> simpanKelas(Map<String, dynamic> data, {int? idKelas}) async => _objek(
        idKelas == null
            ? await ApiService.post('/admin/kelas', body: data)
            : await ApiService.put('/admin/kelas/$idKelas', body: data),
        KelasAdmin.fromJson,
      );

  static Future<ApiResponse<int>> hapusKelas(int idKelas) => _hapus('/admin/kelas/$idKelas');

  /// Keluarkan siswa dari kelas: hanya melepas relasi kelas, data siswa tetap ada.
  static Future<ApiResponse<int>> keluarkanSiswaDariKelas(int idKelas, int idSiswa) =>
      _hapus('/admin/kelas/$idKelas/siswa/$idSiswa');

  // ==================== HELPER ====================

  static Future<ApiResponse<PagedResult<T>>> _daftar<T>(
    String endpoint,
    T Function(Map<String, dynamic>) parse, {
    required int page,
    required int perPage,
    String? search,
    Map<String, String> filter = const {},
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      ...filter,
    };

    final res = await ApiService.get(endpoint, queryParams: params);
    if (res.success && res.data is List) {
      final items = (res.data as List).whereType<Map<String, dynamic>>().map(parse).toList();
      return ApiResponse(
        success: true,
        message: res.message,
        data: PagedResult(items: items, meta: PageMeta.fromJson(res.meta ?? const {})),
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(success: false, message: res.message, statusCode: res.statusCode);
  }

  static ApiResponse<T> _objek<T>(ApiResponse<dynamic> res, T Function(Map<String, dynamic>) parse) {
    if (res.success && res.data is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        message: res.message,
        data: parse(res.data as Map<String, dynamic>),
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(success: false, message: res.message, statusCode: res.statusCode, errors: res.errors);
  }

  /// DELETE endpoint. `data` hasil berisi jumlah catatan penghubung terbaru bila
  /// backend meminta konfirmasi penghapusan catatan (409), selain itu null.
  static Future<ApiResponse<int>> _hapus(String endpoint, {int hapusCatatan = 0}) async {
    final res = await ApiService.delete(hapusCatatan > 0 ? '$endpoint?hapus_catatan=$hapusCatatan' : endpoint);
    final data = res.data;
    final jumlahCatatan = (data is Map && data['perlu_konfirmasi_catatan'] == true)
        ? int.tryParse('${data['jumlah_catatan']}')
        : null;
    return ApiResponse(success: res.success, message: res.message, statusCode: res.statusCode, data: jumlahCatatan);
  }
}
