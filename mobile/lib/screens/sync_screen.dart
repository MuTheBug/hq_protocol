import 'package:flutter/material.dart';

import '../db/record_repository.dart';
import '../sync/sync_service.dart';
import '../theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncService _sync = SyncService.instance;
  final RecordRepository _repo = RecordRepository.instance;

  late final TextEditingController _url =
      TextEditingController(text: _sync.baseUrl);
  late final TextEditingController _user =
      TextEditingController(text: _sync.username ?? '');
  final TextEditingController _pass = TextEditingController();

  bool _busy = false;
  int _pending = 0;
  String? _message;
  bool _messageOk = true;

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _refreshPending() async {
    final p = await _repo.countPendingSync();
    if (mounted) setState(() => _pending = p);
  }

  void _show(SyncResult r) {
    setState(() {
      _message = r.message;
      _messageOk = r.ok;
    });
  }

  Future<void> _loginAndSync() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    await _sync.setBaseUrl(_url.text);
    final login = await _sync.login(_user.text.trim(), _pass.text);
    if (!login.ok) {
      _show(login);
      setState(() => _busy = false);
      return;
    }
    final push = await _sync.push();
    _show(push);
    _pass.clear();
    await _refreshPending();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _syncNow() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await _sync.setBaseUrl(_url.text);
    final push = await _sync.push();
    _show(push);
    await _refreshPending();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _logout() async {
    await _sync.logout();
    setState(() => _message = null);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _sync.isLoggedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('المزامنة مع السيرفر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 12),
          _pendingCard(),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'عنوان السيرفر',
              helperText: 'مثال: http://192.168.1.100:8000',
              prefixIcon: Icon(Icons.dns),
            ),
          ),
          const SizedBox(height: 12),
          if (loggedIn)
            ..._loggedInSection()
          else
            ..._loginSection(),
          if (_message != null) ...[
            const SizedBox(height: 16),
            _messageBox(),
          ],
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      color: HaqqunaColors.light,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: HaqqunaColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'التطبيق يعمل دون اتصال بالكامل. تُحفظ كل البيانات على جهازك. '
                'سجّل الدخول هنا فقط عندما ترغب برفع بياناتك إلى السيرفر.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard() {
    final synced = _pending == 0;
    return Card(
      child: ListTile(
        leading: Icon(
          synced ? Icons.cloud_done : Icons.cloud_upload,
          color: synced ? HaqqunaColors.success : HaqqunaColors.warning,
        ),
        title: Text(synced
            ? 'كل البيانات مُزامَنة'
            : '$_pending سجل بانتظار الرفع'),
        subtitle: _sync.lastSync == null
            ? const Text('لم تتم أي مزامنة بعد')
            : Text('آخر مزامنة: ${_sync.lastSync!.split("T").first}'),
      ),
    );
  }

  List<Widget> _loginSection() {
    return [
      TextField(
        controller: _user,
        decoration: const InputDecoration(
          labelText: 'اسم المستخدم',
          prefixIcon: Icon(Icons.person),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _pass,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'كلمة المرور',
          prefixIcon: Icon(Icons.lock),
        ),
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _busy ? null : _loginAndSync,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.cloud_upload),
        label: Text(_busy ? 'جارٍ المزامنة...' : 'تسجيل الدخول ورفع البيانات'),
      ),
    ];
  }

  List<Widget> _loggedInSection() {
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.verified_user,
              color: HaqqunaColors.success),
          title: Text('مسجّل الدخول: ${_sync.username ?? ""}'),
          trailing: TextButton(
            onPressed: _busy ? null : _logout,
            child: const Text('خروج'),
          ),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _busy ? null : _syncNow,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.sync),
        label: Text(_busy ? 'جارٍ الرفع...' : 'رفع البيانات الآن'),
      ),
    ];
  }

  Widget _messageBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _messageOk
            ? HaqqunaColors.success.withOpacity(0.12)
            : HaqqunaColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _messageOk ? HaqqunaColors.success : HaqqunaColors.danger,
        ),
      ),
      child: Row(
        children: [
          Icon(_messageOk ? Icons.check_circle : Icons.error,
              color: _messageOk ? HaqqunaColors.success : HaqqunaColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(_message!)),
        ],
      ),
    );
  }
}
