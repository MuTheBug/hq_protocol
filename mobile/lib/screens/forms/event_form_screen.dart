import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/choices.dart';
import '../../models/related.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../theme.dart';

/// نموذج واقعة اعتقال - يطابق DetentionEventForm في Django
/// الجهة المعتقِلة قائمة منسدلة مجمّعة حسب المحافظة + خيار "أخرى"
class EventFormScreen extends StatefulWidget {
  final Survivor survivor;
  final DetentionEvent? event;
  const EventFormScreen({super.key, required this.survivor, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _location;
  late final TextEditingController _arrestingCustom;
  late final TextEditingController _personnel;
  late final TextEditingController _reason;
  late final TextEditingController _circumstances;
  late final TextEditingController _witnessesArrest;

  DateTime? _date;
  bool _dateApprox = false;
  String? _governorate;
  String? _selectedFacility;
  bool _familyNotified = false;
  ReferenceData? _ref;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _location = TextEditingController(text: e?.detentionLocation ?? '');
    _arrestingCustom = TextEditingController(text: e?.arrestingEntity ?? '');
    _personnel = TextEditingController(text: e?.arrestingPersonnelDetails ?? '');
    _reason = TextEditingController(text: e?.reasonStated ?? '');
    _circumstances = TextEditingController(text: e?.circumstances ?? '');
    _witnessesArrest = TextEditingController(text: e?.witnessesToArrest ?? '');
    _governorate = e?.governorate;
    _familyNotified = e?.familyNotified ?? false;
    _dateApprox = e?.dateApproximate ?? false;
    if (e?.detentionDate.isNotEmpty == true) {
      try { _date = DateTime.parse(e!.detentionDate); } catch (_) {}
    }
    SyncService.instance.loadReferenceData().then((r) {
      if (mounted) setState(() {
        _ref = r;
        // إذا الجهة موجودة كنص حر في تعديل، حدد لو تطابق فرع
        if (e?.arrestingEntity.isNotEmpty == true && r != null) {
          final match = r.facilities.firstWhere(
              (f) => f.displayName == e!.arrestingEntity,
              orElse: () => Facility(id: -1, nameAr: '', branchNumber: '',
                  parentEntity: '', parentEntityDisplay: '', governorate: ''));
          if (match.id != -1) {
            _selectedFacility = match.displayName;
            _arrestingCustom.clear();
          }
        }
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر تاريخ الاعتقال')));
      return;
    }
    final entity = (_selectedFacility?.isNotEmpty == true && _selectedFacility != '__custom__')
        ? _selectedFacility!
        : _arrestingCustom.text.trim();
    if (entity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر جهة من القائمة أو اكتبها يدوياً')));
      return;
    }

    final e = widget.event ?? DetentionEvent(
      detentionDate: '', detentionLocation: '', arrestingEntity: '',
      survivorLocalId: widget.survivor.localId,
    );
    e.localId ??= const Uuid().v4();
    e.detentionDate = _date!.toIso8601String().substring(0, 10);
    e.dateApproximate = _dateApprox;
    e.detentionLocation = _location.text.trim();
    e.governorate = _governorate;
    e.arrestingEntity = entity;
    e.arrestingPersonnelDetails = _personnel.text.trim();
    e.reasonStated = _reason.text.trim();
    e.circumstances = _circumstances.text.trim();
    e.witnessesToArrest = _witnessesArrest.text.trim();
    e.familyNotified = _familyNotified;
    e.survivorLocalId = widget.survivor.localId;
    e.needsSync = true;

    await DatabaseService.instance.upsertEvent(e);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_ref == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('جاري التحميل...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // بناء القائمة المنسدلة المجمّعة
    final facilitiesByGov = <String, List<Facility>>{};
    for (final f in _ref!.facilities) {
      facilitiesByGov.putIfAbsent(f.governorate, () => []).add(f);
    }
    final govLabel = {for (var c in _ref!.governorates) c.value: c.label};

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل واقعة اعتقال' : 'واقعة اعتقال جديدة'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // التاريخ
          InkWell(
            onTap: () async {
              final p = await showDatePicker(
                context: context, initialDate: _date ?? DateTime(2018),
                firstDate: DateTime(2000), lastDate: DateTime.now(),
              );
              if (p != null) setState(() => _date = p);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'تاريخ الاعتقال *',
                  suffixIcon: Icon(Icons.calendar_today)),
              child: Text(_date?.toIso8601String().substring(0, 10) ?? '— اختر —'),
            ),
          ),
          CheckboxListTile(
            value: _dateApprox,
            title: const Text('التاريخ تقريبي', style: TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            onChanged: (v) => setState(() => _dateApprox = v ?? false),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
                labelText: 'مكان الاعتقال (حاجز/بيت/شارع...) *'),
            validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _governorate,
            decoration: const InputDecoration(labelText: 'محافظة الاعتقال'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ..._ref!.governorates.map(
                  (c) => DropdownMenuItem(value: c.value, child: Text(c.label))),
            ],
            onChanged: (v) => setState(() => _governorate = v),
          ),
          const SizedBox(height: 16),

          // الجهة المعتقِلة - dropdown مجمّع
          DropdownButtonFormField<String>(
            value: _selectedFacility,
            decoration: const InputDecoration(
                labelText: 'الجهة المعتقِلة *',
                helperText: 'اختر من القائمة، أو "أخرى" واكتب يدوياً'),
            isExpanded: true,
            items: _buildGroupedFacilityItems(facilitiesByGov, govLabel),
            onChanged: (v) => setState(() => _selectedFacility = v),
          ),
          if (_selectedFacility == '__custom__' || _selectedFacility == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: _arrestingCustom,
                decoration: const InputDecoration(
                    labelText: 'أو اكتب الجهة يدوياً',
                    hintText: 'مثال: المخابرات الجوية - فرع المنطقة'),
              ),
            ),

          const SizedBox(height: 12),
          TextFormField(
            controller: _personnel,
            decoration: const InputDecoration(
                labelText: 'تفاصيل عناصر الاعتقال (أسماء/رتب/علامات)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'السبب المُعلَن (إن وُجد)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _circumstances,
            decoration: const InputDecoration(
                labelText: 'ظروف الاعتقال بالتفصيل',
                helperText: '>150 حرف يرفع نقطة الموثوقية'),
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _witnessesArrest,
            decoration: const InputDecoration(
                labelText: 'شهود على الاعتقال (جيران، عابرو سبيل...)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _familyNotified,
            title: const Text('هل أُبلغت العائلة؟'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _familyNotified = v ?? false),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEdit ? 'حفظ التعديلات' : 'حفظ الواقعة'),
            ),
          ),
        ]),
      ),
    );
  }

  /// قائمة منسدلة بـoptgroups (تُحاكي Django Select)
  List<DropdownMenuItem<String>> _buildGroupedFacilityItems(
      Map<String, List<Facility>> byGov, Map<String, String> govLabel) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: null, child: Text('— اختر —')),
    ];
    // ترتيب: المحافظات أولاً، ثم "أخرى"
    final sortedGovs = byGov.keys.toList()
      ..sort((a, b) => (govLabel[a] ?? a).compareTo(govLabel[b] ?? b));
    for (final gov in sortedGovs) {
      final label = govLabel[gov] ?? (gov.isEmpty ? 'أفرع أخرى' : gov);
      // فاصل "headline" (يُعرض كعنوان غير قابل للاختيار)
      items.add(DropdownMenuItem(
        value: '__header_$gov',
        enabled: false,
        child: Text('▸ $label',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: HaqqunaColors.primary)),
      ));
      for (final f in byGov[gov]!) {
        items.add(DropdownMenuItem(
          value: f.displayName,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(f.displayName, overflow: TextOverflow.ellipsis),
          ),
        ));
      }
    }
    items.add(const DropdownMenuItem(
      value: '__custom__',
      child: Text('✏ أخرى - اكتب يدوياً',
          style: TextStyle(fontStyle: FontStyle.italic)),
    ));
    return items;
  }
}
