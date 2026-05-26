import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/more_models.dart';
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
    _db = await openDatabase(dbPath, version: 3, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSurvivors(db);
    await _createEvents(db);
    await _createPeriods(db);
    await _createReleases(db);
    await _createConsents(db);
    await _createWitnesses(db);
    await _createNotes(db);
    await _createDocuments(db);
    await _createMedical(db);
    await _createImpact(db);
    await _createInterviews(db);
    await _createHouseholds(db);
    await _createChildren(db);
    await _createHousing(db);
    await _createEducation(db);
    await _createEmployment(db);
    await _createHealth(db);
    await _createNeeds(db);
    await db.execute('''
      CREATE TABLE reference_cache (
        key TEXT PRIMARY KEY, json TEXT, cached_at TEXT
      )
    ''');
  }

  Future<void> _createDocuments(Database db) async {
    await db.execute('''
      CREATE TABLE supporting_documents (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        document_type TEXT DEFAULT 'other', title TEXT, description TEXT,
        file_path TEXT, file_name TEXT, file_size_bytes INTEGER,
        source_description TEXT, date_obtained TEXT,
        original_url TEXT, document_date TEXT,
        document_reference_number TEXT, issuing_authority TEXT,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_doc_survivor ON supporting_documents(survivor_local_id)');
  }

  Future<void> _createMedical(Database db) async {
    await db.execute('''
      CREATE TABLE medical_assessments (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        assessment_type TEXT DEFAULT 'physical',
        assessment_date TEXT, assessor_name TEXT,
        assessor_credentials TEXT, assessor_organization TEXT,
        istanbul_protocol_compliant INTEGER DEFAULT 0,
        physical_findings TEXT, scars_description TEXT,
        disabilities TEXT, psychological_findings TEXT,
        ptsd_indicators INTEGER DEFAULT 0,
        depression_indicators INTEGER DEFAULT 0,
        anxiety_indicators INTEGER DEFAULT 0,
        consistency_with_account TEXT DEFAULT 'not_assessed',
        consistency_notes TEXT,
        consent_to_share INTEGER DEFAULT 0,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_med_survivor ON medical_assessments(survivor_local_id)');
  }

  Future<void> _createImpact(Database db) async {
    await db.execute('''
      CREATE TABLE long_term_impacts (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT UNIQUE,
        physical_injuries_permanent TEXT, chronic_illnesses TEXT,
        disabilities TEXT, psychological_symptoms TEXT,
        sleep_disorders INTEGER DEFAULT 0,
        flashbacks INTEGER DEFAULT 0,
        social_withdrawal INTEGER DEFAULT 0,
        family_impact TEXT, work_impact TEXT,
        education_impact TEXT, financial_impact TEXT,
        current_medications TEXT,
        receiving_treatment INTEGER DEFAULT 0,
        treatment_details TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createInterviews(Database db) async {
    await db.execute('''
      CREATE TABLE interviews (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT, survivor_id INTEGER,
        sequence_number INTEGER DEFAULT 1,
        is_first INTEGER DEFAULT 0, interview_date TEXT,
        duration_minutes INTEGER,
        location_type TEXT DEFAULT 'office', location_detail TEXT,
        language TEXT DEFAULT 'ar_levantine',
        methodology TEXT DEFAULT 'istanbul',
        recorded INTEGER DEFAULT 0,
        consent_to_record INTEGER DEFAULT 0,
        consent_to_publish_recording INTEGER DEFAULT 0,
        summary TEXT,
        gender_appropriate INTEGER DEFAULT 0,
        psychological_referral_after INTEGER DEFAULT 0,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_int_survivor ON interviews(survivor_local_id)');
  }

  Future<void> _createHouseholds(Database db) async {
    await db.execute('''
      CREATE TABLE household_surveys (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT UNIQUE, survivor_id INTEGER,
        marital_status TEXT DEFAULT 'single',
        marital_status_changed_due_to_detention INTEGER DEFAULT 0,
        spouse_name TEXT, spouse_alive INTEGER DEFAULT 1,
        spouse_detained_now INTEGER DEFAULT 0,
        spouse_detained_before INTEGER DEFAULT 0,
        spouse_employed INTEGER DEFAULT 0,
        spouse_occupation TEXT, spouse_age INTEGER,
        household_size INTEGER DEFAULT 1,
        dependents_count INTEGER DEFAULT 0,
        children_count INTEGER DEFAULT 0,
        displacement_status TEXT DEFAULT 'not_displaced',
        displacement_count INTEGER DEFAULT 0,
        original_governorate TEXT, current_governorate TEXT,
        survey_date TEXT, survey_location TEXT,
        survey_notes TEXT,
        consent_to_survey INTEGER DEFAULT 0,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createChildren(Database db) async {
    await db.execute('''
      CREATE TABLE children (
        local_id TEXT PRIMARY KEY, id INTEGER,
        household_local_id TEXT,
        name TEXT, gender TEXT DEFAULT 'male',
        birth_date TEXT, age INTEGER,
        is_in_school INTEGER DEFAULT 1,
        current_stage TEXT DEFAULT 'not_started',
        current_grade TEXT, school_name TEXT,
        dropped_out INTEGER DEFAULT 0,
        dropout_due_to_father_detention INTEGER DEFAULT 0,
        dropout_reason TEXT,
        work_status TEXT DEFAULT 'student',
        has_disability INTEGER DEFAULT 0,
        disability_description TEXT,
        has_chronic_illness INTEGER DEFAULT 0,
        psychological_issues INTEGER DEFAULT 0,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_ch_house ON children(household_local_id)');
  }

  Future<void> _createHousing(Database db) async {
    await db.execute('''
      CREATE TABLE housing_infos (
        local_id TEXT PRIMARY KEY, id INTEGER,
        household_local_id TEXT UNIQUE,
        housing_type TEXT DEFAULT 'rented',
        rent_amount REAL, rent_currency TEXT DEFAULT 'SYP',
        rent_overdue INTEGER DEFAULT 0, rent_overdue_months INTEGER DEFAULT 0,
        threatened_with_eviction INTEGER DEFAULT 0,
        rooms_count INTEGER DEFAULT 1, residents_count INTEGER DEFAULT 1,
        condition TEXT DEFAULT 'acceptable',
        has_electricity INTEGER DEFAULT 0,
        electricity_hours_per_day INTEGER,
        has_water INTEGER DEFAULT 0,
        has_heating INTEGER DEFAULT 0,
        has_sanitation INTEGER DEFAULT 0,
        has_internet INTEGER DEFAULT 0,
        address TEXT, governorate TEXT, city TEXT, neighborhood TEXT,
        owned_original_home_before INTEGER DEFAULT 0,
        original_home_status TEXT,
        property_confiscated INTEGER DEFAULT 0,
        confiscation_details TEXT,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createEducation(Database db) async {
    await db.execute('''
      CREATE TABLE education_status (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT UNIQUE,
        highest_level_before_detention TEXT DEFAULT 'illiterate',
        highest_level_now TEXT DEFAULT 'illiterate',
        studies_interrupted_by_detention INTEGER DEFAULT 0,
        field_of_study TEXT, institution TEXT,
        is_currently_studying INTEGER DEFAULT 0,
        current_program TEXT,
        wants_to_resume INTEGER DEFAULT 0,
        obstacles_to_education TEXT,
        languages_spoken TEXT,
        has_certificates INTEGER DEFAULT 0,
        certificates_details TEXT,
        certificates_lost INTEGER DEFAULT 0,
        needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createEmployment(Database db) async {
    await db.execute('''
      CREATE TABLE employment_infos (
        local_id TEXT PRIMARY KEY, id INTEGER,
        survivor_local_id TEXT UNIQUE,
        status TEXT DEFAULT 'unemployed_seeking',
        current_occupation TEXT,
        same_as_before INTEGER DEFAULT 0,
        unable_due_to_health INTEGER DEFAULT 0,
        unable_due_to_legal INTEGER DEFAULT 0,
        monthly_income REAL, income_currency TEXT DEFAULT 'SYP',
        income_covers_basic_needs INTEGER DEFAULT 0,
        has_salary INTEGER DEFAULT 0,
        has_business_income INTEGER DEFAULT 0,
        has_pension INTEGER DEFAULT 0,
        has_remittance INTEGER DEFAULT 0,
        has_humanitarian_aid INTEGER DEFAULT 0,
        has_family_support INTEGER DEFAULT 0,
        other_income_sources TEXT,
        work_hours_per_week INTEGER,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createHealth(Database db) async {
    await db.execute('''
      CREATE TABLE health_access (
        local_id TEXT PRIMARY KEY, id INTEGER,
        household_local_id TEXT UNIQUE,
        has_health_insurance INTEGER DEFAULT 0, insurance_type TEXT,
        access_to_primary_care INTEGER DEFAULT 0,
        access_to_specialized_care INTEGER DEFAULT 0,
        distance_to_health_facility_km REAL,
        chronic_illnesses_in_family TEXT,
        family_members_with_disability INTEGER DEFAULT 0,
        psychological_support_received INTEGER DEFAULT 0,
        psychological_support_provider TEXT,
        medications_unaffordable INTEGER DEFAULT 0,
        unmet_medical_needs TEXT,
        food_security TEXT DEFAULT 'moderate',
        meals_per_day INTEGER DEFAULT 3,
        notes TEXT, needs_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createNeeds(Database db) async {
    await db.execute('''
      CREATE TABLE needs_assessments (
        local_id TEXT PRIMARY KEY, id INTEGER,
        household_local_id TEXT UNIQUE,
        financial_aid TEXT DEFAULT 'none',
        food_aid TEXT DEFAULT 'none',
        housing_aid TEXT DEFAULT 'none',
        medical_aid TEXT DEFAULT 'none',
        psychological_support TEXT DEFAULT 'none',
        legal_aid TEXT DEFAULT 'none',
        education_aid TEXT DEFAULT 'none',
        vocational_training TEXT DEFAULT 'none',
        documents_recovery TEXT DEFAULT 'none',
        needs_id_card INTEGER DEFAULT 0,
        needs_family_booklet INTEGER DEFAULT 0,
        needs_passport INTEGER DEFAULT 0,
        needs_birth_certificate INTEGER DEFAULT 0,
        needs_marriage_certificate INTEGER DEFAULT 0,
        needs_security_clearance INTEGER DEFAULT 0,
        additional_needs TEXT, barriers_to_aid TEXT,
        assessment_date TEXT,
        follow_up_required INTEGER DEFAULT 1,
        follow_up_date TEXT,
        notes TEXT, needs_sync INTEGER DEFAULT 0
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

  static const _allSyncTables = [
    'survivors', 'detention_events', 'detention_periods',
    'release_events', 'informed_consents', 'witnesses', 'survivor_notes',
    'supporting_documents', 'medical_assessments', 'long_term_impacts',
    'interviews', 'household_surveys', 'children', 'housing_infos',
    'education_status', 'employment_infos', 'health_access',
    'needs_assessments',
  ];

  Future<int> countPendingSync() async {
    int total = 0;
    for (final table in _allSyncTables) {
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

extension MoreDataAccess on DatabaseService {
  // Documents
  Future<List<SupportingDocument>> getDocumentsFor(String sid) async {
    final rows = await db.query('supporting_documents',
        where: 'survivor_local_id = ?', whereArgs: [sid],
        orderBy: 'date_obtained DESC');
    return rows.map(SupportingDocument.fromDbMap).toList();
  }
  Future<void> upsertDocument(SupportingDocument d) =>
      db.insert('supporting_documents', d.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deleteDocument(String lid) =>
      db.delete('supporting_documents', where: 'local_id = ?', whereArgs: [lid]);

  // Medical
  Future<List<MedicalAssessment>> getMedicalFor(String sid) async {
    final rows = await db.query('medical_assessments',
        where: 'survivor_local_id = ?', whereArgs: [sid],
        orderBy: 'assessment_date DESC');
    return rows.map(MedicalAssessment.fromDbMap).toList();
  }
  Future<void> upsertMedical(MedicalAssessment m) =>
      db.insert('medical_assessments', m.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deleteMedical(String lid) =>
      db.delete('medical_assessments', where: 'local_id = ?', whereArgs: [lid]);

  // Long-term impact
  Future<LongTermImpact?> getImpactFor(String sid) async {
    final rows = await db.query('long_term_impacts',
        where: 'survivor_local_id = ?', whereArgs: [sid], limit: 1);
    if (rows.isEmpty) return null;
    return LongTermImpact.fromDbMap(rows.first);
  }
  Future<void> upsertImpact(LongTermImpact i) =>
      db.insert('long_term_impacts', i.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  // Interviews
  Future<List<Interview>> getInterviewsFor(String sid) async {
    final rows = await db.query('interviews',
        where: 'survivor_local_id = ?', whereArgs: [sid],
        orderBy: 'sequence_number');
    return rows.map(Interview.fromDbMap).toList();
  }
  Future<void> upsertInterview(Interview iv) =>
      db.insert('interviews', iv.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deleteInterview(String lid) =>
      db.delete('interviews', where: 'local_id = ?', whereArgs: [lid]);

  // Household
  Future<HouseholdSurvey?> getHouseholdFor(String sid) async {
    final rows = await db.query('household_surveys',
        where: 'survivor_local_id = ?', whereArgs: [sid], limit: 1);
    if (rows.isEmpty) return null;
    return HouseholdSurvey.fromDbMap(rows.first);
  }
  Future<void> upsertHousehold(HouseholdSurvey h) =>
      db.insert('household_surveys', h.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  // Children
  Future<List<Child>> getChildrenFor(String householdLocalId) async {
    final rows = await db.query('children',
        where: 'household_local_id = ?', whereArgs: [householdLocalId]);
    return rows.map(Child.fromDbMap).toList();
  }
  Future<void> upsertChild(Child c) =>
      db.insert('children', c.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deleteChild(String lid) =>
      db.delete('children', where: 'local_id = ?', whereArgs: [lid]);

  // Housing
  Future<HousingInfo?> getHousingFor(String householdLocalId) async {
    final rows = await db.query('housing_infos',
        where: 'household_local_id = ?',
        whereArgs: [householdLocalId], limit: 1);
    if (rows.isEmpty) return null;
    return HousingInfo.fromDbMap(rows.first);
  }
  Future<void> upsertHousing(HousingInfo h) =>
      db.insert('housing_infos', h.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  // Education
  Future<EducationStatus?> getEducationFor(String sid) async {
    final rows = await db.query('education_status',
        where: 'survivor_local_id = ?', whereArgs: [sid], limit: 1);
    if (rows.isEmpty) return null;
    return EducationStatus.fromDbMap(rows.first);
  }
  Future<void> upsertEducation(EducationStatus e) =>
      db.insert('education_status', e.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  // Employment
  Future<EmploymentInfo?> getEmploymentFor(String sid) async {
    final rows = await db.query('employment_infos',
        where: 'survivor_local_id = ?', whereArgs: [sid], limit: 1);
    if (rows.isEmpty) return null;
    return EmploymentInfo.fromDbMap(rows.first);
  }
  Future<void> upsertEmployment(EmploymentInfo e) =>
      db.insert('employment_infos', e.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  // Health
  Future<HealthAccess?> getHealthFor(String householdLocalId) async {
    final rows = await db.query('health_access',
        where: 'household_local_id = ?',
        whereArgs: [householdLocalId], limit: 1);
    if (rows.isEmpty) return null;
    return HealthAccess.fromDbMap(rows.first);
  }
  Future<void> upsertHealth(HealthAccess h) =>
      db.insert('health_access', h.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  // Needs
  Future<NeedsAssessment?> getNeedsFor(String householdLocalId) async {
    final rows = await db.query('needs_assessments',
        where: 'household_local_id = ?',
        whereArgs: [householdLocalId], limit: 1);
    if (rows.isEmpty) return null;
    return NeedsAssessment.fromDbMap(rows.first);
  }
  Future<void> upsertNeeds(NeedsAssessment n) =>
      db.insert('needs_assessments', n.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
}
