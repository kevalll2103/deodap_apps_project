import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deodap Stock Bridge',
      home: const PermissionHandlerScreen(),
    );
  }
}

class PermissionHandlerScreen extends StatefulWidget {
  const PermissionHandlerScreen({super.key});

  @override
  State<PermissionHandlerScreen> createState() => _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Request all required permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone, // Audio permission
      Permission.storage,
      Permission.photos, // For gallery access (iOS specific)
      Permission.location, // General location permission
      Permission.locationWhenInUse, // Location only when app is in use
      Permission.locationAlways, // Location even when app is in background
      Permission.notification,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      // Navigate to splash screen if all permissions granted
      Get.off(() => const Splashscreen());
    } else {
      // Check if any permission is permanently denied
      bool anyPermanentlyDenied =
      statuses.values.any((status) => status.isPermanentlyDenied);

      if (anyPermanentlyDenied) {
        _showSettingsDialog();
      } else {
        // Still navigate to splash (optional)
        Get.off(() => const Splashscreen());
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Denied'),
          content: const Text(
              'Please enable all required permissions from app settings to continue using the app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.off(() => const Splashscreen());
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
