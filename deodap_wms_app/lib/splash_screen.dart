import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_APP_VERSION = 'appVersion';

  String _version = '—';
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAndCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;

    // Get current version
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    setState(() => _version = currentVersion);

    // Navigate after 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (isLoggedIn) {
      _goNext(const HomeScreen());
    } else {
      _goNext(const OnboardingScreen());
    }
  }

  void _goNext(Widget screen) {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => screen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // --- Center logo + loader ---
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/splash_image.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
              ],
            ),
            const Spacer(),
            // --- Footer ---
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.briefcase,
                          size: 16, color: Colors.black87),
                      SizedBox(width: 6),
                      Text(
                        'Powered by vacalvers.com',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version: $_version', // ✅ shows live version
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
}
