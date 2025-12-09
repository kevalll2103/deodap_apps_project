import 'dart:convert';
import 'package:flutter/material.dart' hide Notification;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'settings.dart';
import 'about.dart';
import 'contacts.dart';
import 'profile.dart';
import 'notification.dart';
import 'plans_details.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? userData;
  int _selectedIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
    HomeScreen(userData: userData), // Pass userData to HomeScreen
    PlansScreen(),
    const Contacts(),
    const Settings(),
    const About(),
  ];

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Progress Tracker"),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Profile()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Notification()),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex], // Directly show the selected screen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Plans"),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "About"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; // Accept userData as parameter

  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson == null) return;

    Map<String, dynamic> userData = jsonDecode(userJson);
    String sellerId = userData['seller_id'];

    final url = Uri.parse(
      "https://customprint.deodap.com/api_dropshipper_tracker/total_count_seller.php?seller_id=$sellerId",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      setState(() {
        dashboardData = jsonResponse['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildSummaryCard(String title, Map<String, dynamic> items) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...items.entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text("${e.key}: ${e.value}", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card for a single plan that ALSO shows its step details inside.
  Widget buildPlanWithStepsCard(
      Map<String, dynamic> plan,
      List<dynamic> allSteps,
      ) {
    final planId = plan['plan_id'].toString();
    final planSteps = allSteps
        .where((s) => s is Map && s['plan_id'].toString() == planId)
        .toList();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text("Plan: ${plan['name']}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Text(
          "Total: ${plan['total_steps']}  |  Open: ${plan['open_steps']}  |  In Process: ${plan['inprocess_steps']}  |  Completed: ${plan['completed_steps']}",
          style: const TextStyle(fontSize: 13),
        ),
        children: [
          const Divider(height: 1),
          if (planSteps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No steps yet."),
            )
          else
            ...planSteps.map<Widget>((step) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text("${step['step_number']}"),
                ),
                title: Text("${step['step_description']}"),
                subtitle: Text("Status: ${step['status']}  •  ${step['created_at']}"),
              );
            }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (dashboardData == null) return const Center(child: Text("No data found"));

    final plans = (dashboardData!['plans_with_steps'] as List? ?? []);
    final steps = (dashboardData!['step_details'] as List? ?? []);

    return Column(
      children: [
        // ✅ Welcome Section - Only shows on Home tab
        if (widget.userData != null)
          Container(
            color: Colors.grey.shade200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome @${widget.userData!['seller_name']}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Store Name: ${widget.userData!['store_name']}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),

        // ✅ Dashboard Content
        Expanded(
          child: ListView(
            children: [
              // ✅ Plans Summary
              buildSummaryCard("Plans Summary", {
                "Total Plans": dashboardData!['plans_summary']['total_plans'],
                "Active Plans": dashboardData!['plans_summary']['active_plans'],
                "Inactive Plans": dashboardData!['plans_summary']['inactive_plans'],
              }),

              // ✅ Plans WITH their Step Details inside
              ...plans.map<Widget>((p) =>
                  buildPlanWithStepsCard(Map<String, dynamic>.from(p), steps)),

              // ✅ Comments
              buildSummaryCard("Comments", {
                "Total Comments": dashboardData!['comments']['total_comments'],
              }),
            ],
          ),
        ),
      ],
    );
  }
}
