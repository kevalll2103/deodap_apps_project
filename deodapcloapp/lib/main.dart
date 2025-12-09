import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DEODAP WAREHOUSE TRACKING APP',
      home: PermissionHandler(),
    );
  }
}

class PermissionHandler extends StatefulWidget {
  const PermissionHandler({super.key});

  @override
  State<PermissionHandler> createState() => _PermissionHandlerState();
}

class _PermissionHandlerState extends State<PermissionHandler> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Request all permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.location,
      Permission.notification,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      // Navigate to splash screen
      Get.off(() => Splashscreen());
    } else {
      // Check if any permission is permanently denied
      bool anyPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

      if (anyPermanentlyDenied) {
        _showSettingsDialog();
      } else {
        // Ask again or navigate anyway
        Get.off(() => Splashscreen());
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permissions Denied'),
          content: Text('Please enable permissions from app settings to use this app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.off(() => Splashscreen());
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}