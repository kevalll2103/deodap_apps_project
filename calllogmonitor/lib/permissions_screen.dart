import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  String _statusMessage = 'We need some permissions to get started';
  bool _allPermissionsGranted = false;
  
  // Individual permission states
  bool _hasContactsPermission = false;
  bool _hasPhonePermission = false;
  bool _hasCallLogPermission = false;
  bool _hasNotificationPermission = false;
  
  // Animation controllers
  late AnimationController _contactsAnimationController;
  late AnimationController _phoneAnimationController;
  late AnimationController _callLogAnimationController;
  late AnimationController _notificationAnimationController;

  final List<Permission> _requiredPermissions = [
    Permission.contacts,
    Permission.phone,
    Permission.phone, // Call logs handled via phone permission
    Permission.notification, // Notifications
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _contactsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _phoneAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _callLogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _checkPermissions();
  }

  @override
  void dispose() {
    _contactsAnimationController.dispose();
    _phoneAnimationController.dispose();
    _callLogAnimationController.dispose();
    _notificationAnimationController.dispose();
    super.dispose();
  }

  void _updateAnimations() {
    // Animate based on permission states
    if (_hasContactsPermission) {
      _contactsAnimationController.forward();
    } else {
      _contactsAnimationController.reverse();
    }
    
    if (_hasPhonePermission) {
      _phoneAnimationController.forward();
    } else {
      _phoneAnimationController.reverse();
    }
    
    if (_hasCallLogPermission) {
      _callLogAnimationController.forward();
    } else {
      _callLogAnimationController.reverse();
    }
    
    if (_hasNotificationPermission) {
      _notificationAnimationController.forward();
    } else {
      _notificationAnimationController.reverse();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });

    try {
      final statuses = await Future.wait(
        _requiredPermissions.map((p) => p.status),
      );

      // Update individual permission states
      _hasContactsPermission = await Permission.contacts.status.isGranted;
      _hasPhonePermission = await Permission.phone.status.isGranted;
      _hasCallLogPermission = _hasPhonePermission; // Call log uses phone permission
      _hasNotificationPermission = await Permission.notification.status.isGranted;

      // Animate permission status indicators
      _updateAnimations();

      final allGranted = statuses.every((status) => status.isGranted);

      setState(() {
        _allPermissionsGranted = allGranted;
        _statusMessage = allGranted
            ? 'All permissions granted!'
            : 'Please grant all required permissions to continue';
      });

      if (allGranted) {
        _proceedToRegistration();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking permissions';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestSinglePermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) {
      await _checkPermissions();
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      final statuses = await _requiredPermissions.request();
      final allGranted = statuses.values.every((status) => status.isGranted);

      setState(() {
        _allPermissionsGranted = allGranted;
        _statusMessage = allGranted
            ? 'All permissions granted!'
            : 'Please grant all permissions to continue';
      });

      if (allGranted) {
        _proceedToRegistration();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error requesting permissions';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _proceedToRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_granted', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  size: 60,
                  color: AppTheme.primaryBrown,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Permissions Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Clickable permission tiles
              GestureDetector(
                onTap: () => _requestSinglePermission(Permission.contacts),
                child: _buildPermissionTile(
                  icon: Icons.contacts,
                  title: 'Contacts',
                  description: 'To identify callers in your call log',
                  animationController: _contactsAnimationController,
                  isGranted: _hasContactsPermission,
                ),
              ),
              GestureDetector(
                onTap: () => _requestSinglePermission(Permission.phone),
                child: _buildPermissionTile(
                  icon: Icons.phone,
                  title: 'Phone',
                  description: 'To make and receive calls',
                  animationController: _phoneAnimationController,
                  isGranted: _hasPhonePermission,
                ),
              ),
              GestureDetector(
                onTap: () => _requestSinglePermission(Permission.phone),
                child: _buildPermissionTile(
                  icon: Icons.call,
                  title: 'Call Logs',
                  description: 'To track and manage your call history',
                  animationController: _callLogAnimationController,
                  isGranted: _hasCallLogPermission,
                ),
              ),
              GestureDetector(
                onTap: () => _requestSinglePermission(Permission.notification),
                child: _buildPermissionTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  description: 'To show sync status and important updates',
                  animationController: _notificationAnimationController,
                  isGranted: _hasNotificationPermission,
                  isNotification: true,
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allPermissionsGranted || _isLoading
                      ? null
                      : _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryBrown,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _allPermissionsGranted
                        ? 'Continuing...'
                        : 'Grant All Permissions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!_allPermissionsGranted) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _checkPermissions,
                  child: const Text(
                    'Already granted? Tap here',
                    style: TextStyle(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required AnimationController animationController,
    required bool isGranted,
    bool isNotification = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBrown),
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
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // Animated status light
                    AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isGranted ? Colors.green : Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: (isGranted ? Colors.green : Colors.red)
                                    .withOpacity(0.3 + (animationController.value * 0.4)),
                                blurRadius: 4 + (animationController.value * 4),
                                spreadRadius: 1 + (animationController.value * 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
