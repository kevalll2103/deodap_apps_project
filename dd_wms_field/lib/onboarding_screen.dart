import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class Onboardingscreen extends StatefulWidget {
  const Onboardingscreen({super.key});

  @override
  State<Onboardingscreen> createState() => _OnboardingscreenViewState();
}

class _OnboardingscreenViewState extends State<Onboardingscreen> {
  List onBoardingData = [
    {
      "image": 'assets/a1.png',
      "title":' Welcome to DeoDap WMS Field App',
      "description": 'Streamline your warehouse operations with our powerful field app. Manage orders, track inventory, and boost productivity.',
    },
    {
      "image": 'assets/a3.png',
      "title": 'Quick QR Scanning',
      "description": 'Scan QR codes instantly for pickup orders. Fast, accurate, and efficient order processing at your fingertips.',
    },
    {
      "image": 'assets/a2.png',
      "title": 'Manage Club Orders',
      "description": 'View pending pickups, mark orders as delayed, and keep track of all club orders in real-time.',
    }
  ];

  PageController pageController = PageController();
  int currentPage = 0;

  onChanged(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAE6E0), // Warm leather-like background
      body: Stack(
        children: [
          // Subtle leather texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/leather_texture.png', // Optional: Add a subtle texture
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                errorBuilder: (context, error, stackTrace) => SizedBox(),
              ),
            ),
          ),

          PageView.builder(
            scrollDirection: Axis.horizontal,
            controller: pageController,
            itemCount: onBoardingData.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 100),
                  // Image container with subtle leather-style shadow
                  Container(
                    height: 320,
                    width: double.infinity,
                    child: Image.asset(
                      onBoardingData[index]['image'],
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Leather-style translucent container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        // Leather-like gradient with transparency
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF5F3F0).withOpacity(0.85),
                            Color(0xFFEDE9E3).withOpacity(0.75),
                            Color(0xFFE8E4DD).withOpacity(0.80),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        // Leather-style embossed shadow
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 25,
                            offset: Offset(0, -8),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            spreadRadius: 0,
                            blurRadius: 15,
                            offset: Offset(0, -2),
                          ),
                        ],
                        // Subtle inner shadow for leather depth
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title with leather-appropriate styling
                          Text(
                            onBoardingData[index]['title'],
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2C2E), // Rich dark color
                                height: 1.2,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          // Description with elegant styling
                          Text(
                            onBoardingData[index]['description'],
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6C6C70),
                                height: 1.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Leather-styled Skip button
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  "Skip",
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      color: Color(0xFF007e9b), // Custom teal color
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom navigation with leather styling
          Positioned(
            bottom: 50,
            right: 24,
            left: 24,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                // Leather-textured background
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFAF8F5).withOpacity(0.92),
                    Color(0xFFF2EFE9).withOpacity(0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // Embossed leather effect
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    spreadRadius: 0,
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Leather-styled page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List<Widget>.generate(
                      onBoardingData.length,
                          (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 8,
                          width: (index == currentPage) ? 28 : 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: (index == currentPage)
                                ? LinearGradient(
                              colors: [
                                Color(0xFF007e9b),
                                Color(0xFF00a3c9),
                              ],
                            )
                                : null,
                            color: (index == currentPage)
                                ? null
                                : Color(0xFFCCC9C3),
                            boxShadow: (index == currentPage)
                                ? [
                              BoxShadow(
                                color: Color(0xFF007e9b).withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                                : [],
                          ),
                        );
                      },
                    ),
                  ),

                  // Premium leather-styled button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF007e9b),
                          Color(0xFF006580),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF007e9b).withOpacity(0.35),
                          spreadRadius: 0,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      borderRadius: BorderRadius.circular(14),
                      onPressed: () {
                        if (currentPage < onBoardingData.length - 1) {
                          pageController.nextPage(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            CupertinoPageRoute(builder: (context) => LoginScreen()),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentPage == onBoardingData.length - 1
                                ? "Continue"
                                : "Next",
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (currentPage < onBoardingData.length - 1)
                            Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}