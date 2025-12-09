import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Screens
import 'splash.dart';

// Services
import 'services/background_service.dart';
import 'services/notification_service.dart';

// Constants
const String keyLogin = 'isLoggedIn';
const String keyOnboardingDone = 'isOnboardingDone';

/// WorkManager callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'planUpdateCheck':
          final notificationService = NotificationService();
          await notificationService.initialize();
          await notificationService.checkForUpdates();
          return Future.value(true);
        default:
          debugPrint("Unknown task: $task");
          return Future.value(false);
      }
    } catch (e) {
      debugPrint("Error in background task '$task': $e");
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  debugPrint("Login status: ${prefs.getBool(keyLogin)}");
  debugPrint("Onboarding done: ${prefs.getBool(keyOnboardingDone)}");

  // Init Notification Service (includes permission request)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Init WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // set false in release
  );

  // Register background service
  final backgroundService = BackgroundService();
  await backgroundService.initialize();
  await backgroundService.registerBackgroundTask();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dropshipper Tracker+',
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashscreenView(), // 👈 Splashscreen handles navigation
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
