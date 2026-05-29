import 'package:flutter/material.dart';

/// أنواع الحقول المدعومة في محرّك النماذج العام.
enum FieldType {
  text, // سطر نصي
  multiline, // نص طويل
  integer, // عدد صحيح
  decimal, // عدد عشري
  date, // تاريخ (ISO yyyy-MM-dd)
  boolean, // نعم/لا
  choice, // اختيار واحد من قائمة
  multiChoice, // اختيار متعدد (يُخزَّن كقائمة)
}

/// خيار واحد ضمن قائمة منسدلة (القيمة المخزَّنة + التسمية المعروضة).
@immutable
class Choice {
  final String value;
  final String label;
  const Choice(this.value, this.label);
}

/// تعريف حقل واحد في نموذج كيان.
///
/// المفتاح [key] يطابق تماماً اسم الحقل في نماذج Django،
/// حتى تتوافق حزمة المزامنة مع السيرفر دون تحويل.
@immutable
class FieldSpec {
  final String key;
  final String label;
  final FieldType type;
  final String section;
  final List<Choice> choices;
  final bool required;
  final String? help;

  const FieldSpec(
    this.key,
    this.label,
    this.type, {
    this.section = 'عام',
    this.choices = const [],
    this.required = false,
    this.help,
  });
}

/// تعريف كيان كامل: جدول التخزين + عنوانه + حقوله.
@immutable
class EntitySpec {
  /// اسم جدول SQLite ومفتاح المزامنة (يطابق اسم العلاقة في Django).
  final String table;
  final String titleAr;
  final IconData icon;

  /// كيان مرتبط بالناجي بعلاقة واحد-لواحد (سجل واحد فقط لكل ناجٍ).
  final bool singleton;

  final List<FieldSpec> fields;

  const EntitySpec({
    required this.table,
    required this.titleAr,
    required this.icon,
    required this.fields,
    this.singleton = false,
  });

  /// أقسام النموذج بترتيب ظهورها الأول.
  List<String> get sections {
    final seen = <String>[];
    for (final f in fields) {
      if (!seen.contains(f.section)) seen.add(f.section);
    }
    return seen;
  }

  List<FieldSpec> fieldsInSection(String section) =>
      fields.where((f) => f.section == section).toList();

  FieldSpec? fieldByKey(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }
}
