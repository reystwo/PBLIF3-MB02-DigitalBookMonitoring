import 'package:digital_book_connect/models/orang_tua_models.dart';
import 'package:digital_book_connect/services/api_service.dart';

/// Service layer endpoint khusus Orang Tua / Wali (/api/orang-tua/*).
/// Anak yang ditampilkan ditentukan backend dari akun login, sehingga
/// aplikasi tidak pernah mengirim id orang tua.
class OrangTuaRepository {
  /// Daftar anak yang ditautkan Administrator pada akun orang tua yang login.
  static Future<ApiResponse<List<AnakOrangTua>>> getAnak() async {
    final res = await ApiService.get('/orang-tua/anak');
    if (res.success && res.data is List) {
      final anak = (res.data as List).whereType<Map<String, dynamic>>().map(AnakOrangTua.fromJson).toList();
      return ApiResponse(success: true, message: res.message, data: anak, statusCode: res.statusCode);
    }
    return ApiResponse(
      success: false,
      message: res.success ? 'Format respons server tidak sesuai.' : res.message,
      statusCode: res.statusCode,
    );
  }
}
