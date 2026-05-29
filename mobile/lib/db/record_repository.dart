import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/entities.dart';
import 'app_database.dart';
import 'record.dart';

/// واجهة CRUD عامة لكل الكيانات (تعمل على عمود JSON).
class RecordRepository {
  RecordRepository._();
  static final RecordRepository instance = RecordRepository._();

  Database get _db => AppDatabase.instance.db;

  String _now() => DateTime.now().toIso8601String();

  Future<int> insert(String table, Map<String, dynamic> data,
      {int survivorLocalId = 0}) async {
    final now = _now();
    return _db.insert(table, {
      'survivor_local_id': survivorLocalId,
      'data': jsonEncode(data),
      'needs_sync': 1,
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(String table, int localId,
      Map<String, dynamic> data) async {
    await _db.update(
      table,
      {'data': jsonEncode(data), 'needs_sync': 1, 'updated_at': _now()},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> softDelete(String table, int localId) async {
    await _db.update(
      table,
      {'is_deleted': 1, 'needs_sync': 1, 'updated_at': _now()},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<Record?> getById(String table, int localId) async {
    final rows = await _db.query(table,
        where: 'local_id = ?', whereArgs: [localId], limit: 1);
    if (rows.isEmpty) return null;
    return Record.fromRow(rows.first);
  }

  Future<List<Record>> listForSurvivor(
      String table, int survivorLocalId) async {
    final rows = await _db.query(table,
        where: 'survivor_local_id = ? AND is_deleted = 0',
        whereArgs: [survivorLocalId],
        orderBy: 'local_id ASC');
    return rows.map(Record.fromRow).toList();
  }

  Future<Record?> singletonForSurvivor(
      String table, int survivorLocalId) async {
    final list = await listForSurvivor(table, survivorLocalId);
    return list.isEmpty ? null : list.first;
  }

  Future<int> countForSurvivor(String table, int survivorLocalId) async {
    final c = Sqflite.firstIntValue(await _db.rawQuery(
        'SELECT COUNT(*) FROM $table '
        'WHERE survivor_local_id = ? AND is_deleted = 0',
        [survivorLocalId]));
    return c ?? 0;
  }

  // ---- الناجون ----

  Future<List<Record>> listSurvivors({String? query}) async {
    final rows = await _db.query('survivor',
        where: 'is_deleted = 0', orderBy: 'local_id DESC');
    var list = rows.map(Record.fromRow).toList();
    final q = query?.trim() ?? '';
    if (q.isNotEmpty) {
      list = list.where((r) {
        final d = r.data;
        final hay = [
          d['case_reference'],
          d['first_name'],
          d['father_name'],
          d['family_name'],
          d['national_id'],
          d['alias'],
        ].whereType<String>().join(' ');
        return hay.contains(q);
      }).toList();
    }
    return list;
  }

  Future<int> countPendingSync() async {
    int total = 0;
    for (final t in AppDatabase.allTables) {
      final c = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM $t WHERE needs_sync = 1'));
      total += c ?? 0;
    }
    return total;
  }

  /// حذف ناجٍ وكل سجلاته المرتبطة محلياً (حذف فعلي من الجهاز).
  Future<void> deleteSurvivorCascade(int survivorLocalId) async {
    final batch = _db.batch();
    batch.delete('survivor', where: 'local_id = ?', whereArgs: [survivorLocalId]);
    for (final e in kRelatedEntities) {
      batch.delete(e.table,
          where: 'survivor_local_id = ?', whereArgs: [survivorLocalId]);
    }
    await batch.commit(noResult: true);
  }
}
