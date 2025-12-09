import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'screens/all_call.dart';
import 'screens/incoming_call.dart';
import 'screens/missed_call.dart' show MissedCallsScreen;
import 'screens/never_attend_call.dart';
import 'screens/outgoing_call.dart';
import 'screens/reject_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';
import 'call_history.dart';
import 'dart:io' show Platform;
import 'models/item.dart';
import 'service/service.dart';
import 'widgets/datefilter.dart';
import 'main.dart';
import 'settings_screen.dart';
import 'services/tutorial_service.dart';
import 'package:calllogmonitor/main.dart' as mainFile;
import 'package:calllogmonitor/settings_screen.dart' as settingsFile;

// Date Filter Enums
enum DateFilterType {
  today,
  yesterday,
  currentWeek,
  previousWeek,
  currentMonth,
  previousMonth,
  currentYear,
  custom
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // App version info
  static const String currentAppVersion = "1.0.3";

  // User data
  String _userName = 'Loading...';
  String _userMobile = 'Loading...';
  String _userId = 'Loading...';
  String _userWarehouse = 'Not assigned';
  String _deviceNumber = 'Loading...';
  bool _isRegistered = false;

  // Executive data
  bool _isExecutiveLoggedIn = false;
  String _executiveName = '';
  String _executiveUsername = '';
  String _executiveWarehouse = '';
  String _executiveWarehouseId = '';

  // Dashboard data
  List<Map<String, dynamic>> _dashboardData = [];
  bool _isLoadingDashboard = false;

  // Update checking state
  bool _isCheckingForUpdates = false;

  // Date filter
  DateFilterType _currentDateFilter = DateFilterType.today;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  // API Configuration
  static const String baseURL = 'https://trackship.in';

  // Connectivity and battery
  late final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  int _batteryLevel = 0;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
    _checkConnectivity();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _checkBatteryLevel();
        // Removed automatic update check - now only happens when user taps the icon
      }
    });
    _startAutoRefresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLoadOnScreenOpen();
    });
  }

  // Manual check for app updates (triggered by user action only)
  Future<void> _checkForUpdates() async {
    if (_isCheckingForUpdates) return; // Prevent multiple simultaneous checks

    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceNumber = prefs.getString('mobile_number') ?? _userMobile;
      final warehouse = prefs.getString('warehouse_label') ?? _userWarehouse;

      final response = await http.post(
        Uri.parse('$baseURL/api/lms/app.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'compare_version',
          'device_number': deviceNumber,
          'app_version': currentAppVersion,
          'warehouse': warehouse,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'ok') {
          // No update needed - show success message
          if (mounted) {
            _showNoUpdateAvailableDialog();
          }
        } else if (jsonData['errors'] != null &&
            jsonData['errors'].contains('New version available')) {
          // Show update dialog
          if (mounted) {
            _showUpdateDialog(
              jsonData['use_app_video'] ?? '',
              jsonData['contact_person_number'] ?? '',
              jsonData['download_url'] ?? '',
            );
          }
        } else {
          // Handle other error cases
          if (mounted) {
            _showUpdateCheckError('Unable to check for updates at this time.');
          }
        }
      } else {
        if (mounted) {
          _showUpdateCheckError('Network error. Please try again later.');
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
      if (mounted) {
        _showUpdateCheckError('Failed to check for updates. Please check your internet connection.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
      }
    }
  }

  // Show dialog when no update is available
  void _showNoUpdateAvailableDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Up to Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are using the latest version of the app.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Version $currentAppVersion is the current version.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error dialog when update check fails
  void _showUpdateCheckError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Update Check Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show update dialog (improved responsive design)
  void _showUpdateDialog(String videoUrl, String contactNumber, String downloadUrl) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenWidth < 400;
            final dialogWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.system_update,
                    color: Colors.orange[600],
                    size: isSmallScreen ? 24 : 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Update Available',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: screenHeight * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A new version of the app is available with improved features and bug fixes.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact button if available
                      if (contactNumber.isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _launchUrl('tel:$contactNumber'),
                            icon: const Icon(Icons.phone),
                            label: FittedBox(
                              child: Text('Contact Support: $contactNumber'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[600],
                              side: BorderSide(color: Colors.green[600]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Warning message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Please update to continue using all features.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Later button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Later',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Update button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (downloadUrl.isNotEmpty) {
                      _launchUrl(downloadUrl);
                    } else {
                      // Fallback to Play Store
                      _launchUrl('https://play.google.com/store/apps/details?id=com.deodap.callmonitor');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Launch URL helper
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $url'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _autoLoadOnScreenOpen() async {
    if (!mounted) return;

    print('=== DEBUG: Auto-loading data on screen open ===');
    await _loadUserData();
    await _loadDashboardData();
    await _checkConnectivity();
    await _checkBatteryLevel();
    print('=== DEBUG: Auto-load completed ===');
  }

  Future<void> _initializeScreen() async {
    await _loadUserData();
    if (mounted) {
      _initializeDateFilter();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadDashboardData();
        _checkConnectivity();
        _checkBatteryLevel();
      }
    });
  }

  void _initializeDateFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _fromDate = today;
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Guest';
        _userMobile = prefs.getString('mobile_number') ?? 'Not available';
        _userId = prefs.getInt('user_id')?.toString() ?? 'Not available';
        _userWarehouse = prefs.getString('warehouse_label') ?? 'Not assigned';
        _deviceNumber = _userMobile;
        _isRegistered = prefs.getBool('is_registered') ?? false;

        _isExecutiveLoggedIn = prefs.getBool('is_executive_logged_in') ?? false;
        _executiveName = prefs.getString('executive_name') ?? '';
        _executiveUsername = prefs.getString('executive_username') ?? '';
        _executiveWarehouse = prefs.getString('executive_warehouse_label') ?? '';
        _executiveWarehouseId = prefs.getString('executive_warehouse_id') ?? '';
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _refreshUserData() async {
    await _loadUserData();
    await _loadDashboardData();
    await _checkConnectivity();
    await _checkBatteryLevel();
  }

  Future<void> _loadDashboardData() async {
    if (_isLoadingDashboard) return;

    setState(() {
      _isLoadingDashboard = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceNumber = prefs.getString('mobile_number') ?? _userMobile;

      final fromDateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_fromDate);
      final toDateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_toDate);

      final response = await http.post(
        Uri.parse('$baseURL/api/lms/dashboard.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'summary',
          'device_number': deviceNumber,
          'from_date': fromDateStr,
          'to_date': toDateStr,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'ok' && jsonData['data'] != null) {
          setState(() {
            _dashboardData = List<Map<String, dynamic>>.from(jsonData['data']);
          });
        } else {
          print('API Error: ${jsonData['errors']}');
          setState(() {
            _dashboardData = [];
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        setState(() {
          _dashboardData = [];
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _dashboardData = [];
      });
    } finally {
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  void _onDateFilterChanged(DateTime fromDate, DateTime toDate, DateFilterType filterType) {
    setState(() {
      _fromDate = fromDate;
      _toDate = toDate;
      _currentDateFilter = filterType;
    });
    _loadDashboardData();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      setState(() {
        _connectivityResult = result;
      });
      _connectivitySubscription = _connectivity.onConnectivityChanged
          .listen((ConnectivityResult result) {
        setState(() {
          _connectivityResult = result;
        });
      });
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  Future<void> _checkBatteryLevel() async {
    try {
      if (_batterySubscription != null) {
        await _batterySubscription!.cancel();
        _batterySubscription = null;
      }

      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }

      if (mounted) {
        _batterySubscription = _battery.onBatteryStateChanged.listen((state) async {
          try {
            final lvl = await _battery.batteryLevel;
            if (mounted) {
              setState(() {
                _batteryLevel = lvl;
              });
            }
          } catch (e) {
            print('Error updating battery level: $e');
          }
        });
      }
    } catch (e) {
      print('Error checking battery level: $e');
      if (mounted) {
        setState(() {
          _batteryLevel = 0;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName != 'Loading...' && _userName != 'Guest'
        ? _userName
        : 'User';

    if (hour < 12) {
      return 'Good Morning, $name!';
    } else if (hour < 17) {
      return 'Good Afternoon, $name!';
    } else {
      return 'Good Evening, $name!';
    }
  }

  Widget _buildExecutiveDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      print('=== DEBUG: App resumed - auto-loading data ===');
      _autoLoadOnScreenOpen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();

    if (_batterySubscription != null) {
      _batterySubscription!.cancel();
      _batterySubscription = null;
    }

    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.primaryWarm,
      child: Column(
        children: [
          // Header Section - Deodap Logo
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.accentGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Container(
                  width: 220,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.warmDark.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/deodap_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              size: 30,
                              color: Colors.red,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Greeting Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warmLight.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.warmDark.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBrown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Executive Details Section
          if (_isExecutiveLoggedIn) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.warmDark.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Executive Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildExecutiveDetailRow(Icons.person, 'Name', _executiveName.isNotEmpty ? _executiveName : _executiveUsername),
                  _buildExecutiveDetailRow(Icons.warehouse, 'Warehouse', '$_executiveWarehouse (ID: $_executiveWarehouseId)'),
                  _buildExecutiveDetailRow(Icons.phone, 'Mobile', _executiveUsername),
                ],
              ),
            ),
          ],

          // Status Section - Network and Battery
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warmLight.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.warmDark.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Network Status
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _connectivityResult != ConnectivityResult.none
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _connectivityResult == ConnectivityResult.wifi
                              ? Icons.wifi
                              : _connectivityResult == ConnectivityResult.mobile
                              ? Icons.signal_cellular_4_bar
                              : Icons.signal_wifi_off,
                          size: 16,
                          color: _connectivityResult != ConnectivityResult.none
                              ? Colors.green[600]
                              : Colors.red[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _connectivityResult == ConnectivityResult.wifi
                                ? 'WiFi'
                                : _connectivityResult == ConnectivityResult.mobile
                                ? 'Mobile'
                                : 'Offline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _connectivityResult != ConnectivityResult.none
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Battery Status
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _batteryLevel > 20
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _batteryLevel > 80
                              ? Icons.battery_full
                              : _batteryLevel > 60
                              ? Icons.battery_5_bar
                              : _batteryLevel > 40
                              ? Icons.battery_3_bar
                              : _batteryLevel > 20
                              ? Icons.battery_2_bar
                              : Icons.battery_1_bar,
                          size: 16,
                          color: _batteryLevel > 20
                              ? Colors.green[600]
                              : Colors.red[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_batteryLevel%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _batteryLevel > 20
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warmLight.withOpacity(0.25),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.warmDark.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getUserProfileData(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {};
                final profileImagePath = data['profile_image_path'] as String?;
                final userName = data['user_name'] as String? ?? 'Guest';
                final selectedSim = data['selected_sim'] as String? ?? 'SIM 1';
                final isRegistered = data['is_registered'] as bool? ?? false;

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/user_details');
                  },
                  child: Row(
                    children: [
                      // Profile Image
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBrown.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profileImagePath != null
                              ? Image.file(
                            File(profileImagePath),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(userName, 50);
                            },
                          )
                              : _buildDefaultAvatar(userName, 50),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Status indicators
                            Wrap(
                              spacing: 6,
                              children: [
                                // SIM Indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: selectedSim == 'SIM 1'
                                        ? Colors.blue.withOpacity(0.8)
                                        : Colors.green.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sim_card, size: 10, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text(
                                        selectedSim,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Registration Status
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isRegistered
                                        ? Colors.green.withOpacity(0.8)
                                        : Colors.orange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isRegistered ? Icons.verified : Icons.pending,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        isRegistered ? 'Active' : 'Pending',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Executive LMS Navigation
          if (!_isExecutiveLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  title: Text(
                    'Executive LMS',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/executive_login');
                  },
                ),
              ),
            ),

          if (_isExecutiveLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Icon(
                    Icons.dashboard,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  title: Text(
                    'Executive Dashboard',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/executive_dashboard');
                  },
                ),
              ),
            ),

          // Menu Items Section
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.analytics,
                      title: 'Client Summary',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/search_history');
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'Call History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/call_history');
                      },
                    ),

                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 8,
                      endIndent: 8,
                      color: AppTheme.warmDark,
                    ),
                    const SizedBox(height: 8),

                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.refresh,
                      title: 'Refresh Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _refreshUserData();
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.system_update,
                      title: 'Check for Updates',
                      onTap: () {
                        Navigator.pop(context);
                        _checkForUpdates();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.warmDark.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Image.asset(
                    'assets/home_screen.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business,
                        size: 14,
                        color: AppTheme.textTertiary,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Powered by Deodap v$currentAppVersion',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get user profile data
  Future<Map<String, dynamic>> _getUserProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'profile_image_path': prefs.getString('profile_image_path'),
        'user_name': prefs.getString('user_name') ?? 'Guest',
        'selected_sim': prefs.getString('selected_sim') ?? 'SIM 1',
        'is_registered': prefs.getBool('is_registered') ?? false,
      };
    } catch (e) {
      print('Error loading user profile data: $e');
      return {};
    }
  }

  // Helper method to build default avatar
  Widget _buildDefaultAvatar(String userName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.accentBrown, AppTheme.primaryBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty && userName != 'Loading...' && userName != 'Guest'
              ? userName[0].toUpperCase()
              : 'U',
          style: TextStyle(
            fontSize: size * 0.4,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build drawer items with clean styling
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? AppTheme.warmLight.withOpacity(0.4)
            : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          color: AppTheme.primaryBrown,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: AppTheme.primaryBrown,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dense: true,
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryBrown.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range,
                color: AppTheme.primaryBrown,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filter by Date',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBrown,
                ),
              ),
              const Spacer(),
              if (_isLoadingDashboard)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DateFilterType>(
                    value: _currentDateFilter,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.primaryBrown,
                      size: 18,
                    ),
                    items: DateFilterType.values.map((DateFilterType filter) {
                      return DropdownMenuItem<DateFilterType>(
                        value: filter,
                        child: Text(_getFilterDisplayName(filter)),
                      );
                    }).toList(),
                    onChanged: (DateFilterType? newValue) {
                      if (newValue != null) {
                        if (newValue == DateFilterType.custom) {
                          _showCustomDatePicker();
                        } else {
                          _onDateFilterChanged(
                            _calculateDateRange(newValue)['from']!,
                            _calculateDateRange(newValue)['to']!,
                            newValue,
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getDateRangeText(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_currentDateFilter == DateFilterType.custom)
                  GestureDetector(
                    onTap: _showCustomDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName(DateFilterType filter) {
    switch (filter) {
      case DateFilterType.today:
        return 'Today';
      case DateFilterType.yesterday:
        return 'Yesterday';
      case DateFilterType.currentWeek:
        return 'Current Week';
      case DateFilterType.previousWeek:
        return 'Previous Week';
      case DateFilterType.currentMonth:
        return 'Current Month';
      case DateFilterType.previousMonth:
        return 'Previous Month';
      case DateFilterType.currentYear:
        return 'Current Year';
      case DateFilterType.custom:
        return 'Custom Range';
    }
  }

  Map<String, DateTime> _calculateDateRange(DateFilterType filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (filter) {
      case DateFilterType.today:
        return {
          'from': today,
          'to': endOfToday,
        };

      case DateFilterType.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'from': yesterday,
          'to': yesterday.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        };

      case DateFilterType.currentWeek:
        final weekday = now.weekday;
        final mondayOfWeek = today.subtract(Duration(days: weekday - 1));
        final sundayOfWeek = mondayOfWeek.add(const Duration(days: 6));
        return {
          'from': mondayOfWeek,
          'to': sundayOfWeek.isAfter(today) ? endOfToday : sundayOfWeek.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        };

      case DateFilterType.previousWeek:
        final weekday = now.weekday;
        final mondayOfThisWeek = today.subtract(Duration(days: weekday - 1));
        final mondayOfLastWeek = mondayOfThisWeek.subtract(const Duration(days: 7));
        final sundayOfLastWeek = mondayOfLastWeek.add(const Duration(days: 6));
        return {
          'from': mondayOfLastWeek,
          'to': sundayOfLastWeek.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        };

      case DateFilterType.currentMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        final lastOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        final toDate = lastOfMonth.isAfter(now) ? endOfToday : lastOfMonth;
        return {
          'from': firstOfMonth,
          'to': toDate,
        };

      case DateFilterType.previousMonth:
        final firstOfPrevMonth = DateTime(now.year, now.month - 1, 1);
        final lastOfPrevMonth = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return {
          'from': firstOfPrevMonth,
          'to': lastOfPrevMonth,
        };

      case DateFilterType.currentYear:
        final firstOfYear = DateTime(now.year, 1, 1);
        final lastOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        final toDate = lastOfYear.isAfter(now) ? endOfToday : lastOfYear;
        return {
          'from': firstOfYear,
          'to': toDate,
        };

      case DateFilterType.custom:
        return {
          'from': _fromDate,
          'to': _toDate,
        };
    }
  }

  Future<void> _showCustomDatePicker() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _fromDate,
        end: _toDate.isAfter(now) ? now : _toDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final fromDate = picked.start;
      final toDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );

      final validToDate = toDate.isAfter(now)
          ? DateTime(now.year, now.month, now.day, 23, 59, 59)
          : toDate;

      _onDateFilterChanged(fromDate, validToDate, DateFilterType.custom);
    }
  }

  String _getDateRangeText() {
    final formatter = DateFormat('dd MMM yyyy');

    if (_currentDateFilter == DateFilterType.today) {
      return 'Today: ${formatter.format(_fromDate)}';
    } else if (_currentDateFilter == DateFilterType.yesterday) {
      return 'Yesterday: ${formatter.format(_fromDate)}';
    } else {
      return '${formatter.format(_fromDate)} - ${formatter.format(_toDate)}';
    }
  }

  Widget _buildDashboard() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.warmGradient,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilter(),

              Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dashboardData.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Call Statistics',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.primaryBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDashboardGrid(),
                    ] else if (_isLoadingDashboard) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading dashboard data...'),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dashboard,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No data available for selected period',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting a different date range',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    final displayData = _dashboardData.take(6).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        final childAspectRatio = screenWidth > 400 ? 1.1 : 1.0;
        final spacing = screenWidth > 400 ? 10.0 : 8.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: displayData.length,
          itemBuilder: (context, index) {
            final item = displayData[index];
            return _buildDashboardCard(item, index);
          },
        );
      },
    );
  }

  Widget _buildDashboardCard(Map<String, dynamic> data, int index) {
    final callType = data['call_type'] ?? '';
    final title = data['call_type_title'] ?? 'Unknown';
    final totalCalls = data['total_calls'] ?? 0;
    final totalDuration = data['total_duration'] ?? '0m 0s';

    IconData icon;
    Color color;

    switch (callType.toLowerCase()) {
      case 'all':
        icon = Icons.call;
        color = AppTheme.primaryBrown;
        break;
      case 'missed':
        icon = Icons.call_received;
        color = Colors.red.shade600;
        break;
      case 'incoming':
        icon = Icons.call_received;
        color = Colors.green.shade600;
        break;
      case 'outgoing':
        icon = Icons.call_made;
        color = Colors.blue.shade600;
        break;
      case 'rejected':
        icon = Icons.call_end;
        color = Colors.orange.shade600;
        break;
      case 'never_attended':
        icon = Icons.phone_missed;
        color = Colors.purple.shade600;
        break;
      case 'not_pickup_by_client':
        icon = Icons.phone_disabled;
        color = Colors.grey.shade600;
        break;
      default:
        icon = Icons.phone;
        color = AppTheme.primaryBrown;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;

        final cardPadding = isSmallScreen ? 10.0 : 14.0;
        final iconSize = isSmallScreen ? 36.0 : 42.0;
        final iconInnerSize = isSmallScreen ? 20.0 : 24.0;
        final countFontSize = isSmallScreen ? 18.0 : 22.0;
        final titleFontSize = isSmallScreen ? 11.0 : 12.0;
        final durationFontSize = isSmallScreen ? 9.0 : 10.0;

        return GestureDetector(
          onTap: () => _navigateToCallTypeScreen(context, callType, title),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    size: iconInnerSize,
                    color: color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                FittedBox(
                  child: Text(
                    totalCalls.toString(),
                    style: TextStyle(
                      fontSize: countFontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalDuration,
                  style: TextStyle(
                    fontSize: durationFontSize,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToCallTypeScreen(BuildContext context, String callType, String title) {
    switch (callType.toLowerCase()) {
      case 'all':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      case 'missed':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissedCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      case 'incoming':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomingCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      case 'outgoing':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutgoingCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      case 'rejected':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RejectedCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      case 'never_attended':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeverAttendedCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      case 'not_pickup_by_client':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeverAttendedCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllCallsScreen(deviceNumber: _deviceNumber),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deodap Call Monitor',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          // Sync status indicator
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: mainFile.SyncStatusIndicator(),
          ),

          // Update check button with loading state
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.system_update,
                  color: _isCheckingForUpdates ? Colors.grey : null,
                ),
                tooltip: _isCheckingForUpdates ? 'Checking for updates...' : 'Check for Updates',
                onPressed: _isCheckingForUpdates ? null : _checkForUpdates,
              ),
              if (_isCheckingForUpdates)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
                    Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isSmallScreen = screenWidth < 400;

                  return Row(
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: AppTheme.primaryBrown,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBrown,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            Text(
                              'Track your call activities and performance',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryBrown.withOpacity(0.8),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Version display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBrown.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'v$currentAppVersion',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBrown,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildDashboard(),
          ],
        ),
      ),
    );
  }
}