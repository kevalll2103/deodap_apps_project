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

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text("Seller ID: ${userData!['seller_id']}"),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text("Name: ${userData!['seller_name']}"),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: Text("Store: ${userData!['store_name']}"),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text("Contact: ${userData!['contact_number']}"),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text("Email: ${userData!['email']}"),
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: Text("CRN: ${userData!['crn']}"),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text("Username: ${userData!['username']}"),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text("Created At: ${userData!['created_at']}"),
            ),
          ],
        ),
      ),
    );
  }
}
