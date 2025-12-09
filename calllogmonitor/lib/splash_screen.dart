import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'permissions_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isNavigating = false;
  bool _isDisposed = false;
  String _statusText = "Initializing...";

  static const String currentAppVersion = "1.0.3";
  static const String currentWarehouse = '';
  static const Duration _minimumSplashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isNavigating = true;
    try {
      _fadeController.dispose();
      _scaleController.dispose();
      _pulseController.dispose();
    } catch (e) {
      debugPrint('Animation disposal error: $e');
    }
    super.dispose();
  }

  void _initializeAnimations() {
    // Fade animation for overall screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeApp() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Start animations
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _scaleController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // Start pulse animation
      _pulseController.repeat(reverse: true);

      // Wait a bit before checking registration
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // Ensure minimum splash duration
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < _minimumSplashDuration.inMilliseconds) {
        await Future.delayed(Duration(
          milliseconds: _minimumSplashDuration.inMilliseconds - elapsed,
        ));
      }

      if (!mounted || _isDisposed) return;
      await _checkRegistrationAndNavigate();
    } catch (e) {
      debugPrint('Splash screen initialization error: $e');
      _updateStatus("Something went wrong, loading default...");
      await Future.delayed(const Duration(seconds: 1));
      _navigateToFallback();
    }
  }

  void _updateStatus(String status) {
    if (mounted && !_isDisposed) {
      setState(() {
        _statusText = status;
      });
    }
  }

  Future<void> _checkRegistrationAndNavigate() async {
    if (_isNavigating || _isDisposed || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      if (!mounted || _isDisposed) return;

      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      final permissionsGranted = prefs.getBool('permissions_granted') ?? false;
      final isRegistered = prefs.getBool('is_registered') ?? false;

      // Add a small delay before navigation for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _isDisposed) return;

      if (!onboardingCompleted) {
        _navigateToRoute('/onboarding');
      } else if (!permissionsGranted) {
        _navigateToRoute('/permissions');
      } else if (!isRegistered) {
        _navigateToRoute('/register');
      } else {
        _navigateToRoute('/home');
      }
    } catch (e) {
      debugPrint('Registration check error: $e');
      _navigateToFallback();
    }
  }

  void _navigateToRoute(String route) {
    if (_isNavigating || _isDisposed || !mounted) return;
    _isNavigating = true;

    final routes = {
      '/onboarding': const OnboardingScreen(),
      '/permissions': const PermissionsScreen(),
    };

    try {
      if (routes.containsKey(route)) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                routes[route]!,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
            settings: RouteSettings(name: route),
          ),
        );
      } else {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e) {
      debugPrint('Navigation error to $route: $e');
      _navigateToFallback();
    }
  }

  void _navigateToFallback() {
    if (_isNavigating || _isDisposed || !mounted) return;
    _isNavigating = true;

    try {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
          settings: const RouteSettings(name: '/onboarding'),
        ),
      );
    } catch (e) {
      debugPrint('Fallback navigation error: $e');
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBrown,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.warmGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Decorative background elements
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
        
        // Main content with centered logo
        Column(
          children: [
            // Centered logo taking up most of the screen
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value * _pulseAnimation.value,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Image.asset(
                          'assets/deodap_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.phone_in_talk_rounded,
                                size: 100,
                                color: Color(0xFF2D1810),
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

            // Bottom section with enhanced styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  // Loading indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2D1810).withOpacity(0.3),
                          const Color(0xFF2D1810),
                          const Color(0xFF2D1810).withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2D1810).withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: _pulseAnimation.value * 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Version info with enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Version $currentAppVersion',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF3D251C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Developer credit with enhanced styling
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //     Text(
                  //       'DEODAP INTERNATIONAL PRIVATE LIMITED',
                  //       style: GoogleFonts.inter(
                  //         color: const Color(0xFF4A3328),
                  //         fontSize: 11,
                  //         fontWeight: FontWeight.w500,
                  //         letterSpacing: 0.3,
                  //         shadows: [
                  //           Shadow(
                  //             offset: const Offset(1, 1),
                  //             blurRadius: 1.5,
                  //             color: Colors.white.withOpacity(0.5),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //     const SizedBox(width: 6),
                  //     Icon(
                  //       Icons.favorite,
                  //       size: 12,
                  //       color: const Color(0xFF4A3328).withOpacity(0.7),
                  //     ),
                  //   ],
                  // ),


                  // Developer credit with company icon before text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apartment, // replace with your company logo/icon
                        size: 14,
                        color: const Color(0xFF4A3328).withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DEODAP INTERNATIONAL PRIVATE LIMITED',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF4A3328),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 1.5,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
