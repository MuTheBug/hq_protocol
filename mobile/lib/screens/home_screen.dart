import 'package:flutter/material.dart';

import '../models/survivor.dart';
import '../services/auth_service.dart';
import '../services/survivor_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'survivor_form_screen.dart';
import 'survivor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _total = 0;
  int _pending = 0;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    SyncService.instance.startAutoSync(onSync: (r) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مزامنة: ${r.pushed} مرفوع، ${r.pulled} مستلَم، ${r.errors} خطأ',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _refresh();
      }
    });
    SyncService.instance.hasConnection().then((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    SyncService.instance.stopAutoSync();
    super.dispose();
  }

  Future<void> _refresh() async {
    final list = await SurvivorService.instance.list();
    final pending = await SurvivorService.instance.pendingCount();
    if (!mounted) return;
    setState(() {
      _total = list.length;
      _pending = pending;
    });
  }

  Future<void> _syncNow() async {
    setState(() {});
    final res = await SyncService.instance.syncNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        res.errors > 0
            ? 'مزامنة: ${res.pushed} ↑ ${res.pulled} ↓ — ${res.errors} خطأ'
            : '✓ مزامنة: ${res.pushed} مرفوع، ${res.pulled} مستلَم',
      ),
    ));
    _refresh();
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟ المسوّدات غير المُزامَنة ستبقى.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('حقّنا'),
        actions: [
          if (_pending > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Badge(
                label: Text('$_pending'),
                child: IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: _syncNow,
                  tooltip: 'مزامنة',
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncNow,
              tooltip: 'مزامنة',
            ),
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user?.fullNameAr.isNotEmpty == true
                      ? user!.fullNameAr
                      : user?.username ?? '—'),
                  subtitle: Text(user?.roleDisplay ?? ''),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('تسجيل خروج'),
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_online)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.wifi_off, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'غير متصل — يمكنك المتابعة، البيانات تُحفَظ محلياً',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ]),
              ),
            // بطاقات إحصاء
            Row(children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: 'الناجون',
                  value: '$_total',
                  color: HaqqunaColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.cloud_upload,
                  label: 'بانتظار المزامنة',
                  value: '$_pending',
                  color: _pending > 0
                      ? HaqqunaColors.warning
                      : HaqqunaColors.success,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            // قائمة سريعة
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add,
                    color: HaqqunaColors.primary, size: 32),
                title: const Text('ملف ناجٍ جديد'),
                subtitle: const Text('إنشاء ملف جديد - يعمل offline'),
                trailing: const Icon(Icons.arrow_back_ios),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SurvivorFormScreen(),
                    ),
                  );
                  _refresh();
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt,
                    color: HaqqunaColors.primary, size: 32),
                title: const Text('قائمة الناجين'),
                subtitle: Text('$_total ملف محلياً'),
                trailing: const Icon(Icons.arrow_back_ios),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SurvivorListScreen(),
                    ),
                  );
                  _refresh();
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync,
                    color: HaqqunaColors.primary, size: 32),
                title: const Text('مزامنة الآن'),
                subtitle: Text(_pending > 0
                    ? '$_pending مسودة بانتظار الرفع'
                    : 'كل شيء متزامن'),
                trailing: const Icon(Icons.arrow_back_ios),
                onTap: _syncNow,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SurvivorFormScreen(),
            ),
          );
          _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('ملف جديد'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
