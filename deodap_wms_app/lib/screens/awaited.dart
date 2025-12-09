// lib/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'threshold.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:local_auth/local_auth.dart'; // Commented out - add to pubspec.yaml if needed
import 'all_product.dart';
import 'low_stock.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'qr_inward.dart';
import 'setting_screen.dart';
// ===== iOS Purple Theme =====
const Color kIOSPurple = Color(0xFF6B52A3);
const Color kIOSPurpleLight = Color(0xFF9F7AEA);
const Color kIOSPurpleDark = Color(0xFF6B52A3);
const Color kBg = Color(0xFFF7F8FA);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _tabIndex = 0;

  String _username = '';
  String _warehouse = '';
  String _warehouseLabel = '';
  String _authToken = '';
  String _userEmail = '';
  String _userPhone = '';
  String _profileImagePath = '';
  String _employeeCode = ''; // NEW

  // App Lock Variables
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  String _storedPin = '';
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _isPinDialogShowing = false;
  int _failedAttempts = 0;
  DateTime? _backgroundTime;
  Timer? _lockTimer;
  bool _isInitialized = false; // Track initialization to prevent multiple startup calls
  bool _hasShownStartupPin = false; // Track if PIN has been shown on app startup
  // final LocalAuthentication _localAuth = LocalAuthentication(); // Commented out - add to pubspec.yaml if needed

  static const String baseUrl = 'https://api.vacalvers.com/api-wms-app';
  static const String appId = '1';
  static const String apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  late final Battery _battery;
  late final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _clockTimer;

  String _now = '';
  String _networkLabel = 'Checking…';
  IconData _networkIcon = CupertinoIcons.wifi_exclamationmark;

  int _batteryLevel = -1;
  BatteryState _batteryState = BatteryState.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadAppLockSettings().then((_) {
      // Mark as initialized and show PIN dialog on app startup if PIN is enabled
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (_appLockEnabled && _storedPin.isNotEmpty && !_isPinDialogShowing && !_hasShownStartupPin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPinDialogImmediate(isStartup: true);
          });
        }
      }
    });
    _setupRealtimeBits();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _backgroundTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
      // Only check lock screen if app is fully initialized
        if (_isInitialized) {
          _doRefresh(skipPinCheck: true); // Skip PIN check on resume from navigation
          _checkAndShowLockScreen();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('userName') ?? prefs.getString('currentUser') ?? 'User';
      _warehouse = prefs.getString('currentWarehouse') ?? '';
      _authToken = prefs.getString('authToken') ?? '';
      _userEmail = prefs.getString('userEmail') ?? '';
      _userPhone = prefs.getString('userPhone') ?? '';
      _profileImagePath = prefs.getString('profileImagePath') ?? '';
      _employeeCode = prefs.getString('employeeCode') ?? ''; // NEW
    });

    if (_warehouse.isNotEmpty) {
      await _fetchWarehouseLabel();
    }
  }

  Future<void> _fetchWarehouseLabel() async {
    try {
      final url = Uri.parse('$baseUrl/app_info/warehouse_list');
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'app_id': appId, 'api_key': apiKey}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status_flag'] == 1 && responseData['data'] != null) {
          final warehouses = List<Map<String, dynamic>>.from(responseData['data']);
          final currentWarehouse = warehouses.firstWhere(
                (w) => w['id'].toString() == _warehouse,
            orElse: () => {},
          );
          if (currentWarehouse.isNotEmpty && mounted) {
            setState(() {
              _warehouseLabel = currentWarehouse['label'] ?? 'Warehouse $_warehouse';
            });
          }
        }
      }
    } catch (e) {
      // Error fetching warehouse label: $e
    }
  }

  void _setupRealtimeBits() {
    _battery = Battery();
    _connectivity = Connectivity();

    _tickClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());

    _readBatteryLevel();
    _batteryStateSub = _battery.onBatteryStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _batteryState = s);
      _readBatteryLevel();
    });

    _refreshConnectivity();
    _connSub = _connectivity.onConnectivityChanged.listen(_applyConnectivity);
  }

  void _tickClock() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    if (!mounted) return;
    setState(() {
      _now = '${two(now.hour)}:${two(now.minute)}:${two(now.second)} • ${two(now.day)}-${two(now.month)}-${now.year}';
    });
  }

  Future<void> _readBatteryLevel() async {
    try {
      final lvl = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = lvl);
    } catch (_) {}
  }

  Future<void> _refreshConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _applyConnectivity(results);
    } catch (_) {}
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    final r = results.isNotEmpty ? results.first : ConnectivityResult.none;
    String label;
    IconData icon;

    switch (r) {
      case ConnectivityResult.wifi:
        label = 'Wi-Fi';
        icon = CupertinoIcons.wifi;
        break;
      case ConnectivityResult.mobile:
        label = 'Mobile';
        icon = CupertinoIcons.dot_radiowaves_left_right;
        break;
      case ConnectivityResult.ethernet:
        label = 'Ethernet';
        icon = CupertinoIcons.antenna_radiowaves_left_right;
        break;
      case ConnectivityResult.vpn:
        label = 'VPN';
        icon = CupertinoIcons.lock_shield;
        break;
      case ConnectivityResult.bluetooth:
        label = 'Bluetooth';
        icon = CupertinoIcons.bluetooth;
        break;
      case ConnectivityResult.other:
        label = 'Connected';
        icon = CupertinoIcons.arrow_right_arrow_left;
        break;
      case ConnectivityResult.none:
      default:
        label = 'Offline';
        icon = CupertinoIcons.wifi_exclamationmark;
    }

    if (mounted) {
      setState(() {
        _networkLabel = label;
        _networkIcon = icon;
      });
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _connSub?.cancel();
    _batteryStateSub?.cancel();
    _lockTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _pushCupertino(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => page));
    if (mounted) _doRefresh(skipPinCheck: true); // Skip PIN check when returning from navigation
  }

  Future<void> _replaceWithCupertino(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => page),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('sign out?'),
        content: const Text('Are you sure you want to Sign Out from DeoDap WMS App?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('sign out '),
          ),
        ],
      ),
    );

    if (yes == true) {
      await prefs.clear();
      if (mounted) {
        await _replaceWithCupertino(const OnboardingScreen());
      }
    }
  }

  void _goAllProducts() => _pushCupertino(const ProductsScreen());
  void _goThreshold() => _pushCupertino(const thresholdScreen());
  void _goLowstock() => _pushCupertino(const LowStockAlertsScreen());
  void _goScanner() => _pushCupertino(ClubOrderScanScreen(
    warehouseId: _warehouse.isNotEmpty ? int.parse(_warehouse) : 0,
    warehouseLabel: _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse',
  ));
  void _goSettings() async {
    await _pushCupertino(const setting());
    // Only check for PIN when returning from settings if settings were changed
    // This prevents showing PIN dialog just for navigating back
    // await _loadAppLockSettings(); // Commented out to prevent unnecessary PIN trigger
  }
  void _goNotifications() => _pushCupertino(const LowStockAlertsScreen());

  Future<void> _showUserPopup() async {
    final name = _username;
    final email = _userEmail.isEmpty ? 'Not provided' : _userEmail;
    final phone = _userPhone.isEmpty ? 'Not provided' : _userPhone;
    final wh = _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse';
    final hasPhoto = _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    final isCharging = _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
    final IconData batteryIcon = isCharging ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25;

    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(CupertinoIcons.person_crop_circle, size: 20, color: kIOSPurple),
            SizedBox(width: 6),
            Text('User Details'),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 32,
              backgroundColor: kIOSPurple.withOpacity(0.15),
              backgroundImage: hasPhoto ? FileImage(File(_profileImagePath)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kIOSPurple),
              ),
            ),
            const SizedBox(height: 12),

            // Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.hand_raised_fill, color: Color(0xFFFF8A00), size: 16),
                const SizedBox(width: 6),
                Text(_getGreeting(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kIOSPurple)),
              ],
            ),
            const SizedBox(height: 10),

            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(wh, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(phone, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            if (_userEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            if (_employeeCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Employee Code: $_employeeCode', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Network Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_networkIcon, color: kIOSPurple, size: 18),
                const SizedBox(width: 6),
                Text(_networkLabel, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),

            // Battery Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(batteryIcon, color: kIOSPurple, size: 18),
                const SizedBox(width: 6),
                Text(_batteryLevel < 0 ? '—' : '$_batteryLevel%', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),

            // Time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.time_solid, color: kIOSPurple, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _now.isEmpty ? '—' : _now,
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAppLockSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appLockEnabled = prefs.getBool('appLockEnabled') ?? false;
      final storedPin = prefs.getString('appPin') ?? '';
      final biometricEnabled = prefs.getBool('biometricEnabled') ?? false;



      if (mounted) {
        setState(() {
          _appLockEnabled = appLockEnabled;
          _storedPin = storedPin;
          _biometricEnabled = biometricEnabled;
        });

      }
    } catch (_) {
      // Error loading app lock settings
      // Handle error silently
    }
  }

  void _checkAndShowLockScreen() {
    // Comprehensive check to prevent multiple dialogs
    if (!_isInitialized || !_appLockEnabled || _storedPin.isEmpty || _isPinDialogShowing) {
      return;
    }

    // Only show lock if app was in background for more than 2 seconds
    if (_backgroundTime != null) {
      final timeInBackground = DateTime.now().difference(_backgroundTime!);
      if (timeInBackground.inSeconds < 1) {

        return;
      }
    }

    // Cancel any existing timer to prevent multiple calls
    _lockTimer?.cancel();

    // Show lock after a small delay to allow UI to settle
    _lockTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isInitialized && !_isPinDialogShowing && _appLockEnabled && _storedPin.isNotEmpty) {
        _showLockScreen();
      }
    });
  }

  Future<void> _showPinDialogImmediate({bool isStartup = false}) async {
    // Comprehensive early return check to prevent multiple dialogs
    if (!mounted || !_isInitialized || _isPinDialogShowing || !_appLockEnabled || _storedPin.isEmpty) {
      return;
    }

    // Additional check for startup - only show once per app session
    if (isStartup && _hasShownStartupPin) {
      return;
    }

    // Set state immediately to prevent multiple calls
    setState(() {
      _isPinDialogShowing = true;
      _failedAttempts = 0;
      _errorText = null;
      _pinController.clear();
      if (isStartup) {
        _hasShownStartupPin = true;
      }
    });



    // Try biometric first if enabled
    if (_biometricEnabled) {

      final authenticated = await _authenticateWithBiometrics();
      if (authenticated) {
        setState(() {
          _isPinDialogShowing = false;
        });

        return;
      }
    }

    // Show PIN dialog immediately if still needed
    if (mounted && _isPinDialogShowing) {
      _showPinDialog();
    }
  }



  Future<void> _showLockScreen() async {
    if (_isPinDialogShowing) return;

    setState(() {
      _isPinDialogShowing = true;
      _failedAttempts = 0;
      _errorText = null;
      _pinController.clear();
    });

    // Try biometric first if enabled
    if (_biometricEnabled) {
      final authenticated = await _authenticateWithBiometrics();
      if (authenticated) {
        setState(() {
          _isPinDialogShowing = false;
        });
        return;
      }
    }

    // Show PIN dialog
    _showPinDialog();
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // TODO: Uncomment when local_auth is added to pubspec.yaml
      // final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      // final bool canAuthenticate =
      //     canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      // if (!canAuthenticate) return false;

      // final bool didAuthenticate = await _localAuth.authenticate(
      //   localizedReason: 'Authenticate to access the app',
      //   options: const AuthenticationOptions(
      //     biometricOnly: true,
      //     stickyAuth: true,
      //   ),
      // );

      // return didAuthenticate;

      // For now, return false to show PIN dialog
      return false;
    } catch (e) {

      return false;
    }
  }

  Future<void> _verifyPin() async {
    final enteredPin = _pinController.text.trim();

    if (enteredPin.isEmpty) {
      setState(() {
        _errorText = 'Please enter PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (enteredPin == _storedPin) {
      // Reset failed attempts on successful authentication
      setState(() {
        _failedAttempts = 0;
        _isPinDialogShowing = false;
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog only
      }
    } else {
      setState(() {
        _failedAttempts++;
        _isLoading = false;
        _pinController.clear();
      });

      // Haptic feedback for wrong PIN
      HapticFeedback.heavyImpact();

      if (_failedAttempts >= 3) {
        setState(() {
          _errorText = 'Too many failed attempts. Try again later.';
        });

        // Disable input for 30 seconds after 3 failed attempts
        await Future.delayed(const Duration(seconds: 30));
        if (mounted) {
          setState(() {
            _failedAttempts = 0;
            _errorText = null;
          });
        }
      } else {
        setState(() {
          _errorText = 'Incorrect PIN. ${3 - _failedAttempts} attempts remaining.';
        });

        // Clear error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorText = null;
            });
          }
        });
      }
    }
  }

  // void _showPinDialog() {
  //   if (!mounted || !_isPinDialogShowing) return;
  //
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (ctx) => WillPopScope(
  //       onWillPop: () async => false, // Prevent back button
  //       child: CupertinoTheme(
  //         data: CupertinoTheme.of(context).copyWith(primaryColor: kIOSPurple),
  //         child: Dialog(
  //           backgroundColor: Colors.transparent,
  //           child: Container(
  //             width: MediaQuery.of(context).size.width * 0.85,
  //             constraints: BoxConstraints(
  //               minHeight: 320, // Increased minimum height
  //               maxHeight: 400, // Added maximum height constraint
  //             ),
  //             decoration: BoxDecoration(
  //               color: CupertinoColors.systemBackground.resolveFrom(context),
  //               borderRadius: BorderRadius.circular(16),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 20,
  //                   offset: const Offset(0, 10),
  //                 ),
  //               ],
  //             ),
  //             child: StatefulBuilder(
  //               builder: (context, dialogSetState) => Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   // Header with padding
  //                   Padding(
  //                     padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         const Icon(CupertinoIcons.lock_shield, size: 20, color: kIOSPurple),
  //                         const SizedBox(width: 8),
  //                         const Text(
  //                           'App Locked',
  //                           style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //
  //                   // Content with flexible height
  //                   Expanded(
  //                     child: Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 20),
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           const SizedBox(height: 8),
  //                           const Text(
  //                             'Enter your PIN to unlock the app',
  //                             style: TextStyle(fontSize: 14),
  //                             textAlign: TextAlign.center,
  //                           ),
  //
  //                           if (_biometricEnabled) ...[
  //                             const SizedBox(height: 20),
  //                             CupertinoButton(
  //                               onPressed: () async {
  //                                 final authenticated = await _authenticateWithBiometrics();
  //                                 if (authenticated && mounted) {
  //                                   setState(() {
  //                                     _isPinDialogShowing = false;
  //                                   });
  //                                   Navigator.of(context).pop();
  //                                 }
  //                               },
  //                               child: const Row(
  //                                 mainAxisSize: MainAxisSize.min,
  //                                 children: [
  //                                   Icon(CupertinoIcons.person_2_fill, size: 16),
  //                                   SizedBox(width: 6),
  //                                   Text('Use Biometrics'),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //
  //                           const SizedBox(height: 24),
  //
  //                           if (_errorText != null)
  //                             Padding(
  //                               padding: const EdgeInsets.only(bottom: 12),
  //                               child: Text(
  //                                 _errorText!,
  //                                 style: const TextStyle(
  //                                   color: CupertinoColors.systemRed,
  //                                   fontSize: 12,
  //                                 ),
  //                                 textAlign: TextAlign.center,
  //                               ),
  //                             ),
  //
  //                           CupertinoTextField(
  //                             controller: _pinController,
  //                             placeholder: 'Enter 4-digit PIN',
  //                             keyboardType: TextInputType.number,
  //                             maxLength: 4,
  //                             obscureText: true,
  //                             textAlign: TextAlign.center,
  //                             style: const TextStyle(
  //                               fontSize: 20,
  //                               letterSpacing: 8,
  //                             ),
  //                             onSubmitted: (_) => _verifyPin(),
  //                             enabled: !_isLoading || _failedAttempts >= 3,
  //                           ),
  //
  //                           const SizedBox(height: 16),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //
  //                   // Actions section
  //                   Padding(
  //                     padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
  //                     child: Column(
  //                       children: [
  //                         if (_failedAttempts < 3)
  //                           CupertinoButton(
  //                             onPressed: () {
  //                               Navigator.pop(ctx);
  //                               _showForgotPinDialog();
  //                             },
  //                             child: const Text('Forgot PIN?'),
  //                           ),
  //                         SizedBox(
  //                           width: double.infinity,
  //                           child: CupertinoButton(
  //                             onPressed: (_isLoading || _failedAttempts >= 3) ? null : () => _verifyPin(),
  //                             color: kIOSPurple,
  //                             disabledColor: CupertinoColors.systemGrey,
  //                             borderRadius: BorderRadius.circular(8),
  //                             child: _isLoading
  //                                 ? const CupertinoActivityIndicator(color: CupertinoColors.white)
  //                                 : Text(_failedAttempts >= 3 ? 'Try Again Later' : 'Unlock'),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   ).then((_) {
  //     // Reset state when dialog is closed
  //     if (mounted) {
  //       setState(() {
  //         _isPinDialogShowing = false;
  //       });
  //     }
  //   });
  // }


  void _showPinDialog() {
    if (!mounted || !_isPinDialogShowing) return;

    // Haptic feedback when dialog appears
    HapticFeedback.lightImpact();

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: CupertinoAlertDialog(
            title: Column(
              children: [
                const Icon(
                  CupertinoIcons.lock_shield_fill,
                  size: 36,
                  color: kIOSPurple,
                ),
                const SizedBox(height: 12),
                const Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your PIN to continue',
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: StatefulBuilder(
              builder: (context, dialogSetState) => Column(
                children: [
                  const SizedBox(height: 8),

                  // Error message with animation
                  if (_errorText != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.exclamationmark_circle_fill,
                                color: CupertinoColors.systemRed,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // PIN Input Field
                  Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoTextField(
                      controller: _pinController,
                      placeholder: '••••',
                      placeholderStyle: TextStyle(
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                        fontSize: 24,
                        letterSpacing: 12,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      decoration: null,
                      onChanged: (value) {
                        if (value.length == 4) {
                          _verifyPin();
                        }
                      },
                      onSubmitted: (_) => _verifyPin(),
                      enabled: !_isLoading && _failedAttempts < 3,
                      cursorColor: kIOSPurple,
                      cursorHeight: 24,
                      cursorWidth: 2,
                      cursorRadius: const Radius.circular(1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Biometric Authentication Button (if enabled)
                  if (_biometricEnabled) ...[
                    AnimatedOpacity(
                      opacity: _failedAttempts < 3 ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: CupertinoButton(
                        onPressed: _failedAttempts >= 3
                            ? null
                            : () async {
                          HapticFeedback.mediumImpact();
                          final authenticated = await _authenticateWithBiometrics();
                          if (authenticated && mounted) {
                            setState(() {
                              _isPinDialogShowing = false;
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        borderRadius: BorderRadius.circular(10),
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        disabledColor: CupertinoColors.tertiarySystemFill.resolveFrom(context).withOpacity(0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Platform.isIOS ? CupertinoIcons.person_2_fill : CupertinoIcons.person_2_fill,
                              size: 20,
                              color: _failedAttempts >= 3
                                  ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                                  : kIOSPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Platform.isIOS ? 'Use Face ID' : 'Use Fingerprint',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _failedAttempts >= 3
                                    ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                                    : kIOSPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Forgot PIN option
                  CupertinoButton(
                    onPressed: _failedAttempts >= 3
                        ? null
                        : () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _showForgotPinDialog();
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minSize: 0,
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _failedAttempts >= 3
                            ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                            : kIOSPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[],
          ),
        ),
      ),
    );
  }
  void _showForgotPinDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(primaryColor: kIOSPurple),
        child: CupertinoAlertDialog(
          title: const Text('Forgot PIN?'),
          content: const Text(
            'You will need to sign out and sign back in to reset your app lock settings.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.pop(ctx);
                // Clear app lock settings and navigate to onboarding
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('appLockEnabled', false);
                await prefs.setString('appLockType', 'none');
                await prefs.setString('appPin', '');

                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    CupertinoPageRoute(builder: (_) => const OnboardingScreen()),
                        (route) => false,
                  );
                }
              },
              isDestructiveAction: true,
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doRefresh({bool skipPinCheck = false}) async {
    HapticFeedback.lightImpact();
    await _readBatteryLevel();
    await _refreshConnectivity();
    await _loadUserData();

    // Only reload app lock settings if not skipping PIN check
    if (!skipPinCheck) {
      await _loadAppLockSettings();
    }

    // Don't automatically show PIN dialog on refresh - let lifecycle handle it
    // This prevents multiple dialog calls

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    // Don't check for PIN dialog in build - let lifecycle events handle it
    // This prevents multiple dialog calls during rebuilds

    if (_tabIndex == 1) {
      return Scaffold(
        backgroundColor: kBg,
        body: ClubOrderScanScreen(
          warehouseId: _warehouse.isNotEmpty ? int.parse(_warehouse) : 0,
          warehouseLabel: _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse',
        ),
        bottomNavigationBar: _buildCupertinoTabBar(),
      );
    }
    if (_tabIndex == 2) {
      return Scaffold(
        backgroundColor: kBg,
        body: const ProfileScreen(showAppBar: false),
        bottomNavigationBar: _buildCupertinoTabBar(),
      );
    }

    final displayWarehouse = _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse';
    final hasPhoto = _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kIOSPurple),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(width: 1, height: 24, color: Colors.black12),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DeoDap WMS ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kIOSPurple)),
                SizedBox(height: 2),
                Text('V1.0 • Android App', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          color: kIOSPurple,
        ),
        actions: [
          IconButton(
            tooltip: 'User',
            onPressed: _showUserPopup,
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: kIOSPurple.withOpacity(0.15),
              backgroundImage: hasPhoto ? FileImage(File(_profileImagePath)) : null,
              child: hasPhoto ? null : const Icon(CupertinoIcons.person, size: 18, color: kIOSPurple),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: _goNotifications,
            icon: const Icon(CupertinoIcons.bell_fill, color: kIOSPurple),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _goSettings,
            icon: const Icon(CupertinoIcons.gear_alt_fill, color: kIOSPurple),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.desktopcomputer, size: 18, color: kIOSPurple),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Welcome back, ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kIOSPurple),
                      ),
                      TextSpan(
                        text: _username,
                        style: const TextStyle(fontSize: 22, letterSpacing: -0.2, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                      if (_employeeCode.isNotEmpty) ...[
                        const TextSpan(
                          text: ' (',
                          style: TextStyle(fontSize: 22, letterSpacing: -0.2, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        TextSpan(
                          text: _employeeCode,
                          style: const TextStyle(fontSize: 22, letterSpacing: -0.2, fontWeight: FontWeight.w800, color: kIOSPurple),
                        ),
                        const TextSpan(
                          text: ')',
                          style: TextStyle(fontSize: 22, letterSpacing: -0.2, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.house_alt, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                "Deodap $displayWarehouse",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

            ],
          ),
          const SizedBox(height: 22),

          // Quick Actions - Single column
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 12),
                _quickAction(
                  icon: CupertinoIcons.cube_box_fill,
                  color: const Color(0xFF00A389),
                  title: 'All Products',
                  subtitle: 'Browse catalogue',
                  onTap: _goAllProducts,
                ),
                const SizedBox(height: 10),
                _quickAction(
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                  color: const Color(0xFFFFCC00),
                  title: 'Product Below Threshold',
                  subtitle: 'Transfer pickups',
                  onTap: _goThreshold,
                ),
                const SizedBox(height: 10),
                _quickAction(
                  icon: CupertinoIcons.tray_arrow_down_fill,
                  color: const Color(0xFFFF3B30),
                  title: 'Low Stock',
                  subtitle: 'Total Alert item ',
                  onTap: _goLowstock,
                ),

              ],
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 10))],
              border: Border.all(color: kIOSPurple.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kIOSPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.info_circle_fill, color: kIOSPurple, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tip: Use the bottom tabs to jump directly to QR Inward or Profile.',
                    style: TextStyle(fontSize: 13.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCupertinoTabBar(),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _iosTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.16)),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 10))],
        border: Border.all(color: kIOSPurple.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildDrawer() {
    final isCharging = _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
    final IconData batteryIcon = isCharging ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25;
    final width = MediaQuery.of(context).size.width * 0.72;
    final hasPhoto = _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    return Drawer(
      width: width,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.75),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              top: true,
              bottom: true,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: kIOSPurple.withOpacity(0.95),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    ),
                    alignment: Alignment.center,
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Image.asset('assets/splash_image.png', fit: BoxFit.contain, width: width - 12, height: 120),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.hand_raised_fill, color: Color(0xFFFF8A00), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${_getGreeting()}, $_username${_employeeCode.isNotEmpty ? ' ($_employeeCode)' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _glassTile(
                          child: Row(
                            children: [
                              Icon(_networkIcon, color: Colors.black87, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(_networkLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              Icon(batteryIcon, color: Colors.black87, size: 16),
                              const SizedBox(width: 4),
                              Text(_batteryLevel < 0 ? '—' : '$_batteryLevel%', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _glassTile(
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.time_solid, color: Colors.black54, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(_now.isEmpty ? '—' : _now, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _iosTap(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _tabIndex = 2);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: kIOSPurple.withOpacity(0.15),
                                  backgroundImage: hasPhoto ? FileImage(File(_profileImagePath)) : null,
                                  child: hasPhoto ? null : const Icon(CupertinoIcons.person, color: kIOSPurple, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('View Profile', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userEmail.isNotEmpty ? _userEmail : 'Manage your account',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _drawerTile(
                          icon: CupertinoIcons.house,
                          title: 'Home',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _tabIndex = 0);
                          },
                        ),
                        _drawerTile(
                          icon: CupertinoIcons.qrcode_viewfinder,
                          title: 'Open Scanner',
                          onTap: () {
                            Navigator.pop(context);
                            _goScanner();
                          },
                        ),

                        _drawerTile(
                          icon: CupertinoIcons.cube_box_fill,
                          title: 'all Products',
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black38),
                          onTap: () {
                            Navigator.pop(context);
                            _goAllProducts();
                          },
                        ),
                        _drawerTile(
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          title: 'threshold',
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black38),
                          onTap: () {
                            Navigator.pop(context);
                            _goThreshold();
                          },
                        ),
                        _drawerTile(
                          icon: CupertinoIcons.refresh_bold,
                          title: 'Refresh',
                          onTap: () {
                            Navigator.pop(context);
                            _doRefresh();
                          },
                        ),
                        _drawerTile(
                          icon: CupertinoIcons.gear_solid,
                          title: 'Settings',
                          onTap: () {
                            Navigator.pop(context);
                            _goSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Powered by Vaclvers v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  CupertinoTabBar _buildCupertinoTabBar() {
    return CupertinoTabBar(
      currentIndex: _tabIndex,
      activeColor: kIOSPurple,
      inactiveColor: Colors.black38,
      backgroundColor: Colors.white.withOpacity(0.96),
      border: const Border(top: BorderSide(color: Color(0x11000000))),
      onTap: (i) {
        HapticFeedback.selectionClick();
        setState(() => _tabIndex = i);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.qrcode_viewfinder), label: 'QR Inward'),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle), label: 'Profile'),
      ],
    );
  }

  static Widget _glassTile({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _iosTap({required VoidCallback onTap, required Widget child}) {
    return _ScaleTap(onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    }, child: child);
  }

  ListTile _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      minLeadingWidth: 24,
      horizontalTitleGap: 8,
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing ?? const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black38),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) async {
        await _c.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

class AllProductsScreen extends StatelessWidget {
  const AllProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('All Products', style: TextStyle(color: kIOSPurple, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kIOSPurple),
        leading: IconButton(icon: const Icon(CupertinoIcons.back), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(child: Text('Product Catalogue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('Notifications', style: TextStyle(color: kIOSPurple, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kIOSPurple),
        leading: IconButton(icon: const Icon(CupertinoIcons.back), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(child: Text('No new notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54))),
    );
  }
}