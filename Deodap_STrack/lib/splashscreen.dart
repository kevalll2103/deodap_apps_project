import 'package:Deodap_STrack/homescreen.dart';
import 'package:Deodap_STrack/onboardingscreen.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {

  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_APP_VERSION = 'appVersion';  // Store the version info
  @override
  void initState() {
    super.initState();
    _checkAppVersionAndLoginStatus(context);
  }

  // This method checks if the app version is the same or if it needs to log the user out
  void _checkAppVersionAndLoginStatus(BuildContext context) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate loading

    // Retrieve the login status from SharedPreferences
    var shared = await SharedPreferences.getInstance();
    bool isLoggedIn = shared.getBool(KEY_LOGIN) ?? false;

    // Get the current app version using package_info_plus
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentAppVersion = packageInfo.version;

    // Get the stored app version from SharedPreferences
    String? storedAppVersion = shared.getString(KEY_APP_VERSION);

    // Print the current app version and stored version to console for debugging
    print('Current App Version: $currentAppVersion');
    print('Stored App Version: $storedAppVersion');

    if (storedAppVersion == null) {
      // If this is the first time the app is launched, store the version
      print('First launch or version not stored. Storing current version.');
      shared.setString(KEY_APP_VERSION, currentAppVersion);  // Store the current version

      // Navigate to appropriate screen based on login status
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Homescreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Onboardingscreen()), // Go to Login Screen
        );
      }
    } else {
      // Version mismatch: Logout the user and update version
      if (storedAppVersion != currentAppVersion) {
        print('App version mismatch detected!');
        print('Logging out user and updating version...');

        // Logout the user
        if (isLoggedIn) {
          shared.setBool(KEY_LOGIN, false);  // Log out the user
        }

        shared.setString(KEY_APP_VERSION, currentAppVersion);  // Store the new version

        // Navigate to appropriate screen (Login or Onboarding)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Onboardingscreen()),  // Go to Login Screen after version mismatch
        );
      } else {
        print('App version matches the stored version..');
        if (isLoggedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Homescreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Onboardingscreen()), // Go to Onboarding screen if not logged in
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Spacer(),
          Center(
            child: Image.asset('assets/images/lanchure_icon.png', width: 290,),
          ),
          Spacer(),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: Colors.grey,fontSize: 12),
              children: <TextSpan>[
                TextSpan(text: 'Developed by '),
                TextSpan(text: '@yash kalani'),
              ],
            ),
          ),
          Text(
            "Version: 1.0.0",
            style: TextStyle(
              color: Colors.grey,fontSize: 11
            ),
          ),
          SizedBox(height: 5),

        ],
      ),
    );
  }
}
