import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    await Future.delayed(const Duration(seconds: 2));

    final registered = await StorageService.isRegistered();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            registered ? const HomeScreen() : const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "SafeSpot",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Your Safety Matters",
              style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}