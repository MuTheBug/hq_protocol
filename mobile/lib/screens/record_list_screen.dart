import 'package:flutter/material.dart';

import '../data/entities.dart';
import '../data/field_spec.dart';
import '../db/record.dart';
import '../db/record_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form_screen.dart';

/// شاشة عامة لإدارة كيان متعدد السجلات (وقائع، فترات، شهود، وثائق...).
class RecordListScreen extends StatefulWidget {
  final EntitySpec spec;
  final int survivorLocalId;
  final String? subtitle;

  const RecordListScreen({
    super.key,
    required this.spec,
    required this.survivorLocalId,
    this.subtitle,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final RecordRepository _repo = RecordRepository.instance;
  List<Record> _records = [];
  bool _loading = true;

  EntitySpec get _spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await _repo.listForSurvivor(_spec.table, widget.survivorLocalId);
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormScreen(
          spec: _spec,
          initial: defaultsFor(_spec.table),
          subtitle: widget.subtitle,
        ),
      ),
    );
    if (result == null) return;
    await _repo.insert(_spec.table, result,
        survivorLocalId: widget.survivorLocalId);
    _load();
  }

  Future<void> _edit(Record r) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormScreen(
          spec: _spec,
          initial: r.data,
          subtitle: widget.subtitle,
        ),
      ),
    );
    if (result == null) return;
    await _repo.update(_spec.table, r.localId, result);
    _load();
  }

  Future<void> _delete(Record r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العنصر؟'),
        content: Text(recordHeadline(_spec.table, r.data)),
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
    await _repo.softDelete(_spec.table, r.localId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_spec.titleAr),
            if (widget.subtitle != null)
              Text(widget.subtitle!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_spec.icon, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('لا توجد عناصر في «${_spec.titleAr}»',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      const Text('اضغط + للإضافة',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _records.length,
                  itemBuilder: (_, i) {
                    final r = _records[i];
                    final sub = recordSubtitle(_spec.table, r.data);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: HaqqunaColors.light,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: HaqqunaColors.dark)),
                        ),
                        title: Text(recordHeadline(_spec.table, r.data)),
                        subtitle: sub.isEmpty ? null : Text(sub),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _delete(r),
                        ),
                        onTap: () => _edit(r),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
