import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../dropshipper_plan.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _lastUpdateKey = 'last_plan_update';
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _initializeTimeZone();
    await _initializeNotifications();
    _isInitialized = true;
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('Notification payload: ${response.payload}');
        }
      },
    );
  }

  Future<void> showNotification({required String title, required String body}) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'plan_updates_channel',
      'Plan Updates',
      channelDescription: 'Notifications for plan updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
      payload: 'plan_update',
    );
  }

  Future<void> checkForUpdates() async {
    try {
      if (!_isInitialized) await initialize();
      
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      
      // Here you would typically fetch the latest plan data
      // For example:
      // final response = await http.get(Uri.parse('YOUR_API_ENDPOINT'));
      // final data = jsonDecode(response.body);
      // final planDetails = PlanDetails.fromJson(data);
      
      // For demonstration, we'll just check if there are any new updates
      final hasUpdates = true; // Replace with your actual update check logic
      
      if (hasUpdates) {
        await showNotification(
          title: 'Plan Updated',
          body: 'There are new updates to your dropshipping plan',
        );
        
        // Update last check time
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  Future<void> scheduleDailyUpdateCheck() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'daily_update_channel',
      'Daily Updates',
      channelDescription: 'Daily plan update checks',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.periodicallyShow(
      0, // Notification ID
      'Daily Plan Update',
      'Checking for updates to your dropshipping plan...',
      RepeatInterval.daily,
      const NotificationDetails(android: androidNotificationDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
