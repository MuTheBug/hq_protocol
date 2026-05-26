import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/related.dart';
import '../models/survivor.dart';

/// قاعدة بيانات محلية SQLite - تخزّن كل الكيانات offline.
/// كل جدول له عمود needs_sync لتتبّع المعلّقات.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;
  Database get db {
    if (_db == null) throw StateError('init() أولاً');
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'haqquna.db');
    _db = await openDatabase(dbPath, version: 2, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSurvivors(db);
    await _createEvents(db);
    await _createPeriods(db);
    await _createReleases(db);
    await _createConsents(db);
    await _createWitnesses(db);
    await _createNotes(db);
    await db.execute('''
      CREATE TABLE reference_cache (
        key TEXT PRIMARY KEY, json TEXT, cached_at TEXT
      )
    ''');
  }

  Future<void> _createSurvivors(Database db) async {
    await db.execute('''
      CREATE TABLE survivors (
        local_id TEXT PRIMARY KEY,
        id INTEGER, case_reference TEXT NOT NULL UNIQUE, case_uid TEXT,
        first_name TEXT, father_name TEXT, grandfather_name TEXT,
        family_name TEXT, mother_name TEXT, alias TEXT,
        national_id TEXT, birth_date TEXT,
        birth_date_approximate INTEGER DEFAULT 0,
        birth_governorate TEXT, birth_place_detail TEXT,
        gender TEXT, nationality TEXT DEFAULT 'سورية',
        marital_status_at_detention TEXT,
        address_at_detention TEXT, governorate_at_detention TEXT,
        occupation_category TEXT, occupation_detail TEXT,
        political_activity_category TEXT, political_activity_detail TEXT,
        current_phone TEXT, current_email TEXT,
        current_country TEXT, current_governorate TEXT, current_city TEXT,
        next_of_kin_name TEXT, next_of_kin_relation TEXT, next_of_kin_phone TEXT,
        file_classification TEXT DEFAULT 'draft',
        reliability_score INTEGER DEFAULT 0,
        corroboration_score INTEGER DEFAULT 0,
        completeness_score INTEGER DEFAULT 0,
        overall_score REAL DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        created_at TEXT, updated_at TEXT,
        needs_sync INTEGER DEFAULT 0, sync_error TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_s_sync ON survivors(needs_sync)');
    await db.execute('CREATE INDEX idx_s_ref ON survivors(case_reference)');
  }

  Future<void> _createEvents(Database db) async {
    await db.execute('''
      CREATE TABLE detention_events (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        detention_date TEXT, date_approximate INTEGER DEFAULT 0,
        detention_location TEXT, governorate TEXT,
        arresting_entity TEXT,
        arresting_personnel_details TEXT, reason_stated TEXT,
        circumstances TEXT, witnesses_to_arrest TEXT,
        family_notified INTEGER DEFAULT 0, notes TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_e_survivor ON detention_events(survivor_local_id)');
  }

  Future<void> _createPeriods(Database db) async {
    await db.execute('''
      CREATE TABLE detention_periods (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        facility_id INTEGER, facility_name TEXT,
        from_date TEXT, to_date TEXT, order_index INTEGER DEFAULT 1,
        cell_description TEXT, cellmates_count INTEGER,
        torture_description TEXT,
        sexual_violence_reported INTEGER DEFAULT 0,
        notes TEXT, torture_method_ids TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_p_survivor ON detention_periods(survivor_local_id)');
  }

  Future<void> _createReleases(Database db) async {
    await db.execute('''
      CREATE TABLE release_events (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT UNIQUE, survivor_id INTEGER,
        release_date TEXT, release_type TEXT DEFAULT 'unknown',
        release_location TEXT, bribe_amount TEXT,
        conditions TEXT, circumstances TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createConsents(Database db) async {
    await db.execute('''
      CREATE TABLE informed_consents (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT UNIQUE, survivor_id INTEGER,
        consent_documented INTEGER DEFAULT 0,
        consent_date TEXT, consent_witness TEXT,
        share_with_iiim INTEGER DEFAULT 0,
        share_with_coi INTEGER DEFAULT 0,
        share_with_icc INTEGER DEFAULT 0,
        share_with_universal_jurisdiction INTEGER DEFAULT 0,
        share_with_partner_orgs INTEGER DEFAULT 0,
        share_with_media INTEGER DEFAULT 0,
        share_publicly INTEGER DEFAULT 0,
        anonymize_name INTEGER DEFAULT 0,
        anonymize_photo INTEGER DEFAULT 0,
        anonymize_location INTEGER DEFAULT 0,
        anonymize_family_details INTEGER DEFAULT 0,
        withdrawal_right_explained INTEGER DEFAULT 0,
        confidentiality_limits_explained INTEGER DEFAULT 0,
        intended_uses_explained INTEGER DEFAULT 0,
        consent_withdrawn INTEGER DEFAULT 0,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createWitnesses(Database db) async {
    await db.execute('''
      CREATE TABLE witnesses (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        witness_name TEXT, witness_phone TEXT,
        witness_current_location TEXT,
        facility_id INTEGER, facility_name TEXT,
        period_from TEXT, period_to TEXT, cell_number TEXT,
        how_recognized TEXT, distinguishing_details TEXT,
        specific_incidents TEXT,
        relationship_before TEXT DEFAULT 'stranger',
        is_independent INTEGER DEFAULT 0,
        met_after_release INTEGER DEFAULT 0,
        consent_to_use_testimony INTEGER DEFAULT 0,
        declaration_signed INTEGER DEFAULT 0,
        declaration_date TEXT,
        full_testimony TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_w_survivor ON witnesses(survivor_local_id)');
  }

  Future<void> _createNotes(Database db) async {
    await db.execute('''
      CREATE TABLE survivor_notes (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        note_type TEXT DEFAULT 'general', title TEXT, content TEXT,
        is_pinned INTEGER DEFAULT 0,
        is_confidential INTEGER DEFAULT 0,
        author_username TEXT, created_at TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_n_survivor ON survivor_notes(survivor_local_id)');
  }

  // ============================================================
  // Survivors
  // ============================================================
  Future<List<Survivor>> getAllSurvivors({String? query}) async {
    String where = 'is_archived = 0';
    List<Object?> args = [];
    if (query != null && query.isNotEmpty) {
      where += ' AND (case_reference LIKE ? OR first_name LIKE ? '
          'OR father_name LIKE ? OR family_name LIKE ? OR national_id LIKE ?)';
      final q = '%$query%';
      args = [q, q, q, q, q];
    }
    final rows = await db.query('survivors',
        where: where, whereArgs: args, orderBy: 'created_at DESC');
    return rows.map(Survivor.fromDbMap).toList();
  }

  Future<Survivor?> getByLocalId(String localId) async {
    final rows = await db.query('survivors',
        where: 'local_id = ?', whereArgs: [localId], limit: 1);
    if (rows.isEmpty) return null;
    return Survivor.fromDbMap(rows.first);
  }

  Future<int> countPendingSync() async {
    int total = 0;
    for (final table in [
      'survivors', 'detention_events', 'detention_periods',
      'release_events', 'informed_consents', 'witnesses', 'survivor_notes',
    ]) {
      final r = await db.rawQuery(
          'SELECT COUNT(*) c FROM $table WHERE needs_sync = 1');
      total += (r.first['c'] as int?) ?? 0;
    }
    return total;
  }

  Future<void> upsertSurvivor(Survivor s) async {
    s.localId ??= s.caseReference;
    await db.insert('survivors', s.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Survivor>> getPendingSurvivors() async {
    final rows = await db.query('survivors', where: 'needs_sync = 1');
    return rows.map(Survivor.fromDbMap).toList();
  }

  Future<void> markSurvivorSynced(String localId, int serverId, String? uid) async {
    await db.update('survivors',
        {'id': serverId, 'case_uid': uid, 'needs_sync': 0, 'sync_error': null},
        where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> markSurvivorSyncFailed(String localId, String err) async {
    await db.update('survivors', {'sync_error': err},
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ============================================================
  // Detention Events
  // ============================================================
  Future<List<DetentionEvent>> getEventsFor(String survivorLocalId) async {
    final rows = await db.query('detention_events',
        where: 'survivor_local_id = ?', whereArgs: [survivorLocalId],
        orderBy: 'detention_date');
    return rows.map(DetentionEvent.fromDbMap).toList();
  }

  Future<void> upsertEvent(DetentionEvent e) async {
    await db.insert('detention_events', e.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEvent(String localId) async {
    await db.delete('detention_events',
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ============================================================
  // Detention Periods
  // ============================================================
  Future<List<DetentionPeriod>> getPeriodsFor(String survivorLocalId) async {
    final rows = await db.query('detention_periods',
        where: 'survivor_local_id = ?', whereArgs: [survivorLocalId],
        orderBy: 'order_index, from_date');
    return rows.map(DetentionPeriod.fromDbMap).toList();
  }

  Future<void> upsertPeriod(DetentionPeriod p) async {
    await db.insert('detention_periods', p.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePeriod(String localId) async {
    await db.delete('detention_periods',
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ============================================================
  // Release Events
  // ============================================================
  Future<ReleaseEvent?> getReleaseFor(String survivorLocalId) async {
    final rows = await db.query('release_events',
        where: 'survivor_local_id = ?', whereArgs: [survivorLocalId], limit: 1);
    if (rows.isEmpty) return null;
    return ReleaseEvent.fromDbMap(rows.first);
  }

  Future<void> upsertRelease(ReleaseEvent r) async {
    await db.insert('release_events', r.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ============================================================
  // Informed Consents
  // ============================================================
  Future<InformedConsent?> getConsentFor(String survivorLocalId) async {
    final rows = await db.query('informed_consents',
        where: 'survivor_local_id = ?', whereArgs: [survivorLocalId], limit: 1);
    if (rows.isEmpty) return null;
    return InformedConsent.fromDbMap(rows.first);
  }

  Future<void> upsertConsent(InformedConsent c) async {
    await db.insert('informed_consents', c.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ============================================================
  // Witnesses
  // ============================================================
  Future<List<Witness>> getWitnessesFor(String survivorLocalId) async {
    final rows = await db.query('witnesses',
        where: 'survivor_local_id = ?', whereArgs: [survivorLocalId]);
    return rows.map(Witness.fromDbMap).toList();
  }

  Future<void> upsertWitness(Witness w) async {
    await db.insert('witnesses', w.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWitness(String localId) async {
    await db.delete('witnesses',
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ============================================================
  // Notes
  // ============================================================
  Future<List<SurvivorNote>> getNotesFor(String survivorLocalId) async {
    final rows = await db.query('survivor_notes',
        where: 'survivor_local_id = ?', whereArgs: [survivorLocalId],
        orderBy: 'is_pinned DESC, created_at DESC');
    return rows.map(SurvivorNote.fromDbMap).toList();
  }

  Future<void> upsertNote(SurvivorNote n) async {
    await db.insert('survivor_notes', n.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteNote(String localId) async {
    await db.delete('survivor_notes',
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ============================================================
  // Reference cache
  // ============================================================
  Future<void> cacheReference(String key, String json) async {
    await db.insert('reference_cache',
        {'key': key, 'json': json, 'cached_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> readCache(String key) async {
    final rows = await db.query('reference_cache',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['json'] as String?;
  }

  Future<void> deleteAll() async {
    for (final t in [
      'survivors', 'detention_events', 'detention_periods',
      'release_events', 'informed_consents', 'witnesses',
      'survivor_notes', 'reference_cache',
    ]) {
      await db.delete(t);
    }
  }
}
