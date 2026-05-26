import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// نتيجة استدعاء API
class ApiResult<T> {
  final bool ok;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResult.success(this.data, {this.statusCode})
      : ok = true,
        error = null;
  ApiResult.failure(this.error, {this.statusCode})
      : ok = false,
        data = null;
}

/// HTTP client مبسّط مع دعم Token authentication ومعالجة أخطاء الشبكة
class ApiClient {
  String? _token;

  static final ApiClient instance = ApiClient._();
  ApiClient._();

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers({bool authenticated = true}) {
    final h = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (authenticated && _token != null) {
      h['Authorization'] = 'Token $_token';
    }
    return h;
  }

  Future<ApiResult<Map<String, dynamic>>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path').replace(
      queryParameters: query,
    );
    try {
      late http.Response res;
      final headers = _headers(authenticated: authenticated);
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: headers).timeout(timeout);
          break;
        case 'POST':
          res = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(timeout);
          break;
        case 'PUT':
          res = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(timeout);
          break;
        case 'PATCH':
          res = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(timeout);
          break;
        default:
          return ApiResult.failure('Method غير مدعوم: $method');
      }

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes))
            as Map<String, dynamic>?;
      } catch (_) {
        data = {};
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResult.success(data, statusCode: res.statusCode);
      }
      final errMsg = data?['detail'] ??
          data?['error'] ??
          'خطأ من السيرفر: ${res.statusCode}';
      return ApiResult.failure(errMsg.toString(),
          statusCode: res.statusCode);
    } on SocketException {
      return ApiResult.failure('لا يوجد اتصال بالشبكة');
    } on HttpException {
      return ApiResult.failure('فشل الاتصال بالسيرفر');
    } on FormatException {
      return ApiResult.failure('استجابة غير صالحة من السيرفر');
    } catch (e) {
      return ApiResult.failure('خطأ غير متوقع: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) =>
      _request('GET', path, query: query, authenticated: authenticated);

  Future<ApiResult<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) =>
      _request('POST', path, body: body, authenticated: authenticated);

  Future<ApiResult<Map<String, dynamic>>> put(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('PUT', path, body: body);

  Future<ApiResult<Map<String, dynamic>>> patch(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('PATCH', path, body: body);
}
