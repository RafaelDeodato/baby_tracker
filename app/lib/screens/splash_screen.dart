import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'auth/login_screen.dart';
import 'babies/babies_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await StorageService.getAccessToken();

    if (token == null) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      final result = await ApiService.getMe();
      if (result['status'] == 200) {
        _goTo(const BabiesScreen());
      } else {
        _goTo(const LoginScreen());
      }
    } catch (e) {
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Baby Tracker 🍼',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}
