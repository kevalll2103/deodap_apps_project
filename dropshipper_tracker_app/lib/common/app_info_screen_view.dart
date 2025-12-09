import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoScreenView extends StatefulWidget {
  const AppInfoScreenView({super.key});

  @override
  State<AppInfoScreenView> createState() => _AppInfoScreenViewState();
}

class _AppInfoScreenViewState extends State<AppInfoScreenView> {
  String _currentVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A365D), Color(0xFF2C5AA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'App Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // App Name
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "Deodap Dropshipper\nPlan Progress Tracker",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A365D),
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // App Description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline_rounded,
                        size: 60,
                        color: Color(0xFF1A365D),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Track Your Dropshipper Plan Progress",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A365D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Stay updated with real-time progress of your dropshipper service plan. Track milestones, timelines, and service stages as our team completes each phase of your journey.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Company Logo (if you have one)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/deodap_logo.png', // Update with your logo path
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        child: Icon(
                          Icons.business_rounded,
                          size: 60,
                          color: Color(0xFF1A365D),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Features Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Key Features:",
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A365D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem("📊", "Real-time Progress Tracking"),
                      _buildFeatureItem("📅", "Timeline & Milestone Updates"),
                      _buildFeatureItem("🔔", "Instant Notifications"),
                      _buildFeatureItem("📋", "Service Stage Monitoring"),
                      _buildFeatureItem("💼", "Plan Status Overview"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Copyright
                Text(
                  "© 2024 - 2025 Deodap International Pvt Ltd",
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // License Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A365D).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Deodap Dropshipper Plan Progress Tracker',
                        applicationVersion: _currentVersion,
                        applicationLegalese: '© 2024 - 2025 Deodap International Pvt Ltd',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(200, 50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "View Licenses",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Version Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF1A365D),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Version: $_currentVersion",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2D3748),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Developed by Keval Kateshiya",
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Deodap International Pvt Ltd",
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
