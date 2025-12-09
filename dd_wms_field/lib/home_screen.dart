// lib/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'cod.dart'; // -> cod() screen function/widget
// ===== Your screens ===== // -> ClubOrderScanScreen()
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'help_contact.dart';
import 'setting_screen.dart';
import 'profilescreen.dart';
import 'qr_scanner.dart';
import 'pending_order.dart';
import 'warehouse_listscreen.dart';

// ===== GLOBAL iOS BRAND COLOR =====
const Color kIOSBlue = Color(0xFF007E9B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Drawer key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _username = '';
  String _warehouse = '';
  String _warehouseLabel = '';
  String _authToken = '';

  // API
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-field-app';
  static const String appId = '1';
  static const String apiKey = 'd5e61e52-fd9d-4ac9-a953-fde5fe5f6e5e';

  // Realtime bits
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
    _loadUserData();
    _setupRealtimeBits();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username =
          prefs.getString('userName') ?? prefs.getString('currentUser') ?? 'User';
      _warehouse = prefs.getString('currentWarehouse') ?? '';
      _authToken = prefs.getString('authToken') ?? '';
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
      debugPrint('Error fetching warehouse label: $e');
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
    _clockTimer?.cancel();
    _connSub?.cancel();
    _batteryStateSub?.cancel();
    super.dispose();
  }

  // ======= iOS-like navigation helpers =======
  Future<void> _pushCupertino(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => page));
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
        title: const Text('Logout?'),
        content:
        const Text('Are you sure you want to logout from DeoDap WMS Field App?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (yes == true) {
      await prefs.clear();
      if (mounted) {
        await _replaceWithCupertino(const Onboardingscreen());
      }
    }
  }

  // Coming Soon Dialog
  Future<void> _showComingSoonDialog(String feature) async {
    HapticFeedback.lightImpact();
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(CupertinoIcons.time, color: kIOSBlue, size: 24),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$feature feature will be available very soon.\n\nStay tuned for updates!',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Routes
  void _goReports() => _pushCupertino(const ReportsScreen());
  void _goSettings() => _pushCupertino(const setting());
  void _goProfile() => _pushCupertino(const ProfileScreen());
  void _goClubOrder() => _pushCupertino(const WarehouseListScreen());
  void _goScanner() => _pushCupertino(ClubOrderScanScreen(
    warehouseId: _warehouse.isNotEmpty ? int.parse(_warehouse) : 0,
    warehouseLabel: _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse',
  ));

  // COD and Warehouse Transfer - Coming Soon
  void _goCOD() => _showComingSoonDialog('COD Receive');
  void _goAwaited() => _showComingSoonDialog('Warehouse Transfer Pickup');

  void _doRefresh() async {
    HapticFeedback.lightImpact();
    await _readBatteryLevel();
    await _refreshConnectivity();
    await _loadUserData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshed'), duration: Duration(seconds: 1)),
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final displayWarehouse =
    _warehouseLabel.isNotEmpty ? _warehouseLabel : 'Warehouse $_warehouse';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kIOSBlue),
        titleTextStyle: const TextStyle(
          color: kIOSBlue,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          color: kIOSBlue,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(width: 1, height: 24, color: Colors.black12),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DeoDap WMS Field',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kIOSBlue)),
                SizedBox(height: 2),
                Text('V1.0 • Android App',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: const [
          _AppBarAvatar(),
          _AppBarIcon(icon: CupertinoIcons.gear_alt_fill),
          _AppBarIcon(icon: CupertinoIcons.refresh_bold),
          SizedBox(width: 4),
        ],
      ),

      drawer: _buildDrawer(),

      body: Stack(
        alignment: Alignment.center,
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
            children: [
              // Welcome row
              Row(
                children: [
                  const Icon(CupertinoIcons.desktopcomputer,
                      size: 18, color: kIOSBlue),
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
                              color: kIOSBlue,
                            ),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(CupertinoIcons.house_alt,
                      size: 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    displayWarehouse,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Quick cards
              _sectionCard(
                child: _iosTap(
                  onTap: _goClubOrder,
                  child: Row(
                    children: [
                      _leadingPill(
                          icon: CupertinoIcons.arrow_down_doc, color: kIOSBlue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Club Order Pickup',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text('Receive club orders, scan & verify inward quickly.',
                                style:
                                TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 16, color: Colors.black45),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                child: _iosTap(
                  onTap: _goCOD,
                  child: Row(
                    children: [
                      _leadingPill(
                          icon: CupertinoIcons.creditcard,
                          color: const Color(0xFF00A389)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('COD Receive',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(width: 6),
                                Icon(CupertinoIcons.time, size: 14, color: Colors.orange),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text('Receive / reconcile COD amounts for transfers.',
                                style:
                                TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 16, color: Colors.black45),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                child: _iosTap(
                  onTap: _goAwaited,
                  child: Row(
                    children: [
                      _leadingPill(
                          icon: CupertinoIcons.clock_solid,
                          color: const Color(0xFF00A389)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Warehouse Transfer Pickup',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(width: 6),
                                Icon(CupertinoIcons.time, size: 14, color: Colors.orange),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text('View/act on orders waiting for transfer.',
                                style:
                                TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 16, color: Colors.black45),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Center Scan button
          Positioned(
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: _CenterScannerButton(onTap: _goScanner, color: kIOSBlue),
          ),
        ],
      ),
    );
  }

  // ---------- UI Pieces ----------
  Widget _leadingPill({required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
        border: Border.all(color: const Color(0x11007E9B)),
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

    return Drawer(
      width: width,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            // Soft gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF2F8FA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Content
            Column(
              children: [
                // ==== HEADER ====
                Container(
                  color: kIOSBlue,
                  alignment: Alignment.center,
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Image.asset(
                    'assets/homescreen.png',
                    fit: BoxFit.contain,
                    width: width - 12,
                    height: 120,
                  ),
                ),

                // ==== BODY ====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting with username
                      Row(
                        children: [
                          const Icon(CupertinoIcons.hand_raised_fill,
                              color: Color(0xFFFF8A00), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_getGreeting()}, $_username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Glass: Network + Battery
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
                            Text(_batteryLevel < 0 ? '—' : '$_batteryLevel%',
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Glass: Time
                      _glassTile(
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.time_solid,
                                color: Colors.black54, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_now.isEmpty ? '—' : _now,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Profile capsule
                      _iosTap(
                        onTap: _goProfile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8))
                            ],
                            border: Border.all(color: kIOSBlue.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: kIOSBlue.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: kIOSBlue.withOpacity(0.18)),
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.person,
                                      color: kIOSBlue, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('View Profile',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 2),
                                    Text('Manage your account',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
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

                // ==== DRAWER ITEMS ====
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _drawerTile(
                        icon: CupertinoIcons.house,
                        title: 'Home',
                        onTap: () => Navigator.pop(context),
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
                        icon: CupertinoIcons.tray_arrow_down_fill,
                        title: 'Club Order Pickup',
                        onTap: () {
                          Navigator.pop(context);
                          _goClubOrder();
                        },
                      ),
                      _drawerTile(
                        icon: CupertinoIcons.creditcard,
                        title: 'COD Receive',
                        trailing: const Icon(CupertinoIcons.time, size: 14, color: Colors.orange),
                        onTap: () {
                          Navigator.pop(context);
                          _goCOD();
                        },
                      ),
                      _drawerTile(
                        icon: CupertinoIcons.arrow_2_circlepath,
                        title: 'Warehouse Transfer',
                        trailing: const Icon(CupertinoIcons.time, size: 14, color: Colors.orange),
                        onTap: () {
                          Navigator.pop(context);
                          _goAwaited();
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
                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    leading: const Icon(CupertinoIcons.square_arrow_right,
                        color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
                    'Powered by Vaclvers v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // translucent/glassy tile
  static Widget _glassTile({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }

  // iOS-style tap scale with haptics
  Widget _iosTap({required VoidCallback onTap, required Widget child}) {
    return _ScaleTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: child,
    );
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

// Small app-bar helpers
class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.of(context)
            .push(CupertinoPageRoute(builder: (_) => const ProfileScreen()));
      },
      icon: const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0x14007E9B),
        child: Icon(CupertinoIcons.person, size: 18, color: kIOSBlue),
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  const _AppBarIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: icon == CupertinoIcons.refresh_bold ? 'Refresh' : 'Settings',
      onPressed: () {
        HapticFeedback.selectionClick();
        if (icon == CupertinoIcons.refresh_bold) {
          final state = context.findAncestorStateOfType<_HomeScreenState>();
          state?._doRefresh();
        } else {
          Navigator.of(context)
              .push(CupertinoPageRoute(builder: (_) => const setting()));
        }
      },
      icon: Icon(icon, color: kIOSBlue),
    );
  }
}

// ========= Private widget: scale on tap (iOS-ish) =========
class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.97)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

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

// ======= Center iOS-style Scanner Button =======
class _CenterScannerButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _CenterScannerButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.qrcode_viewfinder, size: 22, color: color),
            const SizedBox(width: 8),
            Text('Open Scanner',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

// ---------------- Example stub screens (use kIOSBlue) ----------------
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('Inventory',
            style: TextStyle(color: kIOSBlue, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kIOSBlue),
        leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(
          child: Text('Inventory Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
    );
  }
}

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('Shipments',
            style: TextStyle(color: kIOSBlue, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kIOSBlue),
        leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(
          child: Text('Shipments Tracking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('Reports',
            style: TextStyle(color: kIOSBlue, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kIOSBlue),
        leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(
          child: Text('Reports & Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
    );
  }
}

class ClubOrderScreen extends StatelessWidget {
  const ClubOrderScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0.6,
      title: const Text('Club Order Inward',
          style:
          TextStyle(color: kIOSBlue, fontWeight: FontWeight.w700)),
      iconTheme: const IconThemeData(color: kIOSBlue),
      leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context)),
    ),
    body: const Center(
      child: Text('Club Order Inward Workflow',
          style: TextStyle(fontSize: 18)),
    ),
  );
}

class CLOAwaitedScreen extends StatelessWidget {
  const CLOAwaitedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('Awaited Orders',
            style:
            TextStyle(color: kIOSBlue, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: kIOSBlue),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('List of CLO-awaited orders will appear here.',
            style: TextStyle(fontSize: 16)),
      ),
    );
  }
}