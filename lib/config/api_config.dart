import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL backend API Laravel
  /// - Android Emulator: 10.0.2.2:8000
  /// - Web / Windows Desktop: 127.0.0.1:8000
  /// - Real Device: ganti dengan IP lokal laptop/komputer Anda (misal: 192.168.1.x:8000)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  static const Duration timeoutDuration = Duration(seconds: 15);
}
