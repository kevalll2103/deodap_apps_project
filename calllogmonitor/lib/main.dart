import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calllogmonitor/main.dart' as mainFile;
// Screens
import 'excutive_login.dart';
import 'excutive_dashboard.dart';
import 'filtered_leads_screen.dart' hide AppTheme;
import 'splash_screen.dart';
import 'home_screen.dart';
import 'register.dart';
import 'permissions_screen.dart';
import 'user_details_screen.dart';
import 'call_history.dart';

// import 'executive_login.dart'; // File doesn't exist
import 'search_history.dart';
// Theme
import 'theme/app_theme.dart';
import 'package:calllogmonitor/settings_screen.dart' as settingsFile;
// Tutorial System
import 'services/tutorial_service.dart';
import 'tutorials/home_screen_tutorial.dart';
import 'tutorials/call_history_tutorial.dart';
import 'tutorials/registration_tutorial.dart';
import 'tutorials/permissions_tutorial.dart';

void main() async {
  try {
    // Ensure that plugin services are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize SharedPreferences early
    await SharedPreferences.getInstance();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(const MyApp());
  } catch (e) {
    // Handle initialization errors
    debugPrint('Initialization error: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _showWelcomeTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize SyncServiceManager when the app starts
    SyncServiceManager().initialize();
    // Check if we should show welcome tutorial
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final isFirstLaunch = await TutorialService.isFirstAppLaunch();
    if (isFirstLaunch && mounted) {
      setState(() {
        _showWelcomeTutorial = true;
      });
    }
  }

  void _onWelcomeTutorialCompleted() {
    setState(() {
      _showWelcomeTutorial = false;
    });
    TutorialService.markFirstAppLaunchCompleted();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose the SyncServiceManager when the app is disposed
    SyncServiceManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        // Notify sync service manager about app resume
        SyncServiceManager.onAppResumed();
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Call Log Monitor',
      theme: AppTheme.lightTheme,

      // Add error handling for route generation
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const SplashScreenWithSync(),
              settings: settings,
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomeScreenWithTutorial(),
              settings: settings,
            );
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterScreenWithTutorial(),
              settings: settings,
            );
          case '/permissions':
            return MaterialPageRoute(
              builder: (context) => const PermissionsScreenWithTutorial(),
              settings: settings,
            );
          case '/user_details':
            return MaterialPageRoute(
              builder: (context) => const UserDetailsScreen(),
              settings: settings,
            );
          case '/call_history':
            return MaterialPageRoute(
              builder: (context) => const CallHistoryScreenWithTutorial(),
              settings: settings,
            );
          case '/executive_login':
            return MaterialPageRoute(
              builder: (context) => ExecutiveLoginScreen(),
              settings: settings,
            );
          case '/executive_dashboard':
            return MaterialPageRoute(
              builder: (context) => ExecutiveDashboard(),
              settings: settings,
            );
          case '/filtered_leads':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (context) => FilteredLeadsScreen(
                  sourceId: args['sourceId'] ?? '',
                  sourceName: args['sourceName'] ?? '',
                  statusId: args['statusId'] ?? '',
                  statusName: args['statusName'] ?? '',
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (context) => const NotFoundScreen(),
              settings: settings,
            );

          default:
            return MaterialPageRoute(
              builder: (context) => const NotFoundScreen(),
              settings: settings,
            );
        }
      },

      // Fallback routes
      routes: {
        '/': (context) => const SplashScreenWithSync(),
        '/home': (context) => const HomeScreenWithTutorial(),
        '/register': (context) => const RegisterScreenWithTutorial(),
        '/permissions': (context) => const PermissionsScreenWithTutorial(),
        '/user_details': (context) => const UserDetailsScreen(),
        '/call_history': (context) => const CallHistoryScreenWithTutorial(),
        '/search_history': (context) => const CallLogsScreen(),
        '/executive_login': (context) => ExecutiveLoginScreen(),
        '/executive_dashboard': (context) => ExecutiveDashboard(),
      },

      initialRoute: '/',

      // Global error handling
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return CustomErrorWidget(errorDetails: errorDetails);
        };

        // Show welcome tutorial overlay if needed
        Widget appChild = child ?? const SizedBox.shrink();
        if (_showWelcomeTutorial) {
          appChild = Stack(
            children: [
              appChild,
              WelcomeTutorial(onCompleted: _onWelcomeTutorialCompleted),
            ],
          );
        }

        return appChild;
      },
    );
  }
}

// Enhanced Splash Screen with Sync Service
class SplashScreenWithSync extends StatelessWidget {
  const SplashScreenWithSync({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// Enhanced Home Screen with Tutorial
class HomeScreenWithTutorial extends StatelessWidget {
  const HomeScreenWithTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScreenTutorialWidget(
      child: const HomeScreen(),
    );
  }
}

// Register Screen with Tutorial
class RegisterScreenWithTutorial extends StatelessWidget {
  const RegisterScreenWithTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationTutorialWidget(
      child: RegisterScreen(),
    );
  }
}

// Permissions Screen with Tutorial
class PermissionsScreenWithTutorial extends StatelessWidget {
  const PermissionsScreenWithTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionsTutorialWidget(
      child: const PermissionsScreen(),
    );
  }
}

// Call History Screen with Tutorial
class CallHistoryScreenWithTutorial extends StatelessWidget {
  const CallHistoryScreenWithTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return CallHistoryTutorialWidget(
      child: const CallHistoryScreen(),
    );
  }
}

// Sync Service Manager as a Singleton
class SyncServiceManager {
  static final SyncServiceManager _instance = SyncServiceManager._internal();
  factory SyncServiceManager() => _instance;
  SyncServiceManager._internal();

  static const platform = MethodChannel('com.example.calllogmonitor/call_log_sync');

  bool _isSyncServiceRunning = false;
  bool _hasCallLogPermission = false;
  bool _hasBatteryOptimization = false;
  bool _hasNotificationPermission = false;
  String _statusMessage = 'Initializing...';
  Timer? _statusCheckTimer;

  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  static void onAppResumed() {
    _instance._checkPermissionsAndStatus();
  }

  bool get isSyncServiceRunning => _isSyncServiceRunning;
  bool get hasCallLogPermission => _hasCallLogPermission;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get hasBatteryOptimization => _hasBatteryOptimization;
  String get statusMessage => _statusMessage;

  Future<void> initialize() async {
    _setupMethodChannelCallbacks();
    await _checkPermissionsAndStatus();
    _startStatusTimer();

    // Auto-start service if all permissions are granted and device is configured
    if (_hasCallLogPermission && _hasNotificationPermission && await _isDeviceConfigured()) {
      await startSyncService();
    }
  }

  void _setupMethodChannelCallbacks() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPermissionResult':
          final bool granted = call.arguments as bool;
          if (granted) {
            await _checkPermissionsAndStatus();
          }
          break;

        case 'onBatteryOptimizationResult':
          final bool isIgnoring = call.arguments as bool;
          if (isIgnoring) {
            await _checkPermissionsAndStatus();
          }
          break;
      }
    });
  }

  void _startStatusTimer() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkServiceStatus();
    });
  }

  Future<void> _checkServiceStatus() async {
    try {
      final isRunning = await platform.invokeMethod('isSyncServiceRunning');
      _isSyncServiceRunning = isRunning ?? false;
      _updateStatus();
    } catch (e) {
      print('Error checking service status: $e');
    }
  }

  Future<void> _checkPermissionsAndStatus() async {
    try {
      final result = await platform.invokeMethod('checkPermissions');
      final permissions = Map<String, bool>.from(result);

      _hasCallLogPermission = permissions['hasCallLogPermission'] ?? false;
      _hasBatteryOptimization = permissions['hasBatteryOptimization'] ?? false;
      _hasNotificationPermission = permissions['hasNotificationPermission'] ?? false;

      _updateStatus();

    } catch (e) {
      print('Error checking permissions: $e');
      _statusMessage = 'Error checking permissions: $e';
      _updateStatus();
    }
  }

  void _updateStatus() {
    if (!_hasCallLogPermission) {
      _statusMessage = 'Waiting for call log permissions...';
      _isSyncServiceRunning = false;
    } else if (!_hasNotificationPermission) {
      _statusMessage = 'Waiting for notification permissions...';
      _isSyncServiceRunning = false;
    } else if (_isSyncServiceRunning) {
      _statusMessage = 'Auto-sync running - Checking every 10 minutes';
    } else {
      _statusMessage = 'Auto-sync stopped';
    }

    _statusController.add(SyncStatus(
      isRunning: _isSyncServiceRunning,
      hasCallLogPermission: _hasCallLogPermission,
      hasNotificationPermission: _hasNotificationPermission,
      hasBatteryOptimization: _hasBatteryOptimization,
      message: _statusMessage,
    ));
  }

  Future<void> requestPermissions() async {
    try {
      await platform.invokeMethod('requestPermissions');
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> requestBatteryOptimization() async {
    try {
      await platform.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (e) {
      print('Error requesting battery optimization: $e');
    }
  }

  Future<void> startSyncService() async {
    try {
      final result = await platform.invokeMethod('startSyncService');
      _isSyncServiceRunning = result ?? false;
      _updateStatus();

      if (_isSyncServiceRunning) {
        print('Sync service started successfully');
      } else {
        print('Failed to start sync service');
      }
    } catch (e) {
      print('Error starting sync service: $e');
      _statusMessage = 'Failed to start sync service: $e';
      _updateStatus();
    }
  }

  Future<void> stopSyncService() async {
    try {
      await platform.invokeMethod('stopSyncService');
      _isSyncServiceRunning = false;
      _updateStatus();
    } catch (e) {
      print('Error stopping sync service: $e');
    }
  }

  Future<bool> _isDeviceConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final warehouseId = prefs.getString('warehouse_id') ?? '';
      final deviceId = prefs.getInt('user_id') ?? 0;
      final mobileNumber = prefs.getString('mobile_number') ?? '';

      return warehouseId.isNotEmpty && deviceId != 0 && mobileNumber.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _statusCheckTimer?.cancel();
    _statusController.close();
  }
}

// Sync Status Data Class
class SyncStatus {
  final bool isRunning;
  final bool hasCallLogPermission;
  final bool hasNotificationPermission;
  final bool hasBatteryOptimization;
  final String message;

  SyncStatus({
    required this.isRunning,
    required this.hasCallLogPermission,
    required this.hasNotificationPermission,
    required this.hasBatteryOptimization,
    required this.message,
  });
}

// Sync Status Indicator Widget
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncServiceManager().statusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status.isRunning ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status.isRunning ? Icons.sync : Icons.sync_disabled,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                status.isRunning ? 'Sync ON' : 'Sync OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Sync Service Control Panel Widget
class SyncServiceControlPanel extends StatelessWidget {
  const SyncServiceControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncServiceManager().statusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final status = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync,
                    color: status.isRunning ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Auto-Sync Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                status.message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              _buildPermissionStatus('Call Log', status.hasCallLogPermission),
              _buildPermissionStatus('Notifications', status.hasNotificationPermission),
              _buildPermissionStatus('Battery Optimization', status.hasBatteryOptimization),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!status.hasCallLogPermission || !status.hasNotificationPermission)
                    ElevatedButton(
                      onPressed: () => SyncServiceManager().requestPermissions(),
                      child: const Text('Grant Permissions'),
                    ),
                  const SizedBox(width: 8),
                  if (!status.hasBatteryOptimization)
                    ElevatedButton(
                      onPressed: () => SyncServiceManager().requestBatteryOptimization(),
                      child: const Text('Battery Settings'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionStatus(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Error App for initialization failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the application',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('Exit App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 404 Screen for unknown routes
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.red.shade50,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The requested page could not be found',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                      (route) => false,
                );
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Error Widget for runtime errors
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.red.shade50,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${errorDetails.exception}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to navigate back to splash screen
                    try {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                            (route) => false,
                      );
                    } catch (e) {
                      SystemNavigator.pop();
                    }
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}