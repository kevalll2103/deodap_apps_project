import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? userData;

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

  Widget _buildItem(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(color: Colors.black54)),
        subtitle: Text(
          value,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Account Information",
            style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildItem("Username", userData!['username'] ?? "N/A",
                Icons.account_circle),
            _buildItem("Customer Reference Number", userData!['crn'] ?? "N/A",
                Icons.confirmation_number),
            _buildItem("Email Address", userData!['email'] ?? "N/A",
                Icons.email_rounded),
            if (userData!['seller_name'] != null)
              _buildItem("Seller Name", userData!['seller_name'], Icons.person),
            if (userData!['contact_number'] != null)
              _buildItem(
                  "Contact Number", userData!['contact_number'], Icons.phone),
          ],
        ),
      ),
    );
  }
}
