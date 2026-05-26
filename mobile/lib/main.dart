/// نقطة دخول تطبيق جمعية حقّنا
///
/// التطبيق offline-first:
/// 1. عند البدء، يقرأ إعدادات السيرفر من SharedPreferences
/// 2. إذا لم يُسجَّل دخول، يفتح ServerConfig ثم Login
/// 3. إذا سُجّل، يفتح HomeScreen مباشرة
/// 4. كل البيانات تُخزَّن محلياً في SQLite
/// 5. المزامنة تتم تلقائياً عند توفر الاتصال
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة قاعدة البيانات المحلية والإعدادات
  await DatabaseService.instance.init();
  await AuthService.instance.init();
  runApp(const HaqqunaApp());
}

class HaqqunaApp extends StatelessWidget {
  const HaqqunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جمعية حقّنا',
      debugShowCheckedModeBanner: false,
      theme: HaqqunaTheme.light(),
      darkTheme: HaqqunaTheme.dark(),
      locale: const Locale('ar', 'SY'),
      supportedLocales: const [
        Locale('ar', 'SY'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // فرض RTL لكل التطبيق
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
