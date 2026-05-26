import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';

/// إدارة تسجيل الدخول وtoken المخزّن بأمان
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user_json';
  static const _kDeviceId = 'device_id';

  final _storage = const FlutterSecureStorage();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<void> init() async {
    await ApiConfig.load();
    _token = await _storage.read(key: _kToken);
    final userJson = await _storage.read(key: _kUser);
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
    if (_token != null) {
      ApiClient.instance.setToken(_token);
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    var id = await _storage.read(key: _kDeviceId);
    if (id == null) {
      id = 'haqquna-${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: _kDeviceId, value: id);
    }
    return id;
  }

  Future<String> _getDeviceName() async {
    try {
      return '${Platform.operatingSystem}-${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }

  /// تسجيل دخول → يحفظ الـtoken في secure storage
  Future<ApiResult<User>> login(String username, String password) async {
    final deviceId = await _getOrCreateDeviceId();
    final deviceName = await _getDeviceName();
    final res = await ApiClient.instance.post(
      '/auth/login/',
      {
        'username': username,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName,
      },
      authenticated: false,
    );
    if (!res.ok || res.data == null) {
      return ApiResult.failure(res.error ?? 'فشل تسجيل الدخول');
    }
    _token = res.data!['token'] as String?;
    _currentUser = User.fromJson(res.data!['user'] as Map<String, dynamic>);
    if (_token != null) {
      ApiClient.instance.setToken(_token);
      await _storage.write(key: _kToken, value: _token);
      await _storage.write(
        key: _kUser, value: jsonEncode(_currentUser!.toJson()));
    }
    return ApiResult.success(_currentUser);
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post('/auth/logout/', {});
    } catch (_) {}
    _token = null;
    _currentUser = null;
    ApiClient.instance.setToken(null);
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
  }
}
