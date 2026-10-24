import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:digital_book_connect/config/api_config.dart';
import 'package:digital_book_connect/services/session_manager.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;
  // Info halaman dari endpoint ber-pagination (current_page, last_page, per_page, total)
  final Map<String, dynamic>? meta;
  // Pesan validasi per field dari respons 422 Laravel
  final Map<String, List<String>> errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
    this.meta,
    this.errors = const {},
  });

  bool get isSuccess => success;

  /// Pesan validasi pertama untuk sebuah field, atau null jika tidak ada.
  String? errorFor(String field) {
    final list = errors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }
}

class ApiService {
  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// GET Request dengan dukungan Smart Fallback
  static Future<ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    return _executeWithFallback(
      (baseUrl) async {
        var uri = Uri.parse('$baseUrl$endpoint');
        if (queryParams != null && queryParams.isNotEmpty) {
          uri = uri.replace(queryParameters: queryParams);
        }

        final headers = await _headers(withAuth: withAuth);
        final response = await http
            .get(uri, headers: headers)
            .timeout(ApiConfig.timeoutDuration);

        return _processResponse(response);
      },
    );
  }

  /// POST Request dengan dukungan Smart Fallback
  static Future<ApiResponse<dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    return _executeWithFallback(
      (baseUrl) async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final headers = await _headers(withAuth: withAuth);
        final response = await http
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConfig.timeoutDuration);

        return _processResponse(response);
      },
    );
  }

  /// PATCH Request dengan dukungan Smart Fallback
  static Future<ApiResponse<dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    return _executeWithFallback(
      (baseUrl) async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final headers = await _headers(withAuth: withAuth);
        final response = await http
            .patch(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConfig.timeoutDuration);

        return _processResponse(response);
      },
    );
  }

  /// PUT Request dengan dukungan Smart Fallback
  static Future<ApiResponse<dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    return _executeWithFallback(
      (baseUrl) async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final headers = await _headers(withAuth: withAuth);
        final response = await http
            .put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConfig.timeoutDuration);

        return _processResponse(response);
      },
    );
  }

  /// DELETE Request dengan dukungan Smart Fallback
  static Future<ApiResponse<dynamic>> delete(
    String endpoint, {
    bool withAuth = true,
  }) async {
    return _executeWithFallback(
      (baseUrl) async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final headers = await _headers(withAuth: withAuth);
        final response = await http
            .delete(uri, headers: headers)
            .timeout(ApiConfig.timeoutDuration);

        return _processResponse(response);
      },
    );
  }

  /// Wrapper eksekusi request dengan otomatis mencoba fallback URL jika URL pertama gagal
  static Future<ApiResponse<dynamic>> _executeWithFallback(
    Future<ApiResponse<dynamic>> Function(String baseUrl) requestFn,
  ) async {
    final initialBaseUrl = ApiConfig.baseUrl;

    try {
      return await requestFn(initialBaseUrl);
    } on SocketException catch (_) {
      return await _handleConnectionFailure(initialBaseUrl, requestFn);
    } on TimeoutException catch (_) {
      return await _handleConnectionFailure(initialBaseUrl, requestFn);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Terjadi kesalahan jaringan: $e',
        statusCode: 500,
      );
    }
  }

  /// Penanganan kegagalan koneksi: Coba auto-discovery candidate URLs
  static Future<ApiResponse<dynamic>> _handleConnectionFailure(
    String failedBaseUrl,
    Future<ApiResponse<dynamic>> Function(String baseUrl) requestFn,
  ) async {
    // Jika user mengunci customBaseUrl, jangan auto-fallback ke URL lain
    if (!ApiConfig.hasCustomBaseUrl) {
      final discoveredUrl = await ApiConfig.discoverWorkingBaseUrl();
      if (discoveredUrl != null && discoveredUrl != failedBaseUrl) {
        try {
          return await requestFn(discoveredUrl);
        } catch (_) {}
      }
    }

    return const ApiResponse(
      success: false,
      message:
          'Tidak dapat terhubung ke server backend. Pastikan server Laravel aktif atau atur IP server di menu Pengaturan Server.',
      statusCode: 0,
    );
  }

  static ApiResponse<dynamic> _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    String message = 'Terjadi kesalahan';
    Map<String, dynamic>? meta;
    final errors = <String, List<String>>{};

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody['message'] != null) {
        message = jsonBody['message'].toString();
      }
      if (jsonBody['meta'] is Map<String, dynamic>) {
        meta = jsonBody['meta'] as Map<String, dynamic>;
      }
      if (jsonBody['errors'] is Map<String, dynamic>) {
        (jsonBody['errors'] as Map<String, dynamic>).forEach((field, pesan) {
          errors[field] = pesan is List ? pesan.map((e) => e.toString()).toList() : [pesan.toString()];
        });
      }
    }

    return ApiResponse(
      success: isSuccess,
      message: message,
      data: jsonBody is Map<String, dynamic> ? jsonBody['data'] : jsonBody,
      statusCode: response.statusCode,
      meta: meta,
      errors: errors,
    );
  }
}
