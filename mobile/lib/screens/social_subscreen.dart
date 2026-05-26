import 'package:flutter/material.dart';

import '../models/more_models.dart';
import '../models/survivor.dart';
import '../services/database_service.dart';
import '../theme.dart';
import 'forms/social_forms.dart';

/// شاشة فرعية لكل أقسام المسح الاجتماعي (تظهر داخل تبويب "اجتماعي")
class SocialSubScreen extends StatefulWidget {
  final Survivor survivor;
  final HouseholdSurvey household;
  final VoidCallback onReload;
  const SocialSubScreen({super.key,
      required this.survivor, required this.household, required this.onReload});

  @override
  State<SocialSubScreen> createState() => _SocialSubScreenState();
}

class _SocialSubScreenState extends State<SocialSubScreen> {
  List<Child> _children = [];
  HousingInfo? _housing;
  EducationStatus? _education;
  EmploymentInfo? _employment;
  HealthAccess? _health;
  NeedsAssessment? _needs;

  @override
  void initState() {
    super.initState();
    _loadSubData();
  }

  Future<void> _loadSubData() async {
    final hh = widget.household.localId!;
    final children = await DatabaseService.instance.getChildrenFor(hh);
    final housing = await DatabaseService.instance.getHousingFor(hh);
    final edu = await DatabaseService.instance.getEducationFor(
        widget.survivor.localId!);
    final emp = await DatabaseService.instance.getEmploymentFor(
        widget.survivor.localId!);
    final health = await DatabaseService.instance.getHealthFor(hh);
    final needs = await DatabaseService.instance.getNeedsFor(hh);
    if (!mounted) return;
    setState(() {
      _children = children;
      _housing = housing;
      _education = edu;
      _employment = emp;
      _health = health;
      _needs = needs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.household;
    return ListView(padding: const EdgeInsets.all(8), children: [
      _sectionCard(
        icon: Icons.family_restroom,
        title: 'بيانات الأسرة',
        subtitle: 'الزواج، الأفراد، التهجير',
        details: '${h.maritalStatus} · ${h.householdSize} فرد · ${h.displacementStatus}',
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              HouseholdFormScreen(survivor: widget.survivor, household: h)));
          _loadSubData();
          widget.onReload();
        },
      ),
      _sectionCard(
        icon: Icons.child_care,
        title: 'الأبناء (${_children.length})',
        subtitle: 'كل ابن/ابنة مع بياناته',
        onTap: () => _showChildren(),
      ),
      _sectionCard(
        icon: Icons.house,
        title: _housing == null ? 'السكن (غير مُسجَّل)' : 'السكن',
        subtitle: _housing == null
            ? 'اضغط لإضافة'
            : '${_housing!.housingType} · ${_housing!.roomsCount} غرف',
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              HousingFormScreen(
                  householdLocalId: h.localId!, housing: _housing)));
          _loadSubData();
        },
      ),
      _sectionCard(
        icon: Icons.school,
        title: _education == null ? 'التعليم (غير مُسجَّل)' : 'التعليم',
        subtitle: _education == null
            ? 'اضغط لإضافة'
            : '${_education!.highestLevelBeforeDetention} → ${_education!.highestLevelNow}',
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              EducationFormScreen(
                  survivor: widget.survivor, education: _education)));
          _loadSubData();
        },
      ),
      _sectionCard(
        icon: Icons.work,
        title: _employment == null ? 'العمل والدخل (غير مُسجَّل)' : 'العمل والدخل',
        subtitle: _employment == null
            ? 'اضغط لإضافة'
            : '${_employment!.status}'
              '${_employment!.monthlyIncome != null ? " · ${_employment!.monthlyIncome} ${_employment!.incomeCurrency}" : ""}',
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              EmploymentFormScreen(
                  survivor: widget.survivor, employment: _employment)));
          _loadSubData();
        },
      ),
      _sectionCard(
        icon: Icons.local_hospital,
        title: _health == null ? 'الصحة والرعاية (غير مُسجَّل)' : 'الصحة والرعاية',
        subtitle: _health == null
            ? 'اضغط لإضافة'
            : 'الأمن الغذائي: ${_health!.foodSecurity}',
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              HealthFormScreen(
                  householdLocalId: h.localId!, health: _health)));
          _loadSubData();
        },
      ),
      _sectionCard(
        icon: Icons.assignment,
        title: _needs == null ? 'تقييم الاحتياجات (غير مُسجَّل)' : 'تقييم الاحتياجات',
        subtitle: _needs == null
            ? 'اضغط لإضافة'
            : _summarizeNeeds(_needs!),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              NeedsFormScreen(
                  householdLocalId: h.localId!, needs: _needs)));
          _loadSubData();
        },
      ),
    ]);
  }

  String _summarizeNeeds(NeedsAssessment n) {
    final priorities = [
      if (n.financialAid != 'none') 'مالية:${n.financialAid}',
      if (n.medicalAid != 'none') 'طبية:${n.medicalAid}',
      if (n.legalAid != 'none') 'قانونية:${n.legalAid}',
      if (n.psychologicalSupport != 'none') 'نفسية:${n.psychologicalSupport}',
    ];
    return priorities.isEmpty ? 'لا أولويات' : priorities.join(' · ');
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? details,
    required VoidCallback onTap,
  }) {
    return Card(child: ListTile(
      leading: Icon(icon, color: HaqqunaColors.primary, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (subtitle != null) Text(subtitle),
        if (details != null) Text(details,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
      trailing: const Icon(Icons.arrow_back_ios, size: 16),
      onTap: onTap,
    ));
  }

  void _showChildren() {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        _ChildrenScreen(household: widget.household)),
    ).then((_) => _loadSubData());
  }
}

class _ChildrenScreen extends StatefulWidget {
  final HouseholdSurvey household;
  const _ChildrenScreen({required this.household});

  @override
  State<_ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<_ChildrenScreen> {
  List<Child> _children = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await DatabaseService.instance.getChildrenFor(
        widget.household.localId!);
    if (mounted) setState(() => _children = c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الأبناء (${_children.length})')),
      body: _children.isEmpty
          ? const Center(child: Text('لا أبناء مسجَّلون'))
          : ListView.builder(itemCount: _children.length, itemBuilder: (_, i) {
              final c = _children[i];
              return Card(margin: const EdgeInsets.all(8), child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.gender == 'female'
                      ? Colors.pink : HaqqunaColors.primary,
                  child: Icon(c.gender == 'female' ? Icons.female : Icons.male,
                      color: Colors.white),
                ),
                title: Text(c.name),
                subtitle: Text(
                    '${c.age != null ? "${c.age} سنة" : ""} · ${c.currentStage}'
                    '${c.droppedOut ? " · ترك الدراسة" : ""}'
                    '${c.dropoutDueToFatherDetention ? " (بسبب الاعتقال)" : ""}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await DatabaseService.instance.deleteChild(c.localId!);
                    _load();
                  },
                ),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChildFormScreen(
                          householdLocalId: widget.household.localId!,
                          child: c)));
                  _load();
                },
              ));
            }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              ChildFormScreen(
                  householdLocalId: widget.household.localId!)));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
