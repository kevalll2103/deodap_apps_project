// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import '../theme/app_theme.dart';
// import '../models/item.dart';
// import '../service/service.dart';
// import '../widgets/tutorial_tooltip.dart';
//
// // ==================== API SERVICE CLASS ====================
//
// enum SyncErrorType {
//   network,
//   server,
//   timeout,
//   rateLimit,
//   authentication,
//   unknown
// }
//
// class SyncResult {
//   final bool success;
//   final Map<String, dynamic>? data;
//   final String message;
//   final SyncErrorType? errorType;
//   final bool shouldRetry;
//   final int? retryAfterSeconds;
//
//   SyncResult({
//     required this.success,
//     this.data,
//     required this.message,
//     this.errorType,
//     this.shouldRetry = false,
//     this.retryAfterSeconds,
//   });
// }
//
// class ApiService {
//   static const String baseURL = 'https://trackship.in';
//   static const String endpoint = '/api/lms/calls.php';
//   static const int maxRetries = 3;
//   static const int baseDelaySeconds = 2;
//  
//   // Rate limiting
//   static DateTime? _lastRequestTime;
//   static const int minRequestIntervalMs = 1000; // 1 second between requests
//
//   static Future<SyncResult> syncCallDataWithRetry({
//     required String warehouseId,
//     required String deviceId,
//     required String registerDeviceNumber,
//     required List<Map<String, dynamic>> callData,
//     required int pageNumber,
//     required int totalPages,
//     int retryCount = 0,
//   }) async {
//     // Rate limiting check
//     await _enforceRateLimit();
//
//     // Network connectivity check
//     if (!await _isNetworkAvailable()) {
//       return SyncResult(
//         success: false,
//         message: 'No network connection available',
//         errorType: SyncErrorType.network,
//         shouldRetry: true,
//         retryAfterSeconds: 30,
//       );
//     }
//
//     final result = await syncCallData(
//       warehouseId: warehouseId,
//       deviceId: deviceId,
//       registerDeviceNumber: registerDeviceNumber,
//       callData: callData,
//       pageNumber: pageNumber,
//       totalPages: totalPages,
//     );
//
//     // Handle retry logic
//     if (!result.success && result.shouldRetry && retryCount < maxRetries) {
//       final delaySeconds = _calculateBackoffDelay(retryCount);
//       print('Retrying sync for page $pageNumber in ${delaySeconds}s (attempt ${retryCount + 1}/$maxRetries)');
//      
//       await Future.delayed(Duration(seconds: delaySeconds));
//      
//       return syncCallDataWithRetry(
//         warehouseId: warehouseId,
//         deviceId: deviceId,
//         registerDeviceNumber: registerDeviceNumber,
//         callData: callData,
//         pageNumber: pageNumber,
//         totalPages: totalPages,
//         retryCount: retryCount + 1,
//       );
//     }
//
//     return result;
//   }
//
//   static Future<SyncResult> syncCallData({
//     required String warehouseId,
//     required String deviceId,
//     required String registerDeviceNumber,
//     required List<Map<String, dynamic>> callData,
//     required int pageNumber,
//     required int totalPages,
//   }) async {
//     try {
//       final url = Uri.parse('$baseURL$endpoint');
//
//       final body = {
//         'action': 'sync_data',
//         'wh_id': warehouseId,
//         'device_id': deviceId,
//         'register_device_number': registerDeviceNumber,
//         'data': jsonEncode(callData),
//         'page_number': pageNumber.toString(),
//         'total_pages': totalPages.toString(),
//         'records_per_page': '50',
//         'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
//       };
//
//       print('API Request URL: $url');
//       print('API Request Body: ${jsonEncode(body)}');
//       print('Syncing Page: $pageNumber of $totalPages');
//
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/x-www-form-urlencoded',
//           'User-Agent': 'CallLogMonitor/1.0',
//         },
//         body: body,
//       ).timeout(const Duration(seconds: 45)); // Increased timeout
//
//       print('API Response Status: ${response.statusCode}');
//       print('API Response Body: ${response.body}');
//
//       return _handleResponse(response, pageNumber);
//     } catch (e) {
//       print('API Error: $e');
//       return _handleError(e, pageNumber);
//     }
//   }
//
//   static SyncResult _handleResponse(http.Response response, int pageNumber) {
//     if (response.statusCode == 200) {
//       try {
//         final responseData = jsonDecode(response.body);
//         return SyncResult(
//           success: true,
//           data: responseData,
//           message: 'Page $pageNumber synced successfully',
//         );
//       } catch (e) {
//         return SyncResult(
//           success: false,
//           message: 'Invalid response format from server',
//           errorType: SyncErrorType.server,
//           shouldRetry: true,
//         );
//       }
//     } else if (response.statusCode == 429) {
//       // Rate limited
//       final retryAfter = int.tryParse(response.headers['retry-after'] ?? '60') ?? 60;
//       return SyncResult(
//         success: false,
//         message: 'Rate limited by server',
//         errorType: SyncErrorType.rateLimit,
//         shouldRetry: true,
//         retryAfterSeconds: retryAfter,
//       );
//     } else if (response.statusCode >= 500) {
//       // Server error - should retry
//       return SyncResult(
//         success: false,
//         message: 'Server error (${response.statusCode}): ${response.body}',
//         errorType: SyncErrorType.server,
//         shouldRetry: true,
//       );
//     } else if (response.statusCode == 401 || response.statusCode == 403) {
//       // Authentication error - don't retry
//       return SyncResult(
//         success: false,
//         message: 'Authentication failed (${response.statusCode})',
//         errorType: SyncErrorType.authentication,
//         shouldRetry: false,
//       );
//     } else {
//       // Client error - don't retry
//       return SyncResult(
//         success: false,
//         message: 'Client error (${response.statusCode}): ${response.body}',
//         errorType: SyncErrorType.unknown,
//         shouldRetry: false,
//       );
//     }
//   }
//
//   static SyncResult _handleError(dynamic error, int pageNumber) {
//     if (error.toString().contains('TimeoutException') || 
//         error.toString().contains('timeout')) {
//       return SyncResult(
//         success: false,
//         message: 'Request timeout for page $pageNumber',
//         errorType: SyncErrorType.timeout,
//         shouldRetry: true,
//       );
//     } else if (error.toString().contains('SocketException') ||
//                error.toString().contains('NetworkException')) {
//       return SyncResult(
//         success: false,
//         message: 'Network error for page $pageNumber',
//         errorType: SyncErrorType.network,
//         shouldRetry: true,
//         retryAfterSeconds: 30,
//       );
//     } else {
//       return SyncResult(
//         success: false,
//         message: 'Unknown error for page $pageNumber: ${error.toString()}',
//         errorType: SyncErrorType.unknown,
//         shouldRetry: true,
//       );
//     }
//   }
//
//   static Future<void> _enforceRateLimit() async {
//     if (_lastRequestTime != null) {
//       final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!).inMilliseconds;
//       if (timeSinceLastRequest < minRequestIntervalMs) {
//         await Future.delayed(Duration(milliseconds: minRequestIntervalMs - timeSinceLastRequest));
//       }
//     }
//     _lastRequestTime = DateTime.now();
//   }
//
//   static int _calculateBackoffDelay(int retryCount) {
//     return (baseDelaySeconds * (1 << retryCount)).clamp(1, 60); // Max 60 seconds
//   }
//
//   static Future<bool> _isNetworkAvailable() async {
//     try {
//       final result = await http.get(
//         Uri.parse('https://www.google.com'),
//         headers: {'User-Agent': 'CallLogMonitor/1.0'},
//       ).timeout(const Duration(seconds: 5));
//       return result.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }
// }
//
// // ==================== MAIN SCREEN ====================
//
// class CallHistoryScreen extends StatefulWidget {
//   const CallHistoryScreen({Key? key}) : super(key: key);
//
//   @override
//   State<CallHistoryScreen> createState() => _CallHistoryScreenState();
// }
//
// class _CallHistoryScreenState extends State<CallHistoryScreen> {
//   // ==================== VARIABLES ====================
//   final PageController _pageController = PageController();
//   static const platform = MethodChannel('com.example.calllogmonitor/call_log_sync');
//
//   // Pagination constants
//   static const int _pageSize = 50;
//
//   // Data variables
//   Map<int, List<CallLogItem>> _pages = {}; // Map of page index to call logs
//   List<CallLogItem> get _currentPageLogs => _pages[_currentPage] ?? [];
//   bool _isLoading = false;
//   bool _isLoadingPage = false;
//   bool _isSyncing = false;
//   String _registeredSim = 'SIM 1';
//   int _totalLogs = 0;
//   int _currentPage = 0;
//   int _totalPages = 0;
//   String _deviceNumber = '';
//   String _warehouseId = '';
//   String _deviceId = '';
//   String _errorMessage = '';
//
//   // Sync tracking
//   Set<int> _syncedPages = {};
//   Map<int, SyncResult> _syncResults = {}; // Track sync results per page
//   bool _isSyncingAll = false;
//   int _currentSyncPage = 0;
//
//   // Auto-sync status
//   bool _autoSyncRunning = false;
//   Timer? _statusCheckTimer;
//  
//   // Enhanced sync state
//   Map<int, int> _pageRetryCount = {}; // Track retry attempts per page
//   DateTime? _lastSyncAttempt;
//   bool _networkAvailable = true;
//
//   // ==================== LIFECYCLE METHODS ====================
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeScreen();
//     _startAutoSyncStatusCheck();
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     _statusCheckTimer?.cancel();
//     super.dispose();
//   }
//
//   // ==================== AUTO-SYNC STATUS MONITORING ====================
//
//   void _startAutoSyncStatusCheck() {
//     _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       if (mounted) {
//         _checkAutoSyncStatus();
//         _checkNetworkStatus();
//       }
//     });
//   }
//
//   Future<void> _checkAutoSyncStatus() async {
//     try {
//       final result = await platform.invokeMethod('isSyncServiceRunning');
//       if (mounted) {
//         setState(() {
//           _autoSyncRunning = result == true;
//         });
//       }
//     } catch (e) {
//       // Handle platform channel errors silently
//       print('Error checking auto-sync status: $e');
//     }
//   }
//
//   Future<void> _checkNetworkStatus() async {
//     try {
//       final isAvailable = await ApiService._isNetworkAvailable();
//       if (mounted && _networkAvailable != isAvailable) {
//         setState(() {
//           _networkAvailable = isAvailable;
//         });
//        
//         // Show network status change notification
//         if (!isAvailable) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(Icons.wifi_off, color: Colors.white, size: 20),
//                   const SizedBox(width: 8),
//                   const Text('Network connection lost'),
//                 ],
//               ),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(Icons.wifi, color: Colors.white, size: 20),
//                   const SizedBox(width: 8),
//                   const Text('Network connection restored'),
//                 ],
//               ),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 2),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print('Error checking network status: $e');
//     }
//   }
//
//   // ==================== INITIALIZATION METHODS ====================
//
//   Future<void> _initializeScreen() async {
//     try {
//       await _loadDeviceData();
//       await _loadRegisteredSim();
//       await _loadTotalCount();
//       await _loadInitialPage();
//     } catch (e) {
//       print('Error initializing screen: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Failed to initialize: $e';
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _loadDeviceData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       if (mounted) {
//         setState(() {
//           _deviceNumber = prefs.getString('mobile_number') ?? 'Unknown';
//           _warehouseId = prefs.getString('warehouse_id') ?? '';
//           _deviceId = prefs.getInt('user_id')?.toString() ?? '';
//         });
//       }
//
//       print('=== DEBUG: Loaded Device Data ===');
//       print('Device Number: $_deviceNumber');
//       print('Warehouse ID: $_warehouseId');
//       print('Device ID: $_deviceId');
//
//     } catch (e) {
//       print('Error loading device data: $e');
//       throw e;
//     }
//   }
//
//   Future<void> _loadRegisteredSim() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedSim = prefs.getString('selected_sim') ?? 'SIM1';
//
//       if (mounted) {
//         setState(() {
//           if (savedSim == 'SIM1') {
//             _registeredSim = 'SIM 1';
//           } else if (savedSim == 'SIM2') {
//             _registeredSim = 'SIM 2';
//           } else {
//             _registeredSim = 'SIM 1';
//           }
//         });
//       }
//
//       print('=== DEBUG: Registered SIM ===');
//       print('Registered SIM: $_registeredSim');
//
//     } catch (e) {
//       print('Error loading registered SIM: $e');
//       if (mounted) {
//         setState(() {
//           _registeredSim = 'SIM 1';
//         });
//       }
//     }
//   }
//
//   Future<void> _loadTotalCount() async {
//     try {
//       _totalLogs = await CallLogService.getTotalCallLogsCount();
//       _totalPages = (_totalLogs / _pageSize).ceil();
//
//       print('=== DEBUG: Total Count Loaded ===');
//       print('Total logs: $_totalLogs');
//       print('Total pages: $_totalPages');
//
//     } catch (e) {
//       print('Error loading total count: $e');
//       throw e;
//     }
//   }
//
//   Future<void> _loadInitialPage() async {
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });
//     }
//
//     try {
//       await _loadPage(0);
//
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//
//     } catch (e) {
//       print('Error loading initial page: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Failed to load call logs: $e';
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   // ==================== DATA LOADING METHODS ====================
//
//   Future<void> _loadPage(int pageIndex) async {
//     // Don't load if page is already loaded or if loading
//     if (_pages.containsKey(pageIndex) || _isLoadingPage) {
//       return;
//     }
//
//     if (mounted) {
//       setState(() {
//         _isLoadingPage = true;
//       });
//     }
//
//     try {
//       final offset = pageIndex * _pageSize;
//
//       // Load all logs for this offset and limit
//       final allLogs = await CallLogService.fetchLogs(
//         offset: offset,
//         limit: _pageSize,
//         simSlot: null, // Load all SIMs, we'll filter below
//       );
//
//       // Filter logs to show only the registered SIM calls
//       final filteredLogs = allLogs.where((log) => log.simSlot == _registeredSim).toList();
//
//       if (mounted) {
//         setState(() {
//           _pages[pageIndex] = filteredLogs;
//           _isLoadingPage = false;
//         });
//       }
//
//       print('=== DEBUG: Page $pageIndex Loaded ===');
//       print('Raw logs: ${allLogs.length}');
//       print('Filtered logs for $_registeredSim: ${filteredLogs.length}');
//
//     } catch (e) {
//       print('Error loading page $pageIndex: $e');
//       if (mounted) {
//         setState(() {
//           _isLoadingPage = false;
//         });
//       }
//       throw e;
//     }
//   }
//
//   Future<void> _onRefresh() async {
//     // Clear all cached pages and reload
//     if (mounted) {
//       setState(() {
//         _pages.clear();
//         _syncedPages.clear();
//         _currentPage = 0;
//       });
//     }
//
//     await _loadTotalCount();
//     await _loadPage(_currentPage);
//   }
//
//   // ==================== PAGE NAVIGATION ====================
//
//   void _goToPage(int pageIndex) async {
//     if (pageIndex >= 0 && pageIndex < _totalPages) {
//       // Load the page if not already loaded
//       if (!_pages.containsKey(pageIndex)) {
//         await _loadPage(pageIndex);
//       }
//
//       _pageController.animateToPage(
//         pageIndex,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }
//
//   void _nextPage() async {
//     if (_currentPage < _totalPages - 1) {
//       final nextPageIndex = _currentPage + 1;
//
//       // Pre-load the next page if not already loaded
//       if (!_pages.containsKey(nextPageIndex)) {
//         await _loadPage(nextPageIndex);
//       }
//
//       _goToPage(nextPageIndex);
//     }
//   }
//
//   void _previousPage() {
//     if (_currentPage > 0) {
//       _goToPage(_currentPage - 1);
//     }
//   }
//
//   void _onPageChanged(int pageIndex) {
//     setState(() {
//       _currentPage = pageIndex;
//     });
//
//     // Pre-load adjacent pages for smoother navigation
//     _preloadAdjacentPages(pageIndex);
//   }
//
//   void _preloadAdjacentPages(int currentPageIndex) {
//     // Pre-load next page
//     final nextPage = currentPageIndex + 1;
//     if (nextPage < _totalPages && !_pages.containsKey(nextPage)) {
//       _loadPage(nextPage);
//     }
//
//     // Pre-load previous page
//     final prevPage = currentPageIndex - 1;
//     if (prevPage >= 0 && !_pages.containsKey(prevPage)) {
//       _loadPage(prevPage);
//     }
//   }
//
//   // ==================== INTERNAL JSON METHODS FOR API SYNC ====================
//
//   String _convertCallTypeToJson(String type) {
//     final lowerType = type.toLowerCase();
//     if (lowerType.contains('incoming')) return 'INCOMING';
//     if (lowerType.contains('outgoing')) return 'OUTGOING';
//     if (lowerType.contains('missed')) return 'MISSED';
//     if (lowerType.contains('rejected')) return 'REJECTED';
//     if (lowerType.contains('blocked')) return 'BLOCKED';
//     if (lowerType.contains('voicemail')) return 'VOICEMAIL';
//     return 'UNKNOWN';
//   }
//
//   String _formatDateForJson(String timestamp) {
//     try {
//       final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
//       return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
//     } catch (_) {
//       return 'Unknown';
//     }
//   }
//
//   Map<String, dynamic> _convertCallToJson(CallLogItem call) {
//     return {
//       "device_number": _deviceNumber,
//       "call_type": _convertCallTypeToJson(call.type),
//       "caller_number": call.number.isEmpty ? "UNKNOWN" : call.number,
//       "caller_name": call.name.isEmpty ? "UNKNOWN" : call.name,
//       "duration": call.duration,
//       "time": _formatDateForJson(call.date),
//     };
//   }
//
//   List<Map<String, dynamic>> _generateJsonFromPage(int pageIndex) {
//     if (_pages.containsKey(pageIndex)) {
//       return _pages[pageIndex]!
//           .map((call) => _convertCallToJson(call))
//           .toList();
//     }
//     return [];
//   }
//
//   // ==================== API SYNC METHODS ====================
//
//   Future<void> _syncCurrentPageToAPI() async {
//     await _syncPageToAPI(_currentPage);
//   }
//
//   Future<void> _syncPageToAPI(int pageIndex) async {
//     if (_isSyncing) return;
//
//     // Validate required fields
//     if (_warehouseId.isEmpty || _deviceId.isEmpty || _deviceNumber.isEmpty) {
//       _showErrorDialog(
//         'Missing Configuration',
//         'Please ensure you are properly registered. Missing data:\n' +
//             (_warehouseId.isEmpty ? '• Warehouse ID\n' : '') +
//             (_deviceId.isEmpty ? '• Device ID\n' : '') +
//             (_deviceNumber.isEmpty ? '• Mobile Number\n' : '') +
//             '\nPlease register again if needed.',
//       );
//       return;
//     }
//
//     // Load page if not already loaded
//     if (!_pages.containsKey(pageIndex)) {
//       await _loadPage(pageIndex);
//     }
//
//     if (!_pages.containsKey(pageIndex) || _pages[pageIndex]!.isEmpty) {
//       _showInfoDialog('No Data', 'No call logs to sync for page ${pageIndex + 1}.');
//       return;
//     }
//
//     if (mounted) {
//       setState(() {
//         _isSyncing = true;
//         _lastSyncAttempt = DateTime.now();
//       });
//     }
//
//     try {
//       final callData = _generateJsonFromPage(pageIndex);
//
//       print('=== DEBUG: Enhanced API Sync Request ===');
//       print('Page: ${pageIndex + 1} of $_totalPages');
//       print('Warehouse ID: $_warehouseId');
//       print('Device ID: $_deviceId');
//       print('Register Device Number: $_deviceNumber');
//       print('Registered SIM: $_registeredSim');
//       print('Call Data Count: ${callData.length}');
//       print('Network Available: $_networkAvailable');
//       print('Previous Retry Count: ${_pageRetryCount[pageIndex] ?? 0}');
//
//       final result = await ApiService.syncCallDataWithRetry(
//         warehouseId: _warehouseId,
//         deviceId: _deviceId,
//         registerDeviceNumber: _deviceNumber,
//         callData: callData,
//         pageNumber: pageIndex + 1,
//         totalPages: _totalPages,
//       );
//
//       if (mounted) {
//         setState(() {
//           _syncResults[pageIndex] = result;
//           if (result.success) {
//             _syncedPages.add(pageIndex);
//             _pageRetryCount.remove(pageIndex); // Reset retry count on success
//           } else {
//             _pageRetryCount[pageIndex] = (_pageRetryCount[pageIndex] ?? 0) + 1;
//           }
//         });
//
//         if (result.success) {
//           _showSuccessDialog(
//             'Page Sync Successful',
//             'Successfully synced page ${pageIndex + 1} with ${callData.length} call logs from $_registeredSim to server.',
//           );
//         } else {
//           String errorTitle = 'Page Sync Failed';
//           String errorMessage = result.message;
//          
//           // Customize error message based on error type
//           switch (result.errorType) {
//             case SyncErrorType.network:
//               errorTitle = 'Network Error';
//               errorMessage = 'Please check your internet connection and try again.\n\n${result.message}';
//               break;
//             case SyncErrorType.server:
//               errorTitle = 'Server Error';
//               errorMessage = 'Server is experiencing issues. The sync will be retried automatically.\n\n${result.message}';
//               break;
//             case SyncErrorType.timeout:
//               errorTitle = 'Request Timeout';
//               errorMessage = 'The request took too long. Please try again.\n\n${result.message}';
//               break;
//             case SyncErrorType.rateLimit:
//               errorTitle = 'Rate Limited';
//               errorMessage = 'Too many requests. Please wait ${result.retryAfterSeconds ?? 60} seconds before trying again.\n\n${result.message}';
//               break;
//             case SyncErrorType.authentication:
//               errorTitle = 'Authentication Failed';
//               errorMessage = 'Please check your registration details and try again.\n\n${result.message}';
//               break;
//             default:
//               break;
//           }
//          
//           _showErrorDialog(errorTitle, errorMessage);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorDialog('Sync Error', 'Unexpected error occurred: ${e.toString()}');
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSyncing = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _syncAllPagesToAPI() async {
//     if (_isSyncingAll || _totalPages == 0) return;
//
//     final shouldContinue = await _showSyncAllConfirmationDialog();
//     if (!shouldContinue) return;
//
//     if (mounted) {
//       setState(() {
//         _isSyncingAll = true;
//         _currentSyncPage = 0;
//         _lastSyncAttempt = DateTime.now();
//       });
//     }
//
//     int successCount = 0;
//     int failureCount = 0;
//     List<String> failedPages = [];
//
//     try {
//       for (int i = 0; i < _totalPages; i++) {
//         if (mounted) {
//           setState(() {
//             _currentSyncPage = i;
//           });
//         }
//
//         // Load page if not already loaded
//         if (!_pages.containsKey(i)) {
//           await _loadPage(i);
//         }
//
//         final callData = _generateJsonFromPage(i);
//
//         if (callData.isNotEmpty) {
//           print('=== Syncing Page ${i + 1}/$_totalPages ===');
//          
//           final result = await ApiService.syncCallDataWithRetry(
//             warehouseId: _warehouseId,
//             deviceId: _deviceId,
//             registerDeviceNumber: _deviceNumber,
//             callData: callData,
//             pageNumber: i + 1,
//             totalPages: _totalPages,
//           );
//
//           if (mounted) {
//             setState(() {
//               _syncResults[i] = result;
//             });
//           }
//
//           if (result.success) {
//             if (mounted) {
//               setState(() {
//                 _syncedPages.add(i);
//                 _pageRetryCount.remove(i); // Reset retry count on success
//               });
//             }
//             successCount++;
//             print('✓ Page ${i + 1} synced successfully');
//           } else {
//             failureCount++;
//             failedPages.add('Page ${i + 1}: ${result.message}');
//             print('✗ Failed to sync page ${i + 1}: ${result.message}');
//            
//             if (mounted) {
//               setState(() {
//                 _pageRetryCount[i] = (_pageRetryCount[i] ?? 0) + 1;
//               });
//             }
//
//             // For critical errors, consider stopping the batch sync
//             if (result.errorType == SyncErrorType.authentication) {
//               print('Authentication error detected, stopping batch sync');
//               break;
//             }
//           }
//
//           // Adaptive delay based on previous results
//           int delayMs = 500; // Base delay
//           if (result.errorType == SyncErrorType.rateLimit) {
//             delayMs = (result.retryAfterSeconds ?? 60) * 1000;
//           } else if (result.errorType == SyncErrorType.server) {
//             delayMs = 2000; // Longer delay for server errors
//           }
//          
//           await Future.delayed(Duration(milliseconds: delayMs));
//         } else {
//           print('Skipping page ${i + 1} - no data');
//           // Default delay for empty pages
//           await Future.delayed(const Duration(milliseconds: 100));
//         }
//       }
//
//       if (mounted) {
//         final totalSyncedLogs = _pages.values.fold(0, (sum, page) => sum + page.length);
//        
//         if (failureCount == 0) {
//           _showSuccessDialog(
//             'All Pages Synced Successfully',
//             'Successfully synced all $_totalPages pages with total $totalSyncedLogs call logs from $_registeredSim.\n\n'
//             '✓ Success: $successCount pages\n'
//             '✗ Failed: $failureCount pages',
//           );
//         } else {
//           _showSyncSummaryDialog(successCount, failureCount, failedPages, totalSyncedLogs);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorDialog(
//           'Batch Sync Error', 
//           'An unexpected error occurred during batch sync:\n\n${e.toString()}\n\n'
//           'Successfully synced: $successCount pages\n'
//           'Failed: $failureCount pages'
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSyncingAll = false;
//           _currentSyncPage = 0;
//         });
//       }
//     }
//   }
//
//   void _showSyncSummaryDialog(int successCount, int failureCount, List<String> failedPages, int totalSyncedLogs) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Icon(
//                 failureCount == 0 ? Icons.check_circle : Icons.warning,
//                 color: failureCount == 0 ? Colors.green : Colors.orange,
//                 size: 28,
//               ),
//               const SizedBox(width: 8),
//               const Text('Sync Summary'),
//             ],
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Batch sync completed with mixed results:\n',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 Text('✓ Successfully synced: $successCount pages'),
//                 Text('✗ Failed to sync: $failureCount pages'),
//                 Text('📊 Total synced logs: $totalSyncedLogs'),
//                
//                 if (failedPages.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   Text(
//                     'Failed Pages:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: Colors.red[700],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ...failedPages.take(5).map((failure) => Padding(
//                     padding: const EdgeInsets.only(left: 8, bottom: 4),
//                     child: Text(
//                       '• $failure',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   )),
//                   if (failedPages.length > 5)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 8),
//                       child: Text(
//                         '... and ${failedPages.length - 5} more',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[500],
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ),
//                 ],
//                
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                   ),
//                   child: Text(
//                     'Tip: Failed pages can be retried individually using the sync button on each page.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.blue[700],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<bool> _showSyncAllConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Sync All Pages'),
//           content: Text(
//             'You are about to sync all $_totalPages pages. This will load and sync all call logs, which may take some time.\n\nNote: Auto-sync is ${_autoSyncRunning ? 'running' : 'stopped'}.\n\nDo you want to continue?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text('Continue'),
//             ),
//           ],
//         );
//       },
//     ) ?? false;
//   }
//
//
//
//   // ==================== UTILITY METHODS ====================
//
//   void _showErrorDialog(String title, String message) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showSuccessDialog(String title, String message) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showInfoDialog(String title, String message) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           icon: const Icon(Icons.info, color: Colors.blue, size: 48),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   String _formatTimestamp(String timestamp) {
//     try {
//       final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
//       return '${dateTime.day.toString().padLeft(2, '0')}/'
//           '${dateTime.month.toString().padLeft(2, '0')}/'
//           '${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:'
//           '${dateTime.minute.toString().padLeft(2, '0')}';
//     } catch (_) {
//       return 'Unknown';
//     }
//   }
//
//   String _formatDuration(String duration) {
//     try {
//       final seconds = int.parse(duration);
//       final minutes = seconds ~/ 60;
//       final remainingSeconds = seconds % 60;
//       if (minutes > 0) {
//         return '${minutes}m ${remainingSeconds}s';
//       } else {
//         return '${seconds}s';
//       }
//     } catch (_) {
//       return duration;
//     }
//   }
//
//   Color _getCallTypeColor(String type) {
//     final lowerType = type.toLowerCase();
//     if (lowerType.contains('incoming')) return Colors.green;
//     if (lowerType.contains('outgoing')) return Colors.blue;
//     if (lowerType.contains('missed')) return Colors.red;
//     if (lowerType.contains('rejected')) return Colors.orange;
//     if (lowerType.contains('blocked')) return Colors.grey;
//     return Colors.grey;
//   }
//
//   IconData _getCallTypeIcon(String type) {
//     final lowerType = type.toLowerCase();
//     if (lowerType.contains('incoming')) return Icons.call_received;
//     if (lowerType.contains('outgoing')) return Icons.call_made;
//     if (lowerType.contains('missed')) return Icons.call_received;
//     if (lowerType.contains('rejected')) return Icons.call_end;
//     if (lowerType.contains('blocked')) return Icons.block;
//     return Icons.phone;
//   }
//
//   // Enhanced sync status helper methods
//   Color _getSyncStatusColor(int pageIndex) {
//     if (_syncedPages.contains(pageIndex)) {
//       return Colors.green;
//     } else if (_syncResults.containsKey(pageIndex)) {
//       final result = _syncResults[pageIndex]!;
//       switch (result.errorType) {
//         case SyncErrorType.network:
//           return Colors.orange;
//         case SyncErrorType.server:
//           return Colors.red;
//         case SyncErrorType.timeout:
//           return Colors.amber;
//         case SyncErrorType.rateLimit:
//           return Colors.purple;
//         case SyncErrorType.authentication:
//           return Colors.red;
//         default:
//           return Colors.grey;
//       }
//     } else {
//       return Colors.orange;
//     }
//   }
//
//   IconData _getSyncStatusIcon(int pageIndex) {
//     if (_syncedPages.contains(pageIndex)) {
//       return Icons.check_circle;
//     } else if (_syncResults.containsKey(pageIndex)) {
//       final result = _syncResults[pageIndex]!;
//       switch (result.errorType) {
//         case SyncErrorType.network:
//           return Icons.wifi_off;
//         case SyncErrorType.server:
//           return Icons.error;
//         case SyncErrorType.timeout:
//           return Icons.access_time;
//         case SyncErrorType.rateLimit:
//           return Icons.speed;
//         case SyncErrorType.authentication:
//           return Icons.lock;
//         default:
//           return Icons.warning;
//       }
//     } else {
//       return Icons.pending;
//     }
//   }
//
//   String _getSyncStatusText(int pageIndex) {
//     if (_syncedPages.contains(pageIndex)) {
//       return 'Synced';
//     } else if (_syncResults.containsKey(pageIndex)) {
//       final result = _syncResults[pageIndex]!;
//       switch (result.errorType) {
//         case SyncErrorType.network:
//           return 'Network Error';
//         case SyncErrorType.server:
//           return 'Server Error';
//         case SyncErrorType.timeout:
//           return 'Timeout';
//         case SyncErrorType.rateLimit:
//           return 'Rate Limited';
//         case SyncErrorType.authentication:
//           return 'Auth Failed';
//         default:
//           return 'Failed';
//       }
//     } else {
//       return 'Not Synced';
//     }
//   }
//
//   // ==================== UI BUILDING METHODS ====================
//
//   Widget _buildHeader() {
//     final loadedPagesCount = _pages.length;
//     final totalLoadedLogs = _pages.values.fold(0, (sum, page) => sum + page.length);
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.primaryBrown.withOpacity(0.1),
//             AppTheme.accentBrown.withOpacity(0.1),
//           ],
//         ),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(16),
//           bottomRight: Radius.circular(16),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Status banners
//           Row(
//             children: [
//               // Auto-sync status banner
//               if (_autoSyncRunning)
//                 Expanded(
//                   child: Container(
//                     margin: const EdgeInsets.only(bottom: 12, right: 8),
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.green.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.sync, color: Colors.green[700], size: 16),
//                         const SizedBox(width: 6),
//                         Flexible(
//                           child: Text(
//                             'Auto-sync active - Checking every 10 minutes',
//                             style: TextStyle(
//                               color: Colors.green[700],
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//              
//               // Network status banner
//               Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: _networkAvailable 
//                       ? Colors.blue.withOpacity(0.1)
//                       : Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: _networkAvailable 
//                         ? Colors.blue.withOpacity(0.3)
//                         : Colors.red.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _networkAvailable ? Icons.wifi : Icons.wifi_off,
//                       color: _networkAvailable ? Colors.blue[700] : Colors.red[700],
//                       size: 16,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       _networkAvailable ? 'Online' : 'Offline',
//                       style: TextStyle(
//                         color: _networkAvailable ? Colors.blue[700] : Colors.red[700],
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title and Info Section
//               Expanded(
//                 flex: 2,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Local Call History',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.primaryBrown,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//
//                     Text(
//                       'Calls ($_registeredSim only)',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//
//                     const SizedBox(height: 4),
//                     Text(
//                       'Page ${_currentPage + 1} of $_totalPages (${_currentPageLogs.length} calls)',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.blue[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//
//                     const SizedBox(height: 2),
//                     Text(
//                       'Loaded: $loadedPagesCount pages ($totalLoadedLogs calls)',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.grey[500],
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//
//                     if (_deviceNumber.isNotEmpty) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         'Mobile No: $_deviceNumber',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[500],
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//
//               const SizedBox(width: 16),
//
//               // Controls Section
//               Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Sync Current Page Button
//                   FirstTimeButton(
//                     tutorialKey: 'sync_current_page_button',
//                     tooltipMessage: 'Manually sync this page of call logs to the server. The button turns green when synced.',
//                     child: _buildActionButton(
//                       isLoading: _isSyncing,
//                       onPressed: _syncCurrentPageToAPI,
//                       icon: _syncedPages.contains(_currentPage)
//                           ? Icons.check_circle
//                           : Icons.sync,
//                       color: _syncedPages.contains(_currentPage)
//                           ? Colors.green
//                           : Colors.blue,
//                       tooltip: _syncedPages.contains(_currentPage)
//                           ? 'Page Synced'
//                           : 'Sync Current Page',
//                       borderColor: _syncedPages.contains(_currentPage)
//                           ? Colors.green.withOpacity(0.3)
//                           : Colors.blue.withOpacity(0.3),
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // Sync All Pages Button
//                   FirstTimeButton(
//                     tutorialKey: 'sync_all_pages_button',
//                     tooltipMessage: 'Sync ALL pages of call logs to the server. Use this for initial setup or complete sync.',
//                     child: _buildActionButton(
//                       isLoading: _isSyncingAll,
//                       onPressed: _syncAllPagesToAPI,
//                       icon: Icons.upload_file,
//                       color: Colors.purple,
//                       tooltip: 'Sync All Pages',
//                       borderColor: Colors.purple.withOpacity(0.3),
//                       loadingWidget: _isSyncingAll
//                           ? Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${_currentSyncPage + 1}/$_totalPages',
//                             style: const TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       )
//                           : null,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required bool isLoading,
//     required VoidCallback onPressed,
//     required IconData icon,
//     required Color color,
//     required String tooltip,
//     required Color borderColor,
//     Widget? loadingWidget,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: borderColor),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: isLoading
//           ? (loadingWidget ??
//           const SizedBox(
//             width: 24,
//             height: 24,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ))
//           : IconButton(
//         onPressed: onPressed,
//         icon: Icon(icon, color: color, size: 24),
//         tooltip: tooltip,
//         padding: EdgeInsets.zero,
//         constraints: const BoxConstraints(
//           minWidth: 24,
//           minHeight: 24,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPaginationControls() {
//     if (_totalPages <= 1) return const SizedBox.shrink();
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           top: BorderSide(color: Colors.grey[200]!),
//           bottom: BorderSide(color: Colors.grey[200]!),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Previous Button
//           IconButton(
//             onPressed: _currentPage > 0 ? _previousPage : null,
//             icon: Icon(
//               Icons.arrow_back_ios,
//               color: _currentPage > 0 ? Colors.blue : Colors.grey,
//             ),
//             tooltip: 'Previous Page',
//           ),
//
//           // Page Indicator with Quick Navigation
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Page Number Input
//                 FirstTimeButton(
//                   tutorialKey: 'page_navigation_button',
//                   tooltipMessage: 'Tap here to jump to a specific page number or see navigation info.',
//                   child: GestureDetector(
//                     onTap: _showPageSelectionDialog,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                       ),
//                       child: Text(
//                         'Page ${_currentPage + 1} of $_totalPages',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.blue[700],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//
//                 // Enhanced Sync Status Indicator
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: _getSyncStatusColor(_currentPage).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: _getSyncStatusColor(_currentPage).withOpacity(0.3),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         _getSyncStatusIcon(_currentPage),
//                         size: 14,
//                         color: _getSyncStatusColor(_currentPage),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         _getSyncStatusText(_currentPage),
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                           color: _getSyncStatusColor(_currentPage),
//                         ),
//                       ),
//                       if (_pageRetryCount[_currentPage] != null && _pageRetryCount[_currentPage]! > 0) ...[
//                         const SizedBox(width: 4),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
//                           decoration: BoxDecoration(
//                             color: Colors.red.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             '${_pageRetryCount[_currentPage]}',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.red[700],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//
//                 // Loading indicator for current page
//                 if (_isLoadingPage) ...[
//                   const SizedBox(width: 12),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const SizedBox(
//                           width: 12,
//                           height: 12,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           'Loading...',
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: Colors.blue[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//
//           // Next Button
//           IconButton(
//             onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
//             icon: Icon(
//               Icons.arrow_forward_ios,
//               color: _currentPage < _totalPages - 1 ? Colors.blue : Colors.grey,
//             ),
//             tooltip: 'Next Page',
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showPageSelectionDialog() {
//     final TextEditingController pageController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Go to Page'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: pageController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Page Number (1 - $_totalPages)',
//                   border: const OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Total Pages: $_totalPages\nCurrent Page: ${_currentPage + 1}\nLoaded Pages: ${_pages.length}\nAuto-sync: ${_autoSyncRunning ? 'Running' : 'Stopped'}',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 final pageNumber = int.tryParse(pageController.text);
//                 if (pageNumber != null && pageNumber >= 1 && pageNumber <= _totalPages) {
//                   Navigator.of(context).pop();
//                   _goToPage(pageNumber - 1);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Please enter a valid page number between 1 and $_totalPages'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//               child: const Text('Go'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildCallItem(CallLogItem call) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         leading: CircleAvatar(
//           radius: 24,
//           backgroundColor: _getCallTypeColor(call.type).withOpacity(0.1),
//           child: Icon(
//             _getCallTypeIcon(call.type),
//             color: _getCallTypeColor(call.type),
//             size: 20,
//           ),
//         ),
//         title: Text(
//           call.number.isEmpty ? 'Unknown' : call.number,
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (call.name.isNotEmpty) ...[
//               const SizedBox(height: 2),
//               Text(
//                 call.name,
//                 style: TextStyle(
//                   color: Colors.grey[700],
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Text(
//                   _formatTimestamp(call.date),
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Text(
//                   _formatDuration(call.duration),
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: _getCallTypeColor(call.type).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     call.type,
//                     style: TextStyle(
//                       color: _getCallTypeColor(call.type),
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: call.simSlot == 'SIM 1'
//                         ? Colors.blue.withOpacity(0.1)
//                         : call.simSlot == 'SIM 2'
//                         ? Colors.green.withOpacity(0.1)
//                         : Colors.grey.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     call.simSlot,
//                     style: TextStyle(
//                       color: call.simSlot == 'SIM 1'
//                           ? Colors.blue[700]
//                           : call.simSlot == 'SIM 2'
//                           ? Colors.green[700]
//                           : Colors.grey[600],
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         trailing: IconButton(
//           icon: Icon(Icons.more_vert, color: Colors.grey[600]),
//           onPressed: () => _showCallDetailsDialog(call),
//         ),
//       ),
//     );
//   }
//
//   void _showCallDetailsDialog(CallLogItem call) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Call Details'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildDetailRow('Number', call.number.isEmpty ? 'Unknown' : call.number),
//               if (call.name.isNotEmpty) _buildDetailRow('Name', call.name),
//               _buildDetailRow('Type', call.type),
//               _buildDetailRow('Date & Time', _formatTimestamp(call.date)),
//               _buildDetailRow('Duration', _formatDuration(call.duration)),
//               _buildDetailRow('SIM Slot', call.simSlot),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 64,
//             color: Colors.red[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Error Loading Data',
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               _errorMessage,
//               style: TextStyle(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 _errorMessage = '';
//               });
//               _initializeScreen();
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSyncStatusBar() {
//     if (_totalPages == 0) return const SizedBox.shrink();
//
//     final syncedCount = _syncedPages.length;
//     final failedCount = _syncResults.values.where((result) => !result.success).length;
//     final pendingCount = _totalPages - syncedCount - failedCount;
//     final syncProgress = syncedCount / _totalPages;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           bottom: BorderSide(color: Colors.grey[200]!),
//         ),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     'Enhanced Sync Status',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: _networkAvailable 
//                           ? Colors.blue.withOpacity(0.1)
//                           : Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(
//                         color: _networkAvailable 
//                             ? Colors.blue.withOpacity(0.3)
//                             : Colors.red.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _networkAvailable ? Icons.wifi : Icons.wifi_off,
//                           size: 10,
//                           color: _networkAvailable ? Colors.blue[700] : Colors.red[700],
//                         ),
//                         const SizedBox(width: 2),
//                         Text(
//                           _networkAvailable ? 'Online' : 'Offline',
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: _networkAvailable ? Colors.blue[700] : Colors.red[700],
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (_autoSyncRunning) ...[
//                     const SizedBox(width: 4),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.green.withOpacity(0.3)),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.sync, size: 10, color: Colors.green[700]),
//                           const SizedBox(width: 2),
//                           Text(
//                             'Auto',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.green[700],
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     '$syncedCount / $_totalPages synced',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                   if (failedCount > 0 || pendingCount > 0)
//                     Text(
//                       '${failedCount > 0 ? '$failedCount failed' : ''}${failedCount > 0 && pendingCount > 0 ? ', ' : ''}${pendingCount > 0 ? '$pendingCount pending' : ''}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//          
//           // Enhanced progress bar with segments
//           Stack(
//             children: [
//               // Background
//               Container(
//                 height: 8,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               // Success progress
//               if (syncProgress > 0)
//                 FractionallySizedBox(
//                   widthFactor: syncProgress,
//                   child: Container(
//                     height: 8,
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//          
//           const SizedBox(height: 8),
//          
//           // Status legend
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildStatusLegendItem(Icons.check_circle, Colors.green, 'Synced', syncedCount),
//               if (failedCount > 0)
//                 _buildStatusLegendItem(Icons.error, Colors.red, 'Failed', failedCount),
//               if (pendingCount > 0)
//                 _buildStatusLegendItem(Icons.pending, Colors.orange, 'Pending', pendingCount),
//               if (_lastSyncAttempt != null)
//                 _buildLastSyncInfo(),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusLegendItem(IconData icon, Color color, String label, int count) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(width: 4),
//         Text(
//           '$label: $count',
//           style: TextStyle(
//             fontSize: 12,
//             color: color,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildLastSyncInfo() {
//     if (_lastSyncAttempt == null) return const SizedBox.shrink();
//    
//     final timeSince = DateTime.now().difference(_lastSyncAttempt!);
//     String timeText;
//    
//     if (timeSince.inMinutes < 1) {
//       timeText = 'Just now';
//     } else if (timeSince.inMinutes < 60) {
//       timeText = '${timeSince.inMinutes}m ago';
//     } else {
//       timeText = '${timeSince.inHours}h ago';
//     }
//    
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
//         const SizedBox(width: 4),
//         Text(
//           'Last: $timeText',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPageContent() {
//     if (!_pages.containsKey(_currentPage)) {
//       // Page not loaded yet, show loading
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading page...'),
//           ],
//         ),
//       );
//     }
//
//     final pageCallLogs = _pages[_currentPage]!;
//
//     if (pageCallLogs.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.phone_disabled,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No Calls on This Page',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'No calls found for $_registeredSim on page ${_currentPage + 1}',
//               style: TextStyle(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       itemCount: pageCallLogs.length,
//       itemBuilder: (context, index) {
//         return _buildCallItem(pageCallLogs[index]);
//       },
//     );
//   }
//
//   // ==================== MAIN BUILD METHOD ====================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('Call Log History'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         elevation: 0,
//         actions: [
//           // Auto-sync status indicator
//           Container(
//             margin: const EdgeInsets.only(right: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: _autoSyncRunning ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: _autoSyncRunning ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   _autoSyncRunning ? Icons.sync : Icons.sync_disabled,
//                   size: 14,
//                   color: _autoSyncRunning ? Colors.green[700] : Colors.grey[600],
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   _autoSyncRunning ? 'Auto' : 'Manual',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: _autoSyncRunning ? Colors.green[700] : Colors.grey[600],
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//
//         ],
//       ),
//       body: _errorMessage.isNotEmpty
//           ? _buildErrorState()
//           : _isLoading
//           ? const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading call history...'),
//           ],
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _onRefresh,
//         child: Column(
//           children: [
//             _buildHeader(),
//             _buildSyncStatusBar(),
//             _buildPaginationControls(),
//             Expanded(
//               child: PageView.builder(
//                 controller: _pageController,
//                 onPageChanged: _onPageChanged,
//                 itemCount: _totalPages,
//                 itemBuilder: (context, index) {
//                   return _buildPageContent();
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }