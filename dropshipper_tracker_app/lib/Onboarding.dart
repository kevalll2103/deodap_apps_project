import 'account_type.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingscreenView extends StatefulWidget {
  const OnboardingscreenView({super.key});

  @override
  State<OnboardingscreenView> createState() => _OnboardingscreenViewState();
}

class _OnboardingscreenViewState extends State<OnboardingscreenView>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onboarding_one.jpg',
      title: 'Track Your Returns',
      subtitle: 'Real-time Monitoring',
      description: 'Stay updated with real-time return status. Track good and bad returns for hassle-free management.',
      icon: Icons.track_changes_rounded,
    ),
    OnboardingData(
      image: 'assets/images/onboarding_two.jpg',
      title: 'Scan Orders Easily',
      subtitle: 'Seamless Scanning',
      description: 'Scan Order IDs and Tracking IDs effortlessly. Verify returns with ease using our intuitive scanning system.',
      icon: Icons.qr_code_scanner_rounded,
    ),
    OnboardingData(
      image: 'assets/images/onboarding_three.jpg',
      title: 'Get Started Today',
      subtitle: 'DeoDap Returns+',
      description: 'Sign up and manage returns like never before. Simplify your dropshipping return process today!',
      icon: Icons.rocket_launch_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAccountType();
    }
  }

  void _navigateToAccountType() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AccountTypescreenView(),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // PageView
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], size);
                },
              ),

              // Skip Button
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: _navigateToAccountType,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        "Skip",
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page Indicators
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.blue[800]
                            : Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation Button
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[800]!,
                        Colors.blue[700]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.08),

              // Animated Hero Image
              Hero(
                tag: 'onboarding-image-${data.image}',
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.8, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        height: size.height * 0.3,
                        width: size.width * 0.8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            data.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  data.icon,
                                  size: 80,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: size.height * 0.06),

              // Animated Icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        data.icon,
                        color: Colors.blue[800],
                        size: 32,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: size.height * 0.04),

              // Title Section with staggered animation
              Column(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.08,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.04),

              // Description with delayed animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}