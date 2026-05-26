import 'package:shared_preferences/shared_preferences.dart';

/// إدارة عنوان السيرفر - يخزّن في SharedPreferences حتى يستمر بين الجلسات
class ApiConfig {
  static const String _kBaseUrl = 'haqquna_base_url';
  static const String defaultUrl = 'http://192.168.1.100:8000';

  static String _baseUrl = defaultUrl;

  static String get baseUrl => _baseUrl;

  /// نقطة الـAPI الأساسية
  static String get apiUrl => '$_baseUrl/api/v1';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_kBaseUrl) ?? defaultUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    // إزالة الـtrailing slash
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, url);
  }
}
