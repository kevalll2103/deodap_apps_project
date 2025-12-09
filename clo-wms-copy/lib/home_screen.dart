import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'club_order_scanner.dart';

// NEW: connectivity & battery
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'help_contact.dart';
import 'setting_screen.dart';
import 'profilescreen.dart';

// =======================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Scaffold Key (drawer open)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _username = '';
  String _warehouse = '';
  String _warehouseLabel = '';
  String _authToken = '';
  List<String> _stockLocations = [];

  bool _showAllLocations = false; // NEW: collapse/expand

  // API Configuration
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-app';
  static const String appId = '1';
  static const String apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  // ====== Realtime / Network / Battery ======
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

  Color get _primaryBlue => const Color(0xFF1976D2);
  Color get _blue700 => Colors.blue.shade700;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRealtimeBits();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username =
          prefs.getString('userName') ?? prefs.getString('currentUser') ?? 'User';
      _warehouse = prefs.getString('currentWarehouse') ?? '';
      _authToken = prefs.getString('authToken') ?? '';

      final locationsJson = prefs.getString('stockLocations');
      if (locationsJson != null) {
        try {
          _stockLocations = List<String>.from(jsonDecode(locationsJson));
        } catch (_) {
          _stockLocations = [];
        }
      }
    });

    if (_warehouse.isNotEmpty) {
      await _fetchWarehouseLabel();
    }
  }

  Future<void> _fetchWarehouseLabel() async {
    try {
      final url = Uri.parse('$baseUrl/app_info/warehouse_list');

      final requestBody = {
        'app_id': appId,
        'api_key': apiKey,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
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
    } catch (e) {
      debugPrint('Error fetching warehouse label: $e');
    }
  }

  void _setupRealtimeBits() {
    _battery = Battery();
    _connectivity = Connectivity();

    // Clock
    _tickClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());

    // Battery
    _readBatteryLevel();
    _batteryStateSub = _battery.onBatteryStateChanged.listen((s) {
      setState(() => _batteryState = s);
      _readBatteryLevel();
    });

    // Connectivity
    _refreshConnectivity();
    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      _applyConnectivity(results);
    });
  }

  void _tickClock() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
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
        icon =  CupertinoIcons.antenna_radiowaves_left_right;
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
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
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

    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout from DeoDap CLO?'),
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

  void _goReports() => _pushCupertino(const ReportsScreen());
  void _goSettings() => _pushCupertino(const setting());
  void _goProfile() => _pushCupertino(const ProfileScreen());
  void _goClubOrder() => _pushCupertino(const ClubOrderScanScreen());

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

      // ===== AppBar: iOS look =====
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0.6,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: _primaryBlue),
        titleTextStyle: TextStyle(
          color: _primaryBlue,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        // Drawer open button (iPhone-like)
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(CupertinoIcons.line_horizontal_3),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          color: _primaryBlue,
        ),

        titleSpacing: 0,
        title: Row(
          children: [
            Container(width: 1, height: 24, color: Colors.black12),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DeoDap CLO',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _primaryBlue)),
                const SizedBox(height: 2),
                const Text('V1.78 • Android App',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          // Profile avatar (Hero for iOS-like transition)
          IconButton(
            tooltip: 'Profile',
            onPressed: _goProfile,
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0x141976D2),
              child: Icon(CupertinoIcons.person, size: 18, color: Color(0xFF1976D2)),
            ),
          ),
          // Settings (in AppBar instead of popup)
          IconButton(
            tooltip: 'Settings',
            onPressed: _goSettings,
            icon: const Icon(CupertinoIcons.gear_alt_fill, color: Color(0xFF1976D2)),
          ),
          // Refresh
          IconButton(
            tooltip: 'Refresh',
            onPressed: _doRefresh,
            icon: const Icon(CupertinoIcons.refresh_bold, color: Color(0xFF1976D2)),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ===== Drawer =====
      drawer: _buildDrawer(),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          // Welcome back + desktop icon + username in ONE ROW (iOS-like subtle)
          Row(
            children: [
              const Icon(CupertinoIcons.desktopcomputer,
                  size: 18, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome back, ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue,
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

          const SizedBox(height: 24),

          // Stock Locations Card (collapsible)
          if (_stockLocations.isNotEmpty) ...[
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.location_solid,
                          size: 20, color: _primaryBlue),
                      const SizedBox(width: 8),
                      const Text(
                        'Stock Physical Locations',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      if (_stockLocations.length > 6)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minSize: 26,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showAllLocations = !_showAllLocations);
                          },
                          child: Text(
                            _showAllLocations ? 'Show less' : 'Show more',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_showAllLocations
                          ? _stockLocations
                          : _stockLocations.take(6))
                          .map((loc) {
                        return Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: _primaryBlue.withOpacity(0.15)),
                          ),
                          child: Text(
                            loc,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _primaryBlue,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick entry
          _sectionCard(
            child: _iosTap(
              onTap: _goClubOrder,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.arrow_down_doc,
                        color: Color(0xFF1A73E8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Club Order Inward',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text(
                          'Receive club orders, scan & verify inward quickly.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
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
    );
  }

  // ---------- UI Pieces ----------
  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: child,
    );
  }

  // ---------- Drawer (Premium / iOS-like) ----------
  Widget _buildDrawer() {
    final isCharging =
        _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
    final IconData batteryIcon =
    isCharging ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25;

    final width = MediaQuery.of(context).size.width * 0.70; // narrower

    return Drawer(
      width: width,
      child: Stack(
        children: [
          // soft gradient bg (premium feel)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF2F6FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // content
          Column(
            children: [
              // 1) LOGO BAR — Blue700 background (compact bg, bigger logo)
              Container(
                width: double.infinity,
                color: _blue700,
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 12), // compact bg
                child: SizedBox(
                  height: 88, // bigger logo but bg paddings small
                  child: Center(
                    child: Image.asset(
                      'assets/deodap_logo.png',
                      fit: BoxFit.contain,
                      width: width - 12, // zoom more
                    ),
                  ),
                ),
              ),

              // 2) CONTENT: Wish+Name → Net+Battery (glass) → Time (glass) → Profile
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wish + Username (row) with orange HELLO icon
                    Row(
                      children: [
                        const Icon(CupertinoIcons.hand_raised_fill
                            , color: Color(0xFFFF8A00), size: 18), // orange
                        const SizedBox(width: 8),
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _username,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- Glass panel (Network + Battery) ---
                    _glassTile(
                      child: Row(
                        children: [
                          Icon(_networkIcon, color: Colors.black87, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _networkLabel,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6), // tighter gap
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
                    const SizedBox(height: 6), // less space between sections

                    // --- Glass panel (Time) ---
                    _glassTile(
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.time_solid,
                              color: Colors.black54, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _now.isEmpty ? '—' : _now,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Profile section (tappable, iOS scale animation)
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
                              offset: Offset(0, 8),
                            )
                          ],
                          border: Border.all(
                            color: _primaryBlue.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _primaryBlue.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _primaryBlue.withOpacity(0.15)),
                              ),
                              child: Center(
                                child: Text(
                                  _username.isNotEmpty
                                      ? _username[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _username,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'WH: ${_warehouseLabel.isNotEmpty ? _warehouseLabel : _warehouse}',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

              // 3) Items (trimmed as requested)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _drawerTile(
                      icon: CupertinoIcons.house,
                      title: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),
                    // REMOVED: Notifications, Inventory, Shipments
                    _drawerTile(
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      title: 'Reports',
                      onTap: () {
                        Navigator.pop(context);
                        _goReports();
                      },
                    ),
                    _drawerTile(
                      icon: CupertinoIcons.tray_arrow_down_fill,
                      title: 'Club Order Inward',
                      onTap: () {
                        Navigator.pop(context);
                        _goClubOrder();
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

              // Logout + Powered By
              const Divider(height: 1),
              ListTile(
                leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Powered by Valcvers v1.0.0',
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
    );
  }

  // translucent/glassy tile
  Widget _glassTile({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35), // transparent look
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

  ListTile _drawerTile(
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      horizontalTitleGap: 8,
      trailing: const Icon(CupertinoIcons.chevron_right,
          size: 16, color: Colors.black38),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _scale =
  Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

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

// ---------------- Other Screens (stubs ok) ----------------

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
            style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
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
            style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
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
            style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
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
          TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w700)),
      iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
      leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context)),
    ),
    body: const Center(
      child: Text('Club Order Inward Workflow', style: TextStyle(fontSize: 18)),
    ),
  );
}
