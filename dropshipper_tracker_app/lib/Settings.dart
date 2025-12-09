import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'common/app_info_screen_view.dart';
import 'common/terms_conditionscreen_view.dart';
import 'invite_friendscreen_emp_view.dart';
import 'common/about_screen.dart';
import 'common/contact_screen_view.dart';
import 'emp_help.dart';
import 'profile.dart';
import 'account_settings.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with TickerProviderStateMixin {
  bool isDarkMode = false;
  bool fingerPrintEnabled = false;
  bool notificationsEnabled = true;
  bool _isLoading = false;
  String status = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Enhanced Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _checkForUpdate();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isLoading = true;
    });
    String version = '1.1.1';

    try {
      var response = await http.post(
        Uri.parse('https://customprint.deodap.com/check_update.php'),
        body: {
          'version': version,
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          status = data['status'] == 'success' ? 'success' : 'error';
        });
      } else {
        setState(() {
          status = 'error';
        });
      }
    } catch (e) {
      setState(() {
        status = 'error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLanguageSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            right: 24,
            left: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language, color: primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Language',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Language option
              Container(
                decoration: BoxDecoration(
                  color: lightBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryBlue.withOpacity(0.3)),
                ),
                child: ListTile(
                  onTap: () => Navigator.pop(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: const Text(
                    'English',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: primaryBlue, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'More languages coming soon!',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, darkBlue],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    bool showBadge = false,
    String badgeText = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? primaryBlue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (showBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: textSecondary,
                      size: 16,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? primaryBlue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: primaryBlue,
              activeTrackColor: primaryBlue.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, darkBlue],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AccountScreen()),
              );
            },
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, darkBlue],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome User!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your preferences',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // General Settings
              _buildSectionHeader('General Settings', Icons.settings_rounded),
              _buildSettingsTile(
                title: 'Language',
                subtitle: 'English (Default)',
                icon: Icons.language_rounded,
                onTap: _showLanguageSelectionBottomSheet,
              ),
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Get notified about important updates',
                icon: Icons.notifications_active_rounded,
                value: notificationsEnabled,
                onChanged: (value) => setState(() => notificationsEnabled = value),
              ),
              _buildSwitchTile(
                title: 'Biometric Security',
                subtitle: 'Use fingerprint or face unlock',
                icon: Icons.fingerprint_rounded,
                value: fingerPrintEnabled,
                onChanged: (value) => setState(() => fingerPrintEnabled = value),
              ),
              _buildSettingsTile(
                title: 'Storage & Privacy',
                subtitle: 'Data usage, cache & permissions',
                icon: Icons.storage_rounded,
                onTap: () {
                  // Navigate to storage settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Storage settings coming soon!'),
                      backgroundColor: primaryBlue,
                    ),
                  );
                },
              ),

              // App Management
              _buildSectionHeader('App Management', Icons.apps_rounded),
              if (status == 'success')
                _buildSettingsTile(
                  title: 'App Updates',
                  subtitle: 'New version available for download',
                  icon: Icons.system_update_rounded,
                  onTap: () {
                    // Navigate to update screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Redirecting to app store...'),
                        backgroundColor: accentGreen,
                      ),
                    );
                  },
                  showBadge: true,
                  badgeText: 'NEW',
                ),
              _buildSettingsTile(
                title: 'App Information',
                subtitle: 'Version details & build info',
                icon: Icons.info_outline_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppInfoScreenView())),
              ),

              // Social & Support
              _buildSectionHeader('Social & Support', Icons.support_agent_rounded),
              _buildSettingsTile(
                title: 'Invite Friends',
                subtitle: 'Share app with your network',
                icon: Icons.group_add_rounded,
                iconColor: accentGreen,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InviteFriendscreenEmpView())),
              ),
              _buildSettingsTile(
                title: 'Help & Support',
                subtitle: 'FAQs, tutorials & contact support',
                icon: Icons.help_outline_rounded,
                iconColor: primaryBlue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => emphelp())),
              ),
              _buildSettingsTile(
                title: 'Terms of Service',
                subtitle: 'App policies & user agreement',
                icon: Icons.description_rounded,
                iconColor: accentOrange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TermsConditionscreenView())),
              ),
              _buildSettingsTile(
                title: 'About Us',
                subtitle: 'Learn more about our company',
                icon: Icons.business_rounded,
                iconColor: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen())),
              ),
              _buildSettingsTile(
                title: 'Contact Support',
                subtitle: 'Get help from our team',
                icon: Icons.contact_support_rounded,
                iconColor: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreenView())),
              ),

              const SizedBox(height: 32),

              // Enhanced App Version Footer
              if (!_isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.1),
                          lightBlue.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Latest Release',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}