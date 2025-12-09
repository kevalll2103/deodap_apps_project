import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '/models/item.dart';

class CallLogService {
  static const MethodChannel _channel =
  MethodChannel('com.example.calllogmonitor/permissions');

  // Cache management
  static final Map<String, List<CallLogItem>> _cache = {};
  static DateTime? _lastCacheUpdate;
  static const int _cacheExpiryMinutes = 5;

  // Sync tracking
  static const String _lastSyncKey = 'last_call_log_sync';
  static const String _lastCallCountKey = 'last_call_count';

  // API configuration
  static const String _baseUrl = 'https://trackship.in';
  static const String _endpoint = '/api/lms/calls.php';
  static const int _requestTimeout = 30;
  static const int _batchSize = 50;

  // ==================== PERMISSION METHODS ====================
  static Future<bool> checkAllPermissions() async {
    try {
      final bool? hasAll = await _channel.invokeMethod('checkAllPermissions');
      return hasAll ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestAllPermissions() async {
    try {
      final bool? granted = await _channel.invokeMethod('requestAllPermissions');
      return granted ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    try {
      final bool? hasPermission = await _channel.invokeMethod('checkPermission');
      return hasPermission ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final bool? granted = await _channel.invokeMethod('requestPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      // Silently handle error
    }
  }

  // ==================== CORE FETCH METHODS ====================
  static Future<List<CallLogItem>> fetchLogs({
    int offset = 0,
    int limit = 200,
    String? simSlot,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final cacheKey = _generateCacheKey(offset, limit, simSlot, startDate, endDate);

      // Return cached data if valid
      if (_cache.containsKey(cacheKey) && _isCacheValid()) {
        return List<CallLogItem>.from(_cache[cacheKey]!);
      }

      // Default date range: last 3 months if not provided
      final fromDate = startDate ?? DateTime.now().subtract(const Duration(days: 90));
      final toDate = endDate ?? DateTime.now();

      final Map<String, dynamic> params = {
        'offset': offset,
        'limit': limit,
        'fromDate': fromDate.millisecondsSinceEpoch,
        'toDate': toDate.millisecondsSinceEpoch,
      };

      if (simSlot != null) {
        params['simSlot'] = simSlot;
      }

      final List<dynamic> rawLogs =
          await _channel.invokeMethod('getCallLogsWithSim', params) ?? [];

      final callLogs = rawLogs
          .map((e) => CallLogItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Cache the results
      _cache[cacheKey] = List<CallLogItem>.from(callLogs);
      _lastCacheUpdate = DateTime.now();

      return callLogs;
    } on PlatformException catch (e) {
      throw Exception('Platform error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch call logs: $e');
    }
  }

  static Future<int> getTotalCallLogsCount({String? simSlot}) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final Map<String, dynamic> params = {
        'fromDate': threeMonthsAgo.millisecondsSinceEpoch,
      };

      if (simSlot != null) {
        params['simSlot'] = simSlot;
      }

      final int totalLogs =
          await _channel.invokeMethod('getTotalCallLogsCount', params) ?? 0;
      return totalLogs;
    } catch (e) {
      return 0;
    }
  }

  // ==================== ADDED METHODS FROM FIRST FILE ====================

  /// Get total count of call logs for a specific SIM only
  static Future<int> getTotalCallLogsCountForSim(String simSlot) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final Map<String, dynamic> params = {
        'fromDate': threeMonthsAgo.millisecondsSinceEpoch,
        'simSlot': simSlot,
      };

      final int totalLogs =
          await _channel.invokeMethod('getTotalCallLogsCount', params) ?? 0;
      return totalLogs;
    } catch (e) {
      // Error getting total count for SIM $simSlot: $e
      return 0;
    }
  }

  /// Fetch call logs for specific SIM with pagination
  static Future<List<CallLogItem>> fetchLogsForSim({
    required int offset,
    required int limit,
    required String simSlot,
  }) async {
    try {
      return await fetchLogs(
        offset: offset,
        limit: limit,
        simSlot: simSlot,
      );
    } catch (e) {
      // Error fetching logs for SIM $simSlot: $e
      return [];
    }
  }


  // ==================== SIM-SPECIFIC METHODS ====================
  static Future<Map<String, int>> getSimSpecificCounts() async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final Map<dynamic, dynamic> counts =
          await _channel.invokeMethod('getSimSpecificCounts', {
            'fromDate': threeMonthsAgo.millisecondsSinceEpoch,
          }) ?? {'sim1': 0, 'sim2': 0, 'unknown': 0};

      return {
        'SIM 1': counts['sim1'] as int? ?? 0,
        'SIM 2': counts['sim2'] as int? ?? 0,
        'Unknown': counts['unknown'] as int? ?? 0,
      };
    } catch (e) {
      return {'SIM 1': 0, 'SIM 2': 0, 'Unknown': 0};
    }
  }

  static Future<List<CallLogItem>> fetchLogsBySim(
      String simSlot, {
        int offset = 0,
        int limit = 200,
      }) async {
    return fetchLogs(offset: offset, limit: limit, simSlot: simSlot);
  }

  static Future<List<CallLogItem>> fetchAllLogs({
    int offset = 0,
    int limit = 200,
  }) async {
    return fetchLogs(offset: offset, limit: limit);
  }

  // ==================== STATISTICS METHODS ====================
  static Future<Map<String, int>> getCallLogStats({String? simSlot}) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final Map<String, dynamic> params = {
        'fromDate': threeMonthsAgo.millisecondsSinceEpoch,
      };

      if (simSlot != null) {
        params['simSlot'] = simSlot;
      }

      final Map<dynamic, dynamic> stats =
          await _channel.invokeMethod('getCallLogStats', params) ?? {};

      return {
        'total': stats['total'] as int? ?? 0,
        'incoming': stats['incoming'] as int? ?? 0,
        'outgoing': stats['outgoing'] as int? ?? 0,
        'missed': stats['missed'] as int? ?? 0,
        'rejected': stats['rejected'] as int? ?? 0,
        'blocked': stats['blocked'] as int? ?? 0,
      };
    } catch (e) {
      return {
        'total': 0,
        'incoming': 0,
        'outgoing': 0,
        'missed': 0,
        'rejected': 0,
        'blocked': 0,
      };
    }
  }

  // ==================== NEW CALL DETECTION ====================
  static Future<List<CallLogItem>> getNewCallLogs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final lastSyncTimestamp = prefs.getInt(_lastSyncKey) ?? 0;
      final lastCallCount = prefs.getInt(_lastCallCountKey) ?? 0;
      final currentCount = await getTotalCallLogsCount();

      if (currentCount <= lastCallCount) {
        return [];
      }

      final recentLogs = await fetchLogs(
        offset: 0,
        limit: 100,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      return recentLogs.where((log) {
        final logTimestamp = int.tryParse(log.date) ?? 0;
        return logTimestamp > lastSyncTimestamp;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<CallLogItem>> getNewCallLogsSince({
    required int timestamp,
    String? simSlot,
  }) async {
    try {
      final recentLogs = await fetchLogs(
        offset: 0,
        limit: 500,
        simSlot: simSlot,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      final newLogs = recentLogs.where((log) {
        final logTimestamp = int.tryParse(log.date) ?? 0;
        return logTimestamp > timestamp;
      }).toList();

      // Sort by timestamp descending
      newLogs.sort((a, b) {
        final aTimestamp = int.tryParse(a.date) ?? 0;
        final bTimestamp = int.tryParse(b.date) ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      return newLogs;
    } catch (e) {
      return [];
    }
  }

  static Future<List<CallLogItem>> getNewCallLogsSinceDate({
    required DateTime since,
    String? simSlot,
  }) async {
    return getNewCallLogsSince(
        timestamp: since.millisecondsSinceEpoch,
        simSlot: simSlot
    );
  }

  static Future<List<CallLogItem>> getRecentCallLogs({
    String? simSlot,
    int limit = 50,
  }) async {
    try {
      final recentLogs = await fetchLogs(
        offset: 0,
        limit: limit,
        simSlot: simSlot,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now(),
      );

      // Sort by timestamp descending
      recentLogs.sort((a, b) {
        final aTimestamp = int.tryParse(a.date) ?? 0;
        final bTimestamp = int.tryParse(b.date) ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      return recentLogs;
    } catch (e) {
      return [];
    }
  }

  // ==================== SYNC METHODS ====================
  static Future<Map<String, dynamic>> syncCallLogsToServer({
    required List<CallLogItem> callLogs,
    int pageNumber = 1,
    int totalPages = 1,
  }) async {
    try {
      final config = await _getDeviceConfig();
      if (!config['isValid']) {
        return {
          'success': false,
          'error': 'Missing device configuration',
          'message': 'Please ensure device is properly registered'
        };
      }

      if (callLogs.isEmpty) {
        return {
          'success': true,
          'message': 'No call logs to sync',
          'synced_count': 0
        };
      }

      final batchedData = _prepareBatchData(callLogs, config['deviceNumber']);
      final body = _buildSyncRequestBody(
          config, batchedData, pageNumber, totalPages
      );

      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: _requestTimeout));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await updateLastSyncTime();
        return {
          'success': true,
          'data': responseData,
          'message': 'Successfully synced ${batchedData.length} call logs',
          'synced_count': batchedData.length
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status ${response.statusCode}',
          'message': response.body
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to sync call logs'
      };
    }
  }

  static Future<Map<String, dynamic>> backgroundSyncCallData({
    required List<Map<String, dynamic>> callData,
  }) async {
    try {
      final config = await _getDeviceConfig();
      if (!config['isValid']) {
        return {
          'success': false,
          'error': 'Missing device configuration',
          'message': 'Device not properly registered'
        };
      }

      final body = {
        'action': 'sync_data',
        'wh_id': config['warehouseId'],
        'device_id': config['deviceId'],
        'register_device_number': config['deviceNumber'],
        'data': jsonEncode(callData),
        'page_number': '1',
        'total_pages': '1',
        'records_per_page': callData.length.toString(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: _requestTimeout));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Background sync successful'
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status ${response.statusCode}',
          'message': response.body
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Background sync failed'
      };
    }
  }

  // ==================== UTILITY METHODS ====================
  static String _generateCacheKey(
      int offset, int limit, String? simSlot, DateTime? startDate, DateTime? endDate
      ) {
    return 'logs_${offset}_${limit}_${simSlot ?? 'all'}_${startDate?.millisecondsSinceEpoch ?? 0}_${endDate?.millisecondsSinceEpoch ?? 0}';
  }

  static Future<Map<String, dynamic>> _getDeviceConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouse_id') ?? '';
    final deviceId = prefs.getInt('user_id')?.toString() ?? '';
    final deviceNumber = prefs.getString('mobile_number') ?? '';

    return {
      'isValid': warehouseId.isNotEmpty && deviceId.isNotEmpty && deviceNumber.isNotEmpty,
      'warehouseId': warehouseId,
      'deviceId': deviceId,
      'deviceNumber': deviceNumber,
    };
  }

  static List<Map<String, dynamic>> _prepareBatchData(
      List<CallLogItem> callLogs, String deviceNumber
      ) {
    final List<Map<String, dynamic>> batchedData = [];

    for (var i = 0; i < callLogs.length; i += _batchSize) {
      final end = (i + _batchSize) < callLogs.length ? (i + _batchSize) : callLogs.length;
      final batch = callLogs.sublist(i, end).map((call) => {
        "device_number": deviceNumber,
        "call_type": _convertCallTypeForAPI(call.type),
        "caller_number": call.number.isEmpty ? "UNKNOWN" : call.number,
        "caller_name": call.name.isEmpty ? "UNKNOWN" : call.name,
        "duration": call.duration,
        "time": _formatDateForAPI(call.date),
        "sim_slot": call.simSlot,
        "sync_timestamp": DateTime.now().toIso8601String(),
      }).toList();
      batchedData.addAll(batch);
    }

    return batchedData;
  }

  static Map<String, String> _buildSyncRequestBody(
      Map<String, dynamic> config,
      List<Map<String, dynamic>> batchedData,
      int pageNumber,
      int totalPages,
      ) {
    return {
      'action': 'sync_data',
      'wh_id': config['warehouseId'],
      'device_id': config['deviceId'],
      'register_device_number': config['deviceNumber'],
      'data': jsonEncode(batchedData),
      'page_number': pageNumber.toString(),
      'total_pages': totalPages.toString(),
      'records_per_page': _batchSize.toString(),
    };
  }

  static String _convertCallTypeForAPI(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('incoming')) return 'INCOMING';
    if (lowerType.contains('outgoing')) return 'OUTGOING';
    if (lowerType.contains('missed')) return 'MISSED';
    if (lowerType.contains('rejected')) return 'REJECTED';
    if (lowerType.contains('blocked')) return 'BLOCKED';
    return 'UNKNOWN';
  }

  static String _formatDateForAPI(String timestamp) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown';
    }
  }

  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    final difference = DateTime.now().difference(_lastCacheUpdate!);
    return difference.inMinutes < _cacheExpiryMinutes;
  }

  static void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  static Future<void> updateLastSyncTime([DateTime? syncTime]) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final timestamp = syncTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastSyncKey, timestamp);
      final currentCount = await getTotalCallLogsCount();
      await prefs.setInt(_lastCallCountKey, currentCount);
    } catch (e) {
      // Silently handle error
    }
  }

  static Future<DateTime?> getLastSyncTime() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearSyncHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_lastCallCountKey);
      clearCache();
    } catch (e) {
      // Silently handle error
    }
  }

  // ==================== ADVANCED METHODS ====================
  static Future<List<CallLogItem>> getCallLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? simSlot,
    int limit = 1000,
  }) async {
    return await fetchLogs(
      offset: 0,
      limit: limit,
      simSlot: simSlot,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<List<CallLogItem>> getCallLogsForNumber(String phoneNumber) async {
    try {
      final allLogs = await fetchLogs(offset: 0, limit: 1000);
      final normalizedTarget = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      return allLogs.where((log) {
        final normalizedLog = log.number.replaceAll(RegExp(r'[^\d+]'), '');
        return log.number == phoneNumber || normalizedLog == normalizedTarget;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> exportCallLogsToJson({
    DateTime? startDate,
    DateTime? endDate,
    String? simSlot,
  }) async {
    try {
      final callLogs = await fetchLogs(
        offset: 0,
        limit: 10000,
        simSlot: simSlot,
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'export_timestamp': DateTime.now().toIso8601String(),
        'total_records': callLogs.length,
        'filters': {
          'sim_slot': simSlot,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'call_logs': callLogs.map((call) => {
          'number': call.number,
          'name': call.name,
          'type': call.type,
          'date': call.date,
          'duration': call.duration,
          'sim_slot': call.simSlot,
          'formatted_date': _formatDateForAPI(call.date),
        }).toList(),
      };
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getRecentActivitySummary({int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final recentLogs = await getCallLogsByDateRange(
        startDate: startDate,
        endDate: DateTime.now(),
      );

      return {
        'period_days': days,
        'total_calls': recentLogs.length,
        'incoming_calls': recentLogs.where((log) => log.type.toLowerCase().contains('incoming')).length,
        'outgoing_calls': recentLogs.where((log) => log.type.toLowerCase().contains('outgoing')).length,
        'missed_calls': recentLogs.where((log) => log.type.toLowerCase().contains('missed')).length,
        'unique_numbers': recentLogs.map((log) => log.number).toSet().length,
        'sim1_calls': recentLogs.where((log) => log.simSlot == 'SIM 1').length,
        'sim2_calls': recentLogs.where((log) => log.simSlot == 'SIM 2').length,
      };
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> forceSyncAllCallLogs() async {
    try {
      await clearSyncHistory();
      final allCallLogs = await fetchLogs(offset: 0, limit: 10000);

      if (allCallLogs.isEmpty) {
        return {
          'success': true,
          'message': 'No call logs to sync',
          'synced_count': 0
        };
      }

      return await syncCallLogsToServer(
        callLogs: allCallLogs,
        pageNumber: 1,
        totalPages: 1,
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to force sync all call logs'
      };
    }
  }

  // ==================== MONITORING METHODS ====================
  static Future<int> getSystemCallLogCount() async {
    try {
      return await _channel.invokeMethod('getSystemCallLogCount') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> checkForNewCalls() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final lastCount = prefs.getInt(_lastCallCountKey) ?? 0;
      final lastSyncTime = prefs.getInt(_lastSyncKey) ?? 0;
      final currentCount = await getTotalCallLogsCount();

      if (currentCount > lastCount) {
        final newCallsCount = currentCount - lastCount;
        final newLogs = await getNewCallLogs();
        return {
          'has_new_calls': true,
          'new_count': newCallsCount,
          'new_logs': newLogs,
          'last_sync': DateTime.fromMillisecondsSinceEpoch(lastSyncTime),
        };
      }

      return {
        'has_new_calls': false,
        'new_count': 0,
        'new_logs': <CallLogItem>[],
        'last_sync': DateTime.fromMillisecondsSinceEpoch(lastSyncTime),
      };
    } catch (e) {
      return {
        'has_new_calls': false,
        'new_count': 0,
        'new_logs': <CallLogItem>[],
        'error': e.toString(),
      };
    }
  }

  // ==================== AUTO SYNC HELPER METHODS ====================
  static Future<Map<String, dynamic>> autoSyncNewCallLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedSim = prefs.getString('selected_sim') ?? 'SIM1';
      final lastSyncTime = prefs.getInt('last_sync_timestamp') ?? 0;
      final simSlot = selectedSim == 'SIM1' ? 'SIM 1' : 'SIM 2';

      final newCallLogs = await getNewCallLogsSince(
        timestamp: lastSyncTime,
        simSlot: simSlot,
      );

      if (newCallLogs.isEmpty) {
        return {
          'success': true,
          'message': 'No new call logs to sync',
          'new_count': 0
        };
      }

      final result = await syncCallLogsToServer(
        callLogs: newCallLogs,
        pageNumber: 1,
        totalPages: 1,
      );

      if (result['success']) {
        await prefs.setInt('last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
        result['new_count'] = newCallLogs.length;
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Auto sync failed'
      };
    }
  }

  static Future<bool> hasNewCallsForAutoSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedSim = prefs.getString('selected_sim') ?? 'SIM1';
      final lastSyncTime = prefs.getInt('last_sync_timestamp') ?? 0;
      final simSlot = selectedSim == 'SIM1' ? 'SIM 1' : 'SIM 2';

      final newCallLogs = await getNewCallLogsSince(
        timestamp: lastSyncTime,
        simSlot: simSlot,
      );

      return newCallLogs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getNewCallsCountForAutoSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedSim = prefs.getString('selected_sim') ?? 'SIM1';
      final lastSyncTime = prefs.getInt('last_sync_timestamp') ?? 0;
      final simSlot = selectedSim == 'SIM1' ? 'SIM 1' : 'SIM 2';

      final newCallLogs = await getNewCallLogsSince(
        timestamp: lastSyncTime,
        simSlot: simSlot,
      );

      return newCallLogs.length;
    } catch (e) {
      return 0;
    }
  }
}