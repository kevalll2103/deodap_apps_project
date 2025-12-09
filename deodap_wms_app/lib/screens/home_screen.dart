import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Screens
import 'all_product.dart';
import 'low_stock.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'qr_inward.dart';
import 'setting_screen.dart';
import 'threshold.dart';

// ===== Theme =====
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

  // Tabs: 0=Home, 1=QR Inward, 2=Profile, 3=Settings
  int _tabIndex = 0;

  // User/Profile
  String _username = '';
  String _warehouse = '';
  String _warehouseLabel = '';
  String _authToken = '';
  String _userEmail = '';
  String _userPhone = '';
  String _profileImagePath = '';
  String _employeeCode = '';

  // App Lock
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
  bool _isInitialized = false;
  bool _hasShownStartupPin = false;
  // final LocalAuthentication _localAuth = LocalAuthentication(); // enable when local_auth added

  // Config (loaded, not hard-coded)
  String _baseUrl = 'https://api.vacalvers.com/api-wms-app';
  String _appId = '1';
  String _apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  // Realtime
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
    _loadApiConfig().then((_) async {
      await _loadUserData();
      await _loadAppLockSettings();
      if (mounted) {
        setState(() => _isInitialized = true);
        if (_appLockEnabled &&
            _storedPin.isNotEmpty &&
            !_isPinDialogShowing &&
            !_hasShownStartupPin) {
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
        if (_isInitialized) {
          _doRefresh(skipPinCheck: true);
          _checkAndShowLockScreen();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _baseUrl = prefs.getString('cfg_baseUrl') ?? _baseUrl;
      _appId = prefs.getString('cfg_appId') ?? _appId;
      _apiKey = prefs.getString('cfg_apiKey') ?? _apiKey;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username =
          prefs.getString('userName') ?? prefs.getString('currentUser') ?? 'User';
      _warehouse = prefs.getString('currentWarehouse') ?? '';
      _authToken = prefs.getString('authToken') ?? '';
      _userEmail = prefs.getString('userEmail') ?? '';
      _userPhone = prefs.getString('userPhone') ?? '';
      _profileImagePath = prefs.getString('profileImagePath') ?? '';
      _employeeCode = prefs.getString('employeeCode') ?? '';
    });

    if (_warehouse.isNotEmpty) {
      await _fetchWarehouseLabel();
    }
  }

  Future<void> _fetchWarehouseLabel() async {
    try {
      final url = Uri.parse('$_baseUrl/app_info/warehouse_list');
      final response = await http.post(
        url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'app_id': _appId, 'api_key': _apiKey}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status_flag'] == 1 && responseData['data'] != null) {
          final warehouses =
          List<Map<String, dynamic>>.from(responseData['data']);
          final currentWarehouse = warehouses.firstWhere(
                (w) => w['id'].toString() == _warehouse,
            orElse: () => {},
          );
          if (currentWarehouse.isNotEmpty && mounted) {
            setState(() {
              _warehouseLabel =
                  currentWarehouse['label'] ?? 'Warehouse $_warehouse';
            });
          }
        }
      }
    } catch (_) {
      // Silent fail: keep fallback label
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
      _now =
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)} • ${two(now.day)}-${two(now.month)}-${now.year}';
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
      final result = await _connectivity.checkConnectivity();
      _applyConnectivity(result);
    } catch (_) {}
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    String label;
    IconData icon;

    // Get the first connectivity result from the list
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    switch (result) {
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
    if (mounted) _doRefresh(skipPinCheck: true);
  }

  Future<void> _replaceWithCupertino(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context)
        .pushReplacement(CupertinoPageRoute(builder: (_) => page));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign out?'),
        content:
        const Text('Are you sure you want to sign out from DeoDap WMS App?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
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
    warehouseLabel: _warehouseLabel.isNotEmpty
        ? _warehouseLabel
        : 'Warehouse $_warehouse',
  ));
  void _goNotifications() => _pushCupertino(const LowStockAlertsScreen());
  void _goSettingsFromDrawer() {
    Navigator.pop(context);
    setState(() => _tabIndex = 3);
  }

  Future<void> _showUserPopup() async {
    final name = _username;
    final email = _userEmail.isEmpty ? 'Not provided' : _userEmail;
    final phone = _userPhone.isEmpty ? 'Not provided' : _userPhone;
    final wh = _warehouseLabel.isNotEmpty
        ? _warehouseLabel
        : 'Warehouse $_warehouse';
    final hasPhoto =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    final isCharging =
        _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
    final IconData batteryIcon =
    isCharging ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25;

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
              backgroundColor: kIOSPurple.withOpacity(0.15),               //  withValues(alpha: 0.15),
              backgroundImage: hasPhoto ? FileImage(File(_profileImagePath)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kIOSPurple),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.hand_raised_fill,
                    color: Color(0xFFFF8A00), size: 16),
                const SizedBox(width: 6),
                Text(_getGreeting(),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kIOSPurple)),
              ],
            ),
            const SizedBox(height: 10),
            Text(name,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(wh, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(phone,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            if (_userEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            if (_employeeCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Employee Code: $_employeeCode',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_networkIcon, color: kIOSPurple, size: 18),
                const SizedBox(width: 6),
                Text(_networkLabel,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(batteryIcon, color: kIOSPurple, size: 18),
                const SizedBox(width: 6),
                Text(_batteryLevel < 0 ? '—' : '$_batteryLevel%',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.time_solid,
                    color: kIOSPurple, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _now.isEmpty ? '—' : _now,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
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
    } catch (_) {}
  }

  void _checkAndShowLockScreen() {
    if (!_isInitialized ||
        !_appLockEnabled ||
        _storedPin.isEmpty ||
        _isPinDialogShowing) {
      return;
    }
    if (_backgroundTime != null) {
      final timeInBackground = DateTime.now().difference(_backgroundTime!);
      if (timeInBackground.inSeconds < 1) {
        return;
      }
    }
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted &&
          _isInitialized &&
          !_isPinDialogShowing &&
          _appLockEnabled &&
          _storedPin.isNotEmpty) {
        _showLockScreen();
      }
    });
  }

  Future<void> _showPinDialogImmediate({bool isStartup = false}) async {
    if (!mounted ||
        !_isInitialized ||
        _isPinDialogShowing ||
        !_appLockEnabled ||
        _storedPin.isEmpty) {
      return;
    }
    if (isStartup && _hasShownStartupPin) return;

    setState(() {
      _isPinDialogShowing = true;
      _failedAttempts = 0;
      _errorText = null;
      _pinController.clear();
      if (isStartup) _hasShownStartupPin = true;
    });

    if (_biometricEnabled) {
      final authenticated = await _authenticateWithBiometrics();
      if (authenticated) {
        if (!mounted) return;
        setState(() => _isPinDialogShowing = false);
        return;
      }
    }
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
    if (_biometricEnabled) {
      final authenticated = await _authenticateWithBiometrics();
      if (authenticated) {
        if (!mounted) return;
        setState(() => _isPinDialogShowing = false);
        return;
      }
    }
    _showPinDialog();
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Uncomment and configure when local_auth is added
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
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _verifyPin() async {
    final enteredPin = _pinController.text.trim();
    if (enteredPin.isEmpty) {
      setState(() => _errorText = 'Please enter PIN');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (enteredPin == _storedPin) {
      setState(() {
        _failedAttempts = 0;
        _isPinDialogShowing = false;
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop(); // close dialog
      }
    } else {
      setState(() {
        _failedAttempts++;
        _isLoading = false;
        _pinController.clear();
      });
      HapticFeedback.heavyImpact();
      if (_failedAttempts >= 3) {
        setState(() {
          _errorText = 'Too many failed attempts. Try again later.';
        });
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
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _errorText = null);
        });
      }
    }
  }

  void _showPinDialog() {
    if (!mounted || !_isPinDialogShowing) return;
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
                const Icon(CupertinoIcons.lock_shield_fill,
                    size: 36, color: kIOSPurple),
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
                    color:
                    CupertinoColors.secondaryLabel, // resolved by default
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
                  if (_errorText != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_circle_fill,
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
                  Container(
                    width: 200,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoTextField(
                      controller: _pinController,
                      placeholder: '••••',
                      placeholderStyle: const TextStyle(
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
                  if (_biometricEnabled) ...[
                    AnimatedOpacity(
                      opacity: _failedAttempts < 3 ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: CupertinoButton(
                        onPressed: _failedAttempts >= 3
                            ? null
                            : () async {
                          HapticFeedback.mediumImpact();
                          final authenticated =
                          await _authenticateWithBiometrics();
                          if (authenticated && mounted) {
                            setState(() {
                              _isPinDialogShowing = false;
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        borderRadius: BorderRadius.circular(10),
                        color: CupertinoColors.tertiarySystemFill,
                        disabledColor: CupertinoColors.tertiarySystemFill
                            .withOpacity(0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.person_2_fill
                                  : CupertinoIcons.person_2_fill,
                              size: 20,
                              color: _failedAttempts >= 3
                                  ? CupertinoColors.tertiaryLabel
                                  : kIOSPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Platform.isIOS ? 'Use Face ID' : 'Use Fingerprint',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _failedAttempts >= 3
                                    ? CupertinoColors.tertiaryLabel
                                    : kIOSPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  CupertinoButton(
                    onPressed: _failedAttempts >= 3
                        ? null
                        : () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _showForgotPinDialog();
                    },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minSize: 0,
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _failedAttempts >= 3
                            ? CupertinoColors.tertiaryLabel
                            : kIOSPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: const <Widget>[],
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
    if (!skipPinCheck) {
      await _loadAppLockSettings();
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    // Route per tab (kept simple and predictable)
    if (_tabIndex == 1) {
      return Scaffold(
        backgroundColor: kBg,
        body: ClubOrderScanScreen(
          warehouseId: _warehouse.isNotEmpty ? int.parse(_warehouse) : 0,
          warehouseLabel: _warehouseLabel.isNotEmpty
              ? _warehouseLabel
              : 'Warehouse $_warehouse',
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

    if (_tabIndex == 3) {
      return Scaffold(
        backgroundColor: kBg,
        body: const setting(),
        bottomNavigationBar: _buildCupertinoTabBar(),
      );
    }

    // ===== Home tab =====
    final displayWarehouse =
    _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse';
    final hasPhoto =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

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
                Text('DeoDap WMS',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kIOSPurple)),
                SizedBox(height: 2),
                Text('V1.0',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
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
              backgroundColor: kIOSPurple.withOpacity(0.15),         //withValues(alpha: 0.15),
              backgroundImage: hasPhoto ? FileImage(File(_profileImagePath)) : null,
              child: hasPhoto
                  ? null
                  : const Icon(CupertinoIcons.person, size: 18, color: kIOSPurple),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: _goNotifications,
            icon: const Icon(CupertinoIcons.bell_fill, color: kIOSPurple),
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
              const Icon(CupertinoIcons.desktopcomputer,
                  size: 18, color: kIOSPurple),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Welcome back, ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kIOSPurple),
                      ),
                      TextSpan(
                        text: _username,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: -0.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      if (_employeeCode.isNotEmpty) ...[
                        const TextSpan(
                          text: ' (',
                          style: TextStyle(
                              fontSize: 22,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: _employeeCode,
                          style: const TextStyle(
                              fontSize: 22,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w800,
                              color: kIOSPurple),
                        ),
                        const TextSpan(
                          text: ')',
                          style: TextStyle(
                              fontSize: 22,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.black),
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
                "DeoDap $displayWarehouse",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Quick Actions
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
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
                  subtitle: 'Total alert items',
                  onTap: _goLowstock,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 20,
                    offset: Offset(0, 10))
              ],
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
                  child: const Icon(CupertinoIcons.info_circle_fill,
                      color: kIOSPurple, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Use the bottom tabs to jump to QR Inward, Profile, or Settings.',
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
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 8))
          ],
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                      const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 18, color: Colors.black38),
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
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 10))
        ],
        border: Border.all(color: kIOSPurple.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildDrawer() {
    final isCharging =
        _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
    final IconData batteryIcon =
    isCharging ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25;
    final width = MediaQuery.of(context).size.width * 0.72;
    final hasPhoto =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

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
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.center,
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Image.asset('assets/splash_image.png',
                        fit: BoxFit.contain, width: width - 12, height: 120),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.hand_raised_fill,
                                color: Color(0xFFFF8A00), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${_getGreeting()}, $_username${_employeeCode.isNotEmpty ? ' ($_employeeCode)' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
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
                                child: Text(_networkLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              Icon(batteryIcon, color: Colors.black87, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _batteryLevel < 0 ? '—' : '$_batteryLevel%',
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _glassTile(
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.time_solid,
                                  color: Colors.black54, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _now.isEmpty ? '—' : _now,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 12),
                                ),
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
                                  backgroundImage:
                                  hasPhoto ? FileImage(File(_profileImagePath)) : null,
                                  child: hasPhoto
                                      ? null
                                      : const Icon(CupertinoIcons.person,
                                      color: kIOSPurple, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('View Profile',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userEmail.isNotEmpty
                                            ? _userEmail
                                            : 'Manage your account',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.black54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_right,
                                    size: 16, color: Colors.black54),
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
                          title: 'All Products',
                          trailing: const Icon(CupertinoIcons.chevron_right,
                              size: 16, color: Colors.black38),
                          onTap: () {
                            Navigator.pop(context);
                            _goAllProducts();
                          },
                        ),
                        _drawerTile(
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          title: 'Threshold',
                          trailing: const Icon(CupertinoIcons.chevron_right,
                              size: 16, color: Colors.black38),
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
                          onTap: _goSettingsFromDrawer,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -3),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      leading: const Icon(CupertinoIcons.square_arrow_right,
                          color: Colors.red),
                      title: const Text('Logout',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600)),
                      trailing:
                      const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Powered by Vacalvers v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600),
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
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.qrcode_viewfinder), label: 'QR Inward'),
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle), label: 'Profile'),
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear), label: 'Settings'),
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
      trailing: trailing ??
          const Icon(CupertinoIcons.chevron_right,
              size: 16, color: Colors.black38),
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

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _scale =
  Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  ));

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
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
