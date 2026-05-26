import 'package:uuid/uuid.dart';

import '../models/survivor.dart';
import 'api_client.dart';
import 'database_service.dart';

/// خدمة إدارة الناجين - تعمل offline-first:
/// - الكتابة تذهب لـSQLite دائماً مع علم needs_sync=true
/// - القراءة من SQLite دائماً
/// - المزامنة تتم منفصلة عبر SyncService
class SurvivorService {
  static final SurvivorService instance = SurvivorService._();
  SurvivorService._();

  final _uuid = const Uuid();

  Future<List<Survivor>> list({String? query}) {
    return DatabaseService.instance.getAllSurvivors(query: query);
  }

  Future<Survivor?> getByLocalId(String localId) {
    return DatabaseService.instance.getByLocalId(localId);
  }

  /// إنشاء ناجٍ جديد محلياً - يُحفَظ مع needs_sync=true
  Future<Survivor> create(Survivor s) async {
    s.localId = _uuid.v4();
    s.needsSync = true;
    s.createdAt = DateTime.now().toIso8601String();
    s.updatedAt = s.createdAt;
    await DatabaseService.instance.upsertSurvivor(s);
    return s;
  }

  /// تعديل ناجٍ - يُحدّث محلياً مع needs_sync=true
  Future<Survivor> update(Survivor s) async {
    s.needsSync = true;
    s.updatedAt = DateTime.now().toIso8601String();
    await DatabaseService.instance.upsertSurvivor(s);
    return s;
  }

  Future<int> pendingCount() {
    return DatabaseService.instance.countPendingSync();
  }
}
