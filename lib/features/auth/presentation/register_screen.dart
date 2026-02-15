import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: authState.isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Create an Account'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Google Sign In handles both login and registration
                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle();
                    },
                    child: const Text('Sign up with Google'),
                  ),
                ],
              ),
      ),
    );
  }
}
