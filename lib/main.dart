import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'services/hive_service.dart';

// Top-level defined in notification_service.dart, but we need to register it here.
// Actually, it's safer to register it inside the service init or main if we import the service.
// The service file already has the @pragma entry point.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.setupInteractedMessage();

  final hiveService = HiveService();
  await hiveService.init();

  runApp(const ProviderScope(child: RealMeApp()));
}

class RealMeApp extends StatelessWidget {
  const RealMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RealMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
