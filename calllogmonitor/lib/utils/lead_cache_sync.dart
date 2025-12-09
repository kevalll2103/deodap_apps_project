import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCacheSync {
  static const _keyCache = 'flutter.leads_contacts_cache';
  static const _keyWh = 'flutter.executive_warehouse_id';
  static const _keySales = 'flutter.executive_id';
  static const _keyAuth = 'flutter.executive_auth_key';

  /// Request the minimum for the native receiver
  static Future<void> ensureNativePermissions() async {
    try {
      await [
        Permission.contacts,       // nice to have for future use
        Permission.phone,          // READ_PHONE_STATE
        Permission.notification,   // Android 13+
      ].request();
      // READ_CALL_LOG is "dangerous" and can only be granted from settings on newer Android.
      // Ask nicely if it's denied.
      if (await Permission.phone.isDenied) {
        await openAppSettings();
      }
    } catch (_) {}
  }

  /// list expects elements like: {'name': 'Keval', 'mobile': '9889663378'}
  static Future<void> writeLeadsCache(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = list
        .map((m) {
      final mobile = (m['mobile'] ?? '').toString().trim();
      if (mobile.isEmpty) return null;
      final name = (m['name'] ?? '').toString().trim();
      return {
        'name': name.isEmpty ? mobile : name,
        'mobile': mobile,
      };
    })
        .whereType<Map<String, dynamic>>()
        .toList();

    await prefs.setString(_keyCache, jsonEncode(filtered));
  }

  /// Helpers to store executive context for the native side (if not already stored elsewhere)
  static Future<void> storeExecutiveContext({
    required String warehouseId,
    required String salesId,
    required String apiAuthKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWh, warehouseId);
    // If you already store as int elsewhere, keep that — native code handles both.
    final sId = int.tryParse(salesId);
    if (sId != null) {
      await prefs.setInt(_keySales, sId);
    } else {
      await prefs.setString(_keySales, salesId);
    }
    await prefs.setString(_keyAuth, apiAuthKey);
  }
}
