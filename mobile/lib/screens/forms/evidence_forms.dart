/// نماذج: الوثائق، التقييم الطبي، الأثر طويل الأمد، المقابلات
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/more_models.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';
import '../../theme.dart';

class DocumentFormScreen extends StatefulWidget {
  final Survivor survivor;
  final SupportingDocument? document;
  const DocumentFormScreen({super.key, required this.survivor, this.document});

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _source;
  late final TextEditingController _url;
  late final TextEditingController _refNum;
  late final TextEditingController _issuer;
  late final TextEditingController _notes;
  DateTime? _obtained;
  DateTime? _docDate;
  String _type = 'other';

  static const Map<String, String> _types = {
    'official_regime': 'وثيقة رسمية من جهة سورية',
    'court_document': 'وثيقة قضائية',
    'arrest_warrant': 'أمر اعتقال',
    'release_order': 'أمر إفراج',
    'transfer_order': 'أمر إحالة/نقل',
    'international_court': 'وثيقة من محكمة دولية/IIIM',
    'leaked': 'وثيقة مسرّبة',
    'family_visit': 'كرت زيارة',
    'family_remittance': 'حوالة مالية',
    'lawyer': 'وثيقة من محامٍ',
    'media': 'مادة إعلامية',
    'social_media': 'منشور سوشيال',
    'photo': 'صورة',
    'video': 'فيديو',
    'audio': 'تسجيل صوتي',
    'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _title = TextEditingController(text: d?.title ?? '');
    _desc = TextEditingController(text: d?.description ?? '');
    _source = TextEditingController(text: d?.sourceDescription ?? '');
    _url = TextEditingController(text: d?.originalUrl ?? '');
    _refNum = TextEditingController(text: d?.documentReferenceNumber ?? '');
    _issuer = TextEditingController(text: d?.issuingAuthority ?? '');
    _notes = TextEditingController(text: d?.notes ?? '');
    _type = d?.documentType ?? 'other';
    if (d?.dateObtained?.isNotEmpty == true) {
      try { _obtained = DateTime.parse(d!.dateObtained!); } catch (_) {}
    }
    if (d?.documentDate?.isNotEmpty == true) {
      try { _docDate = DateTime.parse(d!.documentDate!); } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عنوان الوثيقة مطلوب')));
      return;
    }
    final d = widget.document ?? SupportingDocument(
      title: '', survivorLocalId: widget.survivor.localId,
    );
    d.localId ??= const Uuid().v4();
    d.survivorLocalId = widget.survivor.localId;
    d.documentType = _type;
    d.title = _title.text.trim();
    d.description = _desc.text.trim();
    d.sourceDescription = _source.text.trim();
    d.originalUrl = _url.text.trim();
    d.documentReferenceNumber = _refNum.text.trim();
    d.issuingAuthority = _issuer.text.trim();
    d.notes = _notes.text.trim();
    d.dateObtained = _obtained?.toIso8601String().substring(0, 10);
    d.documentDate = _docDate?.toIso8601String().substring(0, 10);
    d.needsSync = true;
    await DatabaseService.instance.upsertDocument(d);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<DateTime?> _pickDate(DateTime? init) => showDatePicker(
      context: context, initialDate: init ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وثيقة داعمة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'نوع الوثيقة *'),
          items: _types.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _type = v ?? 'other'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان الوثيقة *')),
        const SizedBox(height: 12),
        TextFormField(controller: _desc,
            decoration: const InputDecoration(labelText: 'الوصف والمحتوى'),
            maxLines: 3),
        const SizedBox(height: 12),
        TextFormField(controller: _source,
            decoration: const InputDecoration(
                labelText: 'مصدر الوثيقة (سلسلة الحيازة)',
                helperText: 'من، متى، أين، كيف'),
            maxLines: 4),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await _pickDate(_obtained);
            if (d != null) setState(() => _obtained = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ الاستلام'),
            child: Text(_obtained?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: HaqqunaColors.light,
          child: const Padding(padding: EdgeInsets.all(12), child: Text(
            '📎 رفع الملف الفعلي يحتاج اتصالاً بالسيرفر. '
            'يمكنك إضافة بيانات الوثيقة محلياً، والملف يُرفَق لاحقاً من تطبيق الويب.',
            style: TextStyle(fontSize: 13),
          )),
        ),
        const SizedBox(height: 12),
        const Text('للوثائق الرسمية:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(controller: _refNum,
            decoration: const InputDecoration(labelText: 'الرقم المرجعي')),
        const SizedBox(height: 12),
        TextFormField(controller: _issuer,
            decoration: const InputDecoration(labelText: 'الجهة المُصدرة')),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await _pickDate(_docDate);
            if (d != null) setState(() => _docDate = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ الوثيقة'),
            child: Text(_docDate?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _url,
            decoration: const InputDecoration(
                labelText: 'الرابط الأصلي (للوثائق المسرّبة)')),
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
// التقييم الطبي
// ============================================================
class MedicalFormScreen extends StatefulWidget {
  final Survivor survivor;
  final MedicalAssessment? assessment;
  const MedicalFormScreen({super.key, required this.survivor, this.assessment});

  @override
  State<MedicalFormScreen> createState() => _MedicalFormScreenState();
}

class _MedicalFormScreenState extends State<MedicalFormScreen> {
  late final TextEditingController _assessor;
  late final TextEditingController _credentials;
  late final TextEditingController _org;
  late final TextEditingController _physical;
  late final TextEditingController _scars;
  late final TextEditingController _disabilities;
  late final TextEditingController _psychological;
  late final TextEditingController _consNotes;
  DateTime? _date;
  String _type = 'physical';
  String _consistency = 'not_assessed';
  bool _istanbul = false;
  bool _ptsd = false;
  bool _depression = false;
  bool _anxiety = false;
  bool _consentShare = false;

  static const _types = {
    'physical': 'جسدي', 'psychological': 'نفسي', 'comprehensive': 'شامل',
  };
  static const _consistencyChoices = {
    'not_assessed': 'لم يُقَيَّم',
    'not_consistent': 'غير متوافق',
    'consistent': 'متوافق',
    'highly_consistent': 'متوافق بدرجة عالية',
    'typical': 'نمطي/مطابق تماماً',
    'diagnostic': 'تشخيصي - دليل قاطع',
  };

  @override
  void initState() {
    super.initState();
    final m = widget.assessment;
    _assessor = TextEditingController(text: m?.assessorName ?? '');
    _credentials = TextEditingController(text: m?.assessorCredentials ?? '');
    _org = TextEditingController(text: m?.assessorOrganization ?? '');
    _physical = TextEditingController(text: m?.physicalFindings ?? '');
    _scars = TextEditingController(text: m?.scarsDescription ?? '');
    _disabilities = TextEditingController(text: m?.disabilities ?? '');
    _psychological = TextEditingController(text: m?.psychologicalFindings ?? '');
    _consNotes = TextEditingController(text: m?.consistencyNotes ?? '');
    _type = m?.assessmentType ?? 'physical';
    _consistency = m?.consistencyWithAccount ?? 'not_assessed';
    _istanbul = m?.istanbulProtocolCompliant ?? false;
    _ptsd = m?.ptsdIndicators ?? false;
    _depression = m?.depressionIndicators ?? false;
    _anxiety = m?.anxietyIndicators ?? false;
    _consentShare = m?.consentToShare ?? false;
    if (m?.assessmentDate.isNotEmpty == true) {
      try { _date = DateTime.parse(m!.assessmentDate); } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (_date == null || _assessor.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التاريخ واسم الفاحص مطلوبان')));
      return;
    }
    final m = widget.assessment ?? MedicalAssessment(
      assessmentDate: '', assessorName: '',
      survivorLocalId: widget.survivor.localId,
    );
    m.localId ??= const Uuid().v4();
    m.survivorLocalId = widget.survivor.localId;
    m.assessmentType = _type;
    m.assessmentDate = _date!.toIso8601String().substring(0, 10);
    m.assessorName = _assessor.text.trim();
    m.assessorCredentials = _credentials.text.trim();
    m.assessorOrganization = _org.text.trim();
    m.istanbulProtocolCompliant = _istanbul;
    m.physicalFindings = _physical.text.trim();
    m.scarsDescription = _scars.text.trim();
    m.disabilities = _disabilities.text.trim();
    m.psychologicalFindings = _psychological.text.trim();
    m.ptsdIndicators = _ptsd;
    m.depressionIndicators = _depression;
    m.anxietyIndicators = _anxiety;
    m.consistencyWithAccount = _consistency;
    m.consistencyNotes = _consNotes.text.trim();
    m.consentToShare = _consentShare;
    m.needsSync = true;
    await DatabaseService.instance.upsertMedical(m);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم طبي/نفسي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'نوع التقييم'),
          items: _types.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _type = v ?? 'physical'),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2000), lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ التقييم *'),
            child: Text(_date?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _assessor,
            decoration: const InputDecoration(labelText: 'اسم الفاحص *')),
        const SizedBox(height: 12),
        TextFormField(controller: _credentials,
            decoration: const InputDecoration(labelText: 'المؤهلات والاختصاص')),
        const SizedBox(height: 12),
        TextFormField(controller: _org,
            decoration: const InputDecoration(labelText: 'المنظمة (مثل LDHR)')),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _istanbul,
          title: const Text('متوافق مع بروتوكول إسطنبول'),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _istanbul = v ?? false),
        ),
        const Divider(),
        TextFormField(controller: _physical,
            decoration: const InputDecoration(labelText: 'النتائج الجسدية'),
            maxLines: 4),
        const SizedBox(height: 12),
        TextFormField(controller: _scars,
            decoration: const InputDecoration(labelText: 'وصف الندوب والإصابات'),
            maxLines: 3),
        const SizedBox(height: 12),
        TextFormField(controller: _disabilities,
            decoration: const InputDecoration(labelText: 'الإعاقات المكتسبة'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _psychological,
            decoration: const InputDecoration(labelText: 'النتائج النفسية'),
            maxLines: 4),
        const SizedBox(height: 12),
        CheckboxListTile(value: _ptsd, contentPadding: EdgeInsets.zero,
            title: const Text('علامات اضطراب ما بعد الصدمة (PTSD)'),
            onChanged: (v) => setState(() => _ptsd = v ?? false)),
        CheckboxListTile(value: _depression, contentPadding: EdgeInsets.zero,
            title: const Text('علامات اكتئاب'),
            onChanged: (v) => setState(() => _depression = v ?? false)),
        CheckboxListTile(value: _anxiety, contentPadding: EdgeInsets.zero,
            title: const Text('علامات قلق'),
            onChanged: (v) => setState(() => _anxiety = v ?? false)),
        const Divider(),
        DropdownButtonFormField<String>(
          value: _consistency,
          decoration: const InputDecoration(
              labelText: 'مدى التوافق مع رواية الناجي (مصطلحات إسطنبول)'),
          isExpanded: true,
          items: _consistencyChoices.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _consistency = v ?? 'not_assessed'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _consNotes,
            decoration: const InputDecoration(labelText: 'ملاحظات على التوافق'),
            maxLines: 3),
        const SizedBox(height: 12),
        CheckboxListTile(value: _consentShare, contentPadding: EdgeInsets.zero,
            title: const Text('موافقة على مشاركة التقرير'),
            onChanged: (v) => setState(() => _consentShare = v ?? false)),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}

// ============================================================
// الأثر طويل الأمد
// ============================================================
class ImpactFormScreen extends StatefulWidget {
  final Survivor survivor;
  final LongTermImpact? impact;
  const ImpactFormScreen({super.key, required this.survivor, this.impact});

  @override
  State<ImpactFormScreen> createState() => _ImpactFormScreenState();
}

class _ImpactFormScreenState extends State<ImpactFormScreen> {
  late LongTermImpact _i;
  late final TextEditingController _physical;
  late final TextEditingController _chronic;
  late final TextEditingController _disabilities;
  late final TextEditingController _psychological;
  late final TextEditingController _family;
  late final TextEditingController _work;
  late final TextEditingController _education;
  late final TextEditingController _financial;
  late final TextEditingController _meds;
  late final TextEditingController _treatment;

  @override
  void initState() {
    super.initState();
    _i = widget.impact ?? LongTermImpact(
      survivorLocalId: widget.survivor.localId,
    );
    _physical = TextEditingController(text: _i.physicalInjuriesPermanent ?? '');
    _chronic = TextEditingController(text: _i.chronicIllnesses ?? '');
    _disabilities = TextEditingController(text: _i.disabilities ?? '');
    _psychological = TextEditingController(text: _i.psychologicalSymptoms ?? '');
    _family = TextEditingController(text: _i.familyImpact ?? '');
    _work = TextEditingController(text: _i.workImpact ?? '');
    _education = TextEditingController(text: _i.educationImpact ?? '');
    _financial = TextEditingController(text: _i.financialImpact ?? '');
    _meds = TextEditingController(text: _i.currentMedications ?? '');
    _treatment = TextEditingController(text: _i.treatmentDetails ?? '');
  }

  Future<void> _save() async {
    _i.localId ??= const Uuid().v4();
    _i.survivorLocalId = widget.survivor.localId;
    _i.physicalInjuriesPermanent = _physical.text.trim();
    _i.chronicIllnesses = _chronic.text.trim();
    _i.disabilities = _disabilities.text.trim();
    _i.psychologicalSymptoms = _psychological.text.trim();
    _i.familyImpact = _family.text.trim();
    _i.workImpact = _work.text.trim();
    _i.educationImpact = _education.text.trim();
    _i.financialImpact = _financial.text.trim();
    _i.currentMedications = _meds.text.trim();
    _i.treatmentDetails = _treatment.text.trim();
    _i.needsSync = true;
    await DatabaseService.instance.upsertImpact(_i);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأثر طويل الأمد')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _physical,
            decoration: const InputDecoration(labelText: 'إصابات جسدية دائمة'),
            maxLines: 3),
        const SizedBox(height: 12),
        TextFormField(controller: _chronic,
            decoration: const InputDecoration(labelText: 'أمراض مزمنة ناتجة'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _disabilities,
            decoration: const InputDecoration(labelText: 'إعاقات'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _psychological,
            decoration: const InputDecoration(labelText: 'الأعراض النفسية'),
            maxLines: 3),
        CheckboxListTile(value: _i.sleepDisorders, contentPadding: EdgeInsets.zero,
            title: const Text('اضطرابات نوم'),
            onChanged: (v) => setState(() => _i.sleepDisorders = v ?? false)),
        CheckboxListTile(value: _i.flashbacks, contentPadding: EdgeInsets.zero,
            title: const Text('استرجاع للذكريات (Flashbacks)'),
            onChanged: (v) => setState(() => _i.flashbacks = v ?? false)),
        CheckboxListTile(value: _i.socialWithdrawal, contentPadding: EdgeInsets.zero,
            title: const Text('انعزال اجتماعي'),
            onChanged: (v) => setState(() => _i.socialWithdrawal = v ?? false)),
        const Divider(),
        TextFormField(controller: _family,
            decoration: const InputDecoration(labelText: 'الأثر على العائلة'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _work,
            decoration: const InputDecoration(labelText: 'الأثر على القدرة على العمل'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _education,
            decoration: const InputDecoration(labelText: 'الأثر على التعليم'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _financial,
            decoration: const InputDecoration(labelText: 'الأثر المالي'),
            maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(controller: _meds,
            decoration: const InputDecoration(labelText: 'الأدوية الحالية'),
            maxLines: 2),
        CheckboxListTile(value: _i.receivingTreatment, contentPadding: EdgeInsets.zero,
            title: const Text('يتلقى علاجاً حالياً'),
            onChanged: (v) => setState(() => _i.receivingTreatment = v ?? false)),
        TextFormField(controller: _treatment,
            decoration: const InputDecoration(labelText: 'تفاصيل العلاج'),
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
// المقابلات
// ============================================================
class InterviewFormScreen extends StatefulWidget {
  final Survivor survivor;
  final Interview? interview;
  const InterviewFormScreen({super.key, required this.survivor, this.interview});

  @override
  State<InterviewFormScreen> createState() => _InterviewFormScreenState();
}

class _InterviewFormScreenState extends State<InterviewFormScreen> {
  late final TextEditingController _seq;
  late final TextEditingController _duration;
  late final TextEditingController _locDetail;
  late final TextEditingController _summary;
  late final TextEditingController _notes;
  DateTime? _date;
  String _locType = 'office';
  String _language = 'ar_levantine';
  String _methodology = 'istanbul';
  bool _isFirst = true;
  bool _recorded = false;
  bool _consentRec = false;
  bool _consentPublish = false;
  bool _genderApp = false;
  bool _refAfter = false;

  static const _locTypes = {
    'office': 'في مكاتب الجمعية', 'survivor_home': 'في منزل الناجي',
    'remote': 'عن بُعد', 'phone': 'هاتفية',
    'field': 'ميدانية أخرى', 'other': 'أخرى',
  };
  static const _languages = {
    'ar': 'العربية - الفصحى', 'ar_levantine': 'العربية - الشامية',
    'ku': 'الكردية', 'en': 'الإنجليزية', 'tr': 'التركية',
    'de': 'الألمانية', 'fr': 'الفرنسية', 'other': 'أخرى',
  };
  static const _methodologies = {
    'istanbul': 'بروتوكول إسطنبول', 'semi_structured': 'شبه منظمة',
    'narrative': 'سردية مفتوحة', 'structured': 'استمارة منظمة',
    'follow_up': 'مقابلة متابعة', 'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();
    final i = widget.interview;
    _seq = TextEditingController(text: '${i?.sequenceNumber ?? 1}');
    _duration = TextEditingController(text: i?.durationMinutes?.toString() ?? '');
    _locDetail = TextEditingController(text: i?.locationDetail ?? '');
    _summary = TextEditingController(text: i?.summary ?? '');
    _notes = TextEditingController(text: i?.notes ?? '');
    _locType = i?.locationType ?? 'office';
    _language = i?.language ?? 'ar_levantine';
    _methodology = i?.methodology ?? 'istanbul';
    _isFirst = i?.isFirst ?? true;
    _recorded = i?.recorded ?? false;
    _consentRec = i?.consentToRecord ?? false;
    _consentPublish = i?.consentToPublishRecording ?? false;
    _genderApp = i?.genderAppropriate ?? false;
    _refAfter = i?.psychologicalReferralAfter ?? false;
    if (i?.interviewDate.isNotEmpty == true) {
      try { _date = DateTime.parse(i!.interviewDate); } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر تاريخ المقابلة')));
      return;
    }
    final i = widget.interview ?? Interview(
      interviewDate: '', survivorLocalId: widget.survivor.localId,
    );
    i.localId ??= const Uuid().v4();
    i.survivorLocalId = widget.survivor.localId;
    i.sequenceNumber = int.tryParse(_seq.text) ?? 1;
    i.isFirst = _isFirst;
    i.interviewDate = _date!.toIso8601String().substring(0, 10);
    i.durationMinutes = int.tryParse(_duration.text);
    i.locationType = _locType;
    i.locationDetail = _locDetail.text.trim();
    i.language = _language;
    i.methodology = _methodology;
    i.recorded = _recorded;
    i.consentToRecord = _consentRec;
    i.consentToPublishRecording = _consentPublish;
    i.summary = _summary.text.trim();
    i.genderAppropriate = _genderApp;
    i.psychologicalReferralAfter = _refAfter;
    i.notes = _notes.text.trim();
    i.needsSync = true;
    await DatabaseService.instance.upsertInterview(i);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقابلة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: TextFormField(controller: _seq,
              decoration: const InputDecoration(labelText: 'رقم المقابلة'),
              keyboardType: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: CheckboxListTile(value: _isFirst,
              contentPadding: EdgeInsets.zero,
              title: const Text('الأولى', style: TextStyle(fontSize: 14)),
              onChanged: (v) => setState(() => _isFirst = v ?? false))),
        ]),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2000), lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ المقابلة *'),
            child: Text(_date?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _duration,
            decoration: const InputDecoration(labelText: 'المدة بالدقائق'),
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _locType,
            decoration: const InputDecoration(labelText: 'نوع المكان'),
            items: _locTypes.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _locType = v ?? 'office')),
        const SizedBox(height: 12),
        TextFormField(controller: _locDetail,
            decoration: const InputDecoration(labelText: 'تفاصيل المكان')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _language,
            decoration: const InputDecoration(labelText: 'اللغة'),
            items: _languages.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _language = v ?? 'ar_levantine')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _methodology,
            decoration: const InputDecoration(labelText: 'المنهجية'),
            items: _methodologies.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _methodology = v ?? 'istanbul')),
        const Divider(),
        CheckboxListTile(value: _recorded, contentPadding: EdgeInsets.zero,
            title: const Text('مسجَّلة (صوت/فيديو)'),
            onChanged: (v) => setState(() => _recorded = v ?? false)),
        CheckboxListTile(value: _consentRec, contentPadding: EdgeInsets.zero,
            title: const Text('موافقة على التسجيل'),
            onChanged: (v) => setState(() => _consentRec = v ?? false)),
        CheckboxListTile(value: _consentPublish, contentPadding: EdgeInsets.zero,
            title: const Text('موافقة على نشر التسجيل'),
            onChanged: (v) => setState(() => _consentPublish = v ?? false)),
        CheckboxListTile(value: _genderApp, contentPadding: EdgeInsets.zero,
            title: const Text('روعيت اعتبارات النوع الاجتماعي'),
            onChanged: (v) => setState(() => _genderApp = v ?? false)),
        CheckboxListTile(value: _refAfter, contentPadding: EdgeInsets.zero,
            title: const Text('أُحيلت لدعم نفسي بعد المقابلة'),
            onChanged: (v) => setState(() => _refAfter = v ?? false)),
        const Divider(),
        TextFormField(controller: _summary,
            decoration: const InputDecoration(labelText: 'ملخص المقابلة'),
            maxLines: 5),
        const SizedBox(height: 12),
        TextFormField(controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
            maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ'))),
      ]),
    );
  }
}
