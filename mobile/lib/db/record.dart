import 'dart:convert';

/// سجل عام يمثّل صفاً في أي جدول كيان.
/// تُخزَّن كل حقول الكيان في عمود [data] كـ JSON، ما يسمح بإضافة حقول
/// دون تعديل المخطّط.
class Record {
  final int localId;
  final int? serverId;
  final int survivorLocalId; // 0 لجدول الناجي نفسه
  final Map<String, dynamic> data;
  final bool needsSync;
  final String? updatedAt;

  Record({
    required this.localId,
    required this.serverId,
    required this.survivorLocalId,
    required this.data,
    required this.needsSync,
    required this.updatedAt,
  });

  factory Record.fromRow(Map<String, Object?> row) {
    final raw = row['data'] as String?;
    final Map<String, dynamic> decoded =
        (raw == null || raw.isEmpty)
            ? <String, dynamic>{}
            : (jsonDecode(raw) as Map).cast<String, dynamic>();
    return Record(
      localId: row['local_id'] as int,
      serverId: row['server_id'] as int?,
      survivorLocalId: (row['survivor_local_id'] as int?) ?? 0,
      data: decoded,
      needsSync: ((row['needs_sync'] as int?) ?? 0) == 1,
      updatedAt: row['updated_at'] as String?,
    );
  }

  String str(String key) {
    final v = data[key];
    return v == null ? '' : v.toString();
  }
}
