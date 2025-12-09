import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:package_info_plus/package_info_plus.dart';
// Import all necessary screens
import 'package:amz/common/contact_screen_view.dart';
import 'package:amz/view/employee/dropshipper_registration_screen.dart';
import 'package:amz/view/employee/dropshipper_generated_details_screen.dart';
import 'package:amz/view/employee/employee_userdetailsscreen_view.dart';
import 'package:amz/view/employee/emp_help.dart';
import 'package:amz/view/employee/employee_orderscan_screenview.dart';
import 'package:amz/view/employee/report.dart';
import 'package:amz/view/employee/scan_another_trackingID.dart';
import 'package:amz/view/employee/setting_screen_employee.dart';
import 'package:amz/view/employee/Updated_order_list.dart';
import 'package:amz/view/employee/notifications.dart';
import 'package:amz/view/onboardingscreen_view.dart';
import 'package:amz/view/updatescreen_view.dart';
import 'package:amz/view/employee/wrong_otp_order_screen.dart';
import 'package:amz/view/employee/nota_claim_order.php.dart';
import 'package:amz/view/employee/EditCompletedOrderScreen.dart';
import 'package:amz/view/employee/only_completedorder.dart';
import 'package:amz/widgets/update_dialog.dart';

class HomescreenEmployeeView extends StatefulWidget {
  const HomescreenEmployeeView({super.key});

  @override
  State<HomescreenEmployeeView> createState() => _HomescreenEmployeeViewState();
}

class _HomescreenEmployeeViewState extends State<HomescreenEmployeeView> {
  // State variables
  String userId = '';
  String sellerName = '';
  String contactNumber = '';
  Map<String, dynamic>? sellerData;
  String? errorMessage;
  bool isLoading = true;
  String appVersion = "1.1.1";
  String searchText = '';
  int unseenNotificationCount = 0;
  List<dynamic> originalOrderList = [];
  List<dynamic> filteredOrderList = [];
  File? _avatarImage;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // API endpoints
  static const String _baseUrl = 'https://customprint.deodap.com/api_amzDD_return';
  static const String _notificationEndpoint = '$_baseUrl/get_notification_.php';
  static const String _ordersEndpoint = '$_baseUrl/total_sallercountdata.php';
  static const String _updateEndpoint = '$_baseUrl/checkupdate.php';
  static const String _markNotificationReadEndpoint = '$_baseUrl/get_notification.php';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadAppVersion(),
      _loadUserDetails(),
      fetchOrders(),
      _fetchNotificationCount(),
      _checkAppVersion(),
    ]);
  }

  /// Load app version from package info
  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  /// Loads user details from shared preferences with error handling
  Future<void> _loadUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          userId = prefs.getString('userId') ?? 'N/A';
          sellerName = prefs.getString('admin_email') ?? 'N/A';
          contactNumber = prefs.getString('contact_number') ?? 'N/A';
          final avatarPath = prefs.getString('profile_image_path');
          if (avatarPath != null && File(avatarPath).existsSync()) {
            _avatarImage = File(avatarPath);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  /// Enhanced image picker with error handling and validation
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

  /// Fetches notification count with improved error handling
  Future<void> _fetchNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse(_notificationEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            unseenNotificationCount = data['unseen_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  /// Enhanced order fetching with better error handling
  Future<void> fetchOrders() async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          setState(() {
            errorMessage = "No internet connection available";
            isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse(_ordersEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            isLoading = false;
            sellerData = data['data'] ?? {};
            errorMessage = null;
            originalOrderList = data['data']?['orders'] ?? [];
            filteredOrderList = originalOrderList;
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
          errorMessage = "Network error. Please check your connection.";
          isLoading = false;
        });
      }
    }
  }

  /// App version check with improved error handling
  Future<void> _checkAppVersion() async {
    try {
      final response = await http.post(
        Uri.parse(_updateEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'version': appVersion, 'role': 'employee'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          _showUpdateDialog(data);
        }
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
    }
  }

  /// Enhanced update dialog using custom UpdateDialog widget
  void _showUpdateDialog(Map<String, dynamic> updateData) {
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: updateData['is_mandatory'] != true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => UpdateDialog(
        imageUrl: updateData['image_url'] ?? '',
        currentVersion: appVersion,
        latestVersion: updateData['latest_version'] ?? 'Unknown',
        title: updateData['update_title'] ?? 'Update Available',
        description: updateData['update_description'] ?? 'A new version of the app is available with exciting features and improvements.',
        isMandatory: updateData['is_mandatory'] ?? true,
        onUpdatePressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpdateScreenView()),
          );
        },
        onLaterPressed: updateData['is_mandatory'] != true ? () {
          Navigator.pop(context);
        } : null,
      ),
    );
  }

  /// Clean order statistics card
  Widget _buildOrderCard(String label, String count, Color color, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
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

  /// Enhanced shimmer loading with modern design
  Widget _buildShimmer() {
    return Column(
      children: [
        // Welcome section shimmer
        Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.blue.withOpacity(0.1),
              highlightColor: Colors.blue.withOpacity(0.2),
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: Colors.blue,
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
                    baseColor: Colors.blue.withOpacity(0.1),
                    highlightColor: Colors.blue.withOpacity(0.2),
                    child: Container(
                      height: 20,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.blue.withOpacity(0.1),
                    highlightColor: Colors.blue.withOpacity(0.2),
                    child: Container(
                      height: 16,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue,
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

        // Stats cards shimmer
        ...List.generate(2, (rowIndex) => Column(
          children: [
            Row(
              children: List.generate(3, (index) => Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.blue.withOpacity(0.1),
                  highlightColor: Colors.blue.withOpacity(0.2),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 16),
          ],
        )),
      ],
    );
  }

  /// Enhanced notification management
  Future<void> _handleNotificationTap() async {
    try {
      // Mark notifications as read
      await http.post(Uri.parse(_markNotificationReadEndpoint));
      setState(() => unseenNotificationCount = 0);

      // Navigate to notifications
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotificationScreen()),
      );

      // Refresh notification count after returning
      await _fetchNotificationCount();
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Enhanced logout functionality
  Future<void> _performLogout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Logout',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access your dashboard.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => OnboardingscreenView()),
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error during logout: $e');
        _showErrorSnackBar('Logout failed. Please try again.');
      }
    }
  }

  /// Success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  /// Clean dark blue app bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0), // Dark blue
      elevation: 0,
      title: Text(
        "admin Dashboard",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Notification icon
        Stack(
          children: [
            IconButton(
              onPressed: _handleNotificationTap,
              icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              tooltip: 'Notifications',
            ),
            if (unseenNotificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unseenNotificationCount > 9 ? '9+' : '$unseenNotificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // Profile avatar
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _avatarImage != null
                  ? FileImage(_avatarImage!)
                  : const AssetImage('assets/images/man.jpeg') as ImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  /// Enhanced drawer with white theme
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildDrawerSection('Dashboard', [
                    _buildDrawerItem(
                      Icons.home_rounded,
                      'Home',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HomescreenEmployeeView()),
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.person_rounded,
                      'User Details',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmployeeUserdetailsscreenView()),
                      ),
                    ),
                  ]),

                  _buildDrawerSection('Dropshipper Management', [
                    _buildDrawerItem(
                      Icons.how_to_reg_rounded,
                      'Register Dropshipper',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DropshipperRegisterScreen()),
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.assignment_ind_rounded,
                      'View All Dropshippers',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DropshipperGeneratedDetailsScreen()),
                      ),
                    ),
                  ]),

                  _buildDrawerSection('Tools & Settings', [
                    _buildDrawerItem(
                      Icons.settings_rounded,
                      'Settings',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>  eSettingscreenDropshipperView ()),
                      ),
                    ),


                    _buildDrawerItem(
                      Icons.contact_support_rounded,
                      'Get In Touch',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ContactScreenView()),
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.auto_graph_rounded,
                      'Generate Report',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Report()),
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.refresh_rounded,
                      'Refresh Data',
                          () async {
                        Navigator.pop(context);
                        setState(() => isLoading = true);
                        await _initializeData();
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.blue.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDrawerItem(
                    Icons.logout_rounded,
                    'Logout',
                    _performLogout,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact drawer header with profile details next to image
  Widget _buildDrawerHeader() {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade800,
            Colors.blue.shade700,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 37,
                  backgroundImage: _avatarImage != null
                      ? FileImage(_avatarImage!)
                      : const AssetImage('assets/images/man.jpeg') as ImageProvider,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Profile Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Deodap Admin',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    sellerName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Verified Employee',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.white.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        contactNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
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

  /// Drawer section with title
  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.blue[800],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  /// Enhanced drawer item with white background theme
  Widget _buildDrawerItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isLogout = false,
        bool showBadge = false,
        int badgeCount = 0,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLogout
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue[800]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        icon,
                        color: isLogout ? Colors.red[600] : Colors.blue[800],
                        size: 20,
                      ),
                      if (showBadge && badgeCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isLogout ? Colors.red[600] : Colors.blue[800],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isLogout
                      ? Colors.red[600]!.withOpacity(0.5)
                      : Colors.blue[800]!.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean main body layout
  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? _buildShimmer()
            : errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.blue[800],
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildQRScannerSection(),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Enhanced error state with blue theme
  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.1),
              Colors.red.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red.shade300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refresh data function
  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _initializeData();
  }

  /// Dynamic welcome section with time-based greetings
  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    IconData greetingIcon;
    Color greetingColor;
    
    if (hour >= 5 && hour < 12) {
      greeting = "Good Morning";
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = Colors.orange;
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
      greetingIcon = Icons.wb_sunny_outlined;
      greetingColor = Colors.amber;
    } else if (hour >= 17 && hour < 21) {
      greeting = "Good Evening";
      greetingIcon = Icons.wb_twilight_rounded;
      greetingColor = Colors.deepOrange;
    } else {
      greeting = "Good Night";
      greetingIcon = Icons.nightlight_round;
      greetingColor = Colors.indigo;
    }
    
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            greetingIcon,
            color: greetingColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$greeting, Mr. Deodap Employee",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.grey[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.grey[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${now.day}/${now.month}/${now.year}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
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

  /// Clean stats section
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Order Statistics",
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            PopupMenuButton<String>(
              icon: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A365D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF1A365D),
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 40),
              onSelected: (String value) {
                switch (value) {
                  case 'total_orders':
                    break;
                  case 'today_scan':
                    break;
                  case 'tracking_ids':
                    break;
                  case 'report':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Report()),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                _buildAnimatedPopupMenuItem(
                  'Total Orders',
                  '${sellerData?['total_orders'] ?? 0}',
                  Icons.shopping_bag_rounded,
                  const Color(0xFF1A365D),
                  0,
                  'total_orders',
                ),
                _buildAnimatedPopupMenuItem(
                  "Today's Scan",
                  '${sellerData?['today_scan'] ?? 0}',
                  Icons.qr_code_scanner_rounded,
                  Colors.cyan[600]!,
                  1,
                  'today_scan',
                ),
                _buildAnimatedPopupMenuItem(
                  'Tracking IDs',
                  '${sellerData?['total_tracking_ids'] ?? 0}',
                  Icons.track_changes_rounded,
                  Colors.indigo[600]!,
                  2,
                  'tracking_ids',
                ),
                _buildAnimatedPopupMenuItem(
                  'Generate Report',
                  '',
                  Icons.insert_drive_file_rounded,
                  Colors.deepPurple[400]!,
                  3,
                  'report',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // First row - Status stats
        Row(
          children: [
            _buildOrderCard(
              "Pending",
              "${sellerData?['total_pending'] ?? 0}",
              Colors.amber,
              Icons.pending_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EmployeeOrderscanScreenview()),
              ),
            ),
            _buildOrderCard(
              "Completed",
              "${sellerData?['total_completed'] ?? 0}",
              Colors.green,
              Icons.check_circle_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  OnlyCompletedorder()),
              ),
            ),
            _buildOrderCard(
              "Updated",
              "${sellerData?['total_updated'] ?? 0}",
              Colors.deepOrange,
              Icons.update_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UpdatedOrdersScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Third row - Special status
        Row(
          children: [
            _buildOrderCard(
              "Wrong OTP",
              "${sellerData?['otp_status_wrong'] ?? 0}",
              Colors.red,
              Icons.error_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WrongOtpOrderScreen()),
              ),
            ),
            _buildOrderCard(
              "Not A Claim",
              "${sellerData?['otp_status_notaclaim'] ?? 0}",
              Colors.blueGrey,
              Icons.not_accessible_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotAClaimOrderScreen()),
              ),
            ),
            // Empty space for symmetry
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  /// Clean QR scanner section
  Widget _buildQRScannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Scanner",
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQRScannerButton(
                      "Scan Pending Orders",
                      Icons.qr_code_scanner_rounded,
                      Colors.orange,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ScanAnotherTrackingid()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQRScannerButton(
                      "Scan Completed Orders",
                      Icons.qr_code_scanner_rounded,
                      Colors.green,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditCompletedOrderScreen ()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tip: Use the scanner to quickly update order status",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blue[700],
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
      ],
    );
  }

  /// Clean QR scanner button
  Widget _buildQRScannerButton(
      String title,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Animated popup menu item for 3-dot menu
  PopupMenuItem<String> _buildAnimatedPopupMenuItem(
    String title,
    String count,
    IconData icon,
    Color color,
    int index,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOutBack,
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - animationValue), 0),
            child: Opacity(
              opacity: animationValue.clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (count.isNotEmpty)
                            Text(
                              count,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}