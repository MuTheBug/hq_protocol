import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/survivor.dart';

/// قاعدة بيانات محلية SQLite - تخزّن الناجين offline
///
/// كل ناجٍ يُحفَظ مع علم `needs_sync`:
/// - true: تم إنشاؤه/تعديله محلياً ولم يُرفع للسيرفر بعد
/// - false: مُتزامن مع السيرفر
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Database get db {
    if (_db == null) {
      throw StateError('قاعدة البيانات غير مُهيّأة. استدعِ init() أولاً.');
    }
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'haqquna.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE survivors (
        local_id TEXT PRIMARY KEY,
        id INTEGER,
        case_reference TEXT NOT NULL UNIQUE,
        case_uid TEXT,
        first_name TEXT,
        father_name TEXT,
        grandfather_name TEXT,
        family_name TEXT,
        mother_name TEXT,
        alias TEXT,
        national_id TEXT,
        birth_date TEXT,
        birth_date_approximate INTEGER DEFAULT 0,
        birth_governorate TEXT,
        birth_place_detail TEXT,
        gender TEXT,
        nationality TEXT DEFAULT 'سورية',
        marital_status_at_detention TEXT,
        address_at_detention TEXT,
        governorate_at_detention TEXT,
        occupation_category TEXT,
        occupation_detail TEXT,
        political_activity_category TEXT,
        political_activity_detail TEXT,
        current_phone TEXT,
        current_email TEXT,
        current_country TEXT,
        current_governorate TEXT,
        current_city TEXT,
        next_of_kin_name TEXT,
        next_of_kin_relation TEXT,
        next_of_kin_phone TEXT,
        file_classification TEXT DEFAULT 'draft',
        reliability_score INTEGER DEFAULT 0,
        corroboration_score INTEGER DEFAULT 0,
        completeness_score INTEGER DEFAULT 0,
        overall_score REAL DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        needs_sync INTEGER DEFAULT 0,
        sync_error TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_needs_sync ON survivors(needs_sync)');
    await db.execute('CREATE INDEX idx_case_ref ON survivors(case_reference)');

    // كاش للبيانات المرجعية
    await db.execute('''
      CREATE TABLE reference_cache (
        key TEXT PRIMARY KEY,
        json TEXT,
        cached_at TEXT
      )
    ''');
  }

  // ============================================================
  // عمليات الناجين
  // ============================================================

  Future<List<Survivor>> getAllSurvivors({String? query}) async {
    String where = 'is_archived = 0';
    List<Object?> args = [];
    if (query != null && query.isNotEmpty) {
      where +=
          ' AND (case_reference LIKE ? OR first_name LIKE ? OR father_name LIKE ? OR family_name LIKE ? OR national_id LIKE ?)';
      final q = '%$query%';
      args = [q, q, q, q, q];
    }
    final rows = await db.query(
      'survivors',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Survivor.fromDbMap(r)).toList();
  }

  Future<Survivor?> getByLocalId(String localId) async {
    final rows = await db.query(
      'survivors',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Survivor.fromDbMap(rows.first);
  }

  Future<Survivor?> getByCaseReference(String caseRef) async {
    final rows = await db.query(
      'survivors',
      where: 'case_reference = ?',
      whereArgs: [caseRef],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Survivor.fromDbMap(rows.first);
  }

  Future<List<Survivor>> getPendingSyncSurvivors() async {
    final rows = await db.query(
      'survivors',
      where: 'needs_sync = 1',
    );
    return rows.map((r) => Survivor.fromDbMap(r)).toList();
  }

  Future<int> countPendingSync() async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as c FROM survivors WHERE needs_sync = 1',
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> upsertSurvivor(Survivor s) async {
    s.localId ??= s.caseReference;
    await db.insert(
      'survivors',
      s.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markSynced(String localId, int serverId, String caseUid) async {
    await db.update(
      'survivors',
      {
        'id': serverId,
        'case_uid': caseUid,
        'needs_sync': 0,
        'sync_error': null,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markSyncFailed(String localId, String error) async {
    await db.update(
      'survivors',
      {'sync_error': error},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteAll() async {
    await db.delete('survivors');
    await db.delete('reference_cache');
  }

  // ============================================================
  // كاش المرجع
  // ============================================================

  Future<void> cacheReference(String key, String json) async {
    await db.insert(
      'reference_cache',
      {
        'key': key,
        'json': json,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readCache(String key) async {
    final rows = await db.query(
      'reference_cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['json'] as String?;
  }
}
