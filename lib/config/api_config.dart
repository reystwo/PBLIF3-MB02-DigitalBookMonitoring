import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String prefKeyCustomBaseUrl = 'custom_api_base_url';

  /// IP LAN laptop saat ini (terdeteksi via Wi-Fi)
  static const String defaultLanIp = '192.168.1.7';
  static const String defaultPort = '8000';

  /// URL aktif di memori sesi saat ini
  static String? _activeBaseUrl;
  static bool _hasCustomUrl = false;

  /// Daftar kandidat URL default untuk auto-fallback di Android
  static List<String> get candidateUrls => [
        'http://127.0.0.1:8000/api', // USB kabel via adb reverse
        'http://$defaultLanIp:$defaultPort/api', // HP Fisik via Wi-Fi LAN
        'http://10.0.2.2:8000/api', // Android Emulator
      ];

  /// Inisialisasi awal membaca preferensi pengguna
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(prefKeyCustomBaseUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _activeBaseUrl = _normalizeUrl(savedUrl);
        _hasCustomUrl = true;
      }
    } catch (_) {}
  }

  /// Cek apakah pengguna mengatur custom base URL
  static bool get hasCustomBaseUrl => _hasCustomUrl;

  /// Mengambil Base URL aktif
  static String get baseUrl {
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      return _activeBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Default awal ke 127.0.0.1 (berhasil jika adb reverse aktif)
        return 'http://127.0.0.1:8000/api';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  /// Mengambil custom base URL tersimpan (jika ada)
  static Future<String?> getCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefKeyCustomBaseUrl);
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan custom base URL dari pengaturan pengguna
  static Future<void> setCustomBaseUrl(String url) async {
    final normalized = _normalizeUrl(url);
    _activeBaseUrl = normalized;
    _hasCustomUrl = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyCustomBaseUrl, normalized);
    } catch (_) {}
  }

  /// Mengatur active base URL sementara di sesi memori
  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = _normalizeUrl(url);
  }

  /// Reset pengaturan URL ke mode otomatis
  static Future<void> resetBaseUrl() async {
    _activeBaseUrl = null;
    _hasCustomUrl = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKeyCustomBaseUrl);
    } catch (_) {}
  }

  /// Normalisasi URL agar berakhiran '/api' dan tanpa trailing slash
  static String _normalizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  /// Menguji koneksi ke candidate base URL melalui endpoint /health
  static Future<bool> testConnection(String candidateBaseUrl) async {
    try {
      final normalized = _normalizeUrl(candidateBaseUrl);
      final healthUri = Uri.parse('$normalized/health');

      final response = await http
          .get(healthUri)
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Smart Discovery: Mencari URL server yang merespons
  static Future<String?> discoverWorkingBaseUrl() async {
    for (final candidate in candidateUrls) {
      final ok = await testConnection(candidate);
      if (ok) {
        _activeBaseUrl = candidate;
        return candidate;
      }
    }
    return null;
  }

  static const Duration timeoutDuration = Duration(seconds: 15);
  static const Duration quickCheckTimeout = Duration(seconds: 2);
}
