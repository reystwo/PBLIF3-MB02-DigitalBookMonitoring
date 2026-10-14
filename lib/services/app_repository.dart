import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/siswa_model.dart';
import 'package:digital_book_connect/models/user_model.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/session_manager.dart';

class AppRepository {
  // ==================== AUTHENTICATION ====================

  /// Login ke sistem
  static Future<ApiResponse<UserModel>> login({
    required String username,
    required String password,
    String? role,
  }) async {
    final res = await ApiService.post('/login', withAuth: false, body: {
      'username': username,
      'password': password,
      if (role != null && role.isNotEmpty) 'role': role,
    });

    if (res.success && res.data is Map<String, dynamic>) {
      final token = res.data['token']?.toString() ?? '';
      final userJson = res.data['user'] as Map<String, dynamic>? ?? {};
      final user = UserModel.fromJson(userJson);

      await SessionManager.saveSession(token: token, user: user);

      return ApiResponse(
        success: true,
        message: res.message,
        data: user,
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  /// Profil user aktif
  static Future<ApiResponse<UserModel>> getProfile() async {
    final res = await ApiService.get('/me');
    if (res.success && res.data is Map<String, dynamic>) {
      final userJson = res.data['user'] as Map<String, dynamic>? ?? {};
      final user = UserModel.fromJson(userJson);
      return ApiResponse(
        success: true,
        message: res.message,
        data: user,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await ApiService.post('/logout');
    } catch (_) {}
    await SessionManager.clearSession();
  }

  // ==================== SISWA & KELAS ====================

  /// Ambil daftar siswa
  static Future<ApiResponse<List<SiswaModel>>> getSiswa({
    String? kelas,
    String? search,
  }) async {
    final params = <String, String>{};
    if (kelas != null && kelas.isNotEmpty) params['kelas'] = kelas;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await ApiService.get('/siswa', queryParams: params);
    if (res.success && res.data is List) {
      final list = (res.data as List)
          .map((item) => SiswaModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return ApiResponse(
        success: true,
        message: res.message,
        data: list,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      data: [],
      statusCode: res.statusCode,
    );
  }

  /// Ambil daftar kelas
  static Future<ApiResponse<List<KelasModel>>> getKelas() async {
    final res = await ApiService.get('/kelas');
    if (res.success && res.data is List) {
      final list = (res.data as List)
          .map((item) => KelasModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return ApiResponse(
        success: true,
        message: res.message,
        data: list,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      data: [],
      statusCode: res.statusCode,
    );
  }

  // ==================== CATATAN PENGHUBUNG ====================

  /// Ambil riwayat catatan
  static Future<ApiResponse<List<CatatanModel>>> getCatatan({
    int? idSiswa,
    String? kategori,
    String? search,
  }) async {
    final params = <String, String>{};
    if (idSiswa != null) params['id_siswa'] = idSiswa.toString();
    if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await ApiService.get('/catatan', queryParams: params);
    if (res.success && res.data is List) {
      final list = (res.data as List)
          .map((item) => CatatanModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return ApiResponse(
        success: true,
        message: res.message,
        data: list,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      data: [],
      statusCode: res.statusCode,
    );
  }

  /// Detail satu catatan
  static Future<ApiResponse<CatatanModel>> getDetailCatatan(int idCatatan) async {
    final res = await ApiService.get('/catatan/$idCatatan');
    if (res.success && res.data is Map<String, dynamic>) {
      final catatan = CatatanModel.fromJson(res.data as Map<String, dynamic>);
      return ApiResponse(
        success: true,
        message: res.message,
        data: catatan,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  /// Buat catatan baru (Guru/Admin)
  static Future<ApiResponse<CatatanModel>> createCatatan({
    required int idSiswa,
    required String isi,
    String? kategori,
    DateTime? tanggal,
    String? lampiranNama,
    String? lampiranUkuran,
  }) async {
    final body = <String, dynamic>{
      'id_siswa': idSiswa,
      'isi_catatan': isi,
      if (kategori != null && kategori.isNotEmpty) 'kategori': kategori,
      if (tanggal != null) 'tanggal': tanggal.toIso8601String(),
      if (lampiranNama != null && lampiranNama.isNotEmpty) 'lampiran_nama': lampiranNama,
      if (lampiranUkuran != null && lampiranUkuran.isNotEmpty) 'lampiran_ukuran': lampiranUkuran,
    };

    final res = await ApiService.post('/catatan', body: body);
    if (res.success && res.data is Map<String, dynamic>) {
      final catatan = CatatanModel.fromJson(res.data as Map<String, dynamic>);
      return ApiResponse(
        success: true,
        message: res.message,
        data: catatan,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  /// Balas catatan
  static Future<ApiResponse<CatatanModel>> replyCatatan({
    required int idCatatan,
    required String isi,
  }) async {
    final res = await ApiService.post('/catatan/$idCatatan/balas', body: {
      'isi_catatan': isi,
    });
    if (res.success && res.data is Map<String, dynamic>) {
      final catatan = CatatanModel.fromJson(res.data as Map<String, dynamic>);
      return ApiResponse(
        success: true,
        message: res.message,
        data: catatan,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  // ==================== DASHBOARD & NOTIFIKASI ====================

  /// Data dashboard ringkasan
  static Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    final res = await ApiService.get('/dashboard');
    if (res.success && res.data is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        message: res.message,
        data: res.data as Map<String, dynamic>,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  /// Data notifikasi / feed aktivitas
  static Future<ApiResponse<List<AktivitasModel>>> getNotifikasi() async {
    final res = await ApiService.get('/notifikasi');
    if (res.success && res.data is List) {
      final list = (res.data as List)
          .map((item) => AktivitasModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return ApiResponse(
        success: true,
        message: res.message,
        data: list,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      message: res.message,
      data: [],
      statusCode: res.statusCode,
    );
  }
}
