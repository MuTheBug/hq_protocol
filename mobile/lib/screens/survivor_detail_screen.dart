import 'package:flutter/material.dart';

import '../data/entities.dart';
import '../data/field_spec.dart';
import '../db/record.dart';
import '../db/record_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form_screen.dart';
import 'record_list_screen.dart';

class SurvivorDetailScreen extends StatefulWidget {
  final int survivorLocalId;
  const SurvivorDetailScreen({super.key, required this.survivorLocalId});

  @override
  State<SurvivorDetailScreen> createState() => _SurvivorDetailScreenState();
}

class _SurvivorDetailScreenState extends State<SurvivorDetailScreen> {
  final RecordRepository _repo = RecordRepository.instance;
  Record? _survivor;
  final Map<String, int> _counts = {};
  bool _loading = true;

  int get _sid => widget.survivorLocalId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final survivor = await _repo.getById('survivor', _sid);
    _counts.clear();
    for (final e in kRelatedEntities) {
      _counts[e.table] = await _repo.countForSurvivor(e.table, _sid);
    }
    if (!mounted) return;
    setState(() {
      _survivor = survivor;
      _loading = false;
    });
  }

  String get _name => _survivor == null ? '' : fullNameOf(_survivor!.data);

  Future<void> _editIdentity() async {
    final s = _survivor;
    if (s == null) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormScreen(spec: kSurvivorSpec, initial: s.data),
      ),
    );
    if (result == null) return;
    await _repo.update('survivor', _sid, result);
    _load();
  }

  Future<void> _openSingleton(EntitySpec spec) async {
    final existing = await _repo.singletonForSurvivor(spec.table, _sid);
    final initial = existing?.data ?? defaultsFor(spec.table);
    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecordFormScreen(spec: spec, initial: initial, subtitle: _name),
      ),
    );
    if (result == null) return;
    if (existing != null) {
      await _repo.update(spec.table, existing.localId, result);
    } else {
      await _repo.insert(spec.table, result, survivorLocalId: _sid);
    }
    _load();
  }

  Future<void> _openList(EntitySpec spec) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordListScreen(
          spec: spec,
          survivorLocalId: _sid,
          subtitle: _name,
        ),
      ),
    );
    _load();
  }

  Future<void> _deleteSurvivor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الملف؟'),
        content: const Text(
            'سيُحذف هذا الملف وكل سجلاته من هذا الجهاز نهائياً. '
            'إن لم تتم مزامنته، لن يمكن استرجاعه.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.deleteSurvivorCascade(_sid);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_survivor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('تعذّر تحميل الملف')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_name, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _editIdentity();
              if (v == 'delete') _deleteSurvivor();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('تعديل بيانات الناجي')),
              PopupMenuItem(value: 'delete', child: Text('حذف الملف')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _header(),
          const SizedBox(height: 8),
          _groupTitle('بيانات الناجي'),
          _identityTile(),
          const SizedBox(height: 4),
          _groupTitle('التوثيق'),
          for (final t in kDocumentationTables) _sectionTile(entityByTable(t)),
          const SizedBox(height: 4),
          _groupTitle('المسح الاجتماعي'),
          for (final t in kSocialTables) _sectionTile(entityByTable(t)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _header() {
    final d = _survivor!.data;
    final cls = d['file_classification'] as String?;
    return Card(
      color: HaqqunaColors.light,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: classColor(cls),
              child: Text(classLetter(cls),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_survivor!.str('case_reference'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _survivor!.needsSync
                            ? Icons.cloud_off
                            : Icons.cloud_done,
                        size: 15,
                        color: _survivor!.needsSync
                            ? HaqqunaColors.warning
                            : HaqqunaColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                          _survivor!.needsSync
                              ? 'بانتظار المزامنة'
                              : 'مُزامَن',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTitle(String t) => SectionTitle(t);

  Widget _identityTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person, color: HaqqunaColors.primary),
        title: const Text('الهوية والبيانات الأساسية'),
        subtitle: const Text('اضغط للتعديل'),
        trailing: const Icon(Icons.chevron_left),
        onTap: _editIdentity,
      ),
    );
  }

  Widget _sectionTile(EntitySpec spec) {
    final count = _counts[spec.table] ?? 0;
    final String subtitle;
    if (spec.singleton) {
      subtitle = count > 0 ? 'مُسجَّل — اضغط للتعديل' : 'غير مُسجَّل — اضغط للإضافة';
    } else {
      subtitle = count > 0 ? '$count عنصر' : 'لا عناصر — اضغط للإضافة';
    }
    return Card(
      child: ListTile(
        leading: Icon(spec.icon, color: HaqqunaColors.primary),
        title: Text(spec.titleAr),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!spec.singleton && count > 0)
              CircleAvatar(
                radius: 12,
                backgroundColor: HaqqunaColors.accent,
                child: Text('$count',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            const Icon(Icons.chevron_left),
          ],
        ),
        onTap: () => spec.singleton ? _openSingleton(spec) : _openList(spec),
      ),
    );
  }
}
