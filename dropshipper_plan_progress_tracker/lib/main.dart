import 'package:flutter/material.dart';

// Import your existing screens
import 'login.dart';
import 'dashboard.dart';
import 'Settings.dart';
import 'Appinfo.dart';
import 'plans_details.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropshipper Plan Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Login(),
        '/dashboard': (context) => const Dashboard(),
        '/settings': (context) => const Settings(),
        '/app_info': (context) => const AppInfo(),
        '/plans': (context) => PlansScreen(),
      },
    );
  }
}
