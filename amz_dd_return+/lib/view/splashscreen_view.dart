import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:amz/view/dropshipper/homescreen_dropshipper_view.dart';
import 'package:amz/view/employee/homescreen_employee_view.dart';
import 'package:amz/view/onboardingscreen_view.dart';
import 'package:amz/view/accountypescreen_view.dart';
import 'package:amz/widgets/update_dialog.dart';
import 'package:amz/view/updatescreen_view.dart';

class SplashscreenView extends StatefulWidget {
  const SplashscreenView({super.key});

  @override
  State<SplashscreenView> createState() => _SplashscreenViewState();
}

class _SplashscreenViewState extends State<SplashscreenView>
    with TickerProviderStateMixin {
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_USER_ROLE = 'userRole';
  static const String KEY_APP_VERSION = 'appVersion';
  static const String KEY_ONBOARDING_DONE = 'isOnboardingDone';

  static const String _updateEndpoint =
      'https://customprint.deodap.com/api_amzDD_return/checkupdate.php';

  bool _isCheckingUpdate = false;
  String _currentVersion = '';
  String _statusText = 'Loading...';

  // White theme color palette
  final Color _primaryColor = const Color(0xFF2196F3);
  final Color _secondaryColor = const Color(0xFF64B5F6);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _subtitleColor = const Color(0xFF666666);

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    await _checkForUpdates();

    if (!_isCheckingUpdate) {
      await _checkAppVersionAndLoginStatus();
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection, skipping update check');
        return;
      }

      setState(() {
        _isCheckingUpdate = true;
        _statusText = 'Checking for updates...';
      });

      final prefs = await SharedPreferences.getInstance();
      final String? userRole = prefs.getString(KEY_USER_ROLE);
      final String role = userRole ?? 'admin';

      final response = await http
          .post(
        Uri.parse(_updateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'version': _currentVersion,
          'role': role,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' || data['status'] == 'update_required') {
          if (mounted) await _showUpdateDialog(data);
        } else {
          setState(() {
            _isCheckingUpdate = false;
            _statusText = 'Loading...';
          });
        }
      } else {
        debugPrint('Update check failed: ${response.statusCode}');
        setState(() {
          _isCheckingUpdate = false;
          _statusText = 'Loading...';
        });
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      setState(() {
        _isCheckingUpdate = false;
        _statusText = 'Loading...';
      });
    }
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> updateData) async {
    if (!mounted) return;

    final bool isMandatory = updateData['is_mandatory'] ?? true;

    await showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: UpdateDialog(
            imageUrl: updateData['image_url'] ?? '',
            currentVersion: _currentVersion,
            latestVersion: updateData['latest_version'] ?? 'Unknown',
            title: updateData['update_title'] ?? 'Update Available',
            description: updateData['update_description'] ??
                'A new version is available with improvements and bug fixes.',
            isMandatory: isMandatory,
            onUpdatePressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => UpdateScreenView(updateData: updateData),
                ),
              );
            },
            onLaterPressed: isMandatory
                ? null
                : () {
              Navigator.pop(context);
              setState(() {
                _isCheckingUpdate = false;
                _statusText = 'Loading...';
              });
              _checkAppVersionAndLoginStatus();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _checkAppVersionAndLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;
    final String? userRole = prefs.getString(KEY_USER_ROLE);
    final String? storedAppVersion = prefs.getString(KEY_APP_VERSION);
    final bool hasSeenOnboarding = prefs.getBool(KEY_ONBOARDING_DONE) ?? false;

    if (storedAppVersion != _currentVersion) {
      await prefs.clear();
      if (hasSeenOnboarding) await prefs.setBool(KEY_ONBOARDING_DONE, true);
      await prefs.setString(KEY_APP_VERSION, _currentVersion);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingscreenView()),
      );
      return;
    }

    _navigate(isLoggedIn, userRole);
  }

  void _navigate(bool isLoggedIn, String? role) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool(KEY_ONBOARDING_DONE) ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      if (role == 'employee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomescreenEmployeeView()),
        );
      } else if (role == 'dropshipper') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomescreenDropshipperView()),
        );
      } else {
        _redirectToOnboarding();
      }
    } else {
      if (hasSeenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountTypescreenView()),
        );
      } else {
        _redirectToOnboarding();
      }
    }
  }

  void _redirectToOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_ONBOARDING_DONE, true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingscreenView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF8FAFC),
                const Color(0xFFF1F5F9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    // Top decorative elements
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor.withOpacity(0.1),
                            _secondaryColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),

                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // Top spacer
                          const Spacer(flex: 2),

                          // Logo section with animation
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryColor.withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Hero(
                                    tag: 'app-logo',
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            _primaryColor,
                                            _secondaryColor,
                                          ],
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          'assets/images/DD.png',
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 180,
                                              height: 180,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  colors: [_primaryColor, _secondaryColor],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.local_shipping,
                                                size: 75,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // App title
                          Text(
                            'AMZ Return ++ ',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Efficient Delivery Solutions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _subtitleColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Middle spacer
                          const Spacer(flex: 3),

                          // Loading section
                          Column(
                            children: [
                              // Progress indicator
                              if (_isCheckingUpdate)
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _primaryColor,
                                    ),
                                  ),
                                ),

                              // Status text
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _statusText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _textColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Bottom spacer
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),

                    // Footer section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.grey.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Version info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Version $_currentVersion",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Developer credit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Developed with ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _subtitleColor,
                                ),
                              ),
                              Icon(
                                Icons.favorite,
                                size: 14,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              Text(
                                ' by deodap International Pvt Ltd',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
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
            },
          ),
        ),
      ),
    );
  }
}