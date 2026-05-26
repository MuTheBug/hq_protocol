/// نماذج المسح الاجتماعي: الأسرة، الأطفال، السكن، التعليم، العمل،
/// الصحة، الاحتياجات
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/more_models.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';

const _maritalStatuses = {
  'single': 'أعزب/عزباء', 'engaged': 'مخطوب/ة', 'married': 'متزوج/ة',
  'divorced': 'مطلّق/ة', 'widowed': 'أرمل/أرملة', 'separated': 'منفصل/ة',
};
const _displacementStatuses = {
  'not_displaced': 'لم يُهجَّر', 'idp': 'نازح داخلياً',
  'refugee': 'لاجئ خارج سوريا', 'returnee': 'عائد بعد لجوء',
  'asylum_seeker': 'طالب لجوء',
};
const _governorates = {
  'damascus': 'دمشق', 'rural_damascus': 'ريف دمشق',
  'aleppo': 'حلب', 'homs': 'حمص', 'hama': 'حماة',
  'latakia': 'اللاذقية', 'tartus': 'طرطوس', 'idlib': 'إدلب',
  'daraa': 'درعا', 'suwayda': 'السويداء', 'quneitra': 'القنيطرة',
  'raqqa': 'الرقة', 'deir_ez_zor': 'دير الزور', 'hasakah': 'الحسكة',
};
const _housingTypes = {
  'owned': 'ملك خاص', 'rented': 'إيجار',
  'with_family': 'مع أهل/أقارب', 'shared': 'سكن مشترك',
  'idp_camp': 'مخيم نازحين', 'refugee_camp': 'مخيم لاجئين',
  'shelter': 'مأوى/مركز إيواء', 'damaged': 'منزل متضرر',
  'destroyed': 'المنزل الأصلي مدمَّر', 'homeless': 'بلا مأوى',
  'other': 'أخرى',
};
const _conditions = {
  'good': 'جيدة', 'acceptable': 'مقبولة',
  'poor': 'سيئة', 'very_poor': 'سيئة جداً/غير صالحة للسكن',
};
const _currencies = {
  'SYP': 'ليرة سورية', 'USD': 'دولار', 'TRY': 'ليرة تركية',
  'EUR': 'يورو', 'other': 'أخرى',
};
const _employmentStatus = {
  'employed_formal': 'عمل رسمي', 'employed_informal': 'عمل غير رسمي',
  'self_employed': 'عمل حر', 'daily_labor': 'بالمياومة',
  'unemployed_seeking': 'عاطل يبحث', 'unemployed_not_seeking': 'عاطل لا يبحث',
  'unable_to_work': 'غير قادر صحياً', 'student': 'طالب',
  'retired': 'متقاعد', 'housewife': 'ربّة منزل',
};
const _eduLevels = {
  'illiterate': 'أمي', 'reads_writes': 'يقرأ ويكتب',
  'primary': 'ابتدائي', 'preparatory': 'إعدادي', 'secondary': 'ثانوي',
  'vocational': 'معهد متوسط/مهني', 'bachelor': 'إجازة جامعية',
  'master': 'ماجستير', 'phd': 'دكتوراه',
};
const _childStages = {
  'preschool': 'روضة', 'primary': 'ابتدائي', 'preparatory': 'إعدادي',
  'secondary': 'ثانوي', 'vocational': 'مهني/تقني',
  'university': 'جامعي', 'postgraduate': 'دراسات عليا',
  'not_started': 'لم يبدأ بعد', 'never_attended': 'لم يلتحق قطّ',
};
const _workStatus = {
  'student': 'طالب فقط', 'helps_family': 'يساعد الأسرة',
  'child_labor': 'عمالة أطفال', 'street_work': 'عمل في الشارع',
  'apprentice': 'صبي مهنة', 'regular_job': 'عمل منتظم', 'none': 'لا يعمل',
};
const _foodSecurity = {
  'good': 'جيد', 'moderate': 'متوسط',
  'poor': 'ضعيف', 'severe': 'انعدام أمن غذائي حاد',
};
const _priorities = {
  'critical': 'حرج/طارئ', 'high': 'عالي', 'medium': 'متوسط',
  'low': 'منخفض', 'none': 'لا حاجة',
};

DropdownMenuItem<String> _item(String value, String label) =>
    DropdownMenuItem(value: value, child: Text(label));

List<DropdownMenuItem<String>> _itemsFromMap(Map<String, String> m,
    {bool nullable = false}) {
  return [
    if (nullable) const DropdownMenuItem(value: null, child: Text('—')),
    ...m.entries.map((e) => _item(e.key, e.value)),
  ];
}

// ============================================================
// المسح الاجتماعي (الأسرة)
// ============================================================
class HouseholdFormScreen extends StatefulWidget {
  final Survivor survivor;
  final HouseholdSurvey? household;
  const HouseholdFormScreen({super.key, required this.survivor, this.household});

  @override
  State<HouseholdFormScreen> createState() => _HouseholdFormScreenState();
}

class _HouseholdFormScreenState extends State<HouseholdFormScreen> {
  late HouseholdSurvey _h;
  late final TextEditingController _spouseName;
  late final TextEditingController _spouseOcc;
  late final TextEditingController _spouseAge;
  late final TextEditingController _size;
  late final TextEditingController _deps;
  late final TextEditingController _children;
  late final TextEditingController _displaceCount;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  DateTime? _surveyDate;

  @override
  void initState() {
    super.initState();
    _h = widget.household ?? HouseholdSurvey(
      surveyDate: DateTime.now().toIso8601String().substring(0, 10),
      survivorLocalId: widget.survivor.localId,
    );
    _spouseName = TextEditingController(text: _h.spouseName ?? '');
    _spouseOcc = TextEditingController(text: _h.spouseOccupation ?? '');
    _spouseAge = TextEditingController(text: _h.spouseAge?.toString() ?? '');
    _size = TextEditingController(text: '${_h.householdSize}');
    _deps = TextEditingController(text: '${_h.dependentsCount}');
    _children = TextEditingController(text: '${_h.childrenCount}');
    _displaceCount = TextEditingController(text: '${_h.displacementCount}');
    _location = TextEditingController(text: _h.surveyLocation ?? '');
    _notes = TextEditingController(text: _h.surveyNotes ?? '');
    if (_h.surveyDate.isNotEmpty) {
      try { _surveyDate = DateTime.parse(_h.surveyDate); } catch (_) {}
    }
  }

  Future<void> _save() async {
    _h.localId ??= const Uuid().v4();
    _h.survivorLocalId = widget.survivor.localId;
    _h.spouseName = _spouseName.text.trim();
    _h.spouseOccupation = _spouseOcc.text.trim();
    _h.spouseAge = int.tryParse(_spouseAge.text);
    _h.householdSize = int.tryParse(_size.text) ?? 1;
    _h.dependentsCount = int.tryParse(_deps.text) ?? 0;
    _h.childrenCount = int.tryParse(_children.text) ?? 0;
    _h.displacementCount = int.tryParse(_displaceCount.text) ?? 0;
    _h.surveyDate = _surveyDate?.toIso8601String().substring(0, 10)
        ?? DateTime.now().toIso8601String().substring(0, 10);
    _h.surveyLocation = _location.text.trim();
    _h.surveyNotes = _notes.text.trim();
    _h.needsSync = true;
    await DatabaseService.instance.upsertHousehold(_h);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المسح الاجتماعي للأسرة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(value: _h.maritalStatus,
            decoration: const InputDecoration(labelText: 'الحالة الزوجية الحالية'),
            items: _itemsFromMap(_maritalStatuses),
            onChanged: (v) => setState(() => _h.maritalStatus = v ?? 'single')),
        CheckboxListTile(value: _h.maritalStatusChangedDueToDetention,
            contentPadding: EdgeInsets.zero,
            title: const Text('تغيرت الحالة الزوجية بسبب الاعتقال'),
            onChanged: (v) => setState(() =>
                _h.maritalStatusChangedDueToDetention = v ?? false)),
        const Divider(),
        TextFormField(controller: _spouseName,
            decoration: const InputDecoration(labelText: 'اسم الزوج/ة')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: CheckboxListTile(value: _h.spouseAlive,
              contentPadding: EdgeInsets.zero,
              title: const Text('على قيد الحياة', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _h.spouseAlive = v ?? true))),
          Expanded(child: CheckboxListTile(value: _h.spouseEmployed,
              contentPadding: EdgeInsets.zero,
              title: const Text('يعمل', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _h.spouseEmployed = v ?? false))),
        ]),
        CheckboxListTile(value: _h.spouseDetainedNow,
            contentPadding: EdgeInsets.zero,
            title: const Text('محتجز/ة حالياً'),
            onChanged: (v) => setState(() => _h.spouseDetainedNow = v ?? false)),
        CheckboxListTile(value: _h.spouseDetainedBefore,
            contentPadding: EdgeInsets.zero,
            title: const Text('سبق اعتقاله/ها'),
            onChanged: (v) => setState(() => _h.spouseDetainedBefore = v ?? false)),
        TextFormField(controller: _spouseOcc,
            decoration: const InputDecoration(labelText: 'عمل الزوج/ة')),
        const SizedBox(height: 8),
        TextFormField(controller: _spouseAge,
            decoration: const InputDecoration(labelText: 'عمر الزوج/ة'),
            keyboardType: TextInputType.number),
        const Divider(),
        Row(children: [
          Expanded(child: TextFormField(controller: _size,
              decoration: const InputDecoration(labelText: 'حجم الأسرة'),
              keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _children,
              decoration: const InputDecoration(labelText: 'عدد الأبناء'),
              keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _deps,
              decoration: const InputDecoration(labelText: 'معالون'),
              keyboardType: TextInputType.number)),
        ]),
        const Divider(),
        DropdownButtonFormField<String>(value: _h.displacementStatus,
            decoration: const InputDecoration(labelText: 'وضع التهجير'),
            items: _itemsFromMap(_displacementStatuses),
            onChanged: (v) => setState(() =>
                _h.displacementStatus = v ?? 'not_displaced')),
        TextFormField(controller: _displaceCount,
            decoration: const InputDecoration(labelText: 'كم مرة هُجِّر؟'),
            keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(value: _h.originalGovernorate,
            decoration: const InputDecoration(labelText: 'المحافظة الأصلية'),
            items: _itemsFromMap(_governorates, nullable: true),
            onChanged: (v) => setState(() => _h.originalGovernorate = v)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(value: _h.currentGovernorate,
            decoration: const InputDecoration(labelText: 'المحافظة الحالية'),
            items: _itemsFromMap(_governorates, nullable: true),
            onChanged: (v) => setState(() => _h.currentGovernorate = v)),
        const Divider(),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context,
                initialDate: _surveyDate ?? DateTime.now(),
                firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null) setState(() => _surveyDate = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ المسح'),
            child: Text(_surveyDate?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(controller: _location,
            decoration: const InputDecoration(labelText: 'مكان المسح')),
        const SizedBox(height: 8),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات الباحث'),
            maxLines: 3),
        CheckboxListTile(value: _h.consentToSurvey, contentPadding: EdgeInsets.zero,
            title: const Text('موافقة الناجي على المسح الاجتماعي'),
            onChanged: (v) => setState(() => _h.consentToSurvey = v ?? false)),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// طفل/ابن
// ============================================================
class ChildFormScreen extends StatefulWidget {
  final String householdLocalId;
  final Child? child;
  const ChildFormScreen({super.key, required this.householdLocalId, this.child});

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  late Child _c;
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _grade;
  late final TextEditingController _school;
  late final TextEditingController _reason;
  late final TextEditingController _disability;
  late final TextEditingController _notes;
  DateTime? _birth;

  @override
  void initState() {
    super.initState();
    _c = widget.child ?? Child(
      name: '', householdLocalId: widget.householdLocalId,
    );
    _name = TextEditingController(text: _c.name);
    _age = TextEditingController(text: _c.age?.toString() ?? '');
    _grade = TextEditingController(text: _c.currentGrade ?? '');
    _school = TextEditingController(text: _c.schoolName ?? '');
    _reason = TextEditingController(text: _c.dropoutReason ?? '');
    _disability = TextEditingController(text: _c.disabilityDescription ?? '');
    _notes = TextEditingController(text: _c.notes ?? '');
    if (_c.birthDate?.isNotEmpty == true) {
      try { _birth = DateTime.parse(_c.birthDate!); } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الاسم مطلوب')));
      return;
    }
    _c.localId ??= const Uuid().v4();
    _c.householdLocalId = widget.householdLocalId;
    _c.name = _name.text.trim();
    _c.age = int.tryParse(_age.text);
    _c.birthDate = _birth?.toIso8601String().substring(0, 10);
    _c.currentGrade = _grade.text.trim();
    _c.schoolName = _school.text.trim();
    _c.dropoutReason = _reason.text.trim();
    _c.disabilityDescription = _disability.text.trim();
    _c.notes = _notes.text.trim();
    _c.needsSync = true;
    await DatabaseService.instance.upsertChild(_c);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات ابن/ابنة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _name,
            decoration: const InputDecoration(labelText: 'الاسم *')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _c.gender,
              decoration: const InputDecoration(labelText: 'الجنس'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
              ],
              onChanged: (v) => setState(() => _c.gender = v ?? 'male'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _age,
              decoration: const InputDecoration(labelText: 'العمر'),
              keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context,
                initialDate: _birth ?? DateTime(2015),
                firstDate: DateTime(1990), lastDate: DateTime.now());
            if (d != null) setState(() => _birth = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ الميلاد'),
            child: Text(_birth?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const Divider(),
        const Text('التعليم:', style: TextStyle(fontWeight: FontWeight.bold)),
        CheckboxListTile(value: _c.isInSchool, contentPadding: EdgeInsets.zero,
            title: const Text('في المدرسة حالياً'),
            onChanged: (v) => setState(() => _c.isInSchool = v ?? true)),
        DropdownButtonFormField<String>(value: _c.currentStage,
            decoration: const InputDecoration(labelText: 'المرحلة'),
            items: _itemsFromMap(_childStages),
            onChanged: (v) => setState(() => _c.currentStage = v ?? 'not_started')),
        TextFormField(controller: _grade,
            decoration: const InputDecoration(labelText: 'الصف')),
        TextFormField(controller: _school,
            decoration: const InputDecoration(labelText: 'اسم المدرسة')),
        CheckboxListTile(value: _c.droppedOut, contentPadding: EdgeInsets.zero,
            title: const Text('ترك الدراسة'),
            onChanged: (v) => setState(() => _c.droppedOut = v ?? false)),
        CheckboxListTile(value: _c.dropoutDueToFatherDetention,
            contentPadding: EdgeInsets.zero,
            title: const Text('بسبب اعتقال الأب/الأم'),
            onChanged: (v) =>
                setState(() => _c.dropoutDueToFatherDetention = v ?? false)),
        TextFormField(controller: _reason,
            decoration: const InputDecoration(labelText: 'سبب الترك'),
            maxLines: 2),
        const Divider(),
        const Text('الصحة:', style: TextStyle(fontWeight: FontWeight.bold)),
        CheckboxListTile(value: _c.hasDisability, contentPadding: EdgeInsets.zero,
            title: const Text('لديه إعاقة'),
            onChanged: (v) => setState(() => _c.hasDisability = v ?? false)),
        TextFormField(controller: _disability,
            decoration: const InputDecoration(labelText: 'وصف الإعاقة')),
        CheckboxListTile(value: _c.hasChronicIllness, contentPadding: EdgeInsets.zero,
            title: const Text('مرض مزمن'),
            onChanged: (v) => setState(() => _c.hasChronicIllness = v ?? false)),
        CheckboxListTile(value: _c.psychologicalIssues,
            contentPadding: EdgeInsets.zero,
            title: const Text('معاناة نفسية ملحوظة'),
            onChanged: (v) => setState(() => _c.psychologicalIssues = v ?? false)),
        const Divider(),
        const Text('العمل:', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(value: _c.workStatus,
            decoration: const InputDecoration(labelText: 'وضع العمل'),
            items: _itemsFromMap(_workStatus),
            onChanged: (v) => setState(() => _c.workStatus = v ?? 'student')),
        const SizedBox(height: 12),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
            maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// السكن
// ============================================================
class HousingFormScreen extends StatefulWidget {
  final String householdLocalId;
  final HousingInfo? housing;
  const HousingFormScreen({super.key, required this.householdLocalId, this.housing});

  @override
  State<HousingFormScreen> createState() => _HousingFormScreenState();
}

class _HousingFormScreenState extends State<HousingFormScreen> {
  late HousingInfo _h;
  late final TextEditingController _rent;
  late final TextEditingController _overdueMonths;
  late final TextEditingController _rooms;
  late final TextEditingController _residents;
  late final TextEditingController _elecHours;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _neighborhood;
  late final TextEditingController _origStatus;
  late final TextEditingController _confDetails;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _h = widget.housing ?? HousingInfo(householdLocalId: widget.householdLocalId);
    _rent = TextEditingController(text: _h.rentAmount?.toString() ?? '');
    _overdueMonths = TextEditingController(text: '${_h.rentOverdueMonths}');
    _rooms = TextEditingController(text: '${_h.roomsCount}');
    _residents = TextEditingController(text: '${_h.residentsCount}');
    _elecHours = TextEditingController(text: _h.electricityHoursPerDay?.toString() ?? '');
    _address = TextEditingController(text: _h.address ?? '');
    _city = TextEditingController(text: _h.city ?? '');
    _neighborhood = TextEditingController(text: _h.neighborhood ?? '');
    _origStatus = TextEditingController(text: _h.originalHomeStatus ?? '');
    _confDetails = TextEditingController(text: _h.confiscationDetails ?? '');
    _notes = TextEditingController(text: _h.notes ?? '');
  }

  Future<void> _save() async {
    _h.localId ??= const Uuid().v4();
    _h.householdLocalId = widget.householdLocalId;
    _h.rentAmount = double.tryParse(_rent.text);
    _h.rentOverdueMonths = int.tryParse(_overdueMonths.text) ?? 0;
    _h.roomsCount = int.tryParse(_rooms.text) ?? 1;
    _h.residentsCount = int.tryParse(_residents.text) ?? 1;
    _h.electricityHoursPerDay = int.tryParse(_elecHours.text);
    _h.address = _address.text.trim();
    _h.city = _city.text.trim();
    _h.neighborhood = _neighborhood.text.trim();
    _h.originalHomeStatus = _origStatus.text.trim();
    _h.confiscationDetails = _confDetails.text.trim();
    _h.notes = _notes.text.trim();
    _h.needsSync = true;
    await DatabaseService.instance.upsertHousing(_h);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isRented = _h.housingType == 'rented';
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات السكن')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(value: _h.housingType,
            decoration: const InputDecoration(labelText: 'نوع السكن'),
            isExpanded: true,
            items: _itemsFromMap(_housingTypes),
            onChanged: (v) => setState(() => _h.housingType = v ?? 'rented')),
        if (isRented) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(flex: 2, child: TextFormField(controller: _rent,
                decoration: const InputDecoration(labelText: 'قيمة الإيجار'),
                keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(value: _h.rentCurrency,
                decoration: const InputDecoration(labelText: 'العملة'),
                items: _itemsFromMap(_currencies),
                onChanged: (v) => setState(() => _h.rentCurrency = v ?? 'SYP'))),
          ]),
          CheckboxListTile(value: _h.rentOverdue, contentPadding: EdgeInsets.zero,
              title: const Text('متأخرات إيجار'),
              onChanged: (v) => setState(() => _h.rentOverdue = v ?? false)),
          TextFormField(controller: _overdueMonths,
              decoration: const InputDecoration(labelText: 'عدد أشهر التأخر'),
              keyboardType: TextInputType.number),
          CheckboxListTile(value: _h.threatenedWithEviction,
              contentPadding: EdgeInsets.zero,
              title: const Text('مهدَّد بالإخراج من المنزل'),
              onChanged: (v) =>
                  setState(() => _h.threatenedWithEviction = v ?? false)),
        ],
        const Divider(),
        Row(children: [
          Expanded(child: TextFormField(controller: _rooms,
              decoration: const InputDecoration(labelText: 'عدد الغرف'),
              keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _residents,
              decoration: const InputDecoration(labelText: 'عدد القاطنين'),
              keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _h.condition,
            decoration: const InputDecoration(labelText: 'حالة السكن'),
            items: _itemsFromMap(_conditions),
            onChanged: (v) => setState(() => _h.condition = v ?? 'acceptable')),
        const Divider(),
        const Text('المرافق:', style: TextStyle(fontWeight: FontWeight.bold)),
        CheckboxListTile(value: _h.hasElectricity, contentPadding: EdgeInsets.zero,
            title: const Text('كهرباء'),
            onChanged: (v) => setState(() => _h.hasElectricity = v ?? false)),
        TextFormField(controller: _elecHours,
            decoration: const InputDecoration(labelText: 'ساعات الكهرباء يومياً'),
            keyboardType: TextInputType.number),
        Row(children: [
          Expanded(child: CheckboxListTile(value: _h.hasWater,
              contentPadding: EdgeInsets.zero,
              title: const Text('ماء', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _h.hasWater = v ?? false))),
          Expanded(child: CheckboxListTile(value: _h.hasHeating,
              contentPadding: EdgeInsets.zero,
              title: const Text('تدفئة', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _h.hasHeating = v ?? false))),
        ]),
        Row(children: [
          Expanded(child: CheckboxListTile(value: _h.hasSanitation,
              contentPadding: EdgeInsets.zero,
              title: const Text('صرف صحي', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _h.hasSanitation = v ?? false))),
          Expanded(child: CheckboxListTile(value: _h.hasInternet,
              contentPadding: EdgeInsets.zero,
              title: const Text('إنترنت', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _h.hasInternet = v ?? false))),
        ]),
        const Divider(),
        TextFormField(controller: _address,
            decoration: const InputDecoration(labelText: 'العنوان'),
            maxLines: 2),
        DropdownButtonFormField<String?>(value: _h.governorate,
            decoration: const InputDecoration(labelText: 'المحافظة'),
            items: _itemsFromMap(_governorates, nullable: true),
            onChanged: (v) => setState(() => _h.governorate = v)),
        TextFormField(controller: _city,
            decoration: const InputDecoration(labelText: 'المدينة')),
        TextFormField(controller: _neighborhood,
            decoration: const InputDecoration(labelText: 'الحي')),
        const Divider(),
        CheckboxListTile(value: _h.ownedOriginalHomeBefore,
            contentPadding: EdgeInsets.zero,
            title: const Text('كان يملك منزلاً قبل التهجير'),
            onChanged: (v) =>
                setState(() => _h.ownedOriginalHomeBefore = v ?? false)),
        TextFormField(controller: _origStatus,
            decoration: const InputDecoration(labelText: 'وضع المنزل الأصلي حالياً'),
            maxLines: 2),
        CheckboxListTile(value: _h.propertyConfiscated,
            contentPadding: EdgeInsets.zero,
            title: const Text('تمت مصادرة ممتلكاته'),
            onChanged: (v) => setState(() => _h.propertyConfiscated = v ?? false)),
        TextFormField(controller: _confDetails,
            decoration: const InputDecoration(labelText: 'تفاصيل المصادرة'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
            maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// التعليم
// ============================================================
class EducationFormScreen extends StatefulWidget {
  final Survivor survivor;
  final EducationStatus? education;
  const EducationFormScreen({super.key, required this.survivor, this.education});

  @override
  State<EducationFormScreen> createState() => _EducationFormScreenState();
}

class _EducationFormScreenState extends State<EducationFormScreen> {
  late EducationStatus _e;
  late final TextEditingController _field;
  late final TextEditingController _institution;
  late final TextEditingController _program;
  late final TextEditingController _obstacles;
  late final TextEditingController _languages;
  late final TextEditingController _certDetails;

  @override
  void initState() {
    super.initState();
    _e = widget.education ?? EducationStatus(
      survivorLocalId: widget.survivor.localId,
    );
    _field = TextEditingController(text: _e.fieldOfStudy ?? '');
    _institution = TextEditingController(text: _e.institution ?? '');
    _program = TextEditingController(text: _e.currentProgram ?? '');
    _obstacles = TextEditingController(text: _e.obstaclesToEducation ?? '');
    _languages = TextEditingController(text: _e.languagesSpoken ?? '');
    _certDetails = TextEditingController(text: _e.certificatesDetails ?? '');
  }

  Future<void> _save() async {
    _e.localId ??= const Uuid().v4();
    _e.survivorLocalId = widget.survivor.localId;
    _e.fieldOfStudy = _field.text.trim();
    _e.institution = _institution.text.trim();
    _e.currentProgram = _program.text.trim();
    _e.obstaclesToEducation = _obstacles.text.trim();
    _e.languagesSpoken = _languages.text.trim();
    _e.certificatesDetails = _certDetails.text.trim();
    _e.needsSync = true;
    await DatabaseService.instance.upsertEducation(_e);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الوضع التعليمي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(value: _e.highestLevelBeforeDetention,
            decoration: const InputDecoration(
                labelText: 'أعلى مستوى دراسي قبل الاعتقال'),
            items: _itemsFromMap(_eduLevels),
            onChanged: (v) => setState(() =>
                _e.highestLevelBeforeDetention = v ?? 'illiterate')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _e.highestLevelNow,
            decoration: const InputDecoration(labelText: 'أعلى مستوى حالياً'),
            items: _itemsFromMap(_eduLevels),
            onChanged: (v) => setState(() => _e.highestLevelNow = v ?? 'illiterate')),
        CheckboxListTile(value: _e.studiesInterruptedByDetention,
            contentPadding: EdgeInsets.zero,
            title: const Text('انقطع عن الدراسة بسبب الاعتقال'),
            onChanged: (v) => setState(() =>
                _e.studiesInterruptedByDetention = v ?? false)),
        TextFormField(controller: _field,
            decoration: const InputDecoration(labelText: 'التخصص')),
        TextFormField(controller: _institution,
            decoration: const InputDecoration(labelText: 'المؤسسة التعليمية')),
        const Divider(),
        CheckboxListTile(value: _e.isCurrentlyStudying,
            contentPadding: EdgeInsets.zero,
            title: const Text('يدرس حالياً'),
            onChanged: (v) =>
                setState(() => _e.isCurrentlyStudying = v ?? false)),
        TextFormField(controller: _program,
            decoration: const InputDecoration(labelText: 'البرنامج/المرحلة الحالية')),
        CheckboxListTile(value: _e.wantsToResume, contentPadding: EdgeInsets.zero,
            title: const Text('يرغب باستئناف التعليم'),
            onChanged: (v) => setState(() => _e.wantsToResume = v ?? false)),
        TextFormField(controller: _obstacles,
            decoration: const InputDecoration(labelText: 'عقبات استئناف التعليم'),
            maxLines: 3),
        const Divider(),
        TextFormField(controller: _languages,
            decoration: const InputDecoration(
                labelText: 'اللغات التي يجيدها')),
        CheckboxListTile(value: _e.hasCertificates, contentPadding: EdgeInsets.zero,
            title: const Text('لديه شهادات معتمدة'),
            onChanged: (v) => setState(() => _e.hasCertificates = v ?? false)),
        TextFormField(controller: _certDetails,
            decoration: const InputDecoration(labelText: 'تفاصيل الشهادات'),
            maxLines: 2),
        CheckboxListTile(value: _e.certificatesLost,
            contentPadding: EdgeInsets.zero,
            title: const Text('فقد شهاداته بسبب الاعتقال/التهجير'),
            onChanged: (v) => setState(() => _e.certificatesLost = v ?? false)),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// العمل والدخل
// ============================================================
class EmploymentFormScreen extends StatefulWidget {
  final Survivor survivor;
  final EmploymentInfo? employment;
  const EmploymentFormScreen({super.key, required this.survivor, this.employment});

  @override
  State<EmploymentFormScreen> createState() => _EmploymentFormScreenState();
}

class _EmploymentFormScreenState extends State<EmploymentFormScreen> {
  late EmploymentInfo _e;
  late final TextEditingController _occupation;
  late final TextEditingController _income;
  late final TextEditingController _other;
  late final TextEditingController _hours;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _e = widget.employment ?? EmploymentInfo(
      survivorLocalId: widget.survivor.localId,
    );
    _occupation = TextEditingController(text: _e.currentOccupation ?? '');
    _income = TextEditingController(text: _e.monthlyIncome?.toString() ?? '');
    _other = TextEditingController(text: _e.otherIncomeSources ?? '');
    _hours = TextEditingController(text: _e.workHoursPerWeek?.toString() ?? '');
    _notes = TextEditingController(text: _e.notes ?? '');
  }

  Future<void> _save() async {
    _e.localId ??= const Uuid().v4();
    _e.survivorLocalId = widget.survivor.localId;
    _e.currentOccupation = _occupation.text.trim();
    _e.monthlyIncome = double.tryParse(_income.text);
    _e.otherIncomeSources = _other.text.trim();
    _e.workHoursPerWeek = int.tryParse(_hours.text);
    _e.notes = _notes.text.trim();
    _e.needsSync = true;
    await DatabaseService.instance.upsertEmployment(_e);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العمل والدخل')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(value: _e.status,
            decoration: const InputDecoration(labelText: 'وضع العمل الحالي'),
            isExpanded: true,
            items: _itemsFromMap(_employmentStatus),
            onChanged: (v) => setState(() =>
                _e.status = v ?? 'unemployed_seeking')),
        const SizedBox(height: 12),
        TextFormField(controller: _occupation,
            decoration: const InputDecoration(labelText: 'المهنة الحالية')),
        CheckboxListTile(value: _e.sameAsBefore, contentPadding: EdgeInsets.zero,
            title: const Text('عاد لنفس المهنة السابقة'),
            onChanged: (v) => setState(() => _e.sameAsBefore = v ?? false)),
        CheckboxListTile(value: _e.unableDueToHealth,
            contentPadding: EdgeInsets.zero,
            title: const Text('غير قادر لأسباب صحية ناتجة عن الاحتجاز'),
            onChanged: (v) => setState(() => _e.unableDueToHealth = v ?? false)),
        CheckboxListTile(value: _e.unableDueToLegal,
            contentPadding: EdgeInsets.zero,
            title: const Text('غير قادر لأسباب قانونية'),
            onChanged: (v) => setState(() => _e.unableDueToLegal = v ?? false)),
        const Divider(),
        Row(children: [
          Expanded(flex: 2, child: TextFormField(controller: _income,
              decoration: const InputDecoration(labelText: 'الدخل الشهري'),
              keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: _e.incomeCurrency,
              decoration: const InputDecoration(labelText: 'العملة'),
              items: _itemsFromMap(_currencies),
              onChanged: (v) =>
                  setState(() => _e.incomeCurrency = v ?? 'SYP'))),
        ]),
        CheckboxListTile(value: _e.incomeCoversBasicNeeds,
            contentPadding: EdgeInsets.zero,
            title: const Text('الدخل يغطي الاحتياجات الأساسية'),
            onChanged: (v) =>
                setState(() => _e.incomeCoversBasicNeeds = v ?? false)),
        const Divider(),
        const Text('مصادر الدخل:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        CheckboxListTile(value: _e.hasSalary, contentPadding: EdgeInsets.zero,
            title: const Text('راتب'),
            onChanged: (v) => setState(() => _e.hasSalary = v ?? false)),
        CheckboxListTile(value: _e.hasBusinessIncome, contentPadding: EdgeInsets.zero,
            title: const Text('دخل من عمل تجاري'),
            onChanged: (v) => setState(() => _e.hasBusinessIncome = v ?? false)),
        CheckboxListTile(value: _e.hasPension, contentPadding: EdgeInsets.zero,
            title: const Text('معاش تقاعدي'),
            onChanged: (v) => setState(() => _e.hasPension = v ?? false)),
        CheckboxListTile(value: _e.hasRemittance, contentPadding: EdgeInsets.zero,
            title: const Text('حوالات من الخارج'),
            onChanged: (v) => setState(() => _e.hasRemittance = v ?? false)),
        CheckboxListTile(value: _e.hasHumanitarianAid,
            contentPadding: EdgeInsets.zero,
            title: const Text('مساعدات إنسانية'),
            onChanged: (v) => setState(() => _e.hasHumanitarianAid = v ?? false)),
        CheckboxListTile(value: _e.hasFamilySupport,
            contentPadding: EdgeInsets.zero,
            title: const Text('مساعدات من الأهل'),
            onChanged: (v) => setState(() => _e.hasFamilySupport = v ?? false)),
        TextFormField(controller: _other,
            decoration: const InputDecoration(labelText: 'مصادر دخل أخرى'),
            maxLines: 2),
        TextFormField(controller: _hours,
            decoration: const InputDecoration(labelText: 'ساعات العمل أسبوعياً'),
            keyboardType: TextInputType.number),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
            maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// الصحة والرعاية
// ============================================================
class HealthFormScreen extends StatefulWidget {
  final String householdLocalId;
  final HealthAccess? health;
  const HealthFormScreen({super.key, required this.householdLocalId, this.health});

  @override
  State<HealthFormScreen> createState() => _HealthFormScreenState();
}

class _HealthFormScreenState extends State<HealthFormScreen> {
  late HealthAccess _h;
  late final TextEditingController _insType;
  late final TextEditingController _distance;
  late final TextEditingController _chronic;
  late final TextEditingController _disCount;
  late final TextEditingController _support;
  late final TextEditingController _unmet;
  late final TextEditingController _meals;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _h = widget.health ?? HealthAccess(householdLocalId: widget.householdLocalId);
    _insType = TextEditingController(text: _h.insuranceType ?? '');
    _distance = TextEditingController(
        text: _h.distanceToHealthFacilityKm?.toString() ?? '');
    _chronic = TextEditingController(text: _h.chronicIllnessesInFamily ?? '');
    _disCount = TextEditingController(text: '${_h.familyMembersWithDisability}');
    _support = TextEditingController(text: _h.psychologicalSupportProvider ?? '');
    _unmet = TextEditingController(text: _h.unmetMedicalNeeds ?? '');
    _meals = TextEditingController(text: '${_h.mealsPerDay}');
    _notes = TextEditingController(text: _h.notes ?? '');
  }

  Future<void> _save() async {
    _h.localId ??= const Uuid().v4();
    _h.householdLocalId = widget.householdLocalId;
    _h.insuranceType = _insType.text.trim();
    _h.distanceToHealthFacilityKm = double.tryParse(_distance.text);
    _h.chronicIllnessesInFamily = _chronic.text.trim();
    _h.familyMembersWithDisability = int.tryParse(_disCount.text) ?? 0;
    _h.psychologicalSupportProvider = _support.text.trim();
    _h.unmetMedicalNeeds = _unmet.text.trim();
    _h.mealsPerDay = int.tryParse(_meals.text) ?? 3;
    _h.notes = _notes.text.trim();
    _h.needsSync = true;
    await DatabaseService.instance.upsertHealth(_h);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصحة والوصول للرعاية')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        CheckboxListTile(value: _h.hasHealthInsurance,
            contentPadding: EdgeInsets.zero,
            title: const Text('لديه تأمين صحي'),
            onChanged: (v) =>
                setState(() => _h.hasHealthInsurance = v ?? false)),
        TextFormField(controller: _insType,
            decoration: const InputDecoration(labelText: 'نوع التأمين')),
        const Divider(),
        CheckboxListTile(value: _h.accessToPrimaryCare,
            contentPadding: EdgeInsets.zero,
            title: const Text('وصول للرعاية الأولية'),
            onChanged: (v) =>
                setState(() => _h.accessToPrimaryCare = v ?? false)),
        CheckboxListTile(value: _h.accessToSpecializedCare,
            contentPadding: EdgeInsets.zero,
            title: const Text('وصول للرعاية المتخصصة'),
            onChanged: (v) =>
                setState(() => _h.accessToSpecializedCare = v ?? false)),
        TextFormField(controller: _distance,
            decoration: const InputDecoration(
                labelText: 'بُعد أقرب مرفق صحي (كم)'),
            keyboardType: TextInputType.number),
        const Divider(),
        TextFormField(controller: _chronic,
            decoration: const InputDecoration(
                labelText: 'الأمراض المزمنة في الأسرة'),
            maxLines: 2),
        TextFormField(controller: _disCount,
            decoration: const InputDecoration(
                labelText: 'عدد ذوي الإعاقة في الأسرة'),
            keyboardType: TextInputType.number),
        CheckboxListTile(value: _h.psychologicalSupportReceived,
            contentPadding: EdgeInsets.zero,
            title: const Text('يتلقى دعماً نفسياً'),
            onChanged: (v) =>
                setState(() => _h.psychologicalSupportReceived = v ?? false)),
        TextFormField(controller: _support,
            decoration: const InputDecoration(labelText: 'جهة الدعم النفسي')),
        const Divider(),
        CheckboxListTile(value: _h.medicationsUnaffordable,
            contentPadding: EdgeInsets.zero,
            title: const Text('لا يستطيع تأمين الأدوية'),
            onChanged: (v) =>
                setState(() => _h.medicationsUnaffordable = v ?? false)),
        TextFormField(controller: _unmet,
            decoration: const InputDecoration(labelText: 'احتياجات طبية غير مُلبّاة'),
            maxLines: 2),
        const Divider(),
        DropdownButtonFormField<String>(value: _h.foodSecurity,
            decoration: const InputDecoration(labelText: 'الأمن الغذائي'),
            items: _itemsFromMap(_foodSecurity),
            onChanged: (v) => setState(() => _h.foodSecurity = v ?? 'moderate')),
        TextFormField(controller: _meals,
            decoration: const InputDecoration(labelText: 'وجبات يومية'),
            keyboardType: TextInputType.number),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
            maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// تقييم الاحتياجات
// ============================================================
class NeedsFormScreen extends StatefulWidget {
  final String householdLocalId;
  final NeedsAssessment? needs;
  const NeedsFormScreen({super.key, required this.householdLocalId, this.needs});

  @override
  State<NeedsFormScreen> createState() => _NeedsFormScreenState();
}

class _NeedsFormScreenState extends State<NeedsFormScreen> {
  late NeedsAssessment _n;
  late final TextEditingController _addNeeds;
  late final TextEditingController _barriers;
  late final TextEditingController _notes;
  DateTime? _date;
  DateTime? _followUp;

  @override
  void initState() {
    super.initState();
    _n = widget.needs ?? NeedsAssessment(
      assessmentDate: DateTime.now().toIso8601String().substring(0, 10),
      householdLocalId: widget.householdLocalId,
    );
    _addNeeds = TextEditingController(text: _n.additionalNeeds ?? '');
    _barriers = TextEditingController(text: _n.barriersToAid ?? '');
    _notes = TextEditingController(text: _n.notes ?? '');
    if (_n.assessmentDate.isNotEmpty) {
      try { _date = DateTime.parse(_n.assessmentDate); } catch (_) {}
    }
    if (_n.followUpDate?.isNotEmpty == true) {
      try { _followUp = DateTime.parse(_n.followUpDate!); } catch (_) {}
    }
  }

  Future<void> _save() async {
    _n.localId ??= const Uuid().v4();
    _n.householdLocalId = widget.householdLocalId;
    _n.assessmentDate = _date?.toIso8601String().substring(0, 10)
        ?? DateTime.now().toIso8601String().substring(0, 10);
    _n.followUpDate = _followUp?.toIso8601String().substring(0, 10);
    _n.additionalNeeds = _addNeeds.text.trim();
    _n.barriersToAid = _barriers.text.trim();
    _n.notes = _notes.text.trim();
    _n.needsSync = true;
    await DatabaseService.instance.upsertNeeds(_n);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _priorityField(String label, String value, void Function(String) setter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: value, decoration: InputDecoration(labelText: label),
        items: _itemsFromMap(_priorities),
        onChanged: (v) => setState(() => setter(v ?? 'none')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم الاحتياجات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ التقييم'),
            child: Text(_date?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 16),
        _priorityField('مساعدة مالية', _n.financialAid, (v) => _n.financialAid = v),
        _priorityField('مساعدة غذائية', _n.foodAid, (v) => _n.foodAid = v),
        _priorityField('مساعدة إسكان', _n.housingAid, (v) => _n.housingAid = v),
        _priorityField('مساعدة طبية', _n.medicalAid, (v) => _n.medicalAid = v),
        _priorityField('دعم نفسي', _n.psychologicalSupport,
            (v) => _n.psychologicalSupport = v),
        _priorityField('مساعدة قانونية', _n.legalAid, (v) => _n.legalAid = v),
        _priorityField('دعم تعليم الأبناء', _n.educationAid,
            (v) => _n.educationAid = v),
        _priorityField('تدريب مهني', _n.vocationalTraining,
            (v) => _n.vocationalTraining = v),
        _priorityField('استرداد وثائق رسمية', _n.documentsRecovery,
            (v) => _n.documentsRecovery = v),
        const Divider(),
        const Text('الوثائق المطلوبة:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Row(children: [
          Expanded(child: CheckboxListTile(value: _n.needsIdCard,
              contentPadding: EdgeInsets.zero,
              title: const Text('هوية', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _n.needsIdCard = v ?? false))),
          Expanded(child: CheckboxListTile(value: _n.needsFamilyBooklet,
              contentPadding: EdgeInsets.zero,
              title: const Text('دفتر عائلة', style: TextStyle(fontSize: 13)),
              onChanged: (v) =>
                  setState(() => _n.needsFamilyBooklet = v ?? false))),
        ]),
        Row(children: [
          Expanded(child: CheckboxListTile(value: _n.needsPassport,
              contentPadding: EdgeInsets.zero,
              title: const Text('جواز', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _n.needsPassport = v ?? false))),
          Expanded(child: CheckboxListTile(value: _n.needsBirthCertificate,
              contentPadding: EdgeInsets.zero,
              title: const Text('شهادة ميلاد', style: TextStyle(fontSize: 13)),
              onChanged: (v) =>
                  setState(() => _n.needsBirthCertificate = v ?? false))),
        ]),
        Row(children: [
          Expanded(child: CheckboxListTile(value: _n.needsMarriageCertificate,
              contentPadding: EdgeInsets.zero,
              title: const Text('وثيقة زواج', style: TextStyle(fontSize: 13)),
              onChanged: (v) =>
                  setState(() => _n.needsMarriageCertificate = v ?? false))),
          Expanded(child: CheckboxListTile(value: _n.needsSecurityClearance,
              contentPadding: EdgeInsets.zero,
              title: const Text('إخراج قيد', style: TextStyle(fontSize: 13)),
              onChanged: (v) =>
                  setState(() => _n.needsSecurityClearance = v ?? false))),
        ]),
        const Divider(),
        TextFormField(controller: _addNeeds,
            decoration: const InputDecoration(labelText: 'احتياجات أخرى'),
            maxLines: 2),
        TextFormField(controller: _barriers,
            decoration: const InputDecoration(labelText: 'عقبات الوصول للمساعدات'),
            maxLines: 2),
        CheckboxListTile(value: _n.followUpRequired,
            contentPadding: EdgeInsets.zero,
            title: const Text('يحتاج متابعة'),
            onChanged: (v) => setState(() => _n.followUpRequired = v ?? false)),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context,
                initialDate: _followUp ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d != null) setState(() => _followUp = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ المتابعة'),
            child: Text(_followUp?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
            maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}
