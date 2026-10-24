import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/guru_models.dart';
import 'package:digital_book_connect/services/api_service.dart';

/// Service layer endpoint khusus Guru (/api/guru/*).
/// Cakupan siswa (kelas yang diampu) dan identitas pengirim catatan
/// ditegakkan oleh backend; aplikasi tidak pernah mengirim id guru.
class GuruRepository {
  static Future<ApiResponse<PagedResult<SiswaGuru>>> getSiswa({int page = 1, int perPage = 10, String? search}) =>
      _daftar('/guru/siswa', SiswaGuru.fromJson, page: page, perPage: perPage, search: search);

  static Future<ApiResponse<SiswaGuru>> getDetailSiswa(int idSiswa) async {
    final res = await ApiService.get('/guru/siswa/$idSiswa');
    if (res.success && res.data is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        message: res.message,
        data: SiswaGuru.fromJson(res.data as Map<String, dynamic>),
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(success: false, message: res.message, statusCode: res.statusCode);
  }

  /// Riwayat catatan siswa, terbaru lebih dulu.
  static Future<ApiResponse<PagedResult<CatatanModel>>> getCatatanSiswa(int idSiswa, {int page = 1, int perPage = 10}) =>
      _daftar('/guru/siswa/$idSiswa/catatan', CatatanModel.fromJson, page: page, perPage: perPage);

  static Future<ApiResponse<CatatanModel>> tambahCatatan({
    required int idSiswa,
    required String isi,
    String? kategori,
    DateTime? tanggal,
    String? lampiranNama,
    String? lampiranUkuran,
  }) async {
    final res = await ApiService.post('/guru/siswa/$idSiswa/catatan', body: {
      'isi_catatan': isi,
      if (kategori != null && kategori.isNotEmpty) 'kategori': kategori,
      if (tanggal != null) 'tanggal': tanggal.toIso8601String(),
      if (lampiranNama != null && lampiranNama.isNotEmpty) 'lampiran_nama': lampiranNama,
      if (lampiranUkuran != null && lampiranUkuran.isNotEmpty) 'lampiran_ukuran': lampiranUkuran,
    });
    if (res.success && res.data is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        message: res.message,
        data: CatatanModel.fromJson(res.data as Map<String, dynamic>),
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(success: false, message: res.message, statusCode: res.statusCode, errors: res.errors);
  }

  static Future<ApiResponse<PagedResult<T>>> _daftar<T>(
    String endpoint,
    T Function(Map<String, dynamic>) parse, {
    required int page,
    required int perPage,
    String? search,
  }) async {
    final res = await ApiService.get(endpoint, queryParams: {
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
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
}
