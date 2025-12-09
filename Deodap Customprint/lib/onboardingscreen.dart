import 'package:Deodap_Customprint/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Onboardingscreen extends StatefulWidget {
  const Onboardingscreen({super.key});

  @override
  State<Onboardingscreen> createState() => _OnboardingscreenState();
}

class _OnboardingscreenState extends State<Onboardingscreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: "Get Started With CustomPrinting",
      description: "Unleash your creativity with CustomPrinting. Easily add, update, and delete your Orders. Streamline your printing process with ease.",
      imagePath: "assets/images/onboarding_image_one.png",
    ),
    OnboardingItem(
      title: "User-Friendly Experience",
      description: "Navigate effortlessly through our intuitive interface. Tailored tools for your unique printing needs. Making your tasks simple and efficient.",
      imagePath: "assets/images/onboarding_image_two.png",
    ),
    OnboardingItem(
      title: "Get Started with DeoDap",
      description: "Sign up to unlock the full potential of CustomPrinting. Begin your journey to exceptional prints. Transform your ideas into reality effortlessly.",
      imagePath: "assets/images/onboarding_image_three.png",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const Loginscreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip Button
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _navigateToLogin,
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: const Color(0xFF0B90A1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Page View Content
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingItems.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(_onboardingItems[index]);
                    },
                  ),
                ),

                // Page Indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingItems.length,
                          (index) => _buildPageIndicator(index == _currentPage),
                    ),
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navigateToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B90A1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _onboardingItems.length - 1
                            ? "Get Started"
                            : "Continue",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.imagePath,
            height: MediaQuery.of(context).size.height * 0.35,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B90A1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0B90A1) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}