import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_ROLE = 'role';

  String _version = '—';
  Timer? _bootTimer;

  // Version API
  static const String VERSION_API =
      "https://customprint.deodap.com/stockbridge/new_version.php";

  // API result storage
  String? _updateUrl;
  bool _isForceUpdate = false;

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    super.dispose();
  }

  // ---------------------------
  // INITIAL SETUP
  // ---------------------------
  Future<void> _startSetup() async {
    final bool blockNavigation = await _checkVersionFromServer();

    if (!blockNavigation) {
      await _checkLoginFlow();
    }
  }

  // ---------------------------
  // VERSION CHECK FROM SERVER
  // ---------------------------
  Future<bool> _checkVersionFromServer() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    setState(() => _version = currentVersion);

    try {
      final res = await http.get(Uri.parse(VERSION_API));

      if (res.statusCode != 200) {
        debugPrint("Version API Error: HTTP ${res.statusCode}");
        return false;
      }

      final data = jsonDecode(res.body);

      String latestVersion = data["latest_version"] ?? currentVersion;
      String message = data["message"] ?? "A new version is available.";
      bool forceUpdate = data["force_update"] ?? false;

      // IMPORTANT: Correct key from your API
      String? updateUrl = data["download_link"];

      _updateUrl = updateUrl;
      _isForceUpdate = forceUpdate;

      if (currentVersion != latestVersion) {
        _showUpdateDialog(message, forceUpdate);
        return forceUpdate; // block navigation if force update
      }
    } catch (e) {
      debugPrint("Version API Error: $e");
    }

    return false;
  }

  // ---------------------------
  // OPEN UPDATE URL
  // ---------------------------
  Future<void> _openUpdateUrl() async {
    if (_updateUrl == null || _updateUrl!.isEmpty) {
      debugPrint("No update URL provided");
      return;
    }

    final uri = Uri.parse(_updateUrl!);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ---------------------------
  // UPDATE POPUP
  // ---------------------------
  void _showUpdateDialog(String msg, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text("Update Available"),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text("Update"),
              isDefaultAction: true,
              onPressed: () {
                _openUpdateUrl();
              },
            ),
            if (!forceUpdate)
              CupertinoDialogAction(
                child: const Text("Later"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }

  // ---------------------------
  // LOGIN LOGIC
  // ---------------------------
  Future<void> _checkLoginFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;
    final String? role = prefs.getString(KEY_ROLE);

    await Future.delayed(const Duration(seconds: 2));

    if (!isLoggedIn) {
      _goNext(const Onboardingscreen());
    } else {
      if (role == "admin" || role == "employee") {
        _goNext(const empHomeScreen());
      } else {
        _goNext(const Onboardingscreen());
      }
    }
  }

  // ---------------------------
  // NAVIGATION
  // ---------------------------
  void _goNext(Widget screen) {
    _bootTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => screen),
      );
    });
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Column(
              children: [
                Image.asset(
                  'assets/images/splash.png',
                  width: 260,
                ),
                const SizedBox(height: 20),
                const CupertinoActivityIndicator(),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.briefcase, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Powered by Deodap International Pvt Ltd",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Version: $_version",
                    style: const TextStyle(fontSize: 12),
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
