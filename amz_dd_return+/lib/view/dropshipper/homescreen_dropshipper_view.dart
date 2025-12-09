import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Import all dropshipper screens
import 'package:amz/common/contact_screen_view.dart';
import 'package:amz/view/dropshipper/dropshipper_addreturn_order_view.dart';
import 'package:amz/view/dropshipper/dropshipper_show_orderscreen_view.dart';
import 'package:amz/view/dropshipper/dropshipper_userdetailsscreen_view.dart';
import 'package:amz/view/dropshipper/loginscreen_dropshipper_view.dart';
import 'package:amz/view/updatescreen_view.dart';
import 'package:amz/common/about_screen.dart';
import 'package:amz/view/dropshipper/SettingScreendropshipper.dart';
import 'package:amz/view/dropshipper/dropshipper_completedstatus_order.dart';
import 'package:amz/view/dropshipper/scanneddata_report.dart';
import 'package:amz/view/dropshipper/dropshippper_help.dart';
import 'package:amz/view/dropshipper/scanneddata.dart';
import 'package:amz/view/dropshipper/dropshipper_updated_order.dart';
import 'package:amz/view/dropshipper/dropshipper_WrongOtpscreen.dart';
import 'package:amz/view/dropshipper/dropshipper_notaclaimorder.dart';
import 'package:amz/widgets/update_dialog.dart';

class HomescreenDropshipperView extends StatefulWidget {
  const HomescreenDropshipperView({super.key});

  @override
  State<HomescreenDropshipperView> createState() => _HomescreenDropshipperViewState();
}

class _HomescreenDropshipperViewState extends State<HomescreenDropshipperView> {
  // Original dropshipper state variables
  String sellerId = '';
  String sellerName = '';
  String contactNumber = '';
  String crn = '';
  String storeName = '';
  String username = '';
  String appVersion = "1.1.1";
  Map<String, dynamic>? sellerData;
  String? errorMessage;
  bool isLoading = true;

  // UI state variables
  int unseenNotificationCount = 0;
  File? _avatarImage;
  final ScrollController _scrollController = ScrollController();

  // API endpoints (original dropshipper endpoints)
  static const String _baseUrl = 'https://customprint.deodap.com/api_amzDD_return';
  static const String _notificationEndpoint = '$_baseUrl/get_notification_.php';
  static const String _ordersEndpoint = '$_baseUrl/dropshipper_totalcount_order.php';
  static const String _updateEndpoint = '$_baseUrl/checkupdate.php';
  static const String _markNotificationReadEndpoint = '$_baseUrl/get_notification.php';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
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

  Future<void> _loadUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          sellerId = prefs.getString('seller_id') ?? '';
          sellerName = prefs.getString('seller_name') ?? 'N/A';
          contactNumber = prefs.getString('contact_number') ?? 'N/A';
          crn = prefs.getString('crn') ?? 'N/A';
          storeName = prefs.getString('store_name') ?? 'N/A';
          username = prefs.getString('username') ?? 'N/A';
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

  Future<void> fetchOrders() async {
    try {
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
        Uri.parse("$_ordersEndpoint?seller_id=$sellerId"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            isLoading = false;
            sellerData = data['data'] ?? {};
            errorMessage = null;
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

  Future<void> _checkAppVersion() async {
    try {
      final response = await http.post(
        Uri.parse(_updateEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'version': appVersion, 'role': 'dropshipper'},
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

  Widget _buildCleanContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: child,
    );
  }

  Widget _buildOrderCard(
      String title,
      String count,
      Color primaryColor,
      IconData icon, {
        VoidCallback? onTap,
        String? subtitle,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            HapticFeedback.lightImpact();
            onTap();
          }
        },
        child: _buildCleanContainer(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        // Welcome section shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: _buildCleanContainer(
            width: double.infinity,
            height: 120,
            child: Container(),
          ),
        ),
        const SizedBox(height: 20),

        // Quick actions shimmer
        Row(
          children: List.generate(2, (index) => Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: _buildCleanContainer(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                height: 120,
                child: Container(),
              ),
            ),
          )),
        ),
        const SizedBox(height: 20),

        // Stats cards shimmer
        ...List.generate(2, (rowIndex) => Column(
          children: [
            Row(
              children: List.generate(3, (index) => Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: _buildCleanContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 120,
                    child: Container(),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 12),
          ],
        )),
      ],
    );
  }

  Future<void> _performLogout() async {
    HapticFeedback.mediumImpact();
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red[600],
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreenDropshipperView()),
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error during logout: $e');
        _showErrorSnackBar('Logout failed. Please try again.');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0), // Dark blue
      elevation: 0,
      title: Text(
        "Dashboard",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Profile Header
          Container(
            height: 180,
            padding: const EdgeInsets.only(top: 35, bottom: 15, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1565C0),
                  const Color(0xFF1976D2),
                  const Color(0xFF1E88E5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: _avatarImage != null
                            ? FileImage(_avatarImage!)
                            : const AssetImage('assets/images/man.jpeg') as ImageProvider,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Deodap Dropshipper',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sellerName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'CRN: $crn',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  contactNumber,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
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
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerSection('Dashboard', [
                  _buildDrawerItem(
                    Icons.home_rounded,
                    'Home',
                        () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    Icons.person_rounded,
                    'User Details',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DropshipperUserdetailsscreenView()),
                    ),
                  ),
                ]),

                _buildDrawerSection('Order Management', [
                  _buildDrawerItem(
                    Icons.shopping_bag_rounded,
                    'View Orders',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DropshipperShowOrderscreenView()),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.assignment_return_rounded,
                    'Add Return Order',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DropshipperAddreturnOrderView()),
                    ),
                  ),
                
                ]),

                _buildDrawerSection('Tools & Settings', [
                  _buildDrawerItem(
                    Icons.settings_rounded,
                    'Settings',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingscreenDropshipperView()),
                    ),
                  ),
                 
                  
                  _buildDrawerItem(
                    Icons.contact_support_outlined,
                    'Get In Touch',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ContactScreenView()),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.assessment_rounded,
                    'Report',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DropReport()),
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

              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Developed by',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Keval Kateshiya',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deodap International Pvt Ltd',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version $appVersion',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
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

  Widget _buildDrawerItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isLogout = false,
      }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFF1565C0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red[600] : const Color(0xFF1565C0),
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isLogout ? Colors.red[600] : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildBody() {
    return isLoading
        ? Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildShimmer(),
    )
        : errorMessage != null
        ? _buildErrorState()
        : RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.blue[800],
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 20),
            _buildQuickActionsSection(),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildCleanContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Unknown error occurred',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _refreshData();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _initializeData();
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return _buildCleanContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sellerName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: 12,
                            color: const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            storeName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  size: 24,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Colors.green[600],
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  "Here's your business overview for today",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[700],
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

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildRectangularActionCard(
          title: "Add Return",
          subtitle: "Process returns",
          icon: Icons.assignment_return_rounded,
          color: Colors.pink[600]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DropshipperAddreturnOrderView()),
          ),
        ),
      ],
    );
  }

  Widget _buildRectangularActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

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
                fontSize: 18,
                color: Colors.black87,
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
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF1565C0),
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
                HapticFeedback.lightImpact();
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
                    MaterialPageRoute(builder: (context) => const DropReport()),
                  );

                }
              },
              itemBuilder: (BuildContext context) => [
                _buildAnimatedPopupMenuItem(
                  'Today Orders',
                  '${sellerData?['total_orders'] ?? 0}',
                  Icons.shopping_bag_rounded,
                  const Color(0xFF1565C0),
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
                  'Reports',
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
        const SizedBox(height: 12),

        // Second row
        Row(
          children: [
            _buildOrderCard(
              "Pending",
              "${sellerData?['pending'] ?? 0}",
              Colors.amber[600]!,
              Icons.pending_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DropshipperShowOrderscreenView()),
              ),
            ),
            _buildOrderCard(
              "Completed",
              "${sellerData?['completed'] ?? 0}",
              Colors.green[600]!,
              Icons.check_circle_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DropshipperCompletedstatusOrder()),
              ),
            ),
            _buildOrderCard(
              "Updated",
              "${sellerData?['updated'] ?? 0}",
              Colors.deepOrange[600]!,
              Icons.update_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UpdatedOrdersScreen(sellerId: sellerId)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Third row
        Row(
          children: [
            _buildOrderCard(
              "Wrong OTP",
              "${sellerData?['wrongotp'] ?? 0}",
              Colors.red[600]!,
              Icons.error_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DropshipperwrongotporderView()),
              ),
            ),
            _buildOrderCard(
              "Not A Claim",
              "${sellerData?['notaclaim'] ?? 0}",
              Colors.indigo[600]!,
              Icons.block_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DropshippernotclaimorderView()),
              ),
            ),
            // Third card for visual balance
            Expanded(
              child: _buildCleanContainer(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.teal[600],
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Analytics',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Business Insights Section
        _buildCleanContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: const Color(0xFF1565C0),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Business Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Performance indicators
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      'Today\'s Performance',
                      '${((sellerData?['total_scanned_today'] ?? 0) / (sellerData?['total_orders'] ?? 1) * 100).toStringAsFixed(1)}%',
                      Icons.trending_up_rounded,
                      Colors.green[600]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      'Success Rate',
                      '${((sellerData?['completed'] ?? 0) / (sellerData?['total_orders'] ?? 1) * 100).toStringAsFixed(1)}%',
                      Icons.check_circle_outline_rounded,
                      const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1565C0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }
}