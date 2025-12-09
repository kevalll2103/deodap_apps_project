import 'dart:convert';
import 'package:flutter/material.dart' hide Notification;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'Settings.dart';
import 'about.dart';
import 'contacts.dart';
import 'profile.dart';
import 'notification.dart';
import 'dropshipper_plan.dart';
import 'account_type.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? userData;
  String currentAppVersion = '';

  // Updated Constants for new login system
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_LOGIN_TYPE = 'loginType';

  // Enhanced Modern Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color accentBlue = Color(0xFF03DAC6);
  static const Color whiteColor = Colors.white;
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color textBlack = Colors.black87;
  static const Color textGrey = Colors.black54;
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _checkUserSession();
    loadUserData();
    _initAppVersion();
  }

  // Check if user session is valid
  Future<void> _checkUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;
    final String? loginType = prefs.getString(KEY_LOGIN_TYPE);

    print(
        'DEBUG: _checkUserSession - isLoggedIn: \$isLoggedIn, loginType: \$loginType');

    // If not logged in as 'user', redirect to account selection
    if (!isLoggedIn || loginType != 'user') {
      print(
          'DEBUG: User not logged in or loginType is not user, redirecting...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountTypescreenView()),
      );
    } else {
      print('DEBUG: User session valid.');
    }
  }

  // Updated logout function
  Future<void> _logout() async {
    // Show confirmation dialog
    bool shouldLogout = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.logout, color: errorRed),
                  ),
                  const SizedBox(width: 12),
                  Text('Logout'),
                ],
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: textBlack, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: textGrey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorRed,
                    foregroundColor: whiteColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldLogout) {
      final prefs = await SharedPreferences.getInstance();

      // Clear all user data
      await prefs.clear();

      // Navigate to account type selection and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AccountTypescreenView()),
        (route) => false,
      );
    }
  }

  Future<void> _initAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        currentAppVersion = packageInfo.version;
      });

      // Check for updates after getting app version
      _checkForUpdates();
    } catch (e) {
      print('Error getting app version: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');

      if (userJson == null || currentAppVersion.isEmpty) return;

      Map<String, dynamic> userData = jsonDecode(userJson);
      String role = 'dropshipper'; // Set role based on your app logic

      final url = Uri.parse(
          "https://customprint.deodap.com/api_dropshipper_tracker/checkupdate.php");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role, // Changed from 'dropshipper' to 'role'
          'version': currentAppVersion,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          // Update available
          _showUpdateDialog(jsonResponse);
        } else if (jsonResponse['status'] == 'up_to_date') {
          // App is up to date - no dialog needed
          print('App is up to date');
        } else {
          print('Update check error: ${jsonResponse['message']}');
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        darkBlue,
                        primaryBlue,
                        accentBlue.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: whiteColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          size: 48,
                          color: whiteColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        updateInfo['update_title'] ?? 'Update Available! 🚀',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Version info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightBlue.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: primaryBlue.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Version',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      updateInfo['current_version'] ??
                                          currentAppVersion,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textBlack,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward,
                                    color: primaryBlue),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Latest Version',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      updateInfo['latest_version'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: successGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        updateInfo['update_description'] ??
                            'A new version is available with improvements and bug fixes.',
                        style: TextStyle(
                          fontSize: 15,
                          color: textBlack,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Release notes
                      if (updateInfo['release_notes'] != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: greyLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.new_releases_rounded,
                                      color: warningOrange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "What's New:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textBlack,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                updateInfo['release_notes'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textBlack,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          // Skip button (if not mandatory)
                          if (updateInfo['is_mandatory'] != true)
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Text(
                                  'Maybe Later',
                                  style: TextStyle(
                                    color: textGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),

                          if (updateInfo['is_mandatory'] != true)
                            const SizedBox(width: 12),

                          // Update button
                          Expanded(
                            flex: updateInfo['is_mandatory'] == true ? 1 : 1,
                            child: ElevatedButton.icon(
                              onPressed: () => _downloadUpdate(
                                  updateInfo['download_url'] ??
                                      updateInfo['apk_url']),
                              icon:
                                  const Icon(Icons.download_rounded, size: 20),
                              label: const Text('Update Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: whiteColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
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
        );
      },
    );
  }

  Future<void> _downloadUpdate(String? downloadUrl) async {
    if (downloadUrl == null || downloadUrl.isEmpty) {
      _showSnackBar('Download URL not available', errorRed);
      return;
    }

    try {
      final Uri url = Uri.parse(downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        Navigator.pop(context); // Close update dialog
        _showSnackBar('Download started...', successGreen);
      } else {
        _showSnackBar('Could not open download link', errorRed);
      }
    } catch (e) {
      _showSnackBar('Error downloading update: $e', errorRed);
    }
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    print('DEBUG: loadUserData - userJson: \$userJson');
    if (userJson != null) {
      setState(() {
        userData = jsonDecode(userJson);
        print('DEBUG: loadUserData - userData loaded: \$userData');
      });
    } else {
      print('DEBUG: loadUserData - userJson is null');
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      elevation: 0,
      child: Column(
        children: [
          // Enhanced Profile Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkBlue, primaryBlue, accentBlue.withOpacity(0.8)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Profile Picture
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(42.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 45,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // User Name
                    Text(
                      userData != null
                          ? userData!['seller_name'] ?? 'User'
                          : 'Loading...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Store Name
                    Text(
                      userData != null
                          ? userData!['store_name'] ?? 'Store'
                          : '',
                      style: TextStyle(
                        fontSize: 15,
                        color: whiteColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Enhanced User ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: whiteColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 16,
                            color: whiteColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ID: ${userData != null ? userData!['id'] ?? 'N/A' : 'N/A'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Items with enhanced styling
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                  isSelected: true,
                ),

                _buildDrawerItem(
                  icon: Icons.assignment_rounded,
                  title: 'Plans & Progress',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlanScreen()),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Settings()),
                    );
                  },
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),

                _buildDrawerItem(
                  icon: Icons.account_circle_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Profile()),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationScreen()),
                    );
                  },
                ),

                // Check for Updates menu item
                _buildDrawerItem(
                  icon: Icons.system_update_rounded,
                  title: 'Check for Updates',
                  onTap: () {
                    Navigator.pop(context);
                    _checkForUpdates();
                  },
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),

                // Logout menu item
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  isLogout: true,
                ),
              ],
            ),
          ),

          // Enhanced Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  greyLight.withOpacity(0.5),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Plan Tracker',
                  style: TextStyle(
                    color: textBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version $currentAppVersion',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? lightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLogout
                        ? errorRed.withOpacity(0.1)
                        : isSelected
                            ? primaryBlue
                            : primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isLogout
                        ? errorRed
                        : isSelected
                            ? whiteColor
                            : primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: isLogout
                          ? errorRed
                          : isSelected
                              ? primaryBlue
                              : textBlack,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: primaryBlue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkBlue, primaryBlue, accentBlue.withOpacity(0.8)],
          ),
        ),
      ),
      foregroundColor: whiteColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: whiteColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.analytics_rounded,
              size: 24,
              color: whiteColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Plan Tracker",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: whiteColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        // Enhanced Notification Bell
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: whiteColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: whiteColor,
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: errorRed,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: whiteColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Enhanced Menu Options
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: whiteColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: whiteColor,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 50),
            elevation: 8,
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                  'refresh', Icons.refresh_rounded, 'Refresh Data'),
              _buildPopupMenuItem('sync', Icons.sync_rounded, 'Sync'),
              _buildPopupMenuItem(
                  'update', Icons.system_update_rounded, 'Check Updates'),
              const PopupMenuDivider(),
              _buildPopupMenuItem('logout', Icons.logout, 'Logout'),
              _buildPopupMenuItem(
                  'help', Icons.help_outline_rounded, 'Help & Support'),
            ],
            onSelected: _handleMenuAction,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    value == 'logout' ? errorRed.withOpacity(0.1) : lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 18, color: value == 'logout' ? errorRed : primaryBlue),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: value == 'logout' ? errorRed : textBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'refresh':
        _showSnackBar('Refreshing data...', primaryBlue);
        break;
      case 'sync':
        _showSnackBar('Syncing...', primaryBlue);
        break;
      case 'update':
        _checkForUpdates();
        break;
      case 'logout':
        _logout();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: whiteColor, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.help_outline_rounded, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            Text('Help & Support'),
          ],
        ),
        content: Text(
          'Contact support at support@plantracker.com or call +1-234-567-8900\n\nWe\'re here to help you 24/7!',
          style: TextStyle(color: textBlack, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it',
                style:
                    TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        backgroundColor: greyLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      spreadRadius: 4,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Loading your dashboard...",
                style: TextStyle(
                  fontSize: 18,
                  color: textBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait a moment",
                style: TextStyle(
                  fontSize: 14,
                  color: textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: greyLight,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: HomeScreen(userData: userData),
    );
  }
}

// HomeScreen class with animations removed
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String errorMessage = '';

  // Enhanced Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color accentBlue = Color(0xFF03DAC6);
  static const Color whiteColor = Colors.white;
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color textBlack = Colors.black87;
  static const Color textGrey = Colors.black54;
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');
      if (userJson == null) {
        setState(() {
          errorMessage = 'User data not found';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> userData = jsonDecode(userJson);
      String id = userData['id']?.toString() ?? '';

      if (id.isEmpty) {
        setState(() {
          errorMessage = 'Dropshipper ID not found in user data';
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        "https://customprint.deodap.com/api_dropshipper_tracker/count_data.php?id=$id",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          setState(() {
            dashboardData = jsonResponse;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'API returned unsuccessful response';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch data. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Widget buildEnhancedSummaryCard(String title, Map<String, dynamic> items,
      IconData icon, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: whiteColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textBlack,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...items.entries.map(
              (e) => Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${e.key}:",
                        style: TextStyle(
                          fontSize: 16,
                          color: textBlack,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.1),
                            accentColor.withOpacity(0.05)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        "${e.value}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEnhancedPlanDetailsCard(
      List<dynamic> plansStatus, List<dynamic> stepDetails) {
    return Column(
      children: plansStatus.map<Widget>((planStatus) {
        int planId = planStatus['plan_id'];
        List<dynamic> planSteps =
            stepDetails.where((step) => step['plan_id'] == planId).toList();

        planSteps
            .sort((a, b) => b['plan_step_id'].compareTo(a['plan_step_id']));

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 2,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    Icon(Icons.assignment_rounded, color: whiteColor, size: 20),
              ),
              title: Text(
                "${planStatus['plan_name'] ?? 'Plan ID: $planId'}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildEnhancedStatusChip("Total", planStatus['total_steps'],
                        Colors.grey.shade600),
                    _buildEnhancedStatusChip(
                        "Pending", planStatus['pending_steps'], warningOrange),
                    _buildEnhancedStatusChip("In Process",
                        planStatus['inprocess_steps'], primaryBlue),
                    _buildEnhancedStatusChip("Completed",
                        planStatus['completed_steps'], successGreen),
                  ],
                ),
              ),
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 16),
                if (planSteps.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: greyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: textGrey, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "No steps available for this plan",
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...planSteps.map<Widget>((step) {
                    return _buildStepCard(step);
                  }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step) {
    Color statusColor = _getStatusColor(step['status']);
    String statusText = step['status'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.05),
            statusColor.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "${step['plan_step_id'] ?? '?'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Step Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Title
                  Text(
                    step['step_description'] ?? "Step ${step['plan_step_id']}",
                    style: TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  // Custom Description (if available)
                  if (step['custom_description'] != null &&
                      step['custom_description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      step['custom_description'],
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Status and Date Row
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: whiteColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Update Date
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${step['updated_at'] ?? 'N/A'}",
                              style: TextStyle(
                                fontSize: 11,
                                color: textGrey,
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
    );
  }

  Widget _buildEnhancedStatusChip(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.toString().isEmpty ? label : "$label: $value",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successGreen;
      case 'in process':
        return primaryBlue;
      case 'pending':
        return warningOrange;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue, primaryBlue, accentBlue.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: whiteColor.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 28,
                color: whiteColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back! 👋",
                    style: TextStyle(
                      fontSize: 16,
                      color: whiteColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@${widget.userData!['seller_name'] ?? 'User'}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: whiteColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 14,
                          color: whiteColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${widget.userData!['store_name'] ?? 'Store'}",
                          style: TextStyle(
                            fontSize: 13,
                            color: whiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildLoadingState() {
    return Container(
      color: greyLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.2),
                    spreadRadius: 4,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: primaryBlue,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Loading dashboard data...",
              style: TextStyle(
                fontSize: 18,
                color: textBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please wait while we fetch your progress",
              style: TextStyle(
                fontSize: 14,
                color: textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: greyLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child:
                  Icon(Icons.error_outline_rounded, size: 64, color: errorRed),
            ),
            const SizedBox(height: 20),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 20,
                color: textBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage,
                style: TextStyle(fontSize: 15, color: textGrey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchDashboardData,
              icon: Icon(Icons.refresh_rounded),
              label: Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: whiteColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: greyLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.inbox_rounded, size: 64, color: primaryBlue),
            ),
            const SizedBox(height: 20),
            Text(
              "No data available",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your dashboard will appear here once data is available",
              style: TextStyle(fontSize: 15, color: textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState();
    if (errorMessage.isNotEmpty) return _buildErrorState();
    if (dashboardData == null) return _buildEmptyState();

    // Extract data from API response
    final data = dashboardData!['data'] ?? {};
    final counts = data['counts'] ?? {};
    final plansStatus = List<dynamic>.from(data['plans_status'] ?? []);
    final stepDetails = List<dynamic>.from(data['step_details'] ?? []);

    // Extract counts for display
    final totalSteps = counts['total_steps'] ?? 0;
    final totalPlans = counts['total_plans'] ?? 0;
    final pending = counts['pending'] ?? 0;
    final inProcess = counts['in_process'] ?? 0;
    final completed = counts['completed'] ?? 0;
    final totalChats = counts['total_chats'] ?? 0;
    final totalRegister = counts['total_register'] ?? 0;

    return Container(
      color: greyLight,
      child: Column(
        children: [
          // Welcome Section
          if (widget.userData != null) _buildWelcomeSection(),

          // Dashboard Content
          Expanded(
            child: RefreshIndicator(
              color: primaryBlue,
              backgroundColor: whiteColor,
              onRefresh: fetchDashboardData,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Overall Summary
                  buildEnhancedSummaryCard(
                    "Overview",
                    {
                      "Total Plans": totalPlans,
                      "Total Steps": totalSteps,
                      "Total Registrations": totalRegister,
                      "Total Comments": totalChats,
                    },
                    Icons.analytics_rounded,
                    primaryBlue,
                  ),

                  // Status Breakdown
                  buildEnhancedSummaryCard(
                    "Status Breakdown",
                    {
                      "Pending": pending,
                      "In Process": inProcess,
                      "Completed": completed,
                    },
                    Icons.pie_chart_rounded,
                    accentBlue,
                  ),

                  // Plans with Step Details
                  if (plansStatus.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(
                          left: 16, right: 16, top: 16, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.assignment_turned_in_rounded,
                              color: successGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Plan Details & Progress",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    buildEnhancedPlanDetailsCard(plansStatus, stepDetails),
                  ],

                  // Empty State for Plans
                  if (plansStatus.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No Plans Available",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textBlack,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Your plans and progress tracking will appear here once they are created. Contact support if you need assistance.",
                            style: TextStyle(
                              fontSize: 15,
                              color: textGrey,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PlanScreen()),
                              );
                            },
                            icon: Icon(Icons.add_rounded),
                            label: Text("View Plans"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: whiteColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
