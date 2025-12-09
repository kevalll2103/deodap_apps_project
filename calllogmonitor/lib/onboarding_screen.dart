import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'permissions_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isLoading = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to Deodap Call Monitor",
      subtitle: "Your Smart Communication Partner",
      description: "Monitor and sync your call logs automatically with our powerful call tracking system designed for seamless business operations.",
      imagePath: "assets/onboarding_screen_logo.png",
      backgroundColor: AppTheme.primaryBrown,
      icon: Icons.phone_in_talk_rounded,
      features: [
        "Real-time call monitoring",
        "Secure data handling",
        "Cross-platform sync"
      ],
    ),
    OnboardingPage(
      title: "Automatic Call Sync",
      subtitle: "Never Miss Important Details",
      description: "Your calls are automatically synced to the server every 2 minutes in the background. View detailed call statistics and track all activities in one centralized dashboard.",
      imagePath: null,
      backgroundColor: AppTheme.accentBrown,
      icon: Icons.sync_rounded,
      features: [
        "Background synchronization",
        "Detailed analytics",
        "Activity tracking"
      ],
    ),
    OnboardingPage(
      title: "Ready to Get Started?",
      subtitle: "Setup Takes Less Than 2 Minutes",
      description: "Let's set up your device and start monitoring your calls. The setup process is quick, secure, and designed to get you up and running immediately.",
      imagePath: null,
      backgroundColor: AppTheme.infoWarm,
      icon: Icons.rocket_launch_rounded,
      features: [
        "Quick setup process",
        "Secure configuration",
        "Instant activation"
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _updateProgress();
  }

  void _updateProgress() {
    _progressController.animateTo((_currentPage + 1) / _pages.length);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == _pages.length - 1;
    });

    // Restart animations for new page
    _slideController.reset();
    _scaleController.reset();
    _slideController.forward();
    _scaleController.forward();
    _updateProgress();

    // Enhanced haptic feedback
    HapticFeedback.selectionClick();
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      // Add a slight delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setBool('first_time_install', false);

      // Enhanced haptic feedback for completion
      HapticFeedback.heavyImpact();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const PermissionsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                )),
                child: child,
              );
            },
            settings: const RouteSettings(name: '/permissions'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Setup failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pages[_currentPage].backgroundColor.withOpacity(0.9),
              _pages[_currentPage].backgroundColor.withOpacity(0.7),
              _pages[_currentPage].backgroundColor.withOpacity(0.5),
              AppTheme.primaryWarm,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(isTablet),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPageContent(_pages[index], isTablet);
                    },
                  ),
                ),
                _buildBottomNavigation(isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 32 : 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Enhanced progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_currentPage + 1} of ${_pages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              if (!_isLastPage)
                TextButton.icon(
                  onPressed: _skipOnboarding,
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page, bool isTablet) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 64 : 24,
            vertical: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced hero section
              _buildHeroSection(page, isTablet),

              SizedBox(height: isTablet ? 64 : 48),

              // Title section
              _buildTitleSection(page, isTablet),

              SizedBox(height: isTablet ? 32 : 24),

              // Description
              _buildDescriptionSection(page, isTablet),

              SizedBox(height: isTablet ? 40 : 32),

              // Features list
              _buildFeaturesSection(page, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(OnboardingPage page, bool isTablet) {
    final size = isTablet ? 280.0 : 200.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: page.imagePath != null
          ? ClipOval(
        child: Container(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Image.asset(
            page.imagePath!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                page.icon,
                size: isTablet ? 120 : 80,
                color: Colors.white,
              );
            },
          ),
        ),
      )
          : Icon(
        page.icon,
        size: isTablet ? 120 : 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitleSection(OnboardingPage page, bool isTablet) {
    return Column(
      children: [
        Text(
          page.title,
          style: TextStyle(
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        if (page.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            page.subtitle!,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionSection(OnboardingPage page, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 32 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        page.description,
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          color: Colors.white,
          height: 1.6,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeaturesSection(OnboardingPage page, bool isTablet) {
    return Column(
      children: page.features.map((feature) {
        final index = page.features.indexOf(feature);
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 100)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: page.backgroundColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigation(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 40 : 24),
      child: Column(
        children: [
          // Page dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: _currentPage == index ? 40 : 12,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  boxShadow: _currentPage == index
                      ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                      : null,
                ),
              ),
            ),
          ),

          SizedBox(height: isTablet ? 48 : 32),

          // Navigation buttons
          Row(
            children: [
              // Previous button
              if (_currentPage > 0)
                Expanded(
                  child: _buildNavigationButton(
                    onPressed: _previousPage,
                    text: 'Previous',
                    icon: Icons.arrow_back_ios_rounded,
                    isPrimary: false,
                    isTablet: isTablet,
                  ),
                )
              else
                const Expanded(child: SizedBox()),

              const SizedBox(width: 16),

              // Next/Get Started button
              Expanded(
                flex: 2,
                child: _buildNavigationButton(
                  onPressed: _isLoading ? null : _nextPage,
                  text: _isLastPage ? 'Get Started' : 'Next',
                  icon: _isLastPage
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_ios_rounded,
                  isPrimary: true,
                  isTablet: isTablet,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    required bool isPrimary,
    required bool isTablet,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPrimary ? 0.2 : 0.1),
            blurRadius: isPrimary ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isPrimary
          ? ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _pages[_currentPage].backgroundColor,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 20 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _pages[_currentPage].backgroundColor,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: _pages[_currentPage].backgroundColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: isTablet ? 20 : 18,
              color: _pages[_currentPage].backgroundColor,
            ),
          ],
        ),
      )
          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 20 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 18 : 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String? subtitle;
  final String description;
  final String? imagePath;
  final Color backgroundColor;
  final IconData icon;
  final List<String> features;

  OnboardingPage({
    required this.title,
    this.subtitle,
    required this.description,
    this.imagePath,
    required this.backgroundColor,
    required this.icon,
    required this.features,
  });
}
