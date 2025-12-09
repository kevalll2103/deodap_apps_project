// lib/home/home.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../route/app_route.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userPhone = '';
  String _warehouseLabel = '';
  bool _isReadonly = false;

  // Time & Location
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  String? _locationText;
  bool _locationLoading = false;

  static const String _appVersion = 'v1.1.1';

  @override
  void initState() {
    super.initState();
    _loadSession();
    _startClock();
    _fetchLocation();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = p.getString('userName')?.trim() ?? '';
      _userPhone = p.getString('userPhone')?.trim() ?? '';
      _warehouseLabel = p.getString('currentWarehouseLabel')?.trim() ?? '';
      _isReadonly = (p.getInt('isReadonly') ?? 0) == 1;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Confirmation'),
        content: const Text(
          'Are you sure you want to Signout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Signout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final p = await SharedPreferences.getInstance();
    await p.setBool('isLoggedIn', false);
    await p.remove('authToken');
    await p.remove('currentUser');
    await p.remove('currentWarehouse');
    await p.remove('currentWarehouseLabel');
    await p.remove('loginTime');

    if (!mounted) return;
    Get.offAllNamed(AppRoutes.login);
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty) return 'DD';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _fetchLocation() async {
    if (_locationLoading) return;
    _locationLoading = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission denied';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String formatted = '';

      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];

          if ((p.name ?? '').trim().isNotEmpty) parts.add(p.name!.trim());
          if ((p.street ?? '').trim().isNotEmpty) parts.add(p.street!.trim());
          if ((p.locality ?? '').trim().isNotEmpty) {
            parts.add(p.locality!.trim());
          }
          if ((p.administrativeArea ?? '').trim().isNotEmpty) {
            parts.add(p.administrativeArea!.trim());
          }
          if ((p.postalCode ?? '').trim().isNotEmpty) {
            parts.add(p.postalCode!.trim());
          }

          if (parts.isNotEmpty) {
            formatted = parts.join(', ');
          }
        }
      } catch (_) {
        // ignore & fall back
      }

      formatted = formatted.isNotEmpty
          ? formatted
          : 'Lat ${pos.latitude.toStringAsFixed(4)}, Lng ${pos.longitude.toStringAsFixed(4)}';

      setState(() {
        _locationText = formatted;
      });
    } catch (_) {
      setState(() {
        _locationText = 'Location unavailable';
      });
    } finally {
      _locationLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Navy brand accent (no black theme)
    const Color brand = Color(0xFF0A3D91);
    const Color background = Color(0xFFF5F5F7);

    final initials = _initialsFromName(_userName);

    return Scaffold(
      backgroundColor: background,
      drawer: _HomeDrawer(
        brand: brand,
        userName: _userName,
        userPhone: _userPhone,
        warehouseLabel: _warehouseLabel,
        isReadonly: _isReadonly,
        onLogout: _logout,
        initials: initials,
        now: _now,
        locationText: _locationText,
        appVersion: _appVersion,
      ),
      body: SafeArea(
        child: Builder(
          builder: (ctx) {
            return RefreshIndicator(
              onRefresh: () async {
                await _loadSession();
                await _fetchLocation();
              },
              color: brand,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // iOS-style Curved White Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top bar
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Scaffold.of(ctx).openDrawer(),
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: brand.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.line_horizontal_3,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'DeoDap Staff Packaging',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Profile button – initials avatar (simple, safe)
                                  GestureDetector(
                                    onTap: () {
                                      Get.toNamed(AppRoutes.profile);
                                    },
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: brand,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              // Greeting + time/date
                              _HomeHeader(
                                userName: _userName,
                                onDarkBackground: false,
                                now: _now,
                              ),
                              const SizedBox(height: 14),
                              // Warehouse + mode info row
                              Row(
                                children: [
                                  if (_warehouseLabel.isNotEmpty)
                                    _chip(
                                      icon: CupertinoIcons.house_alt,
                                      label: _warehouseLabel,
                                      color: brand,
                                    ),
                                  if (_isReadonly) ...[
                                    const SizedBox(width: 8),
                                    _chip(
                                      icon: Icons.visibility_outlined,
                                      label: 'Readonly Mode',
                                      color: Colors.orange.shade400,
                                      subtle: true,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _QRScannerSection(
                                brand: brand,
                                surface: Colors.white,
                                warehouseLabel: _warehouseLabel,
                              ),
                              const SizedBox(height: 18),
                              _InfoStrip(brand: brand),
                              const SizedBox(height: 24),
                              _QuickActionsSection(
                                brand: brand,
                                surface: Colors.white,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
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
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    bool subtle = false,
  }) {
    final bg = subtle ? color.withOpacity(0.06) : color.withOpacity(0.08);
    final borderColor = subtle ? color.withOpacity(0.2) : color.withOpacity(0.3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =====================
// HOME HEADER (Greeting)
// =====================

class _HomeHeader extends StatelessWidget {
  final String userName;
  final bool onDarkBackground;
  final DateTime now;

  const _HomeHeader({
    required this.userName,
    this.onDarkBackground = false,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final hour = now.hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    final Color primaryText =
        onDarkBackground ? Colors.white : Colors.black87;
    final Color secondaryText =
        onDarkBackground ? Colors.white70 : Colors.black54;

    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEE, d MMM yyyy').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName.isNotEmpty ? '$greeting, $userName 👋' : '$greeting 👋',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome to DeoDap Staff Packaging Management System',
          style: TextStyle(
            color: secondaryText,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              CupertinoIcons.time,
              size: 16,
              color: secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              '$timeStr • $dateStr',
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =====================
// QR SCANNER SECTION
// =====================

class _QRScannerSection extends StatelessWidget {
  final Color brand;
  final Color surface;
  final String warehouseLabel;

  const _QRScannerSection({
    required this.brand,
    required this.surface,
    required this.warehouseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.03),
        ),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.qrScanner),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: brand.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: brand,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan PO QR Code',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warehouseLabel.isNotEmpty
                          ? 'Start packaging for orders in $warehouseLabel.'
                          : 'Scan the PO QR code to start packaging.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                color: brand,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================
// INFO STRIP (Workflow Hint)
// =====================

class _InfoStrip extends StatelessWidget {
  final Color brand;

  const _InfoStrip({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: brand.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: brand,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Flow: Scan PO → Upload 2 images → Enter shipment packages count → Submit.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.toNamed(AppRoutes.HowItWorksScreen);
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Learn more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// QUICK ACTIONS
// =====================

class _QuickActionsSection extends StatelessWidget {
  final Color brand;
  final Color surface;

  const _QuickActionsSection({
    required this.brand,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        _QuickActionsGrid(),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    const Color surface = Colors.white;
    const Color brand = Color(0xFF0A3D91);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: [
        _HomeQuickTile(
          icon: Icons.inventory_2_outlined,
          label: 'Stock',
          color: brand,
          surface: surface,
          onTap: () {
            Get.snackbar(
              'Coming Soon',
              'Stock management feature',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: surface,
              colorText: Colors.black87,
            );
          },
        ),
        _HomeQuickTile(
          icon: Icons.local_shipping_outlined,
          label: 'Inward / Outward',
          color: Colors.teal,
          surface: surface,
          onTap: () {
            Get.snackbar(
              'Coming Soon',
              'Inward/Outward feature',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: surface,
              colorText: Colors.black87,
            );
          },
        ),
      ],
    );
  }
}

// =====================
// DRAWER
// =====================

class _HomeDrawer extends StatelessWidget {
  final Color brand;
  final String userName;
  final String userPhone;
  final String warehouseLabel;
  final bool isReadonly;
  final VoidCallback onLogout;
  final String initials;
  final DateTime now;
  final String? locationText;
  final String appVersion;

  const _HomeDrawer({
    required this.brand,
    required this.userName,
    required this.userPhone,
    required this.warehouseLabel,
    required this.isReadonly,
    required this.onLogout,
    required this.initials,
    required this.now,
    required this.locationText,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFF5F5F7);
    const Color surface = Colors.white;

    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEE, d MMM').format(now);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.72,
      child: Drawer(
        backgroundColor: background,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              decoration: BoxDecoration(
                color: surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-width logo
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/drawerlogo.png',
                      height: 44,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (context, error, stackTrace) {
                        return Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 28,
                              color: brand,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DeoDap Staff Packaging',
                              style: TextStyle(
                                color: brand,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  // User details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty
                                  ? userName
                                  : 'DeoDap Employee',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (userPhone.isNotEmpty)
                              Text(
                                userPhone,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            if (warehouseLabel.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brand.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    warehouseLabel,
                                    style: TextStyle(
                                      color: brand,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.time,
                                  size: 14,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '• $dateStr',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            if (locationText != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    CupertinoIcons.location_solid,
                                    size: 14,
                                    color: Colors.black45,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationText!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (isReadonly) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 12,
                                      color: Colors.orange[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Readonly Mode',
                                      style: TextStyle(
                                        color: Colors.orange[400],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: brand,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerMenuItem(
                    icon: CupertinoIcons.square_grid_2x2,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: CupertinoIcons.person_crop_circle,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.profile);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: CupertinoIcons.qrcode_viewfinder,
                    title: 'QR Scanner',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.qrScanner);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.analytics_outlined,
                    title: 'Reports',
                    onTap: () {
                      Navigator.pop(context);
                      Get.snackbar(
                        'Coming Soon',
                        'Reports feature',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: surface,
                        colorText: Colors.black87,
                      );
                    },
                  ),
                  const Divider(
                    height: 24,
                    thickness: 0.4,
                    color: Colors.black12,
                  ),
                  _DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.settings);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.privacyPolicy);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.termconditions);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.info_outline,
                    title: 'How It Works',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.HowItWorksScreen);
                    },
                  ),
                ],
              ),
            ),

            // Logout + version footer (compact)
            const Divider(height: 1, thickness: 0.4, color: Colors.black12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    minLeadingWidth: 0,
                    horizontalTitleGap: 8,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    tileColor: surface,
                    leading: const Icon(Icons.logout,
                        color: Colors.redAccent, size: 20),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$appVersion • Powered by DeoDap',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// =====================
// DRAWER MENU ITEM
// =====================

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      hoverColor: Colors.black.withOpacity(0.03),
    );
  }
}

// =====================
// QUICK TILE
// =====================

class _HomeQuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _HomeQuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.03),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
