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

  static const String _appVersion = 'v1.0.0';

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

  // -----------------------
  // COMMON SNACKBAR HELPER
  // -----------------------
  void _showSnack(
    String message, {
    String? title,
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title != null ? '$title\n$message' : message,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.black87,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // -----------------------
  // SESSION / SECURITY
  // -----------------------
  Future<void> _loadSession() async {
    final p = await SharedPreferences.getInstance();
    final isLoggedIn = p.getBool('isLoggedIn') ?? false;

    // Basic security: if user is not logged in, push back to Login
    if (!isLoggedIn) {
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.login);
      return;
    }

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
          'Are you sure you want to sign out from your account?',
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
            child: const Text('Sign out'),
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
    _showSnack('You have been logged out securely.');
    Get.offAllNamed(AppRoutes.login);
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
    setState(() {
      _locationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationText = 'Location services disabled';
          });
          _showSnack(
            'Location services are turned off. Please enable GPS to see your current location.',
            isError: true,
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Location permission denied';
          });
          _showSnack(
            'Location permission denied. You can enable it from app settings.',
            isError: true,
          );
        }
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

      if (!mounted) return;
      setState(() {
        _locationText = formatted;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationText = 'Location unavailable';
      });
      _showSnack(
        'Unable to fetch location. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Brand colors
    const Color brand = Color(0xFF0A3D91);
    const Color background = Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: background,
      drawer: _HomeDrawer(
        brand: brand,
        userName: _userName,
        userPhone: _userPhone,
        warehouseLabel: _warehouseLabel,
        isReadonly: _isReadonly,
        onLogout: _logout,
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
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
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
                                    'Staff Packaging App',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Profile button – only profile image (no initials)
                                  GestureDetector(
                                    onTap: () {
                                      Get.toNamed(AppRoutes.profile);
                                    },
                                    child: const _ProfileAvatar(
                                      radius: 18,
                                      brand: brand,
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
                              const SizedBox(height: 12),
                              // Warehouse + Location chip row
                              Row(
                                children: [
                                  if (_warehouseLabel.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: brand.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.cube_box,
                                            size: 14,
                                            color: brand,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _warehouseLabel,
                                            style: TextStyle(
                                              color: brand,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_warehouseLabel.isNotEmpty)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _LocationChip(
                                        loading: _locationLoading,
                                        locationText: _locationText,
                                        onRetry: _fetchLocation,
                                      ),
                                    ),
                                  ),
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
                              ),
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
}

// =====================
// PROFILE AVATAR WIDGET
// =====================

class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final Color brand;

  const _ProfileAvatar({
    super.key,
    required this.radius,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: brand,
      child: ClipOval(
        child: Image.asset(
          'assets/images/profile.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              CupertinoIcons.person_fill,
              color: Colors.white,
              size: radius,
            );
          },
        ),
      ),
    );
  }
}

// =====================
// LOCATION CHIP
// =====================

class _LocationChip extends StatelessWidget {
  final bool loading;
  final String? locationText;
  final VoidCallback onRetry;

  const _LocationChip({
    super.key,
    required this.loading,
    required this.locationText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final text = locationText;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: !loading ? onRetry : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.location_solid,
              size: 14,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Flexible(
                child: Text(
                  text ?? 'Tap to fetch location',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================
// HEADER
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
            fontSize: 26,
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
        const SizedBox(height: 14),
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

  const _QRScannerSection({
    required this.brand,
    required this.surface,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Scanner',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scan products for inventory & packaging',
                      style: TextStyle(
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
              margin: const EdgeInsets.all(12),
              backgroundColor: surface,
              colorText: Colors.black87,
              borderRadius: 12,
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
              'Inward / Outward feature',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(12),
              backgroundColor: surface,
              colorText: Colors.black87,
              borderRadius: 12,
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
                      _ProfileAvatar(
                        radius: 20,
                        brand: brand,
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
                    icon: CupertinoIcons.person,
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
                        margin: const EdgeInsets.all(12),
                        backgroundColor: surface,
                        colorText: Colors.black87,
                        borderRadius: 12,
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
