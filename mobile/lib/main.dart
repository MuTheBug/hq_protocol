import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'db/app_database.dart';
import 'screens/home_screen.dart';
import 'sync/sync_service.dart';
import 'theme.dart';

/// تطبيق جمعية حقّنا لتوثيق الناجين.
///
/// مبدأ التصميم: التطبيق يعمل دون اتصال بالكامل. لا حاجة لتسجيل الدخول عند
/// بدء التشغيل — يفتح مباشرة على قائمة الملفات. تسجيل الدخول مطلوب فقط
/// عند رفع البيانات إلى السيرفر (المزامنة).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();
  await SyncService.instance.init();
  runApp(const HaqqunaApp());
}

class HaqqunaApp extends StatelessWidget {
  const HaqqunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حقّنا — توثيق الناجين',
      debugShowCheckedModeBanner: false,
      theme: HaqqunaTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
