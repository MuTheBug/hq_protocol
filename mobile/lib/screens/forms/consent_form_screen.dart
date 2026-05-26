import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/related.dart';
import '../../models/survivor.dart';
import '../../services/database_service.dart';
import '../../theme.dart';

/// نموذج الموافقة المستنيرة الطبقية
class ConsentFormScreen extends StatefulWidget {
  final Survivor survivor;
  final InformedConsent? consent;
  const ConsentFormScreen({super.key, required this.survivor, this.consent});

  @override
  State<ConsentFormScreen> createState() => _ConsentFormScreenState();
}

class _ConsentFormScreenState extends State<ConsentFormScreen> {
  late InformedConsent _c;
  late final TextEditingController _witness;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _c = widget.consent ?? InformedConsent(
      survivorLocalId: widget.survivor.localId,
    );
    _witness = TextEditingController(text: _c.consentWitness ?? '');
    if (_c.consentDate?.isNotEmpty == true) {
      try { _date = DateTime.parse(_c.consentDate!); } catch (_) {}
    }
  }

  Future<void> _save() async {
    _c.localId ??= const Uuid().v4();
    _c.survivorLocalId = widget.survivor.localId;
    _c.consentWitness = _witness.text.trim();
    _c.consentDate = _date?.toIso8601String().substring(0, 10);
    _c.needsSync = true;
    await DatabaseService.instance.upsertConsent(_c);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _check(String title, bool value, void Function(bool) onChanged,
      {String? subtitle}) {
    return CheckboxListTile(
      value: value,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: HaqqunaColors.primary, fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموافقة المستنيرة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(
          color: HaqqunaColors.light,
          child: Padding(padding: EdgeInsets.all(12),
            child: Text(
              '⚠ الموافقة المستنيرة شرط أساسي قبل أي توثيق. اطبع نموذج موافقة '
              'موقّع من الناجي قبل إكمال هذه الصفحة.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        _section('الأساسيات'),
        _check('الموافقة موثّقة (موقّعة)', _c.consentDocumented,
            (v) => _c.consentDocumented = v),
        InkWell(
          onTap: () async {
            final p = await showDatePicker(
              context: context, initialDate: _date ?? DateTime.now(),
              firstDate: DateTime(2020), lastDate: DateTime.now(),
            );
            if (p != null) setState(() => _date = p);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'تاريخ الموافقة',
                suffixIcon: Icon(Icons.calendar_today)),
            child: Text(_date?.toIso8601String().substring(0, 10) ?? '—'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _witness,
          decoration: const InputDecoration(
              labelText: 'شاهد على الموافقة (اختياري)'),
        ),

        _section('مَن يُسمح بالمشاركة معه (الموافقة الطبقية)'),
        _check('IIIM (الآلية الدولية)', _c.shareWithIiim,
            (v) => _c.shareWithIiim = v),
        _check('لجنة التحقيق الأممية (CoI)', _c.shareWithCoi,
            (v) => _c.shareWithCoi = v),
        _check('المحكمة الجنائية الدولية (ICC)', _c.shareWithIcc,
            (v) => _c.shareWithIcc = v),
        _check('محاكم الولاية القضائية العالمية',
            _c.shareWithUniversalJurisdiction,
            (v) => _c.shareWithUniversalJurisdiction = v),
        _check('منظمات شريكة', _c.shareWithPartnerOrgs,
            (v) => _c.shareWithPartnerOrgs = v),
        _check('الإعلام', _c.shareWithMedia,
            (v) => _c.shareWithMedia = v),
        _check('نشر علني', _c.sharePublicly, (v) => _c.sharePublicly = v),

        _section('إخفاء الهوية'),
        _check('إخفاء الاسم', _c.anonymizeName, (v) => _c.anonymizeName = v),
        _check('إخفاء الصورة', _c.anonymizePhoto, (v) => _c.anonymizePhoto = v),
        _check('إخفاء الموقع الحالي', _c.anonymizeLocation,
            (v) => _c.anonymizeLocation = v),
        _check('إخفاء تفاصيل العائلة', _c.anonymizeFamilyDetails,
            (v) => _c.anonymizeFamilyDetails = v),

        _section('الإقرار بالفهم'),
        _check('شُرح حق الانسحاب', _c.withdrawalRightExplained,
            (v) => _c.withdrawalRightExplained = v),
        _check('شُرحت حدود السرّية', _c.confidentialityLimitsExplained,
            (v) => _c.confidentialityLimitsExplained = v),
        _check('شُرحت الاستخدامات المحتملة', _c.intendedUsesExplained,
            (v) => _c.intendedUsesExplained = v),

        _section('سحب الموافقة'),
        _check('سُحبت الموافقة', _c.consentWithdrawn,
            (v) => _c.consentWithdrawn = v,
            subtitle: 'فعّل فقط إذا طلب الناجي صراحة سحبها'),

        const SizedBox(height: 24),
        SizedBox(height: 50, child: ElevatedButton.icon(
            onPressed: _save, icon: const Icon(Icons.save),
            label: const Text('حفظ الموافقة'))),
      ]),
    );
  }
}
