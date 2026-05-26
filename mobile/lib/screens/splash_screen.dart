import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'server_config_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), _route);
  }

  Future<void> _route() async {
    if (!mounted) return;
    if (ApiConfig.baseUrl == ApiConfig.defaultUrl) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
      );
      return;
    }
    if (AuthService.instance.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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
              child: const Icon(
                Icons.shield,
                color: HaqqunaColors.primary,
                size: 80,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'جمعية حقّنا',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نظام توثيق الناجين',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
