import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import '../theme.dart';

/// عنوان قسم داخل النموذج.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: HaqqunaColors.primary),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: HaqqunaColors.dark)),
        ],
      ),
    );
  }
}

Color classColor(String? c) {
  switch (c) {
    case 'A':
      return HaqqunaColors.success;
    case 'B':
      return HaqqunaColors.primary;
    case 'C':
      return Colors.grey;
    default:
      return HaqqunaColors.warning; // draft
  }
}

String classLetter(String? c) => (c == null || c == 'draft') ? 'م' : c;

String fullNameOf(Map<String, dynamic> d) {
  final parts = [
    d['first_name'],
    d['father_name'],
    d['grandfather_name'],
    d['family_name'],
  ];
  final name = parts
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ');
  return name.isEmpty ? '(بلا اسم)' : name;
}

/// عنوان مختصر لعنصر في قائمة (حسب نوع الكيان).
String recordHeadline(String table, Map<String, dynamic> d) {
  String s(String k) => (d[k] ?? '').toString();
  switch (table) {
    case 'detention_event':
      final ent = s('arresting_entity');
      return [s('detention_date'), if (ent.isNotEmpty) ent].join(' · ');
    case 'detention_period':
      final f = s('facility_name') == '__other__'
          ? s('facility_other')
          : s('facility_name');
      return [if (f.isNotEmpty) f, s('from_date')].join(' · ');
    case 'witness':
      return s('witness_name').isEmpty ? 'شاهد' : s('witness_name');
    case 'document':
      final t = s('title');
      return t.isEmpty
          ? Ref.labelFor(Ref.documentTypes, s('document_type'))
          : t;
    case 'medical':
      return [
        Ref.labelFor(Ref.assessmentTypes, s('assessment_type')),
        s('assessment_date'),
      ].where((e) => e.isNotEmpty).join(' · ');
    case 'interview':
      final n = s('sequence_number');
      return ['مقابلة${n.isNotEmpty ? ' #$n' : ''}', s('interview_date')]
          .where((e) => e.isNotEmpty)
          .join(' · ');
    case 'note':
      final t = s('title');
      return t.isNotEmpty ? t : Ref.labelFor(Ref.noteTypes, s('note_type'));
    case 'child':
      return s('name').isEmpty ? 'ابن/ابنة' : s('name');
    default:
      return table;
  }
}

String recordSubtitle(String table, Map<String, dynamic> d) {
  String s(String k) => (d[k] ?? '').toString();
  switch (table) {
    case 'detention_event':
      return s('detention_location');
    case 'witness':
      return d['is_independent'] == true ? 'شاهد مستقل' : 'شاهد';
    case 'document':
      return Ref.labelFor(Ref.documentTypes, s('document_type'));
    case 'child':
      final g = Ref.labelFor(Ref.childGenders, s('gender'));
      final age = s('age');
      return [g, if (age.isNotEmpty) '$age سنة'].join(' · ');
    case 'interview':
      return Ref.labelFor(Ref.interviewMethodologies, s('methodology'));
    default:
      return '';
  }
}
