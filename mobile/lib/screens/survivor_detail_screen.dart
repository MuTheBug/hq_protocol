import 'package:flutter/material.dart';

import '../models/choices.dart';
import '../models/more_models.dart';
import '../models/related.dart';
import '../models/survivor.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';
import 'forms/consent_form_screen.dart';
import 'forms/event_form_screen.dart';
import 'forms/evidence_forms.dart';
import 'forms/note_form_screen.dart';
import 'forms/period_form_screen.dart';
import 'forms/release_form_screen.dart';
import 'forms/social_forms.dart';
import 'forms/witness_form_screen.dart';
import 'social_subscreen.dart';
import 'survivor_form_screen.dart';

/// شاشة تفاصيل الناجي بـ7 تبويبات: نظرة عامة، موافقة، احتجاز، شهود،
/// ملاحظات، إفراج، إحالات. كل تبويب يدير سجلاته محلياً.
class SurvivorDetailScreen extends StatefulWidget {
  final String survivorLocalId;
  const SurvivorDetailScreen({super.key, required this.survivorLocalId});

  @override
  State<SurvivorDetailScreen> createState() => _SurvivorDetailScreenState();
}

class _SurvivorDetailScreenState extends State<SurvivorDetailScreen>
    with SingleTickerProviderStateMixin {
  Survivor? _s;
  InformedConsent? _consent;
  ReleaseEvent? _release;
  List<DetentionEvent> _events = [];
  List<DetentionPeriod> _periods = [];
  List<Witness> _witnesses = [];
  List<SurvivorNote> _notes = [];
  List<SupportingDocument> _documents = [];
  List<MedicalAssessment> _medical = [];
  LongTermImpact? _impact;
  List<Interview> _interviews = [];
  HouseholdSurvey? _household;
  ReferenceData? _ref;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 11, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final s = await DatabaseService.instance.getByLocalId(widget.survivorLocalId);
    if (s == null) return;
    final consent = await DatabaseService.instance.getConsentFor(s.localId!);
    final release = await DatabaseService.instance.getReleaseFor(s.localId!);
    final events = await DatabaseService.instance.getEventsFor(s.localId!);
    final periods = await DatabaseService.instance.getPeriodsFor(s.localId!);
    final witnesses = await DatabaseService.instance.getWitnessesFor(s.localId!);
    final notes = await DatabaseService.instance.getNotesFor(s.localId!);
    final documents = await DatabaseService.instance.getDocumentsFor(s.localId!);
    final medical = await DatabaseService.instance.getMedicalFor(s.localId!);
    final impact = await DatabaseService.instance.getImpactFor(s.localId!);
    final interviews = await DatabaseService.instance.getInterviewsFor(s.localId!);
    final household = await DatabaseService.instance.getHouseholdFor(s.localId!);
    final ref = await SyncService.instance.loadReferenceData();
    if (!mounted) return;
    setState(() {
      _s = s;
      _consent = consent;
      _release = release;
      _events = events;
      _periods = periods;
      _witnesses = witnesses;
      _notes = notes;
      _documents = documents;
      _medical = medical;
      _impact = impact;
      _interviews = interviews;
      _household = household;
      _ref = ref;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = _s!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.fullName, style: const TextStyle(fontSize: 16)),
            Text(s.caseReference,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل البيانات الأساسية',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SurvivorFormScreen(survivor: s)));
              _load();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            const Tab(icon: Icon(Icons.dashboard), text: 'نظرة عامة'),
            Tab(icon: const Icon(Icons.shield_outlined),
                text: 'موافقة${_consent?.isFullyCompliant == true ? " ✓" : ""}'),
            Tab(icon: const Icon(Icons.event),
                text: 'اعتقالات (${_events.length})'),
            Tab(icon: const Icon(Icons.timelapse),
                text: 'فترات (${_periods.length})'),
            const Tab(icon: Icon(Icons.exit_to_app), text: 'إفراج'),
            Tab(icon: const Icon(Icons.people),
                text: 'شهود (${_witnesses.length})'),
            Tab(icon: const Icon(Icons.description),
                text: 'وثائق (${_documents.length})'),
            Tab(icon: const Icon(Icons.local_hospital),
                text: 'طبي (${_medical.length})'),
            Tab(icon: const Icon(Icons.videocam),
                text: 'مقابلات (${_interviews.length})'),
            Tab(icon: Icon(_household != null
                ? Icons.home : Icons.home_outlined),
                text: 'اجتماعي'),
            Tab(icon: const Icon(Icons.sticky_note_2),
                text: 'ملاحظات (${_notes.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(s: s, periods: _periods, events: _events,
              witnesses: _witnesses),
          _ConsentTab(survivor: s, consent: _consent, onReload: _load),
          _EventsTab(survivor: s, events: _events, onReload: _load),
          _PeriodsTab(survivor: s, periods: _periods, events: _events,
              facilities: _ref?.facilities ?? [], onReload: _load),
          _ReleaseTab(survivor: s, release: _release, onReload: _load),
          _WitnessesTab(survivor: s, witnesses: _witnesses,
              facilities: _ref?.facilities ?? [], onReload: _load),
          _DocumentsTab(survivor: s, documents: _documents, onReload: _load),
          _MedicalTab(survivor: s, medical: _medical, impact: _impact,
              onReload: _load),
          _InterviewsTab(survivor: s, interviews: _interviews, onReload: _load),
          _SocialTab(survivor: s, household: _household, onReload: _load),
          _NotesTab(survivor: s, notes: _notes, onReload: _load),
        ],
      ),
    );
  }
}

// ============================================================
// تبويب: الوثائق الداعمة
// ============================================================
class _DocumentsTab extends StatelessWidget {
  final Survivor survivor;
  final List<SupportingDocument> documents;
  final VoidCallback onReload;
  const _DocumentsTab({required this.survivor,
      required this.documents, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: documents.isEmpty
          ? const Center(child: Text('لا توجد وثائق'))
          : ListView.builder(itemCount: documents.length,
              itemBuilder: (_, i) {
                final d = documents[i];
                return Card(margin: const EdgeInsets.all(8), child: ListTile(
                  leading: const Icon(Icons.description,
                      color: HaqqunaColors.primary),
                  title: Text(d.title),
                  subtitle: Text('${d.documentType} · ${d.dateObtained ?? "—"}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseService.instance.deleteDocument(d.localId!);
                      onReload();
                    },
                  ),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DocumentFormScreen(
                            survivor: survivor, document: d)));
                    onReload();
                  },
                ));
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => DocumentFormScreen(survivor: survivor)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: التقييم الطبي + الأثر طويل الأمد
// ============================================================
class _MedicalTab extends StatelessWidget {
  final Survivor survivor;
  final List<MedicalAssessment> medical;
  final LongTermImpact? impact;
  final VoidCallback onReload;
  const _MedicalTab({required this.survivor, required this.medical,
      required this.impact, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(8), children: [
        Card(child: ListTile(
          leading: const Icon(Icons.healing, color: HaqqunaColors.primary),
          title: Text(impact == null
              ? 'الأثر طويل الأمد - أضف' : 'الأثر طويل الأمد - مُسجَّل'),
          subtitle: impact != null
              ? Text([
                  if (impact!.sleepDisorders) 'اضطرابات نوم',
                  if (impact!.flashbacks) 'استرجاع ذكريات',
                  if (impact!.socialWithdrawal) 'انعزال',
                  if (impact!.receivingTreatment) 'يتلقى علاجاً',
                ].join(' · '))
              : null,
          trailing: const Icon(Icons.edit),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => ImpactFormScreen(
                    survivor: survivor, impact: impact)));
            onReload();
          },
        )),
        const Padding(padding: EdgeInsets.all(8), child: Text(
          'التقييمات الطبية:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        )),
        ...medical.map((m) => Card(margin: const EdgeInsets.all(8),
            child: ListTile(
          leading: Icon(m.istanbulProtocolCompliant
              ? Icons.verified : Icons.medical_services,
              color: m.istanbulProtocolCompliant
                  ? HaqqunaColors.success : Colors.grey),
          title: Text('${m.assessorName} - ${m.assessmentDate}'),
          subtitle: Text('${m.assessmentType} · ${m.assessorOrganization ?? ""}'
              '${m.istanbulProtocolCompliant ? " ✓ متوافق إسطنبول" : ""}'),
          trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DatabaseService.instance.deleteMedical(m.localId!);
                onReload();
              }),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => MedicalFormScreen(
                    survivor: survivor, assessment: m)));
            onReload();
          },
        ))).toList(),
        if (medical.isEmpty)
          const Padding(padding: EdgeInsets.all(16),
              child: Text('لا توجد تقييمات - استخدم زر +')),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => MedicalFormScreen(survivor: survivor)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: المقابلات
// ============================================================
class _InterviewsTab extends StatelessWidget {
  final Survivor survivor;
  final List<Interview> interviews;
  final VoidCallback onReload;
  const _InterviewsTab({required this.survivor,
      required this.interviews, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: interviews.isEmpty
          ? const Center(child: Text('لا توجد مقابلات'))
          : ListView.builder(itemCount: interviews.length,
              itemBuilder: (_, i) {
                final iv = interviews[i];
                return Card(margin: const EdgeInsets.all(8), child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iv.isFirst
                        ? HaqqunaColors.success : HaqqunaColors.primary,
                    child: Text('${iv.sequenceNumber}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('مقابلة ${iv.interviewDate}'
                      '${iv.isFirst ? " (الأولى)" : ""}'),
                  subtitle: Text('${iv.methodology} · '
                      '${iv.recorded ? "🎥 مسجَّلة" : ""}'
                      '${iv.durationMinutes != null ? " · ${iv.durationMinutes} د" : ""}'),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DatabaseService.instance.deleteInterview(iv.localId!);
                        onReload();
                      }),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => InterviewFormScreen(
                            survivor: survivor, interview: iv)));
                    onReload();
                  },
                ));
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => InterviewFormScreen(survivor: survivor)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: الاجتماعي (مدخل لشاشة فرعية)
// ============================================================
class _SocialTab extends StatelessWidget {
  final Survivor survivor;
  final HouseholdSurvey? household;
  final VoidCallback onReload;
  const _SocialTab({required this.survivor, required this.household,
      required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (household == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.home_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('لم يُسجَّل مسح اجتماعي للأسرة بعد',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => HouseholdFormScreen(survivor: survivor)));
              onReload();
            },
            icon: const Icon(Icons.add),
            label: const Text('ابدأ المسح الاجتماعي'),
          ),
        ]),
      ));
    }
    return SocialSubScreen(survivor: survivor, household: household!,
        onReload: onReload);
  }
}

// ============================================================
// تبويب: نظرة عامة
// ============================================================
class _OverviewTab extends StatelessWidget {
  final Survivor s;
  final List<DetentionPeriod> periods;
  final List<DetentionEvent> events;
  final List<Witness> witnesses;
  const _OverviewTab({required this.s, required this.periods,
      required this.events, required this.witnesses});

  Color _scoreColor(num v) =>
      v >= 4 ? HaqqunaColors.success
      : v >= 2 ? HaqqunaColors.warning
      : HaqqunaColors.danger;

  @override
  Widget build(BuildContext context) {
    final independent = witnesses
        .where((w) => w.isIndependent && w.consentToUseTestimony)
        .length;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ScoreBox('الموثوقية', s.reliabilityScore, _scoreColor(s.reliabilityScore)),
              _ScoreBox('التحقق', s.corroborationScore, _scoreColor(s.corroborationScore)),
              _ScoreBox('الاكتمال', s.completenessScore, _scoreColor(s.completenessScore)),
              _ScoreBox('الإجمالي', s.overallScore, _scoreColor(s.overallScore), big: true),
            ]),
            const Divider(height: 24),
            Text('التصنيف: ${s.fileClassification.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('البيانات الشخصية',
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: HaqqunaColors.primary)),
            const Divider(),
            _row('الاسم الكامل', s.fullName),
            if (s.motherName?.isNotEmpty == true) _row('الأم', s.motherName!),
            if (s.alias?.isNotEmpty == true) _row('الكنية', s.alias!),
            if (s.nationalId?.isNotEmpty == true) _row('الرقم الوطني', s.nationalId!),
            if (s.birthDate != null) _row('تاريخ الميلاد', s.birthDate!),
            _row('الجنس', s.gender == 'male' ? 'ذكر' : s.gender == 'female' ? 'أنثى' : '—'),
            if (s.governorateAtDetention?.isNotEmpty == true)
              _row('محافظة الاعتقال', s.governorateAtDetention!),
            if (s.occupationCategory?.isNotEmpty == true)
              _row('فئة المهنة', s.occupationCategory!),
            if (s.politicalActivityCategory?.isNotEmpty == true)
              _row('النشاط السياسي', s.politicalActivityCategory!),
          ]),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إحصائيات',
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: HaqqunaColors.primary)),
            const Divider(),
            _row('وقائع الاعتقال', '${events.length}'),
            _row('فترات الاحتجاز', '${periods.length}'),
            _row('الشهود', '${witnesses.length}'),
            _row('شهود مستقلون', '$independent'),
            _row('حالة المزامنة', s.needsSync ? '⚠ معلّق' : '✓ مُزامَن'),
          ]),
        ),
      ),
    ]);
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(v)),
        ]),
      );
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final num value;
  final Color color;
  final bool big;
  const _ScoreBox(this.label, this.value, this.color, {this.big = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value is double ? value.toStringAsFixed(1) : '$value',
          style: TextStyle(
              fontSize: big ? 32 : 24,
              fontWeight: FontWeight.bold, color: color)),
      Text('$label / 5',
          style: TextStyle(fontSize: big ? 13 : 11, color: Colors.grey)),
    ]);
  }
}

// ============================================================
// تبويب: الموافقة
// ============================================================
class _ConsentTab extends StatelessWidget {
  final Survivor survivor;
  final InformedConsent? consent;
  final VoidCallback onReload;
  const _ConsentTab({required this.survivor, required this.consent, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      if (consent == null)
        Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('لا توجد موافقة مستنيرة'),
            subtitle: const Text('اضغط لإضافتها قبل أي توثيق'),
            trailing: const Icon(Icons.add),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ConsentFormScreen(survivor: survivor)));
              onReload();
            },
          ),
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(consent!.isFullyCompliant ? Icons.check_circle : Icons.warning,
                    color: consent!.isFullyCompliant ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Text(consent!.isFullyCompliant
                    ? 'موافقة مكتملة' : 'موافقة ناقصة',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ConsentFormScreen(
                          survivor: survivor, consent: consent)));
                  onReload();
                }),
              ]),
              const Divider(),
              const Text('المشاركة المُجازة:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, children: [
                if (consent!.shareWithIiim) const Chip(label: Text('IIIM')),
                if (consent!.shareWithCoi) const Chip(label: Text('CoI')),
                if (consent!.shareWithIcc) const Chip(label: Text('ICC')),
                if (consent!.shareWithUniversalJurisdiction)
                  const Chip(label: Text('UJ')),
                if (consent!.shareWithPartnerOrgs)
                  const Chip(label: Text('شركاء')),
                if (consent!.shareWithMedia) const Chip(label: Text('إعلام')),
              ]),
              const SizedBox(height: 8),
              const Text('إخفاء الهوية:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, children: [
                if (consent!.anonymizeName) const Chip(label: Text('اسم')),
                if (consent!.anonymizePhoto) const Chip(label: Text('صورة')),
                if (consent!.anonymizeLocation) const Chip(label: Text('موقع')),
                if (consent!.anonymizeFamilyDetails) const Chip(label: Text('عائلة')),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

// ============================================================
// تبويب: وقائع الاعتقال
// ============================================================
class _EventsTab extends StatelessWidget {
  final Survivor survivor;
  final List<DetentionEvent> events;
  final VoidCallback onReload;
  const _EventsTab({required this.survivor, required this.events, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: events.isEmpty
          ? const Center(child: Text('لا توجد وقائع - استخدم زر +'))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (_, i) {
                final e = events[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: HaqqunaColors.primary),
                    title: Text('${e.detentionDate} — ${e.detentionLocation}'),
                    subtitle: Text('الجهة: ${e.arrestingEntity}\n'
                        '${e.circumstances?.substring(0, e.circumstances!.length > 100 ? 100 : e.circumstances!.length) ?? ""}'
                        '${(e.circumstances?.length ?? 0) > 100 ? "..." : ""}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton(itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(
                          leading: Icon(Icons.edit), title: Text('تعديل'))),
                      const PopupMenuItem(value: 'delete', child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('حذف'))),
                    ], onSelected: (v) async {
                      if (v == 'edit') {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => EventFormScreen(
                                survivor: survivor, event: e)));
                        onReload();
                      } else if (v == 'delete') {
                        await DatabaseService.instance.deleteEvent(e.localId!);
                        onReload();
                      }
                    }),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => EventFormScreen(survivor: survivor)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: فترات الاحتجاز
// ============================================================
class _PeriodsTab extends StatelessWidget {
  final Survivor survivor;
  final List<DetentionPeriod> periods;
  final List<DetentionEvent> events;
  final List<Facility> facilities;
  final VoidCallback onReload;
  const _PeriodsTab({required this.survivor, required this.periods,
      required this.events, required this.facilities, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: periods.isEmpty
          ? const Center(child: Text('لا توجد فترات احتجاز'))
          : ListView.builder(
              itemCount: periods.length,
              itemBuilder: (_, i) {
                final p = periods[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: HaqqunaColors.primary,
                        child: Text('${p.orderIndex}',
                            style: const TextStyle(color: Colors.white))),
                    title: Text(p.facilityName ?? 'غير محدد'),
                    subtitle: Text('${p.fromDate} → ${p.toDate ?? "؟"}'
                        '${p.sexualViolenceReported ? " ⚠ عنف جنسي" : ""}'),
                    trailing: PopupMenuButton(itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ], onSelected: (v) async {
                      if (v == 'edit') {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PeriodFormScreen(
                                survivor: survivor, period: p,
                                facilities: facilities)));
                        onReload();
                      } else if (v == 'delete') {
                        await DatabaseService.instance.deletePeriod(p.localId!);
                        onReload();
                      }
                    }),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => PeriodFormScreen(
                  survivor: survivor, facilities: facilities)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: الشهود
// ============================================================
class _WitnessesTab extends StatelessWidget {
  final Survivor survivor;
  final List<Witness> witnesses;
  final List<Facility> facilities;
  final VoidCallback onReload;
  const _WitnessesTab({required this.survivor, required this.witnesses,
      required this.facilities, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: witnesses.isEmpty
          ? const Center(child: Text('لا يوجد شهود — استخدم زر +'))
          : ListView.builder(
              itemCount: witnesses.length,
              itemBuilder: (_, i) {
                final w = witnesses[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(
                      w.isIndependent ? Icons.verified_user : Icons.person,
                      color: w.isIndependent
                          ? HaqqunaColors.success : Colors.grey,
                    ),
                    title: Text(w.witnessName),
                    subtitle: Text('${w.facilityName ?? "—"} · '
                        '${w.periodFrom} → ${w.periodTo ?? "؟"}'
                        '${w.declarationSigned ? " ✓ موقّع" : ""}'),
                    trailing: PopupMenuButton(itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ], onSelected: (v) async {
                      if (v == 'edit') {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => WitnessFormScreen(
                                survivor: survivor, witness: w,
                                facilities: facilities)));
                        onReload();
                      } else if (v == 'delete') {
                        await DatabaseService.instance.deleteWitness(w.localId!);
                        onReload();
                      }
                    }),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => WitnessFormScreen(
                  survivor: survivor, facilities: facilities)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: الملاحظات
// ============================================================
class _NotesTab extends StatelessWidget {
  final Survivor survivor;
  final List<SurvivorNote> notes;
  final VoidCallback onReload;
  const _NotesTab({required this.survivor, required this.notes, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: notes.isEmpty
          ? const Center(child: Text('لا توجد ملاحظات'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (_, i) {
                final n = notes[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(
                      n.isPinned ? Icons.push_pin : Icons.sticky_note_2,
                      color: n.isPinned ? Colors.orange : Colors.grey,
                    ),
                    title: Text(n.title?.isEmpty == false ? n.title! : n.noteType),
                    subtitle: Text(n.content,
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DatabaseService.instance.deleteNote(n.localId!);
                        onReload();
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => NoteFormScreen(
                              survivor: survivor, note: n)));
                      onReload();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => NoteFormScreen(survivor: survivor)));
          onReload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// تبويب: الإفراج
// ============================================================
class _ReleaseTab extends StatelessWidget {
  final Survivor survivor;
  final ReleaseEvent? release;
  final VoidCallback onReload;
  const _ReleaseTab({required this.survivor, required this.release, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.exit_to_app, color: HaqqunaColors.primary),
          title: Text(release == null
              ? 'لم تُسجَّل بيانات إفراج' : 'تاريخ الإفراج: ${release!.releaseDate}'),
          subtitle: release == null
              ? const Text('اضغط لإضافة')
              : Text('النوع: ${release!.releaseType}\n${release!.circumstances}'),
          isThreeLine: release != null,
          trailing: Icon(release == null ? Icons.add : Icons.edit),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReleaseFormScreen(
                    survivor: survivor, release: release)));
            onReload();
          },
        ),
      ),
    ]);
  }
}
