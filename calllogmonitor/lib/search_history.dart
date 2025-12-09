import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({Key? key}) : super(key: key);

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> with TickerProviderStateMixin {
  final TextEditingController _callerController = TextEditingController();
  bool _isLoading = false;
  String _deviceNumber = '';
  
  // Main tab controller for Analysis/Summary/Logs/History (now 4 tabs)
  late TabController _mainTabController;
  // Sub tab controller for call type filtering
  late TabController _logsTabController;

  // Scroll controllers for each tab
  Map<String, ScrollController> _scrollControllers = {
    'all': ScrollController(),
    'incoming': ScrollController(),
    'outgoing': ScrollController(),
    'never_attended': ScrollController(),
    'not_pickup_by_client': ScrollController(),
    'missed': ScrollController(),
  };

  // Loading states for automatic loading
  Map<String, bool> _isLoadingMore = {
    'all': false,
    'incoming': false,
    'outgoing': false,
    'never_attended': false,
    'not_pickup_by_client': false,
    'missed': false,
  };

  // Complete data storage (all pages fetched)
  List<dynamic> _allCallData = [];

  // Data storage for different call types (filtered from _allCallData)
  Map<String, List<dynamic>> _callTypeData = {
    'all': [],
    'incoming': [],
    'outgoing': [],
    'never_attended': [],
    'not_pickup_by_client': [],
    'missed': [],
  };

  // Display pagination (for UI only, not data fetching)
  Map<String, Map<String, dynamic>> _displayPagination = {
    'all': {'currentPage': 1, 'itemsPerPage': 20},
    'incoming': {'currentPage': 1, 'itemsPerPage': 20},
    'outgoing': {'currentPage': 1, 'itemsPerPage': 20},
    'never_attended': {'currentPage': 1, 'itemsPerPage': 20},
    'not_pickup_by_client': {'currentPage': 1, 'itemsPerPage': 20},
    'missed': {'currentPage': 1, 'itemsPerPage': 20},
  };

  List<dynamic> _dataSummary = [];
  int _totalRecordsFromAPI = 0;
  int _totalPagesFromAPI = 1;

  // Analysis variables
  Map<String, int> _callTypeCount = {};
  Map<String, Duration> _callTypeDuration = {};
  String _mostActiveDay = '';
  String _mostActiveHour = '';

  // Total calculation variables (based on ALL data)
  Duration _totalCallDuration = Duration.zero;
  int _totalIncoming = 0;
  int _totalOutgoing = 0;
  int _totalMissed = 0;
  int _totalRejected = 0;
  int _totalNeverAttended = 0;
  int _totalNotPickupByClient = 0;
  int _combinedTotalCalls = 0;

  // Duration by type variables
  Duration _incomingDuration = Duration.zero;
  Duration _outgoingDuration = Duration.zero;
  Duration _missedDuration = Duration.zero;
  Duration _rejectedDuration = Duration.zero;
  Duration _neverAttendedDuration = Duration.zero;
  Duration _notPickupByClientDuration = Duration.zero;

  // Search History variables (separate for each tab)
  String _lastSearchedNumber = '';
  List<String> _searchHistory = [];
  String _lastWarehouseSearched = '';
  List<String> _warehouseSearchHistory = [];

  // Warehouse call logs variables
  late TabController _warehouseTabController;
  int _warehouseCurrentPage = 1;
  bool _warehouseIsLoading = false;
  String _warehouseSearchQuery = '';
  String _warehouseRawJson = '';
  String _warehouseErrors = '';
  String _warehouseStatus = '';
  int _warehouseTotalPages = 1;
  List<dynamic> _warehouseCallData = [];
  String _warehouseId = '';
  Map<String, List<dynamic>> _warehouseCallTypeData = {
    'all': [],
    'incoming': [],
    'outgoing': [],
    'missed': [],
    'rejected': [],
  };
  Map<String, bool> _warehouseIsLoadingMore = {
    'all': false,
    'incoming': false,
    'outgoing': false,
    'missed': false,
    'rejected': false,
  };
  Map<String, int> _warehouseCurrentPageMap = {
    'all': 1,
    'incoming': 1,
    'outgoing': 1,
    'missed': 1,
    'rejected': 1,
  };

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _logsTabController = TabController(length: 6, vsync: this);
    _warehouseTabController = TabController(length: 5, vsync: this);
    _warehouseTabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Add listener to main tab controller to force UI rebuilds
    _mainTabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadDeviceNumber();
    _setupScrollListeners();
    _loadSearchHistory(); // Only load search history, not call data
    _loadWarehouseNumber();
  }

  void _setupScrollListeners() {
    _scrollControllers.forEach((callType, controller) {
      controller.addListener(() => _onScroll(callType, controller));
    });
  }

  void _onScroll(String callType, ScrollController controller) {
    if (_isLoadingMore[callType]! || _isLoading) return;

    // Check if user has scrolled near the bottom (within 200 pixels)
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      if (_hasMoreDisplayData(callType)) {
        _loadMoreDisplayData(callType);
      }
    }
  }

  Future<void> _loadDeviceNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _deviceNumber = prefs.getString('mobile_number') ?? '';
      _warehouseId = prefs.getString('warehouse_id') ?? '';
    });
  }

  Future<void> _loadWarehouseNumber() async {
    // Removed fetching warehouse number here as it will be fetched in user_details_screen.dart
  }

  // Load only search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('search_history') ?? '';
    final warehouseHistoryJson = prefs.getString('warehouse_search_history') ?? '';

    setState(() {
      if (historyJson.isNotEmpty) {
        try {
          _searchHistory = List<String>.from(json.decode(historyJson));
        } catch (e) {
          _searchHistory = [];
        }
      }
      if (warehouseHistoryJson.isNotEmpty) {
        try {
          _warehouseSearchHistory = List<String>.from(json.decode(warehouseHistoryJson));
        } catch (e) {
          _warehouseSearchHistory = [];
        }
      }
    });
  }

  // Update search history only
  Future<void> _updateSearchHistory(String callerNumber) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Remove if already exists to avoid duplicates
      _searchHistory.remove(callerNumber);
      // Add to beginning of list
      _searchHistory.insert(0, callerNumber);
      // Keep only last 20 searches
      if (_searchHistory.length > 20) {
        _searchHistory = _searchHistory.take(20).toList();
      }
    });
    
    // Save updated history
    await prefs.setString('search_history', json.encode(_searchHistory));
  }

  // Clear search history
  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory.clear();
    });
  }

  // Search from history
  Future<void> _searchFromHistory(String phoneNumber) async {
    _callerController.text = phoneNumber;
    await _fetchCallLogs();
  }

  String _getCurrentCallType() {
    switch (_logsTabController.index) {
      case 0: return 'all';
      case 1: return 'incoming';
      case 2: return 'outgoing';
      case 3: return 'missed';
      case 4: return 'never_attended';
      case 5: return 'not_pickup_by_client';
      default: return 'all';
    }
  }

  Future<void> _fetchCallLogs() async {
    final callerNumber = _callerController.text.trim();
    if (callerNumber.isEmpty || _deviceNumber.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // **FIX: Force complete state reset with setState**
    await _clearAllDataWithStateUpdate();

    try {
      // First, fetch the first page to get total pages info
      final firstPageResponse = await http.post(
        Uri.parse('https://trackship.in/api/lms/calls.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'call_logs_details',
          'device_number': _deviceNumber,
          'caller_number': callerNumber,
          'page': '1',
        },
      );

      if (firstPageResponse.statusCode == 200) {
        final firstPageData = json.decode(firstPageResponse.body);
        
        setState(() {
          _totalPagesFromAPI = firstPageData['total_page'] ?? 1;
          _totalRecordsFromAPI = firstPageData['total_records'] ?? 0;
          _dataSummary = firstPageData['data_summary'] ?? [];
        });

        // Add first page data
        if (firstPageData['data_list'] != null) {
          _allCallData.addAll(firstPageData['data_list']);
        }

        // Fetch all remaining pages
        if (_totalPagesFromAPI > 1) {
          await _fetchAllRemainingPages(callerNumber);
        }

        // **FIX: Ensure all processing happens in setState**
        setState(() {
          _processAllCallData();
          _performAnalysis();
          _calculateTotals();
          _lastSearchedNumber = callerNumber;
        });

        // Update search history
        await _updateSearchHistory(callerNumber);

        // **FIX: Force UI refresh after data processing**
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // Force rebuild
            });
          }
        });

      } else {
        _showErrorSnackBar('Something went wrong');
      }
    } catch (e) {
      _showErrorSnackBar('Something went wrong');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAllRemainingPages(String callerNumber) async {
    List<Future<http.Response>> requests = [];
    
    // Create concurrent requests for all remaining pages
    for (int page = 2; page <= _totalPagesFromAPI; page++) {
      requests.add(
        http.post(
          Uri.parse('https://trackship.in/api/lms/calls.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'action': 'call_logs_details',
            'device_number': _deviceNumber,
            'caller_number': callerNumber,
            'page': page.toString(),
          },
        )
      );
    }

    // Execute all requests concurrently
    try {
      final responses = await Future.wait(requests);
      
      for (var response in responses) {
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData['data_list'] != null) {
            _allCallData.addAll(jsonData['data_list']);
          }
        }
      }
    } catch (e) {
      print('Error fetching remaining pages: $e');
    }
  }

  void _processAllCallData() {
    // Clear existing filtered data
    _callTypeData.forEach((key, value) => value.clear());
    
    // Create a set to track unique calls and prevent duplicates
    Set<String> uniqueCallIds = {};
    
    for (var call in _allCallData) {
      String callId = '${call['call_date']}_${call['call_time']}_${call['call_type']}_${call['duration']}';
      
      // Skip if duplicate
      if (uniqueCallIds.contains(callId)) {
        continue;
      }
      uniqueCallIds.add(callId);
      
      String callType = call['call_type']?.toString().toLowerCase() ?? 'unknown';
      
      // Add to 'all' category
      _callTypeData['all']!.add(call);
      
      // Add to specific category
      if (_callTypeData.containsKey(callType)) {
        _callTypeData[callType]!.add(call);
      }
    }
    
    // Remove duplicates from _allCallData as well
    _allCallData = _callTypeData['all']!;
  }

  // **FIX: Enhanced clear method with proper state management**
  Future<void> _clearAllDataWithStateUpdate() async {
    setState(() {
      _clearAllData();
    });

    // **FIX: Reset scroll positions properly**
    await _resetScrollPositions();

    // **FIX: Reset logs sub-tab synchronously**
    _logsTabController.index = 0;

    // Small delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void _clearAllData() {
    _allCallData.clear();
    _callTypeData.forEach((key, value) => value.clear());
    _displayPagination.forEach((key, value) {
      value['currentPage'] = 1;
    });
    _isLoadingMore.forEach((key, value) => _isLoadingMore[key] = false);
    _dataSummary.clear();
    _totalRecordsFromAPI = 0;
    _totalPagesFromAPI = 1;
    _resetTotals();
    _callTypeCount.clear();
    _callTypeDuration.clear();
    _lastSearchedNumber = '';
    _mostActiveDay = '';
    _mostActiveHour = '';
  }

  // **FIX: Proper scroll position reset**
  Future<void> _resetScrollPositions() async {
    for (var controller in _scrollControllers.values) {
      if (controller.hasClients) {
        try {
          await controller.animateTo(
            0.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        } catch (e) {
          // If animation fails, jump to position
          if (controller.hasClients) {
            controller.jumpTo(0.0);
          }
        }
      }
    }
  }

  // Clear all data and UI
  Future<void> _clearAllDataAndUI() async {
    await _clearAllDataWithStateUpdate();
    _callerController.clear();
    setState(() {
      // Force UI rebuild
    });
  }

  void _loadMoreDisplayData(String callType) {
    if (_isLoadingMore[callType]! || !_hasMoreDisplayData(callType)) return;
    
    setState(() {
      _isLoadingMore[callType] = true;
    });

    // Simulate a small delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayPagination[callType]!['currentPage']++;
          _isLoadingMore[callType] = false;
        });
      }
    });
  }

  List<dynamic> _getDisplayData(String callType) {
    final data = _callTypeData[callType] ?? [];
    final currentPage = _displayPagination[callType]!['currentPage'] as int;
    final itemsPerPage = _displayPagination[callType]!['itemsPerPage'] as int;
    
    final endIndex = currentPage * itemsPerPage;
    return data.take(endIndex).toList();
  }

  bool _hasMoreDisplayData(String callType) {
    final data = _callTypeData[callType] ?? [];
    final currentPage = _displayPagination[callType]!['currentPage'] as int;
    final itemsPerPage = _displayPagination[callType]!['itemsPerPage'] as int;
    
    return data.length > (currentPage * itemsPerPage);
  }

  void _performAnalysis() {
    _callTypeCount.clear();
    _callTypeDuration.clear();
    
    Map<String, int> dayCount = {};
    Map<String, int> hourCount = {};

    // Use ALL call data for analysis
    for (var call in _allCallData) {
      // Count call types
      String callType = call['call_type']?.toString().toLowerCase() ?? 'unknown';
      _callTypeCount[callType] = (_callTypeCount[callType] ?? 0) + 1;

      // Calculate duration by type
      String durationStr = call['duration']?.toString() ?? '00:00:00';
      Duration duration = _parseDuration(durationStr);
      _callTypeDuration[callType] = (_callTypeDuration[callType] ?? Duration.zero) + duration;

      // Analyze most active day and hour
      String date = call['call_date']?.toString() ?? '';
      String time = call['call_time']?.toString() ?? '';
      
      if (date.isNotEmpty) {
        DateTime? callDate = DateTime.tryParse(date);
        if (callDate != null) {
          String dayName = _getDayName(callDate.weekday);
          dayCount[dayName] = (dayCount[dayName] ?? 0) + 1;
        }
      }

      if (time.isNotEmpty) {
        String hour = time.split(':')[0];
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }
    }

    // Find most active day and hour
    _mostActiveDay = dayCount.entries
        .fold<MapEntry<String, int>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev)
        ?.key ?? 'Unknown';
        
    _mostActiveHour = hourCount.entries
        .fold<MapEntry<String, int>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev)
        ?.key ?? 'Unknown';
  }

  void _calculateTotals() {
    // Reset totals
    _resetTotals();

    // Use ALL call data for calculations
    for (var call in _allCallData) {
      String callType = call['call_type']?.toString().toLowerCase() ?? '';
      String durationStr = call['duration']?.toString() ?? '00:00:00';
      Duration duration = _parseDuration(durationStr);

      // Add to total duration
      _totalCallDuration += duration;
      
      // Count by call type and add duration
      switch (callType) {
        case 'incoming':
          _totalIncoming++;
          _incomingDuration += duration;
          break;
        case 'outgoing':
          _totalOutgoing++;
          _outgoingDuration += duration;
          break;
        case 'missed':
          _totalMissed++;
          _missedDuration += duration;
          break;
        case 'rejected':
          _totalRejected++;
          _rejectedDuration += duration;
          break;
        case 'never_attended':
          _totalNeverAttended++;
          _neverAttendedDuration += duration;
          break;
        case 'not_pickup_by_client':
          _totalNotPickupByClient++;
          _notPickupByClientDuration += duration;
          break;
      }
    }

    // Calculate combined total calls
    _combinedTotalCalls = _totalIncoming + _totalOutgoing + _totalMissed + 
                         _totalRejected + _totalNeverAttended + _totalNotPickupByClient;
  }

  int parseDurationToSeconds(String duration) {
    int seconds = 0;
    final hourRegex = RegExp(r'(\d+)h');
    final minuteRegex = RegExp(r'(\d+)m');
    final secondRegex = RegExp(r'(\d+)s');
    final hourMatch = hourRegex.firstMatch(duration);
    final minuteMatch = minuteRegex.firstMatch(duration);
    final secondMatch = secondRegex.firstMatch(duration);
    if (hourMatch != null) {
      seconds += int.parse(hourMatch.group(1)!) * 3600;
    }
    if (minuteMatch != null) {
      seconds += int.parse(minuteMatch.group(1)!) * 60;
    }
    if (secondMatch != null) {
      seconds += int.parse(secondMatch.group(1)!);
    }
    return seconds;
  }

  String formatSeconds(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours}h ${minutes}m ${seconds}s";
  }

  Duration _parseDuration(String durationStr) {
    try {
      int totalSeconds = parseDurationToSeconds(durationStr);
      return Duration(seconds: totalSeconds);
    } catch (e) {
      return Duration.zero;
    }
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDuration(Duration duration) {
    return formatSeconds(duration.inSeconds);
  }

  String _getCallTypeDisplayName(String callType) {
    switch (callType.toLowerCase()) {
      case 'never_attended':
        return 'Never Attend';
      case 'not_pickup_by_client':
        return 'Not Picked by Client';
      case 'incoming':
        return 'Incoming';
      case 'outgoing':
        return 'Outgoing';
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      default:
        // Capitalize first letter and lowercase the rest
        if (callType.isEmpty) return '';
        return callType[0].toUpperCase() + callType.substring(1).toLowerCase();
    }
  }

  // Helper methods for action buttons
  void _copyNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $phoneNumber to clipboard')),
    );
  }

  void _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SMS app')),
      );
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    final whatsappUrl = "https://wa.me/$phoneNumber";
    final Uri whatsappUri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp is not installed')),
      );
    }
  }

  void _makeCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not make call')),
      );
    }
  }

  void _showNotesDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notes for $phoneNumber'),
          content: const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter your notes here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Save notes functionality
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes saved')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabeledActionButton(IconData icon, Color color, String label, String tooltip, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  @override
  void dispose() {
    _callerController.dispose();
    _mainTabController.dispose();
    _logsTabController.dispose();
    _warehouseTabController.dispose();
    _scrollControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }
  
  Future<void> _handleRefresh() async {
    // Save current main tab index
    int currentMainTabIndex = _mainTabController.index;

    // Save current sub-tab index depending on main tab
    int currentSubTabIndex = 0;
    if (currentMainTabIndex == 0) {
      currentSubTabIndex = _warehouseTabController.index;
    } else if (currentMainTabIndex == 1) {
      currentSubTabIndex = _logsTabController.index;
    }

    // Clear all data and search history
    await _clearAllDataWithStateUpdate();
    await _clearSearchHistory();
    _callerController.clear();
    _warehouseSearchQuery = '';

    // Clear warehouse data
    setState(() {
      _warehouseCallData.clear();
      _warehouseCallTypeData.forEach((key, value) => value.clear());
      _warehouseCurrentPage = 1;
      _warehouseCurrentPageMap.forEach((key, value) => _warehouseCurrentPageMap[key] = 1);
      _warehouseIsLoadingMore.forEach((key, value) => _warehouseIsLoadingMore[key] = false);
    });

    // Reset scroll positions
    await _resetScrollPositions();

    // Restore tab indices
    setState(() {
      _mainTabController.index = currentMainTabIndex;
      if (currentMainTabIndex == 0) {
        _warehouseTabController.index = currentSubTabIndex;
      } else if (currentMainTabIndex == 1) {
        _logsTabController.index = currentSubTabIndex;
      }
    });
  }

  void _resetTotals() {
    _totalCallDuration = Duration.zero;
    _totalIncoming = 0;
    _totalOutgoing = 0;
    _totalMissed = 0;
    _totalRejected = 0;
    _totalNeverAttended = 0;
    _totalNotPickupByClient = 0;
    _combinedTotalCalls = 0;
    _incomingDuration = Duration.zero;
    _outgoingDuration = Duration.zero;
    _missedDuration = Duration.zero;
    _rejectedDuration = Duration.zero;
    _neverAttendedDuration = Duration.zero;
    _notPickupByClientDuration = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _handleRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(icon: Icon(Icons.support_agent), text: 'customer calls'),
            Tab(icon: Icon(Icons.phone), text: 'Logs'),
            Tab(icon: Icon(Icons.analytics), text: 'Summary'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Section for Warehouse Call Logs tab
          if (_mainTabController.index == 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by Number or Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _warehouseSearchQuery = value;
                    },
                    onSubmitted: (value) {
                      _warehouseSearchQuery = value;
                      _warehouseCurrentPage = 1;
                      _fetchWarehouseCallLogs();
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _warehouseIsLoading ? null : () {
                      _warehouseCurrentPage = 1;
                      _fetchWarehouseCallLogs();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Customer & Staff Call List'),
                  ),
                ],
              ),
            ),
          // Search Section for Logs tab
          if (_mainTabController.index == 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _callerController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Caller Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchCallLogs,
                    icon: const Icon(Icons.search),
                    label: const Text('Search Call Logs'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildWarehouseCallLogsTab(),
                _buildCallLogsTab(),
                _buildCombinedSummaryAnalysisTab(),
                _buildSearchHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Search History Tab
  Widget _buildSearchHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_searchHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Search History'),
                        content: const Text('Are you sure you want to clear all search history?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _clearSearchHistory();
                    }
                  },
                  icon: const Icon(Icons.clear_all, color: Colors.red),
                  label: const Text('Clear History', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search history list
          Expanded(
            child: _searchHistory.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No search history',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Previously searched numbers will appear here',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchHistory.length,
                    itemBuilder: (context, index) {
                      final phoneNumber = _searchHistory[index];
                      final isCurrentSearch = phoneNumber == _lastSearchedNumber;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isCurrentSearch ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentSearch ? Colors.blue : Colors.grey,
                            child: const Icon(Icons.phone, color: Colors.white),
                          ),
                          title: Text(
                            phoneNumber,
                            style: TextStyle(
                              fontWeight: isCurrentSearch ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentSearch ? Colors.blue : Colors.black,
                            ),
                          ),
                          subtitle: isCurrentSearch 
                              ? const Text(
                                  'Currently loaded',
                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCurrentSearch)
                                IconButton(
                                  icon: const Icon(Icons.search, color: Colors.blue),
                                  tooltip: 'Search this number',
                                  onPressed: () => _searchFromHistory(phoneNumber),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Remove from history',
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remove from History'),
                                      content: Text('Remove "$phoneNumber" from search history?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    final prefs = await SharedPreferences.getInstance();
                                    setState(() {
                                      _searchHistory.removeAt(index);
                                    });
                                    await prefs.setString('search_history', json.encode(_searchHistory));
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: isCurrentSearch ? null : () => _searchFromHistory(phoneNumber),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogsTab() {
    return Column(
      children: [
        // Call Type Tabs
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _logsTabController,
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
              Tab(text: 'Missed'),
              Tab(text: 'Never Attend'),
              Tab(text: 'Not Picked by Client'),
            ],
          ),
        ),
        
        // Call Logs Content
        Expanded(
          child: TabBarView(
            controller: _logsTabController,
            children: [
              _buildCallTypeList('all'),
              _buildCallTypeList('incoming'),
              _buildCallTypeList('outgoing'),
              _buildCallTypeList('missed'),
              _buildCallTypeList('never_attended'),
              _buildCallTypeList('not_pickup_by_client'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallTypeList(String callType) {
    final allData = _callTypeData[callType] ?? [];
    final displayData = _getDisplayData(callType);
    final hasMore = _hasMoreDisplayData(callType);
    final isLoadingMore = _isLoadingMore[callType]!;

    return Column(
      children: [
        // Data Info
        if (allData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing: ${displayData.length} of ${allData.length}'),
                Text('Total ${_getCallTypeDisplayName(callType)}: ${allData.length} calls'),
              ],
            ),
          ),

        // Call Logs List with Auto-Loading
        Expanded(
          child: allData.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_getCallTypeDisplayName(callType)} calls found',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollControllers[callType],
                  itemCount: displayData.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at bottom while loading more
                    if (isLoadingMore && index == displayData.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Loading more...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    if (index >= displayData.length) return const SizedBox();

                    final call = displayData[index];
                    final phoneNumber = call['caller_number'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getCallTypeColor(call['call_type']),
                                  child: Icon(
                                    _getCallTypeIcon(call['call_type']),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                    '${call['call_date']} • ${call['call_time']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                      if (callType == 'all')
                                        Text(
                                          'Type: ${_getCallTypeDisplayName(call['call_type'] ?? '')}',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      Text(
                                        'Number: $phoneNumber',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${call['duration']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                            _buildLabeledActionButton(Icons.call, Colors.blue, 'Call', 'Call', () => _makeCall(phoneNumber)),
                            _buildLabeledActionButton(Icons.message, Colors.green, 'SMS', 'SMS', () => _sendSMS(phoneNumber)),
                            _buildLabeledActionButton(Icons.chat, Colors.green.shade700, 'WhatsApp', 'WhatsApp', () => _openWhatsApp(phoneNumber)),
                            _buildLabeledActionButton(Icons.copy, Colors.grey, 'Copy', 'Copy', () => _copyNumber(phoneNumber)),
                            _buildLabeledActionButton(Icons.note_add, Colors.orange, 'Notes', 'Notes', () => _showNotesDialog(phoneNumber)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom indicator for scroll hint (only when there's more data)
        if (hasMore && !isLoadingMore && displayData.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Scroll down for more',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCombinedSummaryAnalysisTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _allCallData.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No summary data available', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              children: [
                // API Info Card
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text(
                              'Data Fetch Summary',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTotalRow('Total Pages Fetched', _totalPagesFromAPI.toString(), Icons.pages),
                        _buildTotalRow('Actual Unique Records', _allCallData.length.toString(), Icons.verified),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Combined Totals Card - ALL PAGES DATA
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assessment, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Combined Totals (All Pages)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTotalRow('Total Calls', _combinedTotalCalls.toString(), Icons.phone),
                        _buildTotalRow('Total Duration', _formatDuration(_totalCallDuration), Icons.access_time),
                        const Divider(thickness: 2),
                        const Text(
                          'Call Count & Duration by Type:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildDurationRow('Incoming', _totalIncoming.toString(), _formatDuration(_incomingDuration), Icons.call_received, Colors.green),
                        _buildDurationRow('Outgoing', _totalOutgoing.toString(), _formatDuration(_outgoingDuration), Icons.call_made, Colors.blue),
                        _buildDurationRow('Missed', _totalMissed.toString(), _formatDuration(_missedDuration), Icons.call_received, Colors.red),
                        _buildDurationRow('Rejected', _totalRejected.toString(), _formatDuration(_rejectedDuration), Icons.call_end, Colors.orange),
                        _buildDurationRow('Never Attend', _totalNeverAttended.toString(), _formatDuration(_neverAttendedDuration), Icons.phone_disabled, Colors.purple),
                        _buildDurationRow('Not Picked by Client', _totalNotPickupByClient.toString(), _formatDuration(_notPickupByClientDuration), Icons.phone_missed, Colors.brown),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Stats Overview (Based on ALL data)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Overview (All Pages)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickStat('Total\nCalls', _combinedTotalCalls.toString(), Colors.blue),
                            _buildQuickStat('Total\nDuration', _formatDurationShort(_totalCallDuration), Colors.green),
                            _buildQuickStat('Avg Duration\nper Call', _getAverageDuration(), Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Call Type Distribution by Count (Based on ALL data)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call Type Distribution by Count (All Pages)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ..._callTypeCount.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getCallTypeColorByName(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${_getCallTypeDisplayName(entry.key)}: ${entry.value} calls'),
                                  ),
                                  Text(
                                    '${(entry.value / _combinedTotalCalls * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Duration Analysis (Based on ALL data)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Duration by Type (All Pages)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ..._callTypeDuration.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_getCallTypeDisplayName(entry.key)}:'),
                                  Text(_formatDuration(entry.value)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _allCallData.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.summarize, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No summary data available', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              children: [
                // API Info Card
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text(
                              'Data Fetch Summary',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTotalRow('Total Pages Fetched', _totalPagesFromAPI.toString(), Icons.pages),
                        _buildTotalRow('Actual Unique Records', _allCallData.length.toString(), Icons.verified),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Combined Totals Card - ALL PAGES DATA
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assessment, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Combined Totals (All Pages)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTotalRow('Total Calls', _combinedTotalCalls.toString(), Icons.phone),
                        _buildTotalRow('Total Duration', _formatDuration(_totalCallDuration), Icons.access_time),
                        const Divider(thickness: 2),
                        const Text(
                          'Call Count & Duration by Type:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildDurationRow('Incoming', _totalIncoming.toString(), _formatDuration(_incomingDuration), Icons.call_received, Colors.green),
                        _buildDurationRow('Outgoing', _totalOutgoing.toString(), _formatDuration(_outgoingDuration), Icons.call_made, Colors.blue),
                        _buildDurationRow('Missed', _totalMissed.toString(), _formatDuration(_missedDuration), Icons.call_received, Colors.red),
                        _buildDurationRow('Rejected', _totalRejected.toString(), _formatDuration(_rejectedDuration), Icons.call_end, Colors.orange),
                        _buildDurationRow('Never Attend', _totalNeverAttended.toString(), _formatDuration(_neverAttendedDuration), Icons.phone_disabled, Colors.purple),
                        _buildDurationRow('Not Picked by Client', _totalNotPickupByClient.toString(), _formatDuration(_notPickupByClientDuration), Icons.phone_missed, Colors.brown),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationRow(String label, String count, String duration, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$count calls',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              duration,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _callTypeCount.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No analysis data available', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              children: [
                // Quick Stats Overview (Based on ALL data)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Overview (All Pages)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickStat('Total\nCalls', _combinedTotalCalls.toString(), Colors.blue),
                            _buildQuickStat('Total\nDuration', _formatDurationShort(_totalCallDuration), Colors.green),
                            _buildQuickStat('Avg Duration\nper Call', _getAverageDuration(), Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Call Type Distribution by Count (Based on ALL data)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call Type Distribution by Count (All Pages)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ..._callTypeCount.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getCallTypeColorByName(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${_getCallTypeDisplayName(entry.key)}: ${entry.value} calls'),
                                  ),
                                  Text(
                                    '${(entry.value / _combinedTotalCalls * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Duration Analysis (Based on ALL data)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Duration by Type (All Pages)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ..._callTypeDuration.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_getCallTypeDisplayName(entry.key)}:'),
                                  Text(_formatDuration(entry.value)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDurationShort(Duration duration) {
    return formatSeconds(duration.inSeconds);
  }

  String _getAverageDuration() {
    if (_combinedTotalCalls == 0) return '0s';
    
    int avgSeconds = _totalCallDuration.inSeconds ~/ _combinedTotalCalls;
    
    return formatSeconds(avgSeconds);
  }

  Color _getCallTypeColor(String? callType) {
    switch (callType?.toLowerCase()) {
      case 'incoming':
        return Colors.green;
      case 'outgoing':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      case 'rejected':
        return Colors.orange;
      case 'never_attended':
        return Colors.purple;
      case 'not_pickup_by_client':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getCallTypeColorByName(String callTypeName) {
    switch (callTypeName.toLowerCase()) {
      case 'incoming':
        return Colors.green;
      case 'outgoing':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      case 'rejected':
        return Colors.orange;
      case 'never_attended':
        return Colors.purple;
      case 'not_pickup_by_client':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getCallTypeIcon(String? callType) {
    switch (callType?.toLowerCase()) {
      case 'incoming':
        return Icons.call_received;
      case 'outgoing':
        return Icons.call_made;
      case 'missed':
        return Icons.call_received;
      case 'rejected':
        return Icons.call_end;
      case 'never_attended':
        return Icons.phone_disabled;
      case 'not_pickup_by_client':
        return Icons.phone_missed;
      default:
        return Icons.phone;
    }
  }

  // Warehouse Call Logs Methods
  Future<void> _fetchWarehouseCallLogs() async {
    if (_warehouseSearchQuery.isEmpty) return;

    setState(() {
      _warehouseIsLoading = true;
    });

    try {
      final bodyMap = {
        'action': 'get_cutomer_call_logs',
        'warehouse': _warehouseId,
        'search': _warehouseSearchQuery,
        'type': 'all',
        'page': _warehouseCurrentPage.toString(),
      };

      final response = await http.post(
        Uri.parse('https://trackship.in/api/lms/calls.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyMap,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> callLogs = [];

        // Process the response data similar to _fetchWarehouseCallLogsByType
        if (data is List) {
          callLogs = data;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          callLogs = data['data'];
        }

        setState(() {
          _warehouseRawJson = json.encode(data);
          // Process and store the call logs data
          _processWarehouseCallData(callLogs);
          _warehouseTotalPages = 1; // Reset for new search
        });
      } else {
        _showErrorSnackBar('Failed to fetch warehouse call logs');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }

    setState(() {
      _warehouseIsLoading = false;
    });
  }


  Widget _buildWarehouseCallLogsTab() {
    return Column(
      children: [
        TabBar(
          controller: _warehouseTabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
            Tab(text: 'Missed'),
            Tab(text: 'Rejected'),
          ],
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
        Expanded(
          child: TabBarView(
            controller: _warehouseTabController,
            children: [
              _buildWarehouseCallTypeList('all'),
              _buildWarehouseCallTypeList('incoming'),
              _buildWarehouseCallTypeList('outgoing'),
              _buildWarehouseCallTypeList('missed'),
              _buildWarehouseCallTypeList('rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseCallTypeList(String callType) {
    final callLogs = _warehouseCallTypeData[callType] ?? [];
    final isLoadingMore = _warehouseIsLoadingMore[callType] ?? false;

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification.metrics.pixels >= scrollNotification.metrics.maxScrollExtent - 200) {
          _loadMoreWarehouseCallLogs(callType);
        }
        return false;
      },
      child: callLogs.isEmpty
          ? Center(
              child: Text(
                'No $callType calls found',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: callLogs.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == callLogs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final call = callLogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getCallTypeColor(call['call_type']),
                              child: Icon(
                                _getCallTypeIcon(call['call_type']),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${call['call_date']} - ${call['call_time']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (callType == 'all')
                                    Text(
                                      'Type: ${_getCallTypeDisplayName(call['call_type'] ?? '')}',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  Text(
                                    'Number: ${call['device_number'] ?? ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (call['staff_name'] != null && call['staff_name'].toString().isNotEmpty)
                                    Text(
                                      'Staff: ${call['staff_name']}',
                                      style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${call['duration']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.call, Colors.blue, 'Call', () => _makeWarehouseCall(call['device_number'] ?? '')),
                            _buildActionButton(Icons.message, Colors.green, 'SMS', () => _sendSMS(call['device_number'] ?? '')),
                            _buildActionButton(Icons.chat, Colors.green.shade700, 'WhatsApp', () => _openWhatsApp(call['device_number'] ?? '')),
                            _buildActionButton(Icons.copy, Colors.grey, 'Copy', () => _copyWarehouseNumber(call['device_number'] ?? '')),
                            _buildActionButton(Icons.note_add, Colors.orange, 'Notes', () => _showNotesDialog(call['device_number'] ?? '')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getWarehouseCallTypeColor(String callType) {
    switch (callType.toLowerCase()) {
      case 'incoming':
        return Colors.green;
      case 'outgoing':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      case 'rejected':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getWarehouseCallTypeIcon(String callType) {
    switch (callType.toLowerCase()) {
      case 'incoming':
        return Icons.call_received;
      case 'outgoing':
        return Icons.call_made;
      case 'missed':
        return Icons.call_missed;
      case 'rejected':
        return Icons.call_missed_outgoing;
      default:
        return Icons.call;
    }
  }

  void _makeWarehouseCall(String phoneNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phoneNumber')),
    );
  }

  void _copyWarehouseNumber(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $phoneNumber')),
    );
  }

  void _loadMoreWarehouseCallLogs(String callType) {
    if (_warehouseIsLoadingMore[callType]!) return;
    if (_warehouseCurrentPageMap[callType]! >= _warehouseTotalPages) return;

    setState(() {
      _warehouseCurrentPageMap[callType] = _warehouseCurrentPageMap[callType]! + 1;
    });

    _fetchWarehouseCallLogsByType(callType);
  }

  void _processWarehouseCallData(List<dynamic> callLogs) {
    // Clear existing data
    _warehouseCallTypeData.forEach((key, value) => value.clear());

    // The API returns a list of groups, each with a "title" and "CallData" list
    // We need to flatten the CallData lists into a single list for processing
    List<dynamic> flattenedCallLogs = [];
    for (var group in callLogs) {
      if (group is Map && group.containsKey('CallData') && group['CallData'] is List) {
        flattenedCallLogs.addAll(group['CallData']);
      }
    }

    // Process each call log and categorize by type
    for (var call in flattenedCallLogs) {
      String callType = call['call_type']?.toString().toLowerCase() ?? 'unknown';

      // Add to 'all' category
      _warehouseCallTypeData['all']!.add(call);

      // Add to specific category if it exists
      if (_warehouseCallTypeData.containsKey(callType)) {
        _warehouseCallTypeData[callType]!.add(call);
      }
    }
  }

  Future<void> _fetchWarehouseCallLogsByType(String callType) async {
    if (_warehouseSearchQuery.isEmpty) return;

    setState(() {
      _warehouseIsLoadingMore[callType] = true;
    });

    try {
      final bodyMap = {
        'action': 'get_cutomer_call_logs',
        'warehouse': _warehouseId,
        'search': _warehouseSearchQuery,
        'type': callType,
        'page': _warehouseCurrentPageMap[callType].toString(),
      };

      final response = await http.post(
        Uri.parse('https://trackship.in/api/lms/calls.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyMap,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> callLogs = [];
        if (data is List) {
          callLogs = data;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          callLogs = data['data'];
        }
        setState(() {
          if (_warehouseCurrentPageMap[callType] == 1) {
            _warehouseCallTypeData[callType] = callLogs;
          } else {
            _warehouseCallTypeData[callType]!.addAll(callLogs);
          }
          _warehouseTotalPages = 1;
        });
      } else {
        _showErrorSnackBar('Failed to fetch warehouse call logs');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }

    setState(() {
      _warehouseIsLoadingMore[callType] = false;
    });
  }
}
