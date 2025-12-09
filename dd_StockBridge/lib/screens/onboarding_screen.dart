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
      "image": 'assets/images/a1.png',
      "title": 'Welcome to DeoDap stock bridge app',
      "description":
          'Streamline your warehouse operations with our powerful field app. Manage orders, track inventory, and boost productivity.',
    },
    {
      "image": 'assets/images/a3.png',
      "title": 'Barcode, Stock & Rack Management',
      "description":
          'Scan QR codes instantly for pickup orders. Fast, accurate, and efficient order processing at your fingertips.',
    },
    {
      "image": 'assets/images/a2.png',
      "title": 'Critical Stock & Sales Insights',
      "description":
          'Get real-time critical stock alerts based on last 7 or 30 days sales data. Track purchase needs and maintain ideal inventory levels effortlessly.',
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
      backgroundColor: CupertinoColors.white,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.horizontal,
            controller: pageController,
            itemCount: onBoardingData.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  // Image container
                  Container(
                    height: 320,
                    width: double.infinity,
                    child: Image.asset(
                      onBoardingData[index]['image'],
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // iOS-style content container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 36),
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(25, 0, 0, 0),
                            spreadRadius: 0,
                            blurRadius: 25,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            onBoardingData[index]['title'],
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.label,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Description
                          Text(
                            onBoardingData[index]['description'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: CupertinoColors.secondaryLabel,
                              height: 1.5,
                              letterSpacing: -0.2,
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

          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (context) => const LoginScreenview()),
                  );
                },
                child: Text(
                  "Skip",
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ),

          // Bottom navigation bar
          Positioned(
            bottom: 50,
            right: 24,
            left: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
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
                            color: (index == currentPage)
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.systemGrey4,
                            boxShadow: (index == currentPage)
                                ? [
                                    BoxShadow(
                                      color: CupertinoColors.systemBlue
                                          .withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      },
                    ),
                  ),

                  // Next/Continue button
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemBlue.withOpacity(0.35),
                          spreadRadius: 0,
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      borderRadius: BorderRadius.circular(14),
                      onPressed: () {
                        if (currentPage < onBoardingData.length - 1) {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            CupertinoPageRoute(
                                builder: (context) =>
                                    const LoginScreenview()),
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
                              fontSize: 17,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (currentPage < onBoardingData.length - 1)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                                color: CupertinoColors.white,
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