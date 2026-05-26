import 'package:flutter/material.dart';

import '../models/survivor.dart';
import '../services/survivor_service.dart';
import '../theme.dart';
import 'survivor_form_screen.dart';

class SurvivorListScreen extends StatefulWidget {
  const SurvivorListScreen({super.key});

  @override
  State<SurvivorListScreen> createState() => _SurvivorListScreenState();
}

class _SurvivorListScreenState extends State<SurvivorListScreen> {
  List<Survivor> _list = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await SurvivorService.instance.list(
      query: _query.isEmpty ? null : _query,
    );
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  Color _classColor(String c) {
    switch (c) {
      case 'A': return HaqqunaColors.success;
      case 'B': return HaqqunaColors.primary;
      case 'C': return Colors.grey;
      default: return HaqqunaColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الناجون')),
      body: Column(children: [
        // شريط البحث
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'بحث: اسم، رقم قضية، رقم وطني...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _query = '');
                        _refresh();
                      },
                    )
                  : null,
            ),
            onChanged: (v) {
              _query = v;
              _refresh();
            },
          ),
        ),
        // عدّاد
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text('${_list.length} ملف',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_list.any((s) => s.needsSync))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: HaqqunaColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_list.where((s) => s.needsSync).length} غير مُزامَن',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // القائمة
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('لا توجد ملفات',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        itemCount: _list.length,
                        itemBuilder: (_, i) {
                          final s = _list[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _classColor(s.fileClassification),
                                child: Text(
                                  s.fileClassification == 'draft'
                                      ? 'م'
                                      : s.fileClassification,
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(s.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.caseReference,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Row(children: [
                                    Icon(
                                      s.gender == 'female'
                                          ? Icons.female
                                          : Icons.male,
                                      size: 14,
                                    ),
                                    if (s.governorateAtDetention != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8),
                                        child: Text(
                                            s.governorateAtDetention ?? '',
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      ),
                                    const Spacer(),
                                    Text(
                                      'الدرجة: ${s.overallScore.toStringAsFixed(1)}/5',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ]),
                                ],
                              ),
                              trailing: s.needsSync
                                  ? const Icon(Icons.cloud_off,
                                      color: HaqqunaColors.warning, size: 20)
                                  : const Icon(Icons.cloud_done,
                                      color: HaqqunaColors.success, size: 20),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SurvivorFormScreen(
                                      survivor: s,
                                    ),
                                  ),
                                );
                                _refresh();
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SurvivorFormScreen()),
          );
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
