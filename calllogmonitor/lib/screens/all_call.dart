import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:calllogmonitor/theme/app_theme.dart';
import '../widgets/call_action_sheet.dart';
import '../services/notes_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AllCallsScreen extends StatefulWidget {
  final String deviceNumber;

  const AllCallsScreen({required this.deviceNumber, Key? key}) : super(key: key);

  @override
  State<AllCallsScreen> createState() => _AllCallsScreenState();
}

class _AllCallsScreenState extends State<AllCallsScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _tabs = [
    {'label': 'All', 'type': 'all'},
    {'label': 'Incoming', 'type': 'INCOMING'},
    {'label': 'Outgoing', 'type': 'OUTGOING'},
    {'label': 'Missed', 'type': 'MISSED'},
    {'label': 'Rejected', 'type': 'REJECTED'},
    {'label': 'Never Attended', 'type': 'never_attended'},
    {'label': 'Not Pickup By Client', 'type': 'not_pickup_by_client'},
  ];

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  List<dynamic> _groups = [];
  List<dynamic> _filteredGroups = [];
  Map<String, String> _notesCache = {};

  String _searchQuery = '';
  String _currentType = 'all';

  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadNotesCache();
    _fetchCalls(_currentType);
  }

  Future<void> _loadNotesCache() async {
    _notesCache = await NotesService.getAllNotes();
    if (mounted) setState(() {});
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _searchQuery = '';
      _currentPage = 1;
      _totalPages = 1;
    });
    _fetchCalls(_tabs[_tabController.index]['type']!);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading &&
        _currentPage < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _fetchCalls(String type) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _groups.clear();
      _filteredGroups.clear();
      _currentType = type;
      _currentPage = 1;
    });

    try {
      final response = await http.post(
        Uri.parse('https://trackship.in/api/lms/calls.php'),
        body: {
          'action': 'get_device_call_logs_v2',
          'device_number': widget.deviceNumber,
          'type': type,
          'page': '1',
          'app.version': '1.0.0',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        _groups = body['data'] ?? [];
        _totalPages = int.tryParse(body['total_page']?.toString() ?? '1') ?? 1;
        _applySearch();
      } else {
        _error = 'Error loading data';
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;

    try {
      final response = await http.post(
        Uri.parse('https://trackship.in/api/lms/calls.php'),
        body: {
          'action': 'get_device_call_logs_v2',
          'device_number': widget.deviceNumber,
          'type': _currentType,
          'page': nextPage.toString(),
          'app.version': '1.0.0',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final newGroups = body['data'] ?? [];
        _totalPages = int.tryParse(body['total_page']?.toString() ?? '1') ?? _totalPages;
        _currentPage = nextPage;
        _groups = _mergeGroups(_groups, newGroups);
        _applySearch();
      }
    } catch (_) {
      // Optionally log or show error
    }

    setState(() => _isLoadingMore = false);
  }

  List<dynamic> _mergeGroups(List<dynamic> oldGroups, List<dynamic> newGroups) {
    final Map<String, List<dynamic>> merged = {};
    for (var group in oldGroups) {
      merged[group['title']] = List.from(group['CallData'] ?? []);
    }
    for (var group in newGroups) {
      final title = group['title'];
      final calls = group['CallData'] ?? [];
      if (merged.containsKey(title)) {
        merged[title]!.addAll(calls);
      } else {
        merged[title] = List.from(calls);
      }
    }
    return merged.entries.map((e) => {'title': e.key, 'CallData': e.value}).toList();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredGroups = List.from(_groups);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredGroups = _groups.map((group) {
        final filteredCalls = (group['CallData'] ?? []).where((call) {
          final number = (call['caller_number'] ?? '').toLowerCase();
          final name = (call['caller_name'] ?? '').toLowerCase();
          return number.contains(query) || name.contains(query);
        }).toList();

        return {
          'title': group['title'],
          'CallData': filteredCalls,
        };
      }).where((group) => (group['CallData'] as List).isNotEmpty).toList();
    }

    setState(() {});
  }

  Color _getCallTypeColor(String type) {
    switch (type) {
      case 'INCOMING':
        return AppTheme.successWarm;
      case 'OUTGOING':
        return AppTheme.infoWarm;
      case 'MISSED':
        return AppTheme.errorWarm;
      case 'REJECTED':
        return AppTheme.warningWarm;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getCallTypeIcon(String type) {
    switch (type) {
      case 'INCOMING':
        return Icons.call_received;
      case 'OUTGOING':
        return Icons.call_made;
      case 'MISSED':
        return Icons.call_missed;
      case 'REJECTED':
        return Icons.call_missed_outgoing;
      default:
        return Icons.call;
    }
  }

  void _showCallActionSheet(Map<String, dynamic> call) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallActionSheet(
        phoneNumber: call['caller_number'] ?? '',
        contactName: call['caller_name']?.isNotEmpty == true
            ? call['caller_name']
            : null,
        onNotesUpdated: () {
          _loadNotesCache();
        },
      ),
    );
  }

  String _formatDuration(String? duration) {
    if (duration == null || duration.isEmpty) return '';
    try {
      final seconds = int.parse(duration);
      if (seconds == 0) return '';
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (minutes > 0) {
        return '${minutes}m ${remainingSeconds}s';
      } else {
        return '${seconds}s';
      }
    } catch (_) {
      return duration;
    }
  }

  // Helper methods for action buttons
  void _copyNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone number copied: $phoneNumber'),
        duration: const Duration(seconds: 2),
      ),
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
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
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

  void _showNotesDialog(Map<String, dynamic> call) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallActionSheet(
        phoneNumber: call['caller_number'] ?? '',
        contactName: call['caller_name']?.isNotEmpty == true
            ? call['caller_name']
            : null,
        onNotesUpdated: () {
          _loadNotesCache();
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWarm,
      appBar: AppBar(
        title: Text("Call Logs", style: AppTheme.headingMedium),
        backgroundColor: AppTheme.primaryWarm,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryBrown,
          labelColor: AppTheme.primaryBrown,
          unselectedLabelColor: AppTheme.textTertiary,
          labelStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          tabs: _tabs.map((tab) => Tab(text: tab['label'])).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.warmLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                decoration: AppTheme.getInputDecoration('Search by number or name...', icon: Icons.search),
                onChanged: (val) {
                  _searchQuery = val;
                  _applySearch();
                },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryBrown,
              ),
            )
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppTheme.errorWarm, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorWarm),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchCalls(_currentType),
                    style: AppTheme.primaryButtonStyle,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _filteredGroups.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_disabled, color: AppTheme.textTertiary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No calls found'
                        : 'No results for "$_searchQuery"',
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _filteredGroups.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoadingMore && index == _filteredGroups.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  );
                }

                final group = _filteredGroups[index];
                final calls = group['CallData'];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          group['title'] ?? '',
                          style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryBrown),
                        ),
                      ),
                      ...List.generate(calls.length, (i) {
                        final call = calls[i];
                        final callType = call['call_type'] ?? '';
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: i == 0
                                  ? BorderSide.none
                                  : BorderSide(color: AppTheme.dividerColor),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Main info row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                  // Call type icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getCallTypeColor(callType).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _getCallTypeColor(callType).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _getCallTypeIcon(callType),
                                      color: _getCallTypeColor(callType),
                                      size: 18,
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Compact info block
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Name/Number
                                        Text(
                                          (call['caller_name'] ?? '').isNotEmpty 
                                              ? call['caller_name'] 
                                              : call['caller_number'] ?? 'Unknown',
                                          style: AppTheme.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.primaryBrown,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        // Phone number (always show if different from name)
                                        if ((call['caller_name'] ?? '').isNotEmpty && 
                                            call['caller_number'] != null && 
                                            call['caller_number'].toString().isNotEmpty)
                                          Text(
                                            call['caller_number'],
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        
                                        const SizedBox(height: 2),
                                        
                                        // Compact date/time and duration row
                                        Row(
                                          children: [
                                            // Date/Time
                                            Expanded(
                                              child: Text(
                                                '${call['call_date'] ?? ''} • ${call['call_time'] ?? ''}',
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            
                                            // Duration
                                            if (_formatDuration(call['duration']).isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getCallTypeColor(callType).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _formatDuration(call['duration']),
                                                  style: AppTheme.bodySmall.copyWith(
                                                    color: _getCallTypeColor(callType),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            
                                            // Call type badge
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getCallTypeColor(callType).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                callType.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getCallTypeColor(callType),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Notes indicator
                                  if (_notesCache.containsKey(call['caller_number']) && 
                                      _notesCache[call['caller_number']]!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.note_alt,
                                        size: 14,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Action icons row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.copy,
                                      label: 'Copy',
                                      color: Colors.grey[600]!,
                                      onTap: () => _copyNumber(call['caller_number'] ?? ''),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.message,
                                      label: 'SMS',
                                      color: Colors.green[600]!,
                                      onTap: () => _sendSMS(call['caller_number'] ?? ''),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.chat,
                                      label: 'WhatsApp',
                                      color: Colors.green[700]!,
                                      onTap: () => _openWhatsApp(call['caller_number'] ?? ''),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.call,
                                      label: 'Call',
                                      color: Colors.blue[600]!,
                                      onTap: () => _makeCall(call['caller_number'] ?? ''),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.note_add,
                                      label: 'Notes',
                                      color: Colors.orange[600]!,
                                      onTap: () => _showNotesDialog(call),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}