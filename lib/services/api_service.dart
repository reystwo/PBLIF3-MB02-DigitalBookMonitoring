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

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  bool get isSuccess => success;
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

  /// GET Request
  static Future<ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _headers(withAuth: withAuth);
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeoutDuration);

      return _processResponse(response);
    } on SocketException {
      return const ApiResponse(
        success: false,
        message: 'Tidak dapat terhubung ke server backend. Pastikan server Laravel/Laragon aktif.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        message: 'Koneksi ke server waktu habis (timeout).',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Terjadi kesalahan jaringan: $e',
        statusCode: 500,
      );
    }
  }

  /// POST Request
  static Future<ApiResponse<dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _headers(withAuth: withAuth);
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);

      return _processResponse(response);
    } on SocketException {
      return const ApiResponse(
        success: false,
        message: 'Tidak dapat terhubung ke server backend. Pastikan server Laravel/Laragon aktif.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        message: 'Koneksi ke server waktu habis (timeout).',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Terjadi kesalahan jaringan: $e',
        statusCode: 500,
      );
    }
  }

  /// PATCH Request
  static Future<ApiResponse<dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _headers(withAuth: withAuth);
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);

      return _processResponse(response);
    } on SocketException {
      return const ApiResponse(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        message: 'Koneksi ke server waktu habis (timeout).',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Terjadi kesalahan jaringan: $e',
        statusCode: 500,
      );
    }
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

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody['message'] != null) {
        message = jsonBody['message'].toString();
      }
    }

    return ApiResponse(
      success: isSuccess,
      message: message,
      data: jsonBody is Map<String, dynamic> ? jsonBody['data'] : jsonBody,
      statusCode: response.statusCode,
    );
  }
}
