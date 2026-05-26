import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/choices.dart';
import '../../models/related.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';

class PeriodFormScreen extends StatefulWidget {
  final Survivor survivor;
  final DetentionPeriod? period;
  final List<Facility> facilities;
  const PeriodFormScreen({
    super.key, required this.survivor, this.period, required this.facilities,
  });

  @override
  State<PeriodFormScreen> createState() => _PeriodFormScreenState();
}

class _PeriodFormScreenState extends State<PeriodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cellDesc;
  late final TextEditingController _cellmates;
  late final TextEditingController _tortureDesc;
  late final TextEditingController _notes;
  late final TextEditingController _orderIndex;
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _facilityId;
  bool _sexualViolence = false;

  @override
  void initState() {
    super.initState();
    final p = widget.period;
    _cellDesc = TextEditingController(text: p?.cellDescription ?? '');
    _cellmates = TextEditingController(text: p?.cellmatesCount?.toString() ?? '');
    _tortureDesc = TextEditingController(text: p?.tortureDescription ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _orderIndex = TextEditingController(text: '${p?.orderIndex ?? 1}');
    _facilityId = p?.facilityId;
    _sexualViolence = p?.sexualViolenceReported ?? false;
    if (p?.fromDate.isNotEmpty == true) {
      try { _fromDate = DateTime.parse(p!.fromDate); } catch (_) {}
    }
    if (p?.toDate?.isNotEmpty == true) {
      try { _toDate = DateTime.parse(p!.toDate!); } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromDate == null || _facilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الفرع وتاريخ البداية مطلوبان')));
      return;
    }
    final p = widget.period ?? DetentionPeriod(
      fromDate: '', survivorLocalId: widget.survivor.localId,
    );
    p.localId ??= const Uuid().v4();
    p.survivorLocalId = widget.survivor.localId;
    p.facilityId = _facilityId;
    p.facilityName = widget.facilities
        .firstWhere((f) => f.id == _facilityId).displayName;
    p.fromDate = _fromDate!.toIso8601String().substring(0, 10);
    p.toDate = _toDate?.toIso8601String().substring(0, 10);
    p.orderIndex = int.tryParse(_orderIndex.text) ?? 1;
    p.cellDescription = _cellDesc.text.trim();
    p.cellmatesCount = int.tryParse(_cellmates.text);
    p.tortureDescription = _tortureDesc.text.trim();
    p.sexualViolenceReported = _sexualViolence;
    p.notes = _notes.text.trim();
    p.needsSync = true;
    await DatabaseService.instance.upsertPeriod(p);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context, initialDate: initial ?? DateTime(2018),
      firstDate: DateTime(2000), lastDate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.period == null ? 'فترة احتجاز جديدة' : 'تعديل فترة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<int>(
            value: _facilityId,
            decoration: const InputDecoration(labelText: 'الفرع/السجن *'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('— اختر —')),
              ...widget.facilities.map((f) => DropdownMenuItem(
                  value: f.id, child: Text(f.displayName, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _facilityId = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: InkWell(
              onTap: () async {
                final d = await _pickDate(_fromDate);
                if (d != null) setState(() => _fromDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'من *'),
                child: Text(_fromDate?.toIso8601String().substring(0, 10) ?? '—'),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: InkWell(
              onTap: () async {
                final d = await _pickDate(_toDate);
                if (d != null) setState(() => _toDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'إلى'),
                child: Text(_toDate?.toIso8601String().substring(0, 10) ?? '—'),
              ),
            )),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _orderIndex,
            decoration: const InputDecoration(labelText: 'ترتيب الفترة (1، 2، 3...)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cellDesc,
            decoration: const InputDecoration(labelText: 'وصف الزنزانة'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cellmates,
            decoration: const InputDecoration(labelText: 'عدد المحتجزين معه'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tortureDesc,
            decoration: const InputDecoration(
                labelText: 'وصف التعذيب التفصيلي',
                helperText: '>200 حرف يرفع نقطة الموثوقية'),
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _sexualViolence,
            title: const Text('بلاغ عن عنف جنسي'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _sexualViolence = v ?? false),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ),
        ]),
      ),
    );
  }
}
