import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const String _keyAppLockEnabled = 'appLockEnabled';
  static const String _keyAppLockType = 'appLockType';
  static const String _keyAppPin = 'appPin';

  static Future<bool> isAppLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAppLockEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getAppLockType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAppLockType) ?? 'none';
    } catch (_) {
      return 'none';
    }
  }

  static Future<String> getAppPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAppPin) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> verifyPin(String enteredPin) async {
    try {
      final storedPin = await getAppPin();
      return enteredPin == storedPin;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disableAppLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAppLockEnabled, false);
      await prefs.setString(_keyAppLockType, 'none');
      await prefs.setString(_keyAppPin, '');
    } catch (_) {
      // Handle error silently
    }
  }
}