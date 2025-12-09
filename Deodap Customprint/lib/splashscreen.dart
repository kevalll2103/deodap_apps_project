import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your screens
import 'package:Deodap_Customprint/homescreen.dart';        // HomescreenCupertinoIOS()
import 'package:Deodap_Customprint/onboardingscreen.dart';  // Onboardingscreen()

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  static const String KEY_LOGIN = 'isLoggedIn';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    Timer(const Duration(milliseconds: 1200), _goNext);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = 'v${info.version} (${info.buildNumber})');
  }

  Future<void> _goNext() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
        isLoggedIn ? const HomescreenCupertinoIOS() : const Onboardingscreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Center logo
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/lanchure_icon.png',
                  width: size.width * 0.45, // adjust if needed
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Bottom: powered by + version
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  const Text(
                    'Powered by customprint.deeodp.com',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _version.isEmpty ? '' : _version,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
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
