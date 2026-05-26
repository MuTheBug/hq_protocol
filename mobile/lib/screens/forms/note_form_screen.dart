import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/related.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';

class NoteFormScreen extends StatefulWidget {
  final Survivor survivor;
  final SurvivorNote? note;
  const NoteFormScreen({super.key, required this.survivor, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  String _type = 'general';
  bool _pinned = false;
  bool _confidential = false;

  static const Map<String, String> _types = {
    'general': 'ملاحظة عامة',
    'follow_up': 'متابعة',
    'referral': 'إحالة',
    'medical': 'طبية/نفسية',
    'legal': 'قانونية',
    'security': 'أمنية/حماية',
    'family': 'متعلقة بالعائلة',
    'inconsistency': 'ملاحظة على اتساق الرواية',
    'verification': 'تحقق من معلومة',
    'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _title = TextEditingController(text: n?.title ?? '');
    _content = TextEditingController(text: n?.content ?? '');
    _type = n?.noteType ?? 'general';
    _pinned = n?.isPinned ?? false;
    _confidential = n?.isConfidential ?? false;
  }

  Future<void> _save() async {
    if (_content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('محتوى الملاحظة مطلوب')));
      return;
    }
    final n = widget.note ?? SurvivorNote(
      content: '', survivorLocalId: widget.survivor.localId,
    );
    n.localId ??= const Uuid().v4();
    n.survivorLocalId = widget.survivor.localId;
    n.noteType = _type;
    n.title = _title.text.trim();
    n.content = _content.text.trim();
    n.isPinned = _pinned;
    n.isConfidential = _confidential;
    n.createdAt ??= DateTime.now().toIso8601String();
    n.needsSync = true;
    await DatabaseService.instance.upsertNote(n);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.note == null ? 'ملاحظة جديدة' : 'تعديل')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'نوع الملاحظة'),
          items: _types.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _type = v ?? 'general'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان مختصر')),
        const SizedBox(height: 12),
        TextFormField(controller: _content,
            decoration: const InputDecoration(labelText: 'الملاحظة *'),
            maxLines: 6),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _pinned, title: const Text('تثبيت في أعلى الملف'),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _pinned = v ?? false),
        ),
        CheckboxListTile(
          value: _confidential, title: const Text('سرّية (للمشرفين فقط)'),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _confidential = v ?? false),
        ),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}
