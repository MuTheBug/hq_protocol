import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/choices.dart';
import '../../models/related.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';

class WitnessFormScreen extends StatefulWidget {
  final Survivor survivor;
  final Witness? witness;
  final List<Facility> facilities;
  const WitnessFormScreen({
    super.key, required this.survivor, this.witness, required this.facilities,
  });

  @override
  State<WitnessFormScreen> createState() => _WitnessFormScreenState();
}

class _WitnessFormScreenState extends State<WitnessFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _cell;
  late final TextEditingController _how;
  late final TextEditingController _distinguishing;
  late final TextEditingController _incidents;
  late final TextEditingController _testimony;
  DateTime? _from;
  DateTime? _to;
  DateTime? _declDate;
  int? _facilityId;
  String _relationship = 'stranger';
  bool _independent = false;
  bool _metAfter = false;
  bool _consent = false;
  bool _signed = false;

  static const Map<String, String> _relationships = {
    'stranger': 'لم يكن يعرفه',
    'acquaintance': 'معرفة',
    'friend': 'صديق',
    'relative': 'قريب',
    'colleague': 'زميل عمل/دراسة',
  };

  @override
  void initState() {
    super.initState();
    final w = widget.witness;
    _name = TextEditingController(text: w?.witnessName ?? '');
    _phone = TextEditingController(text: w?.witnessPhone ?? '');
    _location = TextEditingController(text: w?.witnessCurrentLocation ?? '');
    _cell = TextEditingController(text: w?.cellNumber ?? '');
    _how = TextEditingController(text: w?.howRecognized ?? '');
    _distinguishing = TextEditingController(text: w?.distinguishingDetails ?? '');
    _incidents = TextEditingController(text: w?.specificIncidents ?? '');
    _testimony = TextEditingController(text: w?.fullTestimony ?? '');
    _facilityId = w?.facilityId;
    _relationship = w?.relationshipBefore ?? 'stranger';
    _independent = w?.isIndependent ?? false;
    _metAfter = w?.metAfterRelease ?? false;
    _consent = w?.consentToUseTestimony ?? false;
    _signed = w?.declarationSigned ?? false;
    void parseDate(String? s, void Function(DateTime) set) {
      if (s?.isNotEmpty == true) {
        try { set(DateTime.parse(s!)); } catch (_) {}
      }
    }
    parseDate(w?.periodFrom, (d) => _from = d);
    parseDate(w?.periodTo, (d) => _to = d);
    parseDate(w?.declarationDate, (d) => _declDate = d);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _how.text.trim().isEmpty
        || _facilityId == null || _from == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الاسم، الفرع، تاريخ البداية، وكيفية التعرف مطلوبة')));
      return;
    }
    final w = widget.witness ?? Witness(
      witnessName: '', periodFrom: '', howRecognized: '',
      survivorLocalId: widget.survivor.localId,
    );
    w.localId ??= const Uuid().v4();
    w.survivorLocalId = widget.survivor.localId;
    w.witnessName = _name.text.trim();
    w.witnessPhone = _phone.text.trim();
    w.witnessCurrentLocation = _location.text.trim();
    w.facilityId = _facilityId;
    w.facilityName = widget.facilities
        .firstWhere((f) => f.id == _facilityId).displayName;
    w.periodFrom = _from!.toIso8601String().substring(0, 10);
    w.periodTo = _to?.toIso8601String().substring(0, 10);
    w.cellNumber = _cell.text.trim();
    w.howRecognized = _how.text.trim();
    w.distinguishingDetails = _distinguishing.text.trim();
    w.specificIncidents = _incidents.text.trim();
    w.relationshipBefore = _relationship;
    w.isIndependent = _independent;
    w.metAfterRelease = _metAfter;
    w.consentToUseTestimony = _consent;
    w.declarationSigned = _signed;
    w.declarationDate = _declDate?.toIso8601String().substring(0, 10);
    w.fullTestimony = _testimony.text.trim();
    w.needsSync = true;
    await DatabaseService.instance.upsertWitness(w);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.witness == null ? 'شاهد جديد' : 'تعديل')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _name,
            decoration: const InputDecoration(labelText: 'اسم الشاهد *')),
        const SizedBox(height: 12),
        TextFormField(controller: _phone,
            decoration: const InputDecoration(labelText: 'هاتف الشاهد')),
        const SizedBox(height: 12),
        TextFormField(controller: _location,
            decoration: const InputDecoration(labelText: 'الموقع الحالي')),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _facilityId,
          decoration: const InputDecoration(labelText: 'الفرع الذي رآه فيه *'),
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
              final d = await showDatePicker(context: context,
                  initialDate: _from ?? DateTime(2018),
                  firstDate: DateTime(2000), lastDate: DateTime.now());
              if (d != null) setState(() => _from = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'من *'),
              child: Text(_from?.toIso8601String().substring(0, 10) ?? '—'),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: _to ?? DateTime(2019),
                  firstDate: DateTime(2000), lastDate: DateTime.now());
              if (d != null) setState(() => _to = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'إلى'),
              child: Text(_to?.toIso8601String().substring(0, 10) ?? '—'),
            ),
          )),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _cell,
            decoration: const InputDecoration(labelText: 'رقم الزنزانة (إن أمكن)')),
        const SizedBox(height: 12),
        TextFormField(controller: _how,
            decoration: const InputDecoration(
                labelText: 'كيف تعرّف عليه؟ *'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _distinguishing,
            decoration: const InputDecoration(labelText: 'تفاصيل مميزة'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _incidents,
            decoration: const InputDecoration(labelText: 'حوادث محددة شهدها'),
            maxLines: 3),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _relationship,
          decoration: const InputDecoration(labelText: 'العلاقة قبل الاعتقال'),
          items: _relationships.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _relationship = v ?? 'stranger'),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _independent,
          title: const Text('شاهد مستقل'),
          subtitle: const Text('لم يلتقِ بالناجي بعد الإفراج', style: TextStyle(fontSize: 12)),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _independent = v ?? false),
        ),
        CheckboxListTile(
          value: _metAfter, title: const Text('التقيا بعد الإفراج'),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _metAfter = v ?? false),
        ),
        CheckboxListTile(
          value: _consent,
          title: const Text('موافقة الشاهد على استخدام شهادته'),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _consent = v ?? false),
        ),
        CheckboxListTile(
          value: _signed, title: const Text('بيان موقّع'),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _signed = v ?? false),
        ),
        TextFormField(controller: _testimony,
            decoration: const InputDecoration(labelText: 'نص الشهادة الكامل'),
            maxLines: 6),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ الشاهد'))),
      ]),
    );
  }
}
