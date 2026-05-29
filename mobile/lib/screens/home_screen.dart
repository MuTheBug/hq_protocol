import 'package:flutter/material.dart';

import '../data/entities.dart';
import '../data/reference_data.dart';
import '../db/record.dart';
import '../db/record_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form_screen.dart';
import 'survivor_detail_screen.dart';
import 'sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecordRepository _repo = RecordRepository.instance;
  final TextEditingController _search = TextEditingController();

  List<Record> _survivors = [];
  int _pending = 0;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listSurvivors(query: _query);
    final pending = await _repo.countPendingSync();
    if (!mounted) return;
    setState(() {
      _survivors = list;
      _pending = pending;
      _loading = false;
    });
  }

  Future<void> _addSurvivor() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormScreen(
          spec: kSurvivorSpec,
          initial: defaultsFor('survivor'),
        ),
      ),
    );
    if (result == null) return;
    final localId = await _repo.insert('survivor', result);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurvivorDetailScreen(survivorLocalId: localId),
      ),
    );
    _load();
  }

  Future<void> _openSync() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SyncScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حقّنا — توثيق الناجين'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'المزامنة',
                onPressed: _openSync,
              ),
              if (_pending > 0)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: HaqqunaColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_pending',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'بحث: اسم، رقم قضية، رقم وطني...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _query = '';
                          _load();
                        },
                      ),
              ),
              onChanged: (v) {
                _query = v;
                _load();
              },
            ),
          ),
          _statusBar(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _survivors.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _survivors.length,
                          itemBuilder: (_, i) => _tile(_survivors[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSurvivor,
        icon: const Icon(Icons.add),
        label: const Text('ملف جديد'),
      ),
    );
  }

  Widget _statusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Text('${_survivors.length} ملف',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(_pending > 0 ? Icons.cloud_off : Icons.cloud_done,
              size: 16,
              color:
                  _pending > 0 ? HaqqunaColors.warning : HaqqunaColors.success),
          const SizedBox(width: 4),
          Text(
            _pending > 0 ? '$_pending بانتظار المزامنة' : 'كل البيانات مُزامَنة',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.folder_open, size: 70, color: Colors.grey),
        SizedBox(height: 16),
        Text('لا توجد ملفات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        SizedBox(height: 6),
        Text('اضغط «ملف جديد» لبدء توثيق ناجٍ',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _tile(Record r) {
    final d = r.data;
    final cls = d['file_classification'] as String?;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: classColor(cls),
          child: Text(classLetter(cls),
              style: const TextStyle(color: Colors.white)),
        ),
        title: Text(fullNameOf(d)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.str('case_reference'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(d['gender'] == 'female' ? Icons.female : Icons.male,
                    size: 14),
                if (r.str('governorate_at_detention').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                        Ref.labelFor(Ref.governorates,
                            r.str('governorate_at_detention')),
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          r.needsSync ? Icons.cloud_off : Icons.cloud_done,
          color: r.needsSync ? HaqqunaColors.warning : HaqqunaColors.success,
          size: 20,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SurvivorDetailScreen(survivorLocalId: r.localId),
            ),
          );
          _load();
        },
      ),
    );
  }
}
