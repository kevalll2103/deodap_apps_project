import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? userData;

  // Blue-White Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color whiteColor = Colors.white;
  static const Color greyLight = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      setState(() {
        userData = jsonDecode(userJson);
      });
    }
  }

  Widget _buildProfileInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: darkBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        backgroundColor: greyLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: whiteColor,
          foregroundColor: darkBlue,
          title: const Text(
            "Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: greyLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _ProfileState.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData!['seller_name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData!['store_name'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  _buildProfileInfoCard(
                    "ID",
                    userData!['id']?.toString() ?? 'N/A',
                    Icons.fingerprint_rounded,
                  ),
                  _buildProfileInfoCard(
                    "Contact Number",
                    userData!['contact_number'] ?? 'N/A',
                    Icons.phone_rounded,
                  ),
                  _buildProfileInfoCard(
                    "Email Address",
                    userData!['email'] ?? 'N/A',
                    Icons.email_rounded,
                  ),
                  _buildProfileInfoCard(
                    "Username",
                    userData!['username'] ?? 'N/A',
                    Icons.account_circle_rounded,
                  ),
                  _buildProfileInfoCard(
                    "Customer Reference Number",
                    userData!['crn'] ?? 'N/A',
                    Icons.confirmation_number_rounded,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
