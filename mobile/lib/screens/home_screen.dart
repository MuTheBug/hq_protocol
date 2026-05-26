import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/survivor_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'server_config_screen.dart';
import 'survivor_form_screen.dart';
import 'survivor_list_screen.dart';

/// الشاشة الرئيسية - تعمل بدون تسجيل دخول
///
/// المتطوّع يفتح التطبيق ويبدأ التوثيق فوراً. تسجيل الدخول مطلوب فقط
/// عند الضغط على زر "مزامنة" أو "تحميل البيانات المرجعية".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _total = 0;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    // لا نُشغّل auto-sync لأن المتطوّع قد لا يكون مسجّلاً
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

  /// طلب تسجيل دخول إن لم يكن مُسجَّلاً، ثم تنفيذ الإجراء
  Future<bool> _ensureLoggedIn() async {
    if (AuthService.instance.isAuthenticated) return true;

    final wantsLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.login, color: HaqqunaColors.primary),
          SizedBox(width: 8),
          Text('تسجيل دخول مطلوب'),
        ]),
        content: const Text(
          'المزامنة تحتاج لاتصال آمن بالسيرفر. يرجى تسجيل الدخول مرة واحدة.\n\n'
          'البيانات المحلية تبقى محفوظة في كل الأحوال.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('تسجيل دخول'),
          ),
        ],
      ),
    );
    if (wantsLogin != true) return false;

    if (!mounted) return false;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return result == true && AuthService.instance.isAuthenticated;
  }

  Future<void> _syncNow() async {
    if (_pending == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لا توجد بيانات بانتظار المزامنة'),
      ));
      return;
    }
    final ok = await _ensureLoggedIn();
    if (!ok) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final res = await SyncService.instance.syncNow();
    if (!mounted) return;
    Navigator.pop(context); // close loading
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.errors > 0
          ? 'مزامنة: ${res.pushed} ↑ ${res.pulled} ↓ — ${res.errors} خطأ'
          : '✓ مزامنة: ${res.pushed} مرفوع، ${res.pulled} مستلَم'),
    ));
    _refresh();
  }

  Future<void> _loadReference() async {
    final ok = await _ensureLoggedIn();
    if (!ok) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final r = await SyncService.instance.loadReferenceData(forceRefresh: true);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r != null
          ? '✓ تم تحميل ${r.facilities.length} فرع + ${r.governorates.length} محافظة'
          : 'فشل التحميل'),
    ));
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل خروج؟'),
        content: const Text(
          'سيُلغى الـtoken المخزّن. البيانات المحلية تبقى محفوظة.\n'
          'ستحتاج لتسجيل دخول مجدداً عند المزامنة.',
        ),
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
    if (yes == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final isLoggedIn = AuthService.instance.isAuthenticated;
    return Scaffold(
      appBar: AppBar(
        title: const Text('حقّنا'),
        actions: [
          // زر المزامنة - مع شارة المعلّقات
          if (_pending > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
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
          // قائمة المزيد
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLoggedIn
                        ? (user?.fullNameAr.isNotEmpty == true
                            ? user!.fullNameAr
                            : user?.username ?? '—')
                        : 'وضع محلي (غير مسجَّل)'),
                    Text(
                      isLoggedIn ? user?.roleDisplay ?? '' : 'لا حساب نشط',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLoggedIn ? Colors.grey : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'sync',
                child: const ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('مزامنة الآن'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: _syncNow,
              ),
              PopupMenuItem(
                value: 'reload',
                child: const ListTile(
                  leading: Icon(Icons.cloud_download),
                  title: Text('تحديث البيانات المرجعية'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: _loadReference,
              ),
              PopupMenuItem(
                value: 'server',
                child: const ListTile(
                  leading: Icon(Icons.dns),
                  title: Text('إعدادات السيرفر'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServerConfigScreen(),
                      ),
                    );
                  });
                },
              ),
              if (isLoggedIn)
                PopupMenuItem(
                  value: 'logout',
                  child: const ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('تسجيل خروج'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: _logout,
                )
              else
                PopupMenuItem(
                  value: 'login',
                  child: const ListTile(
                    leading: Icon(Icons.login, color: HaqqunaColors.primary),
                    title: Text('تسجيل دخول'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // شريط الحالة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLoggedIn
                    ? HaqqunaColors.light
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLoggedIn
                      ? HaqqunaColors.accent
                      : Colors.orange,
                ),
              ),
              child: Row(children: [
                Icon(
                  isLoggedIn ? Icons.cloud_done : Icons.phonelink_off,
                  color: isLoggedIn
                      ? HaqqunaColors.primary
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn
                            ? 'متصل بـ ${ApiConfig.baseUrl}'
                            : 'وضع محلي - بياناتك محفوظة على الجهاز فقط',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isLoggedIn
                            ? 'يمكنك المزامنة في أي وقت'
                            : 'سجّل دخول عند الحاجة للمزامنة',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

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
                subtitle: const Text('يحفظ محلياً فوراً'),
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
                leading: Icon(Icons.sync,
                    color: _pending > 0
                        ? HaqqunaColors.warning
                        : HaqqunaColors.success,
                    size: 32),
                title: Text(_pending > 0
                    ? 'مزامنة الآن ($_pending معلّق)'
                    : 'مزامنة الآن'),
                subtitle: Text(isLoggedIn
                    ? 'متصل ومُجاز - اضغط للمزامنة'
                    : 'يتطلب تسجيل دخول'),
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
            MaterialPageRoute(builder: (_) => const SurvivorFormScreen()),
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
        child: Column(children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }
}
