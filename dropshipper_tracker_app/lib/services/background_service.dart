import 'package:workmanager/workmanager.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();

  factory BackgroundService() => _instance;

  BackgroundService._internal();

  Future<void> initialize() async {
    // Any initialization code can go here
    // For now, we'll just print that the service is initialized
    print('BackgroundService initialized');
  }

  Future<void> registerBackgroundTask() async {
    // Register for periodic background tasks (every 15 minutes)
    await Workmanager().registerPeriodicTask(
      'plan_update_check',
      'planUpdateCheck',
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }
}
