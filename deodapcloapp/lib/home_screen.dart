import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NEW: connectivity & battery
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'help_contact.dart';
import 'setting_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  String _warehouse = '';
  // Removed filters
  // String _selectedFilter = 'All';

  // ====== Realtime / Network / Battery ======
  late final Battery _battery;
  late final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _clockTimer;

  String _now = '';
  String _networkLabel = 'Checking…';
  IconData _networkIcon = Icons.wifi_off_rounded;

  int _batteryLevel = -1; // unknown initially
  BatteryState _batteryState = BatteryState.unknown;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRealtimeBits();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('currentUser') ?? 'User';
      _warehouse = prefs.getString('currentWarehouse') ?? 'Warehouse 1';
    });
  }

  void _setupRealtimeBits() {
    _battery = Battery();
    _connectivity = Connectivity();

    // Clock
    _tickClock(); // set immediately
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());

    // Battery
    _readBatteryLevel();
    _batteryStateSub = _battery.onBatteryStateChanged.listen((s) {
      setState(() => _batteryState = s);
      _readBatteryLevel(); // refresh level when state changes
    });

    // Connectivity
    _refreshConnectivity();
    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      _applyConnectivity(results);
    });
  }

  void _tickClock() {
    final now = DateTime.now();
    final two = (int n) => n.toString().padLeft(2, '0');
    setState(() {
      _now =
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)} • ${two(now.day)}-${two(now.month)}-${now.year}';
    });
  }

  Future<void> _readBatteryLevel() async {
    try {
      final lvl = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = lvl);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _refreshConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _applyConnectivity(results);
    } catch (_) {
      // ignore
    }
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    // On Android/iOS there is usually a single result in the list.
    final r = results.isNotEmpty ? results.first : ConnectivityResult.none;
    String label;
    IconData icon;

    switch (r) {
      case ConnectivityResult.wifi:
        label = 'Wi-Fi';
        icon = Icons.wifi_rounded;
        break;
      case ConnectivityResult.mobile:
        label = 'Mobile';
        icon = Icons.network_cell_rounded;
        break;
      case ConnectivityResult.ethernet:
        label = 'Ethernet';
        icon = Icons.settings_ethernet_rounded;
        break;
      case ConnectivityResult.vpn:
        label = 'VPN';
        icon = Icons.vpn_lock_rounded;
        break;
      case ConnectivityResult.bluetooth:
        label = 'Bluetooth';
        icon = Icons.bluetooth_rounded;
        break;
      case ConnectivityResult.other:
        label = 'Connected';
        icon = Icons.device_hub_rounded;
        break;
      case ConnectivityResult.none:
      default:
        label = 'Offline';
        icon = Icons.wifi_off_rounded;
    }

    if (mounted) {
      setState(() {
        _networkLabel = label;
        _networkIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _connSub?.cancel();
    _batteryStateSub?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('currentUser');
    await prefs.remove('currentWarehouse');
    await prefs.remove('loginTime');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Onboardingscreen()),
      );
    }
  }

  // ---------- Helpers ----------
  void _goInventory() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
  void _goShipments() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShipmentsScreen()));
  void _goReports() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));

  void _doRefresh() async {
    // Put your API/DB reload logic here
    await _readBatteryLevel();
    await _refreshConnectivity();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshed')),
    );
    setState(() {}); // trigger rebuild
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0.6,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 60,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 20),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _tick(width: 6),
            const SizedBox(width: 6),
            _tick(width: 10),
            const SizedBox(width: 6),
            _tick(width: 14),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Navexa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                Text('V1.78 • iOS', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          // Removed Search button as requested
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (v) {
              switch (v) {
                case 'refresh':
                  _doRefresh();
                  break;
                case 'inventory':
                  _goInventory();
                  break;
                case 'shipments':
                  _goShipments();
                  break;
                case 'reports':
                  _goReports();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Row(
                children: [Icon(Icons.refresh, size: 18), SizedBox(width: 8), Text('Refresh')],
              )),
              PopupMenuItem(value: 'inventory', child: Text('Inventory')),
              PopupMenuItem(value: 'shipments', child: Text('Shipments')),
              PopupMenuItem(value: 'reports', child: Text('Reports')),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          // Header: Warehouse + ID
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _warehouse,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
              ),
              const SizedBox(width: 12),
              _statusPill(text: 'Live', color: Colors.green),
            ],
          ),
          const SizedBox(height: 4),
          const Text('N#12550815', style: TextStyle(fontSize: 13, color: Colors.grey)),

          const SizedBox(height: 18),

          // Removed "Report operations" card

          // Removed filter chips (All/Available/Employed)

          // Cards (kept)
          _buildHaulixCard(
            title: 'Haulix - N°52561',
            status: 'Available',
            statusColor: Colors.green,
            batteryLife: 72,
            batteryColor: Colors.green,
            platforms: const [
              {'name': 'FA', 'code': 'N°54251', 'weight': '120Kg', 'status': 'Done', 'color': 0xFF2E7D32},
              {'name': 'A',  'code': 'N°67834', 'weight': '320Kg', 'status': 'Done', 'color': 0xFF2E7D32},
              {'name': 'BF', 'code': 'N°753215', 'weight': '54Kg',  'status': 'Error', 'color': 0xFFD32F2F},
            ],
            initiallyExpanded: true,
          ),
          const SizedBox(height: 12),
          _buildHaulixCard(
            title: 'Haulix - N°98645',
            status: 'Available',
            statusColor: Colors.green,
            batteryLife: 41,
            batteryColor: Colors.red,
            platforms: const [
              {'name': 'FA', 'code': 'N°54251', 'weight': '160Kg', 'status': 'Done', 'color': 0xFF2E7D32},
            ],
            initiallyExpanded: false,
          ),
        ],
      ),
    );
  }

  // ---------- UI Pieces ----------

  Widget _tick({required double width}) => Container(
    width: width,
    height: 20,
    decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(3)),
  );

  Widget _statusPill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _buildHaulixCard({
    required String title,
    required String status,
    required Color statusColor,
    required int batteryLife,
    required Color batteryColor,
    required List<Map<String, dynamic>> platforms,
    required bool initiallyExpanded,
  }) {
    final ValueNotifier<bool> expanded = ValueNotifier<bool>(initiallyExpanded);

    return _sectionCard(
      child: ValueListenableBuilder<bool>(
        valueListenable: expanded,
        builder: (_, isExpanded, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF4F6FB), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.precision_manufacturing, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(status, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Per-card 3-dot menu (also navigates)
                  PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (v) {
                      switch (v) {
                        case 'inventory':
                          _goInventory();
                          break;
                        case 'shipments':
                          _goShipments();
                          break;
                        case 'reports':
                          _goReports();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'inventory', child: Text('Inventory')),
                      PopupMenuItem(value: 'shipments', child: Text('Shipments')),
                      PopupMenuItem(value: 'reports', child: Text('Reports')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.more_vert, color: Colors.black45),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => expanded.value = !isExpanded,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Battery
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Battery life', style: TextStyle(fontSize: 12.5, color: Colors.black54)),
                  Text('$batteryLife%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: batteryColor)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE9EFF5),
                  valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                  value: batteryLife / 100,
                ),
              ),

              if (isExpanded) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _headerCell('Platform', width: 70),
                    _headerCell('Names', flex: 1),
                    _headerCell('Weight', width: 70),
                    _headerCell('', width: 86),
                  ],
                ),
                const SizedBox(height: 10),
                for (final p in platforms) _platformRow(p),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _headerCell(String label, {double? width, int? flex}) {
    final w = Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45));
    if (flex != null) return Expanded(flex: flex, child: w);
    return SizedBox(width: width ?? 60, child: w);
  }

  Widget _platformRow(Map<String, dynamic> p) {
    final Color tagColor = Color(p['color'] as int);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(p['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(child: Text(p['code'], style: const TextStyle(fontSize: 13, color: Colors.black87))),
          SizedBox(width: 70, child: Text(p['weight'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Container(
            width: 86,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(18)),
            child: Text(p['status'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------- Drawer ----------
  Widget _buildDrawer() {
    final isCharging = _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
    final batteryIcon = isCharging
        ? Icons.battery_charging_full_rounded
        : Icons.battery_std_rounded;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1976D2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Top row: Logo + status chips
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO (from assets/deodap.png)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        image: const DecorationImage(
                          image: AssetImage('assets/deodap_logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chip(
                            icon: Icons.schedule_rounded,
                            label: _now.isEmpty ? 'Time' : _now,
                          ),
                          _chip(
                            icon: _networkIcon,
                            label: _networkLabel,
                          ),
                          _chip(
                            icon: batteryIcon,
                            label: _batteryLevel < 0 ? 'Battery' : '$_batteryLevel%',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // User name + warehouse
                Text(_username,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Warehouse: $_warehouse',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Home'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    _goInventory();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text('Shipments'),
                  onTap: () {
                    Navigator.pop(context);
                    _goShipments();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Reports'),
                  onTap: () {
                    Navigator.pop(context);
                    _goReports();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const setting()));
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------- Other Screens (unchanged basics; kept minimal) ----------------

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text('Inventory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(child: Text('Inventory Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
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
        title: const Text('Shipments', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(child: Text('Shipments Tracking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
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
        title: const Text('Reports', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(child: Text('Reports & Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
    );
  }
}
