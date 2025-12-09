import 'dart:async';
import 'package:flutter/services.dart';
import '/models/item.dart';

class CallLogService {
  static const MethodChannel _channel =
  MethodChannel('com.example.calllogmonitor/permissions');

  static Future<bool> checkAllPermissions() async {
    try {
      final bool hasAll = await _channel.invokeMethod('checkAllPermissions');
      return hasAll;
    } catch (e) {
      print('Error checking all permissions: $e');
      return false;
    }
  }

  static Future<bool> requestAllPermissions() async {
    try {
      final bool granted = await _channel.invokeMethod('requestAllPermissions');
      return granted;
    } catch (e) {
      print('Error requesting all permissions: $e');
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkPermission');
      return hasPermission;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestPermission');
      return granted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  static Future<List<CallLogItem>> fetchLogs({
    int offset = 0,
    int limit = 200,
    String? simSlot, // Add simSlot parameter (null means all SIMs)
  }) async {
    try {
      // Calculate timestamp for 3 months ago
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final timestampThreeMonthsAgo = threeMonthsAgo.millisecondsSinceEpoch;

      // Prepare parameters
      final Map<String, dynamic> params = {
        'offset': offset,
        'limit': limit,
        'fromDate': timestampThreeMonthsAgo,
      };

      // Add simSlot parameter if specified
      if (simSlot != null) {
        params['simSlot'] = simSlot;
      }

      final List<dynamic> rawLogs =
      await _channel.invokeMethod('getCallLogsWithSim', params);

      return rawLogs
          .map((e) => CallLogItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch call logs: $e');
    }
  }

  static Future<int> getTotalCallLogsCount({String? simSlot}) async {
    try {
      // Calculate timestamp for 3 months ago
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final timestampThreeMonthsAgo = threeMonthsAgo.millisecondsSinceEpoch;

      // Prepare parameters
      final Map<String, dynamic> params = {
        'fromDate': timestampThreeMonthsAgo,
      };

      // Add simSlot parameter if specified
      if (simSlot != null) {
        params['simSlot'] = simSlot;
      }

      final int totalLogs =
      await _channel.invokeMethod('getTotalCallLogsCount', params);
      return totalLogs;
    } catch (e) {
      print('Error getting total call logs count: $e');
      return 0;
    }
  }

  // New method to get SIM-specific call logs count for last 3 months
  static Future<Map<String, int>> getSimSpecificCounts() async {
    try {
      // Calculate timestamp for 3 months ago
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final timestampThreeMonthsAgo = threeMonthsAgo.millisecondsSinceEpoch;

      final Map<dynamic, dynamic> counts =
      await _channel.invokeMethod('getSimSpecificCounts', {
        'fromDate': timestampThreeMonthsAgo,
      });
      return {
        'SIM 1': counts['sim1'] ?? 0,
        'SIM 2': counts['sim2'] ?? 0,
        'SIM Unknown': counts['unknown'] ?? 0,
      };
    } catch (e) {
      print('Error getting SIM specific counts: $e');
      return {'SIM 1': 0, 'SIM 2': 0, 'SIM Unknown': 0};
    }
  }

  // Helper method to fetch logs for specific SIM
  static Future<List<CallLogItem>> fetchLogsBySim(
      String simSlot, {
        int offset = 0,
        int limit = 200,
      }) async {
    return fetchLogs(
      offset: offset,
      limit: limit,
      simSlot: simSlot,
    );
  }

  // Helper method to fetch all logs (backward compatibility)
  static Future<List<CallLogItem>> fetchAllLogs({
    int offset = 0,
    int limit = 200,
  }) async {
    return fetchLogs(
      offset: offset,
      limit: limit,
      simSlot: null, // null means fetch from all SIMs
    );
  }

  // New method to fetch logs after a specific timestamp
  static Future<List<CallLogItem>> fetchLogsAfterTimestamp({
    required int timestamp,
    required String simSlot,
  }) async {
    try {
      // Fetch recent logs (last 1000 to cover most cases)
      final allLogs = await fetchLogs(
        offset: 0,
        limit: 1000,
        simSlot: simSlot,
      );

      // Filter logs after timestamp
      final filteredLogs = allLogs.where((log) {
        try {
          final logTimestamp = int.parse(log.date);
          return logTimestamp > timestamp;
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort by timestamp (newest first)
      filteredLogs.sort((a, b) {
        try {
          final aTime = int.parse(a.date);
          final bTime = int.parse(b.date);
          return bTime.compareTo(aTime);
        } catch (e) {
          return 0;
        }
      });

      return filteredLogs;
    } catch (e) {
      print('Error fetching logs after timestamp: $e');
      return [];
    }
  }
}
