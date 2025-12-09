import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

/// --- Brand Palette (Purple) ---
class AppColors {
  static const Color purple = Color(0xFF6B52A3);     // Primary
  static const Color purpleDark = Color(0xFF6B52A3); // Button shadow/grad end
  static const Color purpleLight = Color(0xFFEDE9FE); // Accents / fills
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textMuted = Color(0xFF6C6C70);
  static const Color bg = Color(0xFFF4F2F8); // soft off-white with a hint of violet
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenViewState();
}

class _OnboardingScreenViewState extends State<OnboardingScreen> {
  final List<Map<String, String>> onBoardingData = const [
    {
      "image": 'assets/a1.png',
      "title": 'Welcome to DeoDap Warehouse Management',
      "description":
      'Optimize your warehouse operations with DeoDap’s WMS. Track inventory, manage orders, and boost efficiency in app.',
    },
    {
      "image": 'assets/a3.png',
      "title": 'Quick QR Scanning',
      "description":
      'Easily scan product or order QR codes to ensure fast, accurate, and reliable order handling within your warehouse workflow.',
    },
    {
      "image": 'assets/a2.png',
      "title": 'Manage Warehouse Orders & Tracking',
      "description":
      'Access all warehouse orders in real time—view pending pickups, mark delays, and monitor warehouse activities efficiently.',
    },
  ];

  final PageController pageController = PageController();
  int currentPage = 0;

  void onChanged(int index) => setState(() => currentPage = index);

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Soft background with a gentle vertical gradient toward purple
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0, -1),
            end: Alignment(0, 1),
            colors: [Color(0xFFF9F7FF), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Optional texture overlay (won't crash if missing)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.03,
                    child: Image(
                      image: AssetImage('assets/leather_texture.png'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // === PAGE CONTENT (image big + bottom curved panel) ===
              LayoutBuilder(
                builder: (context, constraints) {
                  final double maxW = constraints.maxWidth;
                  final double maxH = constraints.maxHeight;

                  // Larger image height — sits behind the curved bottom panel
                  final double imageTopPadding = maxH * 0.2;
                  final double imageHeightFactor = 0.80; // increased

                  return PageView.builder(
                    controller: pageController,
                    itemCount: onBoardingData.length,
                    onPageChanged: onChanged,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data = onBoardingData[index];

                      return Stack(
                        children: [
                          // ===== Big Illustration (top) =====
                          Positioned.fill(
                            child: Column(
                              children: [
                                SizedBox(height: imageTopPadding),
                                Expanded(
                                  flex: (imageHeightFactor * 1000).toInt(),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: maxW * 0.06,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: maxW * 0.95,
                                        child: AspectRatio(
                                          aspectRatio: 1.15, // slightly wider than square
                                          child: Image.asset(
                                            data['image']!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Spacer area that will be covered by the bottom panel
                                const SizedBox(height: 0),
                              ],
                            ),
                          ),

                          // ===== Curved Bottom Panel with Title + Subtitle + Controls =====
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _BottomPanel(
                              width: maxW,
                              height: maxH * 0.34, // curved panel height
                              sidePad: maxW * 0.06,
                              title: data['title']!,
                              description: data['description']!,
                              titleSize: _clamp(maxW * 0.058, 20, 26),
                              descSize: _clamp(maxW * 0.041, 13, 16),
                              pageCount: onBoardingData.length,
                              currentPage: currentPage,
                              onNext: () {
                                if (currentPage < onBoardingData.length - 1) {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 420),
                                    curve: Curves.easeOutCubic,
                                  );
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    CupertinoPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // Skip button (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
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
}

/// Curved bottom panel that holds (title, subtitle, indicators, CTA)
class _BottomPanel extends StatelessWidget {
  final double width;
  final double height;
  final double sidePad;
  final String title;
  final String description;
  final double titleSize;
  final double descSize;
  final int pageCount;
  final int currentPage;
  final VoidCallback onNext;

  const _BottomPanel({
    super.key,
    required this.width,
    required this.height,
    required this.sidePad,
    required this.title,
    required this.description,
    required this.titleSize,
    required this.descSize,
    required this.pageCount,
    required this.currentPage,
    required this.onNext,
  });

  bool get _isLast => currentPage == pageCount - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.94),
            AppColors.purpleLight.withOpacity(0.72),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(sidePad, 16, sidePad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.2,
                color: AppColors.textDark,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.5),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: descSize,
                fontWeight: FontWeight.w400,
                height: 1.45,
                letterSpacing: -0.1,
                color: AppColors.textMuted,
              ),
            ),
          ),

          const Spacer(),

          // Indicators + CTA (inside a small elevated strip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.95),
                  AppColors.purpleLight.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Indicators
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(pageCount, (i) {
                      final bool active = i == currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 8,
                        width: active ? 26 : 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: active
                              ? const LinearGradient(
                            colors: [AppColors.purple, AppColors.purpleDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: active ? null : const Color(0xFFCEC9DB),
                          boxShadow: active
                              ? [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                              : [],
                        ),
                      );
                    }),
                  ),
                ),

                // CTA
                _isLast
                // Last page: "Get Started" button
                    ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.purple, AppColors.purpleDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onNext,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                )
                // Other pages: circular next button
                    : DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.purple, AppColors.purpleDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(999),
                    minimumSize: const Size(52, 52),
                    onPressed: onNext,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

/// Utility to clamp a value between min and max.
double _clamp(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
