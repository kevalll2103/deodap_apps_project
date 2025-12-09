import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'Onboarding.dart';
import 'account_type.dart';
import 'dashboard.dart';
import 'dashboard_salespeople.dart';

class SplashscreenView extends StatefulWidget {
  const SplashscreenView({super.key});

  @override
  State<SplashscreenView> createState() => _SplashscreenViewState();
}

class _SplashscreenViewState extends State<SplashscreenView>
    with TickerProviderStateMixin {
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_LOGIN_TYPE = 'loginType'; // नया key add किया
  static const String KEY_APP_VERSION = 'appVersion';
  static const String KEY_ONBOARDING_DONE = 'isOnboardingDone';

  String _currentVersion = '';

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
    await Future.delayed(const Duration(seconds: 3));

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    await _checkAppVersionAndLoginStatus();
  }

  Future<void> _checkAppVersionAndLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;
    final String? loginType = prefs.getString(KEY_LOGIN_TYPE); // Login type check करें
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

    _navigate(isLoggedIn, loginType);
  }

  void _navigate(bool isLoggedIn, String? loginType) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool(KEY_ONBOARDING_DONE) ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      // Login type के आधार पर navigate करें
      if (loginType == 'sales') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SalespersonDashboard()),
        );
      } else {
        // Default या 'user' type के लिए Dashboard खोलें
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  // Main content area
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Hero(
                              tag: 'app-logo',
                              child: Image.asset(
                                'assets/images/deodap.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Footer section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Version info
                        Text(
                          "Version $_currentVersion",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _subtitleColor,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Company name
                        Text(
                          'Deodap International Pvt Ltd',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
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
