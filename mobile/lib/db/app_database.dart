import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/entities.dart';

/// قاعدة البيانات المحلية (SQLite). جدول لكل كيان، وكل الحقول في عمود JSON.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('AppDatabase.init() لم تُستدعَ بعد');
    }
    return d;
  }

  /// كل الجداول: الناجي + الكيانات المرتبطة.
  static List<String> get allTables =>
      ['survivor', ...kRelatedEntities.map((e) => e.table)];

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'haqquna.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final t in allTables) {
      batch.execute('''
        CREATE TABLE $t (
          local_id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          survivor_local_id INTEGER NOT NULL DEFAULT 0,
          data TEXT NOT NULL DEFAULT '{}',
          needs_sync INTEGER NOT NULL DEFAULT 1,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT
        )
      ''');
      batch.execute('CREATE INDEX idx_${t}_sv ON $t (survivor_local_id)');
    }
    await batch.commit(noResult: true);
  }
}
