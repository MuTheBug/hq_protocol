import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../theme.dart';
import 'home_screen.dart';

/// شاشة الترحيب - تنتقل مباشرة للداشبورد دون فحص تسجيل دخول.
/// المتطوّع يبدأ بإدخال البيانات فوراً؛ التسجيل لاحقاً عند الحاجة للمزامنة.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaqqunaColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.shield,
                  color: HaqqunaColors.primary, size: 80),
            ),
            const SizedBox(height: 20),
            const Text('جمعية حقّنا',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('نظام توثيق الناجين',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
