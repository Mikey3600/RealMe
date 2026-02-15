import 'package:flutter/material.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simulate initial loading (e.g., checking auth state, initializing services)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate to Auth Gate (handles Login vs Home)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Brand Icon can go here if you have one.
            // For now, text based logo.
            Text(
              'RealMe',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connect Humanly',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
