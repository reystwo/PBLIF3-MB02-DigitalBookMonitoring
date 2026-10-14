import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_book_connect/models/user_model.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Simpan sesi login
  static Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    final prefs = await _instance;
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Ambil token Sanctum
  static Future<String?> getToken() async {
    final prefs = await _instance;
    return prefs.getString(_keyToken);
  }

  /// Ambil user yang sedang login
  static Future<UserModel?> getUser() async {
    final prefs = await _instance;
    final userStr = prefs.getString(_keyUser);
    if (userStr == null) return null;
    try {
      final userMap = jsonDecode(userStr) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }

  /// Periksa apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Hapus sesi (Logout)
  static Future<void> clearSession() async {
    final prefs = await _instance;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
