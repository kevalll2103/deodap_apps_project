import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class Onboardingscreen extends StatefulWidget {
  const Onboardingscreen ({super.key});

  @override
  State<Onboardingscreen> createState() => _OnboardingscreenViewState();
}

class _OnboardingscreenViewState extends State<Onboardingscreen> {
  List onBoardingData = [
    {
      "image": 'assets/onboarding_one.gif',
      "title": 'Welcome to Club Order\nManagement System',
      "description": 'Track stock in real time, process orders faster, and dispatch seamlessly. Simplify bulk club order management effortlessly',
    },
    {
      "image": 'assets/onboarding_three.gif',
      "title": 'Real-Time Visibility',
      "description": 'Stay on top of every order with instant updates, smart reports, and a smooth user experience that keeps you informed at every step.',
    },
    {
      "image": 'assets/sammy-line-shopping.gif',
      "title": 'Get Started Today',
      "description": 'Enable quick permissions, sign in securely, and enjoy faster checkouts with hassle-free order processing from day one.',
    }
  ];

  PageController pageController = PageController();
  int currentPage = 0;

  // Update the current page index on page change
  onChanged(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed to white background

      body: Center(
        child: Stack(
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
                    SizedBox(height: 150),  // Spacing for image
                    Container(
                      height: 300,
                      width: double.infinity,
                      child: Image.asset(
                        onBoardingData[index]['image'],
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    ),
                    SizedBox(height: 75),

                    // White background container with rounded top corners, full width, and full height
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),  // Rounded top left
                            topRight: Radius.circular(30),  // Rounded top right
                            bottomLeft: Radius.circular(0), // Sharp bottom left
                            bottomRight: Radius.circular(0), // Sharp bottom right
                          ),
                          // Added subtle shadow for depth on white background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              onBoardingData[index]['title'],
                              style: GoogleFonts.oswald(
                                textStyle: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000)
                                  , // Keep the dark color for title
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              onBoardingData[index]['description'],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600], // Slightly darker gray for better visibility
                              ),
                              maxLines: 9,
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

            // Skip button at top-right - Changed color for white background
            Positioned(
              top: 30,
              right: 10,
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: Color(0xFF000000)
                      , // Changed to dark color for visibility on white background
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom navigation indicators and forward button
            Positioned(
              bottom: 30,
              right: 20,
              left: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(
                        onBoardingData.length,
                            (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200), // Fixed duration unit
                            height: 8,
                            width: (index == currentPage) ? 40 : 15,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: (index == currentPage) ? Color(0xFF1976D2)
                                  : Colors.grey[400], // Adjusted inactive color
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (currentPage < onBoardingData.length - 1) {
                        // Move to the next page
                        pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      } else {
                        // Navigate to login screen when on the last page
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2), // Keep dark button color for contrast
                      foregroundColor: Colors.white, // Ensure text stays white
                      minimumSize: Size(140, 39),
                      elevation: 3, // Added elevation for better visibility on white background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                    child: Text(
                      currentPage == onBoardingData.length - 1 ? "Continue" : "Get Started",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white, // Explicit white text color
                        fontWeight: FontWeight.w600, // Added font weight for better visibility
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
