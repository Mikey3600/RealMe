import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import 'login_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../../core/theme/app_colors.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUserProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
