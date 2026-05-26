import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/choices.dart';
import '../models/survivor.dart';
import 'api_client.dart';
import 'database_service.dart';

class SyncResult {
  final int pushed;
  final int pulled;
  final int errors;
  final List<String> errorMessages;
  SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.errors = 0,
    this.errorMessages = const [],
  });
}

/// خدمة المزامنة - تدفع المعلّقات للسيرفر وتسحب التغييرات
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _connectivity = Connectivity();
  StreamSubscription? _connectivitySub;

  /// يبدأ الاستماع للاتصال - عند توفر الشبكة يُشغّل المزامنة آلياً
  void startAutoSync({Function(SyncResult)? onSync}) {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) async {
      final hasNet = result.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.mobile);
      if (hasNet) {
        final res = await syncNow();
        if (onSync != null) onSync(res);
      }
    });
  }

  void stopAutoSync() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<bool> hasConnection() async {
    final res = await _connectivity.checkConnectivity();
    return res.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile);
  }

  /// مزامنة كاملة: push ثم pull
  Future<SyncResult> syncNow() async {
    if (!await hasConnection()) {
      return SyncResult(errors: 1, errorMessages: ['لا يوجد اتصال']);
    }

    int pushed = 0, errors = 0;
    final errorMessages = <String>[];

    // 1. Push: ارفع المعلّقات
    final pending = await DatabaseService.instance.getPendingSyncSurvivors();
    if (pending.isNotEmpty) {
      final body = {
        'device_id': 'mobile',
        'survivors': pending.map((s) {
          final m = s.toApiJson();
          m['_local_id'] = s.localId;
          return m;
        }).toList(),
      };
      final res = await ApiClient.instance.post('/sync/push/', body);
      if (res.ok && res.data != null) {
        final results = res.data!['results'] as List? ?? [];
        for (final r in results) {
          final localId = r['_local_id'] as String?;
          if (r['ok'] == true && localId != null) {
            await DatabaseService.instance.markSynced(
              localId,
              r['server_id'] as int,
              '', // case_uid يأتي في pull
            );
            pushed++;
          } else if (localId != null) {
            await DatabaseService.instance.markSyncFailed(
              localId, r['error']?.toString() ?? 'فشل غير معروف',
            );
            errors++;
            errorMessages.add('${r['case_reference']}: ${r['error']}');
          }
        }
      } else {
        errors++;
        errorMessages.add(res.error ?? 'فشل push');
      }
    }

    // 2. Pull: اسحب التغييرات (آخر مزامنة = آخر updated_at محلي)
    int pulled = await _pullChanges();

    return SyncResult(
      pushed: pushed,
      pulled: pulled,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  Future<int> _pullChanges() async {
    // ابحث عن آخر updated_at لدينا
    final db = DatabaseService.instance.db;
    final rows = await db.rawQuery(
      'SELECT MAX(updated_at) AS last_sync FROM survivors WHERE id IS NOT NULL',
    );
    final since = rows.first['last_sync'] as String?;

    final res = await ApiClient.instance.get(
      '/sync/pull/',
      query: since != null ? {'since': since} : null,
    );
    if (!res.ok || res.data == null) return 0;
    final survivors = res.data!['survivors'] as List? ?? [];
    int pulled = 0;
    for (final j in survivors) {
      try {
        final s = Survivor.fromJson(j as Map<String, dynamic>);
        s.localId = s.caseReference;
        s.needsSync = false;
        await DatabaseService.instance.upsertSurvivor(s);
        pulled++;
      } catch (_) {}
    }
    return pulled;
  }

  /// تحميل البيانات المرجعية وتخزينها (يُستدعى مرة بعد تسجيل الدخول)
  Future<ReferenceData?> loadReferenceData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await DatabaseService.instance.readCache('reference');
      if (cached != null) {
        return ReferenceData.fromJson(jsonDecode(cached));
      }
    }
    final res = await ApiClient.instance.get('/reference/');
    if (!res.ok || res.data == null) {
      // ربما offline - حاول الكاش
      final cached = await DatabaseService.instance.readCache('reference');
      return cached != null
          ? ReferenceData.fromJson(jsonDecode(cached))
          : null;
    }
    await DatabaseService.instance.cacheReference(
      'reference', jsonEncode(res.data),
    );
    return ReferenceData.fromJson(res.data!);
  }
}
