import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amz/view/splashscreen_view.dart';

class DropshipperUserdetailsscreenView extends StatefulWidget {
  const DropshipperUserdetailsscreenView({super.key});

  @override
  State<DropshipperUserdetailsscreenView> createState() => _DropshipperUserdetailsscreenViewState();
}

class _DropshipperUserdetailsscreenViewState extends State<DropshipperUserdetailsscreenView> {
  String sellerName = '';
  String contactNumber = '';
  String crn = '';
  String storeName = '';
  String email = '';
  String selectedAvatar = 'assets/images/avatar1.png';
  File? avatarImage;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          sellerName = prefs.getString('seller_name') ?? 'N/A';
          contactNumber = prefs.getString('contact_number') ?? 'N/A';
          crn = prefs.getString('crn') ?? 'N/A';
          storeName = prefs.getString('store_name') ?? 'N/A';
          email = prefs.getString('email') ?? 'admin@deodap.com';
          selectedAvatar = prefs.getString('selectedAvatar') ?? 'assets/images/avatar1.png';

          final avatarPath = prefs.getString('profile_image_path');
          if (avatarPath != null && File(avatarPath).existsSync()) {
            avatarImage = File(avatarPath);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Logout',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to logout from your account?',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[800], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You will need to login again to access your account.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _performLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SplashscreenView()),
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      _showSnackBar('Logout failed. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildZoomableAvatar() {
    return GestureDetector(
      onTap: () {
        if (avatarImage != null) {
          _showImageZoomDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1565C0), // Dark blue border
        ),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipOval(
            child: avatarImage != null
                ? Image.file(
              avatarImage!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            )
                : Image.asset(
              selectedAvatar,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageZoomDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: avatarImage != null
                        ? Image.file(avatarImage!)
                        : Image.asset(selectedAvatar),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: const Color(0xFF1565C0),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1565C0),
              size: 22,
            ),
            tooltip: 'Go back',
          ),
          Expanded(
            child: Text(
              "User Details",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildZoomableAvatar(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "DEODAP DROPSHIPPER",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                "Logout",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Text(
                "Version: 1.1.1",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "© 2025 Deodap. All rights reserved.",
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Developed by Keval Kateshiya",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1565C0),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildProfileSection(),
                    Column(
                      children: [
                        _buildDetailCard(
                          sellerName,
                          'Seller name used in app',
                          Icons.person_rounded,
                          Colors.white,
                        ),
                        _buildDetailCard(
                          contactNumber,
                          'Contact Number (Username)',
                          Icons.phone_rounded,
                          Colors.white,
                        ),
                        _buildDetailCard(
                          email,
                          'Registered Email ID',
                          Icons.email_rounded,
                          Colors.white,
                        ),
                        _buildDetailCard(
                          crn,
                          'Customer Relation Number',
                          Icons.confirmation_number_rounded,
                          Colors.white,
                        ),
                        _buildDetailCard(
                          storeName,
                          'Store Name',
                          Icons.store_rounded,
                          Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }
}