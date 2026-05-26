import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/related.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';

class ReleaseFormScreen extends StatefulWidget {
  final Survivor survivor;
  final ReleaseEvent? release;
  const ReleaseFormScreen({super.key, required this.survivor, this.release});

  @override
  State<ReleaseFormScreen> createState() => _ReleaseFormScreenState();
}

class _ReleaseFormScreenState extends State<ReleaseFormScreen> {
  late final TextEditingController _location;
  late final TextEditingController _bribe;
  late final TextEditingController _conditions;
  late final TextEditingController _circumstances;
  DateTime? _date;
  String _type = 'unknown';

  static const Map<String, String> _types = {
    'unconditional': 'إفراج غير مشروط',
    'conditional': 'إفراج مشروط',
    'amnesty': 'عفو عام',
    'settlement': 'تسوية وضع',
    'bribe': 'بدفع رشوة',
    'exchange': 'تبادل/صفقة',
    'escape': 'فرار',
    'transfer_out': 'نقل لجهة أخرى',
    'unknown': 'غير معلوم',
  };

  @override
  void initState() {
    super.initState();
    final r = widget.release;
    _location = TextEditingController(text: r?.releaseLocation ?? '');
    _bribe = TextEditingController(text: r?.bribeAmount ?? '');
    _conditions = TextEditingController(text: r?.conditions ?? '');
    _circumstances = TextEditingController(text: r?.circumstances ?? '');
    _type = r?.releaseType ?? 'unknown';
    if (r?.releaseDate.isNotEmpty == true) {
      try { _date = DateTime.parse(r!.releaseDate); } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر تاريخ الإفراج')));
      return;
    }
    final r = widget.release ?? ReleaseEvent(
      releaseDate: '', survivorLocalId: widget.survivor.localId,
    );
    r.localId ??= const Uuid().v4();
    r.survivorLocalId = widget.survivor.localId;
    r.releaseDate = _date!.toIso8601String().substring(0, 10);
    r.releaseType = _type;
    r.releaseLocation = _location.text.trim();
    r.bribeAmount = _bribe.text.trim();
    r.conditions = _conditions.text.trim();
    r.circumstances = _circumstances.text.trim();
    r.needsSync = true;
    await DatabaseService.instance.upsertRelease(r);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات الإفراج')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        InkWell(
          onTap: () async {
            final p = await showDatePicker(
              context: context, initialDate: _date ?? DateTime(2019),
              firstDate: DateTime(2000), lastDate: DateTime.now(),
            );
            if (p != null) setState(() => _date = p);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'تاريخ الإفراج *',
                suffixIcon: Icon(Icons.calendar_today)),
            child: Text(_date?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'نوع الإفراج *'),
          items: _types.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _type = v ?? 'unknown'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _location,
          decoration: const InputDecoration(labelText: 'مكان الإفراج'),
        ),
        if (_type == 'bribe') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _bribe,
            decoration: const InputDecoration(labelText: 'قيمة الرشوة'),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _conditions,
          decoration: const InputDecoration(labelText: 'شروط الإفراج'),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _circumstances,
          decoration: const InputDecoration(labelText: 'ظروف الإفراج بالتفصيل'),
          maxLines: 5,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'),
          ),
        ),
      ]),
    );
  }
}
