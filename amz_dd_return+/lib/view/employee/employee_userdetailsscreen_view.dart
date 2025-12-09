import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amz/view/splashscreen_view.dart';
import 'package:amz/view/onboardingscreen_view.dart';

class EmployeeUserdetailsscreenView extends StatefulWidget {
  const EmployeeUserdetailsscreenView({super.key});

  @override
  State<EmployeeUserdetailsscreenView> createState() => _EmployeeUserdetailsscreenViewState();
}

class _EmployeeUserdetailsscreenViewState extends State<EmployeeUserdetailsscreenView> {
  String userId = '';
  String sellerName = '';
  String contactNumber = '';
  String password = '';
  File? avatarImage;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    File? img;
    if (path != null && File(path).existsSync()) {
      img = File(path);
    }

    setState(() {
      userId = prefs.getString('userId') ?? 'EMP-1001';
      sellerName = prefs.getString('userEmail') ?? 'admin@deodap.com';
      contactNumber = prefs.getString('contact_number') ?? '8866966703';
      password = prefs.getString('userPassword') ?? '********';
      avatarImage = img;
    });
  }

  String getMaskedPhone(String number) {
    if (number.length >= 10) {
      return '+91 ••••• •••' + number.substring(number.length - 2);
    }
    return number;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red[600],
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF718096),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => SplashscreenView()),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    ImageProvider imageProvider;

    if (avatarImage != null) {
      imageProvider = FileImage(avatarImage!);
    } else {
      imageProvider = AssetImage('assets/images/man.jpeg');
    }

    return GestureDetector(
      onTap: () {
        if (avatarImage != null) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          avatarImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A365D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1A365D), size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: const Color(0xFF718096),
              fontSize: 14,
            ),
          ),
        ),
        Divider(color: const Color(0xFFE2E8F0), indent: 70),
      ],
    );
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
        title: Text(
          'Employee Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileImage(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A365D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "DEODAP ADMIN",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF1A365D),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.email_rounded, sellerName, "Official Email ID"),
                  _buildInfoTile(Icons.phone_rounded, getMaskedPhone(contactNumber), "Verified Contact Number"),
                  _buildInfoTile(Icons.badge_rounded, "EMPLOYEE ACCESS", "Internal Staff ID • Confidential"),
                  _buildInfoTile(Icons.lock_outline_rounded, password, "Account Password"),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    "© 2025 Deodap • All rights reserved",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF718096),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Developed by Keval Kateshiya",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF718096),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}