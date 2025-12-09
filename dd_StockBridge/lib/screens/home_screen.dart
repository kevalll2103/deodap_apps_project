import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'onboarding_screen.dart';
import 'oms_all_order.dart';
import 'user_registration.dart';
import 'user_details.dart';
import 'report.dart';
import 'inward_sku.dart';
import 'setting_screen.dart';
import 'admin_profile_screen.dart';
import 'app_info.dart';
import 'qr_inward.dart';
import 'qr_outward.dart';
import 'oms_daily_order.dart';
import 'stock_list.dart';
import 'low_stock.dart';
import 'shopfiy_daily_order.dart';
import 'shopify_order.dart';
import 'home_screen.dart';
import 'all_picked_order.dart';
import 'picked_order_employee.dart';
import 'inward_sku_warehouse_staff.dart';

class empHomeScreen extends StatefulWidget {
  const empHomeScreen({super.key});

  @override
  State<empHomeScreen> createState() => _empHomeScreenState();
}

class _empHomeScreenState extends State<empHomeScreen> {
  // ===================== STATE =====================
  String userId = '';
  String sellerName = '';
  String contactNumber = '';
  String _role = 'employee'; // admin / employee
  bool get _isAdmin => _role == 'admin';
  bool get _isEmployee => _role == 'employee';

  Map<String, dynamic>? sellerData;
  String? errorMessage;
  bool isLoading = true;
  String appVersion = '1.0.0';
  String searchText = '';
  List<dynamic> originalOrderList = [];
  List<dynamic> filteredOrderList = [];
  File? _avatarImage;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Live time
  DateTime _now = DateTime.now();
  Timer? _timer;

  // Drawer
  bool _isDrawerOpen = false;

  // ===================== API CONFIG =====================
  static const String _baseUrl = 'https://customprint.deodap.com/stockbridge';
  static const String _ordersEndpoint = '$_baseUrl/total_count.php';
  static const String _updateEndpoint = '$_baseUrl/checkupdate.php'; // reserved

  // ===================== INIT / DISPOSE =====================
  @override
  void initState() {
    super.initState();
    _initializeData();
    _startClock();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ===================== COMMON TEXT STYLE =====================
  TextStyle _poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: TextDecoration.none,
    );
  }

  // Live clock
  void _startClock() {
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _loadAppVersion(),
        _loadUserDetails(),
        fetchOrders(),
      ]);
    } catch (e) {
      debugPrint('Error in _initializeData: $e');
    }
  }

  // ===================== LOADERS =====================
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      _role = prefs.getString('role') ?? 'employee';

      final storedUserId = prefs.getString('admin_id') ??
          prefs.getString('employee_id') ??
          prefs.getString('user_id') ??
          'N/A';

      String name = prefs.getString('name') ??
          prefs.getString('admin_name') ??
          'Employee';

      final phone = prefs.getString('contact_number') ??
          prefs.getString('admin_contact') ??
          'N/A';

      final email = prefs.getString('employee_email') ?? '';

      if (name.toLowerCase() == 'employee' && email.isNotEmpty) {
        name = email.split('@').first;
      }

      final avatarPath = prefs.getString('profile_image_path');
      File? avatarFile;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        final file = File(avatarPath);
        if (file.existsSync()) avatarFile = file;
      }

      setState(() {
        userId = storedUserId;
        sellerName = name;
        contactNumber = phone;
        _avatarImage = avatarFile;
      });
    } catch (e) {
      debugPrint('Error loading user details: $e');
      if (mounted) {
        setState(() {
          sellerName = 'Employee';
          contactNumber = 'N/A';
        });
      }
    }
  }

  Future<void> fetchOrders() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          setState(() {
            errorMessage = 'No internet connection available';
            isLoading = false;
          });
        }
        return;
      }

      final response = await http
          .get(
            Uri.parse(_ordersEndpoint),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              errorMessage = 'Unexpected response from server';
              isLoading = false;
            });
          }
          return;
        }

        final data = decoded;
        if (data['success'] == true && data['data'] != null && mounted) {
          final total = (data['data']['total'] ?? {}) as Map<String, dynamic>;
          final today = (data['data']['today'] ?? {}) as Map<String, dynamic>;

          final flattened = <String, dynamic>{
            'total_oms_orders': total['oms_orders'] ?? 0,
            'total_shopify_orders': total['shopify_orders'] ?? 0,
            'total_combined_orders': total['combined_orders'] ?? 0,
            'total_employees': total['employees'] ?? 0,
            'total_oms_stock': total['oms_stock'] ?? 0,
            'oms_orders_today': today['oms_orders_today'] ?? 0,
            'shopify_orders_today': today['shopify_orders_today'] ?? 0,
            'combined_orders_today': today['combined_orders_today'] ?? 0,
            'employees_today': today['employees_today'] ?? 0,
            'oms_stock_today': today['oms_stock_today'] ?? 0,
          };

          setState(() {
            isLoading = false;
            sellerData = flattened;
            errorMessage = null;
            originalOrderList = const [];
            filteredOrderList = const [];
          });
        } else {
          if (mounted) {
            setState(() {
              errorMessage = data['message'] ?? 'Failed to load data';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Server error: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Network error. Please check your connection.';
          isLoading = false;
        });
      }
    }
  }

  // ===================== SNACKBARS =====================
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: CupertinoColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: _poppins(fontSize: 16, color: CupertinoColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: CupertinoColors.activeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: _poppins(fontSize: 16, color: CupertinoColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: CupertinoColors.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ===================== LOGOUT =====================
  Future<void> _performLogout() async {
    final confirmLogout = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title:
            Text('Confirm Logout', style: _poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to sign out?',
          style: _poppins(fontSize: 14, color: CupertinoColors.systemGrey),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: _poppins()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout', style: _poppins()),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => Onboardingscreen()),
          (route) => false,
        );
      } catch (e) {
        debugPrint('Error during logout: $e');
        _showErrorSnackBar('Logout failed. Please try again.');
      }
    }
  }

  // ===================== IMAGE PICKER =====================
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', pickedFile.path);
        if (mounted) {
          setState(() => _avatarImage = File(pickedFile.path));
        }
        _showSuccessSnackBar('Profile image updated successfully');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to update profile image');
    }
  }

  // ===================== REFRESH =====================
  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _initializeData();
  }

  // ===================== DRAWER =====================
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
      });
    }
  }

  void _navigateFromDrawer(Widget page) {
    _closeDrawer();
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => page),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: _poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildDrawer(double width) {
    return SafeArea(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _avatarImage != null
                        ? FileImage(_avatarImage!)
                        : const AssetImage('assets/images/admin.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sellerName.isEmpty
                              ? 'Hi, Employee'
                              : 'Hi, $sellerName',
                          style: _poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contactNumber,
                          style: _poppins(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v$appVersion · ${_isAdmin ? 'Admin' : 'Employee'}',
                          style: _poppins(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // MENU
            Expanded(
              child: CupertinoScrollbar(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // DASHBOARD & PROFILE
                    _drawerSectionTitle('Dashboard & Profile'),
                    _buildDrawerItem(
                      icon: CupertinoIcons.house_fill,
                      label: 'Home',
                      onTap: _closeDrawer,
                    ),
                    _buildDrawerItem(
                      icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                      label: _isAdmin ? 'Admin Profile' : 'Employee Profile',
                      onTap: () => _navigateFromDrawer(ProfileScreen()),
                    ),

                    // ORDERS & PICKING
                    _drawerSectionTitle('Orders & Picking'),
                    _buildDrawerItem(
                      icon: CupertinoIcons.mail,
                      label: 'Daily OMS Orders',
                      onTap: () =>
                          _navigateFromDrawer(OMSDailyOrdersScreen()),
                    ),
                    _buildDrawerItem(
                      icon: CupertinoIcons.mail,
                      label: 'Daily Shopify Orders',
                      onTap: () =>
                          _navigateFromDrawer(ShopifyOrdersdailyScreen()),
                    ),
                    if (_isEmployee)
                      _buildDrawerItem(
                        icon: CupertinoIcons.check_mark_circled,
                        label: 'My Picked Orders',
                        onTap: () => _navigateFromDrawer(
                          myPickedOrdersScreen(),
                        ),
                      ),
                    if (_isAdmin)
                      _buildDrawerItem(
                        icon: CupertinoIcons.checkmark_seal_fill,
                        label: 'All Picked Orders',
                        onTap: () => _navigateFromDrawer(
                          AllEmployeePickedOrdersScreen(),
                        ),
                      ),

                    // ADMIN TOOLS
                    if (_isAdmin) ...[
                      _drawerSectionTitle('Admin Tools'),
                      _buildDrawerItem(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        label: 'Register Employee',
                        onTap: () => _navigateFromDrawer(UserRegister()),
                      ),
                      _buildDrawerItem(
                        icon: CupertinoIcons.person_3_fill,
                        label: 'View All Employees',
                        onTap: () => _navigateFromDrawer(
                          EmployeesListScreen(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: CupertinoIcons.doc_chart_fill,
                        label: 'Generate Report',
                        onTap: () => _navigateFromDrawer(Report()),
                      ),
                    ],

                    // SETTINGS & APP
                    _drawerSectionTitle('Settings & App'),
                    _buildDrawerItem(
                      icon: CupertinoIcons.gear_alt_fill,
                      label: 'Settings',
                      onTap: () => _navigateFromDrawer(setting()),
                    ),
                    _buildDrawerItem(
                      icon: CupertinoIcons.refresh,
                      label: 'Refresh Data',
                      onTap: () async {
                        _closeDrawer();
                        await _refreshData();
                      },
                    ),
                    _buildDrawerItem(
                      icon: CupertinoIcons.info_circle_fill,
                      label: 'App Info',
                      onTap: () => _navigateFromDrawer(
                        AppInfoScreenView(),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // SIGN OUT
                    _buildDrawerItem(
                      icon: CupertinoIcons.square_arrow_right,
                      label: 'Sign Out',
                      isDestructive: true,
                      onTap: () async {
                        _closeDrawer();
                        await _performLogout();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // FOOTER
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey5.withOpacity(0.8),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                'Vaclvers · OMS · Shopify · DeoDap',
                style: _poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final Color textColor =
        isDestructive ? CupertinoColors.systemRed : CupertinoColors.label;
    final Color iconColor =
        isDestructive ? CupertinoColors.systemRed : CupertinoColors.activeBlue;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: CupertinoColors.systemGrey2,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isDrawerOpen) {
          _closeDrawer();
          return false;
        }
        return true;
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemBackground.withOpacity(0.98),
          border: null,
          middle: Text(
            _isAdmin ? 'Admin Dashboard' : 'Employee Dashboard',
            style: _poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _toggleDrawer,
            child: const Icon(
              CupertinoIcons.bars,
              color: CupertinoColors.activeBlue,
              size: 24,
            ),
          ),
          trailing: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: _avatarImage != null
                  ? FileImage(_avatarImage!)
                  : const AssetImage('assets/images/admin.png')
                      as ImageProvider,
            ),
          ),
        ),
        child: Builder(
          builder: (context) {
            final width = MediaQuery.of(context).size.width * 0.75;
            return Stack(
              children: [
                _buildBody(),
                // Backdrop
                IgnorePointer(
                  ignoring: !_isDrawerOpen,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isDrawerOpen ? 1.0 : 0.0,
                    child: GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
                // Drawer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: _isDrawerOpen ? 0 : -width,
                  top: 0,
                  bottom: 0,
                  child: _buildDrawer(width),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===================== BODY =====================
  Widget _buildBody() {
    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Material(
          color: Colors.transparent,
          child: isLoading
              ? _buildShimmer()
              : errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: Colors.grey[800],
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildWelcomeSection(),
                            const SizedBox(height: 20),
                            _buildQRScannerSection(),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ===================== SHIMMER =====================
  Widget _buildShimmer() {
    return Column(
      children: [
        Row(
          children: [
            Shimmer.fromColors(
              baseColor: CupertinoColors.systemGrey4.withOpacity(0.3),
              highlightColor: CupertinoColors.systemGrey4.withOpacity(0.5),
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: CupertinoColors.systemGrey4.withOpacity(0.3),
                    highlightColor:
                        CupertinoColors.systemGrey4.withOpacity(0.5),
                    child: Container(
                      height: 20,
                      width: 200,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey4,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: CupertinoColors.systemGrey4.withOpacity(0.3),
                    highlightColor:
                        CupertinoColors.systemGrey4.withOpacity(0.5),
                    child: Container(
                      height: 16,
                      width: 150,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey4,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ...List.generate(
          2,
          (rowIndex) => Column(
            children: [
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Shimmer.fromColors(
                      baseColor: CupertinoColors.systemGrey4.withOpacity(0.3),
                      highlightColor:
                          CupertinoColors.systemGrey4.withOpacity(0.5),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 120,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey4,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== ERROR STATE =====================
  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: CupertinoColors.systemRed.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 40,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: _poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: _poppins(
                fontSize: 15,
                color: CupertinoColors.systemRed.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(16),
              onPressed: _refreshData,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.refresh),
                  const SizedBox(width: 8),
                  Text(
                    'Try Again',
                    style: _poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WELCOME SECTION =====================
  Widget _buildWelcomeSection() {
    final now = _now;
    final hour = now.hour;

    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final displayName = sellerName.isNotEmpty ? sellerName : 'DeoDap Employee';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: CupertinoColors.systemGrey5,
            ),
            child: const Icon(
              CupertinoIcons.person_crop_circle,
              color: CupertinoColors.label,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName',
                  style: _poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.time,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: _poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateString,
                      style: _poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
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
  }

  // ===================== QR SCANNER SECTION =====================
  Widget _buildQRScannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Scanner',
          style: _poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQRScannerButton(
                      'Scan Inward',
                      CupertinoIcons.qrcode_viewfinder,
                      CupertinoColors.activeOrange,
                      () {
                        if (_isAdmin) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => const InwardSku(),
                            ),
                          );
                        } else if (_isEmployee) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) =>
                                  const InwardSkuWarehouseStaff(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Access Denied")),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQRScannerButton(
                      'Scan Outward',
                      CupertinoIcons.qrcode,
                      CupertinoColors.activeGreen,
                      () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const QROutwardScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      CupertinoIcons.lightbulb_fill,
                      color: CupertinoColors.systemYellow,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use the scanner to quickly update order status.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== QR SCANNER BUTTON =====================
  Widget _buildQRScannerButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: _poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ORDER CARD =====================
  Widget _buildOrderCard(
    String label,
    String count,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: CupertinoColors.systemGrey5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 10),
              Text(
                count,
                style: _poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: _poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== STATS POPUP DIALOG (3-dot menu) =====================
  void _showStatsSheet() {
    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: Text(
            'Order Statistics',
            style: _poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                const SizedBox(height: 6),
                _statsSheetRow(
                  title: 'Total Orders',
                  value: '${sellerData?['total_combined_orders'] ?? 0}',
                  icon: CupertinoIcons.cart_fill_badge_plus,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 8),
                _statsSheetRow(
                  title: "Today's Orders",
                  value: '${sellerData?['combined_orders_today'] ?? 0}',
                  icon: CupertinoIcons.cart_fill_badge_plus,
                  color: CupertinoColors.activeGreen,
                ),
                const SizedBox(height: 8),
                _statsSheetRow(
                  title: 'Today OMS Orders',
                  value: '${sellerData?['oms_orders_today'] ?? 0}',
                  icon: CupertinoIcons.cube_box_fill,
                  color: CupertinoColors.systemIndigo,
                ),
              ],
            ),
          ),
          actions: [
            if (_isAdmin)
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => Report()),
                  );
                },
                child: Text(
                  'Open Report',
                  style: _poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: _poppins()),
            ),
          ],
        );
      },
    );
  }

  Widget _statsSheetRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: _poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: _poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }

  // ===================== STATS SECTION =====================
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + dialog trigger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Statistics',
              style: _poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showStatsSheet,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  size: 18,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1
        Row(
          children: [
            _buildOrderCard(
              'OMS all orders',
              '${sellerData?['total_oms_orders'] ?? 0}',
              CupertinoColors.activeOrange,
              CupertinoIcons.cube_box_fill,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => OMSOrdersScreen()),
              ),
            ),
            _buildOrderCard(
              'DeoDap all orders',
              '${sellerData?['total_shopify_orders'] ?? 0}',
              CupertinoColors.systemRed,
              CupertinoIcons.cart_fill,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const ShopifyOrdersScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2
        Row(
          children: [
            _buildOrderCard(
              'OMS daily orders',
              '${sellerData?['oms_orders_today'] ?? 0}',
              CupertinoColors.activeGreen,
              CupertinoIcons.cube_box,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => OMSDailyOrdersScreen()),
              ),
            ),
            _buildOrderCard(
              'DeoDap daily orders',
              '${sellerData?['shopify_orders_today'] ?? 0}',
              CupertinoColors.systemGrey,
              CupertinoIcons.cart,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => ShopifyOrdersdailyScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3
        Row(
          children: [
            _buildOrderCard(
              'OMS SKU stock',
              '${sellerData?['total_oms_stock'] ?? 0}',
              CupertinoColors.systemIndigo,
              CupertinoIcons.cube_box_fill,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => StockHomePage()),
              ),
            ),
            _buildOrderCard(
              _isAdmin ? 'All picked orders' : 'My picked orders',
              '--',
              CupertinoColors.systemTeal,
              CupertinoIcons.checkmark_seal_fill,
              onTap: () {
                if (_isAdmin) {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => AllEmployeePickedOrdersScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => myPickedOrdersScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
