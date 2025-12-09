import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../route/app_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String KEY_LOGIN = 'isLoggedIn';

  String _version = '—';

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;

    // Get current app version
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });

    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 2));

    // Navigate using GetX
    if (isLoggedIn) {
      Get.offNamed(AppRoutes.home);
    } else {
      Get.offNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // --- Center Logo ---
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/splash.png',
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
                      Icon(
                        CupertinoIcons.briefcase,
                        size: 16,
                        color: Colors.black87,
                      ),
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
                    'Version: $_version',
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
