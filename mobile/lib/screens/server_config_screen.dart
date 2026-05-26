import 'package:flutter/material.dart';

import '../config/api_config.dart';
import 'login_screen.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _ctrl = TextEditingController(text: ApiConfig.baseUrl);

  Future<void> _save() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان غير صالح')),
      );
      return;
    }
    await ApiConfig.setBaseUrl(url);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد عنوان السيرفر')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كيف أجد عنوان اللابتوب؟',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'على اللابتوب، شغّل النظام بـ ./run.sh ثم افتح صفحة '
                      '"الجوال" من القائمة لترى العنوان الكامل.\n\n'
                      'مثال: http://192.168.1.100:8000',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('عنوان السيرفر:'),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.100:8000',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('حفظ والمتابعة'),
            ),
            const SizedBox(height: 12),
            const Text(
              'بعد الحفظ، يحتاج التطبيق اتصالاً واحداً باللابتوب لتحميل '
              'البيانات المرجعية. بعدها يعمل offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
