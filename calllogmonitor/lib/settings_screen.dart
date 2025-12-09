import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Settings values
  bool _hapticFeedbackEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;
  String _selectedTheme = 'System';
  String _syncInterval = '5 minutes';
  bool _isLoading = false;

  // Device information
  Map<String, dynamic> _deviceInfo = {};
  List<Map<String, dynamic>> _simCards = [];
  bool _deviceInfoLoading = true;

  // App info
  static const String appVersion = "1.0.0";
  static const String buildNumber = "100";

  // Platform channel for device details
  static const platform = MethodChannel('com.example.calllogmonitor/device_info');

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _loadDeviceInfo();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _hapticFeedbackEnabled = prefs.getBool('haptic_feedback_enabled') ?? true;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
        _selectedTheme = prefs.getString('selected_theme') ?? 'System';
        _syncInterval = prefs.getString('sync_interval') ?? '5 minutes';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading settings: $e');
    }
  }

  Future<void> _loadDeviceInfo() async {
    setState(() => _deviceInfoLoading = true);

    try {
      final deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> info = {};
      List<Map<String, dynamic>> simCards = [];

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info = {
          'deviceId': androidInfo.id,
          'deviceName': '${androidInfo.brand} ${androidInfo.model}',
          'deviceModel': androidInfo.model,
          'deviceBrand': androidInfo.brand,
          'deviceType': 'Android',
          'androidVersion': androidInfo.version.release,
          'androidSdkVersion': androidInfo.version.sdkInt.toString(),
          'manufacturer': androidInfo.manufacturer,
          'hardware': androidInfo.hardware,
          'device': androidInfo.device,
          'fingerprint': androidInfo.fingerprint,
          'display': androidInfo.display,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'host': androidInfo.host,
          'product': androidInfo.product,
          'tags': androidInfo.tags,
          'type': androidInfo.type,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };

        // Get SIM card information using platform channel only
        try {
          final simData = await platform.invokeMethod('getSimCardsInfo');
          if (simData != null && simData is List) {
            simCards = simData.map<Map<String, dynamic>>((item) =>
            Map<String, dynamic>.from(item as Map)).toList();
          }
        } catch (e) {
          // If platform method fails, try to get SIM count
          try {
            final simCount = await platform.invokeMethod('getSimCount');
            final count = simCount ?? 1;
            for (int i = 0; i < count; i++) {
              try {
                final simInfo = await platform.invokeMethod('getSimInfo', {'slotIndex': i});
                if (simInfo != null) {
                  simCards.add(Map<String, dynamic>.from(simInfo as Map));
                } else {
                  simCards.add({
                    'slotIndex': i,
                    'carrierName': 'Unknown',
                    'displayName': 'SIM ${i + 1}',
                    'phoneNumber': 'Not available',
                    'countryIso': 'Unknown',
                    'isNetworkRoaming': false,
                    'isDataRoaming': false,
                  });
                }
              } catch (e) {
                simCards.add({
                  'slotIndex': i,
                  'carrierName': 'Unknown',
                  'displayName': 'SIM ${i + 1}',
                  'phoneNumber': 'Not available',
                  'countryIso': 'Unknown',
                  'isNetworkRoaming': false,
                  'isDataRoaming': false,
                });
              }
            }
          } catch (e2) {
            // Final fallback - assume single SIM
            simCards = [
              {
                'slotIndex': 0,
                'carrierName': 'Unknown',
                'displayName': 'SIM 1',
                'phoneNumber': 'Not available',
                'countryIso': 'Unknown',
                'isNetworkRoaming': false,
                'isDataRoaming': false,
              }
            ];
          }
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info = {
          'deviceId': iosInfo.identifierForVendor ?? 'Unknown',
          'deviceName': iosInfo.name,
          'deviceModel': iosInfo.model,
          'deviceType': 'iOS',
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'utsname': iosInfo.utsname.toString(),
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };

        // iOS SIM handling (more limited)
        simCards = [
          {
            'slotIndex': 0,
            'carrierName': 'iOS Device',
            'displayName': 'Primary SIM',
            'phoneNumber': 'Not available on iOS',
            'countryIso': 'Unknown',
            'isNetworkRoaming': false,
            'isDataRoaming': false,
          }
        ];
      }

      setState(() {
        _deviceInfo = info;
        _simCards = simCards;
        _deviceInfoLoading = false;
      });
    } catch (e) {
      setState(() {
        _deviceInfoLoading = false;
        // Provide fallback data
        _deviceInfo = {
          'deviceName': 'Unknown Device',
          'deviceModel': 'Unknown',
          'deviceBrand': 'Unknown',
          'deviceType': Platform.isAndroid ? 'Android' : 'iOS',
          'androidVersion': 'Unknown',
          'deviceId': 'Unknown',
          'manufacturer': 'Unknown',
        };
        _simCards = [
          {
            'slotIndex': 0,
            'carrierName': 'Unknown',
            'displayName': 'SIM 1',
            'phoneNumber': 'Not available',
            'countryIso': 'Unknown',
            'isNetworkRoaming': false,
            'isDataRoaming': false,
          }
        ];
      });
      _showErrorSnackBar('Error loading device info: Using fallback data');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }

      // Haptic feedback
      if (_hapticFeedbackEnabled) {
        HapticFeedback.lightImpact();
      }

      _showSuccessSnackBar('Setting saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save setting: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (_hapticFeedbackEnabled) {
          HapticFeedback.selectionClick();
        }
      } else {
        _showErrorSnackBar('Could not launch $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching URL: $e');
    }
  }

  Future<void> _clearAppData() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Clear App Data',
      content: 'This will reset all app settings and data. This action cannot be undone. Are you sure?',
      confirmText: 'Clear Data',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (_hapticFeedbackEnabled) {
          HapticFeedback.heavyImpact();
        }

        _showSuccessSnackBar('App data cleared successfully');

        // Reload settings
        await _loadSettings();
      } catch (e) {
        _showErrorSnackBar('Failed to clear app data: $e');
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: 24,
                  color: AppTheme.primaryBrown,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Device Details',
                style: TextStyle(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._deviceInfo.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${_formatKey(entry.key)}:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.primaryBrown, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (Match m) => ' ${m.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ')
        .trim();
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  size: 32,
                  color: AppTheme.primaryBrown,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Deodap',
                style: TextStyle(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deodap Call Monitor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version $appVersion (Build $buildNumber)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Deodap Technologies is a leading provider of innovative mobile solutions for business productivity and communication.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Our mission is to create powerful yet simple tools that help businesses streamline their operations and improve efficiency.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),
                _buildAboutLinkTile(
                  icon: Icons.language,
                  title: 'Visit our website',
                  url: 'https://deodap.in',
                ),
                const SizedBox(height: 8),
                _buildAboutLinkTile(
                  icon: Icons.email,
                  title: 'Contact us',
                  url: 'mailto:contact@deodap.in',
                ),
                const SizedBox(height: 8),
                _buildAboutLinkTile(
                  icon: Icons.phone,
                  title: 'Support',
                  url: 'tel:+918401234567',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.primaryBrown, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 8,
        );
      },
    );
  }

  Widget _buildAboutLinkTile({
    required IconData icon,
    required String title,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBrown, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              color: AppTheme.primaryBrown,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    if (_deviceInfoLoading) {
      return _buildSettingsSection(
        title: 'Device Information',
        icon: Icons.phone_android,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            ),
          ),
        ],
      );
    }

    return _buildSettingsSection(
      title: 'Device Information',
      icon: Icons.phone_android,
      children: [
        _buildInfoTile(
          title: 'Device Name',
          subtitle: _deviceInfo['deviceName'] ?? 'Unknown',
          icon: Icons.smartphone,
        ),
        _buildInfoTile(
          title: 'Model',
          subtitle: _deviceInfo['deviceModel'] ?? 'Unknown',
          icon: Icons.phone_android,
        ),
        _buildInfoTile(
          title: 'Brand',
          subtitle: _deviceInfo['deviceBrand'] ?? 'Unknown',
          icon: Icons.branding_watermark,
        ),
        _buildInfoTile(
          title: 'Android Version',
          subtitle: _deviceInfo['androidVersion'] ?? 'Unknown',
          icon: Icons.android,
        ),
        _buildInfoTile(
          title: 'Device ID',
          subtitle: _deviceInfo['deviceId'] ?? 'Unknown',
          icon: Icons.fingerprint,
        ),
        _buildInfoTile(
          title: 'Available SIMs',
          subtitle: '${_simCards.length} SIM${_simCards.length != 1 ? 's' : ''} detected',
          icon: Icons.sim_card,
        ),
        _buildActionTile(
          title: 'View Full Device Details',
          subtitle: 'See complete device information',
          icon: Icons.info_outline,
          onTap: _showDeviceDetailsDialog,
        ),
      ],
    );
  }

  Widget _buildSimCardsSection() {
    if (_deviceInfoLoading) {
      return _buildSettingsSection(
        title: 'SIM Cards',
        icon: Icons.sim_card,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            ),
          ),
        ],
      );
    }

    if (_simCards.isEmpty) {
      return _buildSettingsSection(
        title: 'SIM Cards',
        icon: Icons.sim_card,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No SIM cards detected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    return _buildSettingsSection(
      title: 'SIM Cards (${_simCards.length})',
      icon: Icons.sim_card,
      children: _simCards.asMap().entries.map((entry) {
        final index = entry.key;
        final sim = entry.value;

        return _buildSimCardTile(
          simNumber: index + 1,
          carrierName: sim['carrierName'] ?? 'Unknown',
          phoneNumber: sim['phoneNumber'] ?? 'Not available',
          displayName: sim['displayName'] ?? 'SIM ${index + 1}',
          countryCode: sim['countryIso'] ?? 'Unknown',
          isRoaming: sim['isNetworkRoaming'] ?? false,
        );
      }).toList(),
    );
  }

  Widget _buildSimCardTile({
    required int simNumber,
    required String carrierName,
    required String phoneNumber,
    required String displayName,
    required String countryCode,
    required bool isRoaming,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sim_card,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIM $simNumber - $displayName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      carrierName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRoaming)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ROAMING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Details
          _buildSimDetailRow('Phone Number', phoneNumber),
          _buildSimDetailRow('Country Code', countryCode),
          _buildSimDetailRow('Status', isRoaming ? 'Roaming' : 'Active'),
        ],
      ),
    );
  }

  Widget _buildSimDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWarm,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBrown,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBrown),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Sync status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SyncStatusIndicator(isActive: _autoSyncEnabled),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown))
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),

                // Device Information Section
                _buildDeviceInfoSection(),

                // SIM Cards Section
                _buildSimCardsSection(),

                // App Settings
                _buildSettingsSection(
                  title: 'App Settings',
                  icon: Icons.tune,
                  children: [
                    _buildSwitchTile(
                      title: 'Haptic Feedback',
                      subtitle: 'Vibration on interactions',
                      value: _hapticFeedbackEnabled,
                      onChanged: (value) {
                        setState(() => _hapticFeedbackEnabled = value);
                        _saveSetting('haptic_feedback_enabled', value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Notifications',
                      subtitle: 'Push notifications',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _saveSetting('notifications_enabled', value);
                      },
                    ),
                    _buildDropdownTile(
                      title: 'Theme',
                      subtitle: 'App appearance',
                      value: _selectedTheme,
                      items: ['Light', 'Dark', 'System'],
                      onChanged: (value) {
                        setState(() => _selectedTheme = value!);
                        _saveSetting('selected_theme', value);
                      },
                    ),
                  ],
                ),

                // Sync Settings
                _buildSettingsSection(
                  title: 'Sync Settings',
                  icon: Icons.sync,
                  children: [
                    _buildSwitchTile(
                      title: 'Auto Sync',
                      subtitle: 'Automatically sync data',
                      value: _autoSyncEnabled,
                      onChanged: (value) {
                        setState(() => _autoSyncEnabled = value);
                        _saveSetting('auto_sync_enabled', value);
                      },
                    ),
                    _buildDropdownTile(
                      title: 'Sync Interval',
                      subtitle: 'How often to sync',
                      value: _syncInterval,
                      items: ['1 minute', '5 minutes', '15 minutes', '30 minutes', '1 hour'],
                      onChanged: (value) {
                        setState(() => _syncInterval = value!);
                        _saveSetting('sync_interval', value);
                      },
                    ),
                    _buildActionTile(
                      title: 'Sync Now',
                      subtitle: 'Manually sync all data',
                      icon: Icons.sync,
                      onTap: () {
                        if (_hapticFeedbackEnabled) {
                          HapticFeedback.mediumImpact();
                        }
                        _showSuccessSnackBar('Sync completed successfully');
                      },
                    ),
                  ],
                ),

                // About Section
                _buildSettingsSection(
                  title: 'About',
                  icon: Icons.info,
                  children: [
                    _buildInfoTile(
                      title: 'App Version',
                      subtitle: '$appVersion (Build $buildNumber)',
                      icon: Icons.info_outline,
                    ),
                    _buildInfoTile(
                      title: 'Developer',
                      subtitle: 'Deodap Technologies',
                      icon: Icons.business,
                    ),
                    _buildActionTile(
                      title: 'Company Website',
                      subtitle: 'https://deodap.in',
                      icon: Icons.language,
                      onTap: () => _launchURL('https://deodap.in'),
                    ),
                    _buildActionTile(
                      title: 'About Deodap',
                      subtitle: 'Learn more about us',
                      icon: Icons.info_outline,
                      onTap: _showAboutDialog,
                    ),
                    _buildActionTile(
                      title: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      icon: Icons.privacy_tip,
                      onTap: () => _launchURL('https://deodap.in/pages/privacy-policy'),
                    ),
                    _buildActionTile(
                      title: 'Terms of Service',
                      subtitle: 'View terms and conditions',
                      icon: Icons.description,
                      onTap: () => _launchURL('https://deodap.in/pages/terms-conditions'),
                    ),
                  ],
                ),

                // Advanced Settings
                _buildSettingsSection(
                  title: 'Advanced',
                  icon: Icons.settings_applications,
                  children: [
                    _buildActionTile(
                      title: 'Clear App Data',
                      subtitle: 'Reset all settings and data',
                      icon: Icons.delete_forever,
                      onTap: _clearAppData,
                      isDestructive: true,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBrown.withOpacity(0.1),
            AppTheme.accentBrown.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              color: AppTheme.primaryBrown,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize your app experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryBrown, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBrown,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBrown,
        activeTrackColor: AppTheme.primaryBrown.withOpacity(0.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBrown,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.primaryBrown,
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.primaryBrown,
              size: 20,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBrown),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBrown,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppTheme.primaryBrown;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color,
      ),
      onTap: () {
        if (_hapticFeedbackEnabled) {
          HapticFeedback.selectionClick();
        }
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// Sync Status Indicator Component
class SyncStatusIndicator extends StatelessWidget {
  final bool isActive;

  const SyncStatusIndicator({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.sync : Icons.sync_disabled,
            color: isActive ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
