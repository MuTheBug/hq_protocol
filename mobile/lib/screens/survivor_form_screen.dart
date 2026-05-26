import 'package:flutter/material.dart';

import '../models/choices.dart';
import '../models/survivor.dart';
import '../services/survivor_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';

class SurvivorFormScreen extends StatefulWidget {
  final Survivor? survivor;
  const SurvivorFormScreen({super.key, this.survivor});

  @override
  State<SurvivorFormScreen> createState() => _SurvivorFormScreenState();
}

class _SurvivorFormScreenState extends State<SurvivorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _caseRef;
  late final TextEditingController _firstName;
  late final TextEditingController _fatherName;
  late final TextEditingController _grandfatherName;
  late final TextEditingController _familyName;
  late final TextEditingController _motherName;
  late final TextEditingController _alias;
  late final TextEditingController _nationalId;
  late final TextEditingController _birthPlace;
  late final TextEditingController _addressAtDetention;
  late final TextEditingController _occupationDetail;
  late final TextEditingController _politicalDetail;
  late final TextEditingController _currentPhone;
  late final TextEditingController _currentCity;
  late final TextEditingController _kinName;
  late final TextEditingController _kinPhone;

  // Dropdowns
  String? _gender;
  String? _birthGov;
  String? _governorateAtDetention;
  String? _currentCountry;
  String? _currentGov;
  String? _occupation;
  String? _politicalActivity;
  String? _marital;
  String _fileClass = 'draft';
  DateTime? _birthDate;
  bool _birthDateApprox = false;
  bool _busy = false;
  String? _error;

  ReferenceData? _ref;

  bool get _isEdit => widget.survivor != null;

  @override
  void initState() {
    super.initState();
    final s = widget.survivor;
    _caseRef = TextEditingController(text: s?.caseReference ?? _suggestCaseRef());
    _firstName = TextEditingController(text: s?.firstName ?? '');
    _fatherName = TextEditingController(text: s?.fatherName ?? '');
    _grandfatherName = TextEditingController(text: s?.grandfatherName ?? '');
    _familyName = TextEditingController(text: s?.familyName ?? '');
    _motherName = TextEditingController(text: s?.motherName ?? '');
    _alias = TextEditingController(text: s?.alias ?? '');
    _nationalId = TextEditingController(text: s?.nationalId ?? '');
    _birthPlace = TextEditingController(text: s?.birthPlaceDetail ?? '');
    _addressAtDetention = TextEditingController(text: s?.addressAtDetention ?? '');
    _occupationDetail = TextEditingController(text: s?.occupationDetail ?? '');
    _politicalDetail = TextEditingController(text: s?.politicalActivityDetail ?? '');
    _currentPhone = TextEditingController(text: s?.currentPhone ?? '');
    _currentCity = TextEditingController(text: s?.currentCity ?? '');
    _kinName = TextEditingController(text: s?.nextOfKinName ?? '');
    _kinPhone = TextEditingController(text: s?.nextOfKinPhone ?? '');

    _gender = s?.gender;
    _birthGov = s?.birthGovernorate;
    _governorateAtDetention = s?.governorateAtDetention;
    _currentCountry = s?.currentCountry;
    _currentGov = s?.currentGovernorate;
    _occupation = s?.occupationCategory;
    _politicalActivity = s?.politicalActivityCategory;
    _marital = s?.maritalStatusAtDetention;
    _fileClass = s?.fileClassification ?? 'draft';
    if (s?.birthDate != null) {
      try {
        _birthDate = DateTime.parse(s!.birthDate!);
      } catch (_) {}
    }
    _birthDateApprox = s?.birthDateApproximate ?? false;

    SyncService.instance.loadReferenceData().then((r) {
      if (mounted) setState(() => _ref = r);
    });
  }

  String _suggestCaseRef() {
    final year = DateTime.now().year;
    final rand = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'HQ-$year-${rand.toString().padLeft(4, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _gender!.isEmpty) {
      setState(() => _error = 'اختر الجنس');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      Survivor s;
      if (_isEdit) {
        s = widget.survivor!;
      } else {
        s = Survivor(
          caseReference: _caseRef.text.trim(),
          firstName: _firstName.text.trim(),
          fatherName: _fatherName.text.trim(),
          familyName: _familyName.text.trim(),
          gender: _gender!,
        );
      }
      // طبّق القيم
      s.caseReference = _caseRef.text.trim();
      s.firstName = _firstName.text.trim();
      s.fatherName = _fatherName.text.trim();
      s.grandfatherName = _grandfatherName.text.trim();
      s.familyName = _familyName.text.trim();
      s.motherName = _motherName.text.trim();
      s.alias = _alias.text.trim();
      s.nationalId = _nationalId.text.trim();
      s.birthPlaceDetail = _birthPlace.text.trim();
      s.addressAtDetention = _addressAtDetention.text.trim();
      s.occupationDetail = _occupationDetail.text.trim();
      s.politicalActivityDetail = _politicalDetail.text.trim();
      s.currentPhone = _currentPhone.text.trim();
      s.currentCity = _currentCity.text.trim();
      s.nextOfKinName = _kinName.text.trim();
      s.nextOfKinPhone = _kinPhone.text.trim();
      s.gender = _gender!;
      s.birthGovernorate = _birthGov;
      s.governorateAtDetention = _governorateAtDetention;
      s.currentCountry = _currentCountry;
      s.currentGovernorate = _currentGov;
      s.occupationCategory = _occupation;
      s.politicalActivityCategory = _politicalActivity;
      s.maritalStatusAtDetention = _marital;
      s.fileClassification = _fileClass;
      s.birthDate = _birthDate?.toIso8601String().substring(0, 10);
      s.birthDateApproximate = _birthDateApprox;

      if (_isEdit) {
        await SurvivorService.instance.update(s);
      } else {
        await SurvivorService.instance.create(s);
      }

      if (!mounted) return;
      // محاولة مزامنة فورية
      SyncService.instance.syncNow();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'حُفظت التعديلات' : 'تم إنشاء الملف')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'خطأ: $e';
      });
    }
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(children: [
          Container(width: 4, height: 20, color: HaqqunaColors.accent),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HaqqunaColors.primary)),
        ]),
      );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<Choice> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('—')),
        ...items.map(
            (c) => DropdownMenuItem(value: c.value, child: Text(c.label))),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ref == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('جاري التحميل...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل ملف ناجٍ' : 'ملف ناجٍ جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // المرجع والتصنيف
            _section('المعرّفات'),
            TextFormField(
              controller: _caseRef,
              decoration: const InputDecoration(labelText: 'رقم القضية *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _gap(),
            _dropdown(
              label: 'تصنيف الملف',
              value: _fileClass,
              items: _ref!.fileClassifications,
              onChanged: (v) => setState(() => _fileClass = v ?? 'draft'),
            ),

            _section('الاسم'),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'الاسم *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _gap(),
            TextFormField(
              controller: _fatherName,
              decoration: const InputDecoration(labelText: 'اسم الأب *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _gap(),
            TextFormField(
              controller: _grandfatherName,
              decoration: const InputDecoration(labelText: 'اسم الجد'),
            ),
            _gap(),
            TextFormField(
              controller: _familyName,
              decoration: const InputDecoration(labelText: 'اسم العائلة *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _gap(),
            TextFormField(
              controller: _motherName,
              decoration: const InputDecoration(labelText: 'اسم الأم'),
            ),
            _gap(),
            TextFormField(
              controller: _alias,
              decoration: const InputDecoration(labelText: 'الكنية'),
            ),

            _section('الهوية'),
            TextFormField(
              controller: _nationalId,
              decoration: const InputDecoration(labelText: 'الرقم الوطني'),
              keyboardType: TextInputType.number,
            ),
            _gap(),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime(1980, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _birthDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_birthDate == null
                        ? '—'
                        : _birthDate!.toIso8601String().substring(0, 10)),
                  ),
                ),
              ),
            ]),
            CheckboxListTile(
              value: _birthDateApprox,
              title: const Text('التاريخ تقريبي', style: TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _birthDateApprox = v ?? false),
            ),
            _dropdown(
              label: 'محافظة الولادة',
              value: _birthGov,
              items: _ref!.governorates,
              onChanged: (v) => setState(() => _birthGov = v),
            ),
            _gap(),
            TextFormField(
              controller: _birthPlace,
              decoration:
                  const InputDecoration(labelText: 'مكان الولادة (مدينة/قرية)'),
            ),
            _gap(),
            _dropdown(
              label: 'الجنس *',
              value: _gender,
              items: _ref!.genders,
              onChanged: (v) => setState(() => _gender = v),
            ),
            _gap(),
            _dropdown(
              label: 'الحالة الزوجية وقت الاعتقال',
              value: _marital,
              items: _ref!.maritalStatuses,
              onChanged: (v) => setState(() => _marital = v),
            ),

            _section('وقت الاعتقال'),
            _dropdown(
              label: 'محافظة الاعتقال',
              value: _governorateAtDetention,
              items: _ref!.governorates,
              onChanged: (v) => setState(() => _governorateAtDetention = v),
            ),
            _gap(),
            TextFormField(
              controller: _addressAtDetention,
              decoration:
                  const InputDecoration(labelText: 'العنوان وقت الاعتقال'),
              maxLines: 2,
            ),
            _gap(),
            _dropdown(
              label: 'فئة المهنة',
              value: _occupation,
              items: _ref!.occupations,
              onChanged: (v) => setState(() => _occupation = v),
            ),
            _gap(),
            TextFormField(
              controller: _occupationDetail,
              decoration:
                  const InputDecoration(labelText: 'تفاصيل المهنة'),
            ),
            _gap(),
            _dropdown(
              label: 'فئة النشاط السياسي',
              value: _politicalActivity,
              items: _ref!.politicalActivities,
              onChanged: (v) => setState(() => _politicalActivity = v),
            ),
            _gap(),
            TextFormField(
              controller: _politicalDetail,
              decoration:
                  const InputDecoration(labelText: 'تفاصيل النشاط (اختياري)'),
              maxLines: 3,
            ),

            _section('معلومات الاتصال الحالية'),
            TextFormField(
              controller: _currentPhone,
              decoration:
                  const InputDecoration(labelText: 'الهاتف الحالي'),
              keyboardType: TextInputType.phone,
            ),
            _gap(),
            _dropdown(
              label: 'بلد الإقامة',
              value: _currentCountry,
              items: _ref!.countries,
              onChanged: (v) => setState(() => _currentCountry = v),
            ),
            _gap(),
            _dropdown(
              label: 'المحافظة الحالية (إن داخل سوريا)',
              value: _currentGov,
              items: _ref!.governorates,
              onChanged: (v) => setState(() => _currentGov = v),
            ),
            _gap(),
            TextFormField(
              controller: _currentCity,
              decoration: const InputDecoration(labelText: 'المدينة الحالية'),
            ),
            _gap(),
            TextFormField(
              controller: _kinName,
              decoration: const InputDecoration(labelText: 'اسم قريب للتواصل'),
            ),
            _gap(),
            TextFormField(
              controller: _kinPhone,
              decoration: const InputDecoration(labelText: 'هاتف القريب'),
              keyboardType: TextInputType.phone,
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEdit ? 'حفظ التعديلات' : 'حفظ الملف'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
