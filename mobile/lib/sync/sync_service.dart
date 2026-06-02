import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/entities.dart';
import '../data/field_spec.dart';
import '../db/app_database.dart';
import '../db/record_repository.dart';

class SyncResult {
  final bool ok;
  final String message;
  final int pushed;
  final int failed;
  const SyncResult(this.ok, this.message, {this.pushed = 0, this.failed = 0});
}

/// خدمة المزامنة: التطبيق يعمل دون اتصال بالكامل، والمزامنة (الرفع للسيرفر)
/// تتطلب تسجيل دخول وتُنفَّذ عند الطلب فقط.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _kUrl = 'server_url';
  static const _kUser = 'sync_username';
  static const _kLastSync = 'last_sync';
  static const _kToken = 'sync_token';
  static const _defaultUrl = 'http://192.168.1.100:8000';

  /// خريطة جدول التطبيق → مفتاح الحزمة المتوقّع في السيرفر.
  static const Map<String, String> _bundleKeys = {
    'consent': 'consent',
    'detention_event': 'detention_events',
    'detention_period': 'detention_periods',
    'release': 'release_event',
    'witness': 'witnesses',
    'document': 'documents',
    'medical': 'medical_assessments',
    'impact': 'long_term_impact',
    'interview': 'interviews',
    'note': 'notes',
    'household': 'household_survey',
    'child': 'children',
    'housing': 'housing',
    'education': 'education',
    'employment': 'employment',
    'health': 'health_access',
    'needs': 'needs',
  };

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final RecordRepository _repo = RecordRepository.instance;

  String _baseUrl = _defaultUrl;
  String? _token;
  String? _username;
  String? _lastSync;

  String get baseUrl => _baseUrl;
  String? get username => _username;
  String? get lastSync => _lastSync;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  String get _api => '$_baseUrl/api/v1';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_kUrl) ?? _defaultUrl;
    _username = prefs.getString(_kUser);
    _lastSync = prefs.getString(_kLastSync);
    _token = await _secure.read(key: _kToken);
  }

  Future<void> setBaseUrl(String url) async {
    url = url.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isEmpty) return;
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrl, url);
  }

  Future<void> logout() async {
    _token = null;
    await _secure.delete(key: _kToken);
  }

  Future<SyncResult> login(String username, String password) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_api/auth/login/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'device_name': 'تطبيق حقّنا (أندرويد)',
              'device_id': 'flutter-app',
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        _token = data['token'] as String?;
        _username = username;
        await _secure.write(key: _kToken, value: _token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUser, username);
        return const SyncResult(true, 'تم تسجيل الدخول بنجاح');
      } else if (resp.statusCode == 401) {
        return const SyncResult(false, 'اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      return SyncResult(false, 'تعذّر تسجيل الدخول (رمز ${resp.statusCode})');
    } catch (_) {
      return const SyncResult(
          false, 'تعذّر الوصول للسيرفر — تأكد من العنوان والاتصال بالشبكة');
    }
  }

  /// رفع كل الملفات التي عليها تغييرات غير مُزامَنة.
  Future<SyncResult> push() async {
    if (!isLoggedIn) {
      return const SyncResult(false, 'يجب تسجيل الدخول أولاً');
    }
    final dirty = await _dirtySurvivorIds();
    if (dirty.isEmpty) {
      return const SyncResult(true, 'كل البيانات مُزامَنة — لا تغييرات جديدة');
    }

    final bundles = <Map<String, dynamic>>[];
    final attachments = <String, File>{};
    for (final sid in dirty) {
      final b = await _buildBundle(sid);
      if (b == null) continue;
      _extractAttachments(b, attachments);
      bundles.add(b);
    }

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$_api/sync/push/'));
      request.headers['Authorization'] = 'Token $_token';
      request.fields['payload'] =
          jsonEncode({'survivors': bundles, 'device_id': 'flutter-app'});
      for (final entry in attachments.entries) {
        final f = entry.value;
        if (!await f.exists()) continue;
        request.files.add(await http.MultipartFile.fromPath(
          entry.key,
          f.path,
          filename: p.basename(f.path),
        ));
      }
      final streamed =
          await request.send().timeout(const Duration(seconds: 180));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 401) {
        await logout();
        return const SyncResult(
            false, 'انتهت صلاحية الجلسة — يرجى تسجيل الدخول من جديد');
      }
      if (resp.statusCode != 200) {
        return SyncResult(false, 'فشلت المزامنة (رمز ${resp.statusCode})');
      }

      final data =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      int pushed = 0, failed = 0;
      for (final r in results) {
        final m = r as Map<String, dynamic>;
        if (m['ok'] == true) {
          pushed++;
          final localId = m['_local_id'];
          final serverId = m['server_id'];
          if (localId is int) {
            await _markSurvivorSynced(
                localId, serverId is int ? serverId : null);
          }
        } else {
          failed++;
        }
      }

      _lastSync = DateTime.now().toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSync, _lastSync!);

      final msg = failed == 0
          ? 'تمت مزامنة $pushed ملف بنجاح'
          : 'تمت مزامنة $pushed ملف · فشل $failed';
      return SyncResult(true, msg, pushed: pushed, failed: failed);
    } catch (_) {
      return const SyncResult(
          false, 'تعذّر الوصول للسيرفر أثناء المزامنة — حاول لاحقاً');
    }
  }

  /// يمشي على الحزمة المُجمَّعة ويستبدل كل مسار صورة محلية برمز
  /// `att:<token>` ويضيف الملف إلى خريطة المرفقات للرفع.
  void _extractAttachments(
      Map<String, dynamic> bundle, Map<String, File> out) {
    void process(EntitySpec spec, Map<String, dynamic> row) {
      for (final f in spec.fields) {
        if (f.type != FieldType.image) continue;
        final v = row[f.key];
        if (v is! String || v.isEmpty || v.startsWith('att:')) continue;
        final file = File(v);
        if (!file.existsSync()) continue;
        final token = 'att:${out.length}-${DateTime.now().microsecondsSinceEpoch}';
        out[token] = file;
        row[f.key] = token;
      }
    }

    process(kSurvivorSpec, bundle);
    for (final entry in _bundleKeys.entries) {
      final spec = entityByTable(entry.key);
      final v = bundle[entry.value];
      if (spec.singleton) {
        if (v is Map<String, dynamic>) process(spec, v);
      } else if (v is List) {
        for (final item in v) {
          if (item is Map<String, dynamic>) process(spec, item);
        }
      }
    }
  }

  Future<Set<int>> _dirtySurvivorIds() async {
    final db = AppDatabase.instance.db;
    final ids = <int>{};
    final sv =
        await db.rawQuery('SELECT local_id FROM survivor WHERE needs_sync = 1');
    for (final r in sv) {
      ids.add(r['local_id'] as int);
    }
    for (final e in kRelatedEntities) {
      final rows = await db.rawQuery(
          'SELECT DISTINCT survivor_local_id FROM ${e.table} '
          'WHERE needs_sync = 1');
      for (final r in rows) {
        final v = r['survivor_local_id'] as int?;
        if (v != null && v != 0) ids.add(v);
      }
    }
    return ids;
  }

  Future<Map<String, dynamic>?> _buildBundle(int sid) async {
    final survivor = await _repo.getById('survivor', sid);
    if (survivor == null) return null;
    final bundle = <String, dynamic>{};
    bundle.addAll(survivor.data);
    bundle['_local_id'] = sid;
    if (survivor.serverId != null) bundle['_server_id'] = survivor.serverId;

    for (final entry in _bundleKeys.entries) {
      final spec = entityByTable(entry.key);
      final records = await _repo.listForSurvivor(entry.key, sid);
      if (records.isEmpty) continue;
      if (spec.singleton) {
        bundle[entry.value] = records.first.data;
      } else {
        bundle[entry.value] = records.map((r) => r.data).toList();
      }
    }
    return bundle;
  }

  Future<void> _markSurvivorSynced(int localId, int? serverId) async {
    final db = AppDatabase.instance.db;
    await db.update(
      'survivor',
      {'needs_sync': 0, if (serverId != null) 'server_id': serverId},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    for (final e in kRelatedEntities) {
      await db.update(
        e.table,
        {'needs_sync': 0},
        where: 'survivor_local_id = ?',
        whereArgs: [localId],
      );
    }
  }
}
