import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'lead_detail_screen.dart';
import 'package:calllogmonitor/theme/app_theme.dart';

class FilteredLeadsScreen extends StatefulWidget {
  final String sourceId;
  final String sourceName;
  final String statusId;
  final String statusName;

  const FilteredLeadsScreen({
    Key? key,
    required this.sourceId,
    required this.sourceName,
    required this.statusId,
    required this.statusName,
  }) : super(key: key);

  @override
  _FilteredLeadsScreenState createState() => _FilteredLeadsScreenState();
}

class _FilteredLeadsScreenState extends State<FilteredLeadsScreen> {
  bool _isLoading = true;
  bool _isCachingInBackground = false;
  int _cachingProgress = 0;
  int _cachingTotal = 0;
  String _warehouseId = '';
  String _salesId = '';
  String _apiAuthKey = '';

  List<Map<String, dynamic>> _filteredLeads = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalLeads = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  final ScrollController _scrollController = ScrollController();

  static const String baseURL = "https://trackship.in";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _ensureNativePermissionsOnce();
    _loadExecutiveData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading &&
        _hasMoreData &&
        _currentPage < _totalPages) {
      _loadMoreData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExecutiveData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _warehouseId = prefs.getString('executive_warehouse_id') ?? '';
      _salesId = prefs.getInt('executive_id')?.toString() ?? '';
      _apiAuthKey = prefs.getString('executive_auth_key') ?? '';
    });

    debugPrint('=== Executive Data Loaded ===');
    debugPrint('Warehouse ID: $_warehouseId');
    debugPrint('Sales ID: $_salesId');
    debugPrint('Auth Key: ${_apiAuthKey.isNotEmpty ? "Present" : "Missing"}');

    await _fetchFilteredLeads();
  }

  Future<void> _forceRefresh() async {
    debugPrint('=== Force Refresh Initiated ===');
    setState(() {
      _isLoading = true;
      _filteredLeads.clear();
      _currentPage = 1;
      _totalPages = 1;
      _totalLeads = 0;
      _hasMoreData = true;
      _isLoadingMore = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    await _fetchFilteredLeads();
  }

  /// 🚀 FIXED: Fetch ALL pages for native cache in background
  Future<void> _fetchAllPagesForCache() async {
    setState(() {
      _isCachingInBackground = true;
      _cachingProgress = 0;
      _cachingTotal = 0;
    });

    try {
      debugPrint('=== 🔄 Starting cache update for ALL pages ===');

      List<Map<String, dynamic>> allLeads = [];
      int currentPage = 1;
      int totalPages = 1;
      int failureCount = 0;
      const int maxFailures = 3;

      // First, get total pages from the API
      debugPrint('📥 Fetching page 1 to determine total pages...');

      final firstResponse = await http.post(
        Uri.parse('$baseURL/api/lms/leads.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: {
          'action': 'list_all',
          'api_auth_key': _apiAuthKey,
          'wh_id': _warehouseId,
          'sales_id': _salesId,
          'source_id': widget.sourceId,
          'status_id': widget.statusId,
          'page': '1',
          'per_page': '20',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      ).timeout(const Duration(seconds: 30));

      if (firstResponse.statusCode == 200) {
        final firstData = json.decode(firstResponse.body);

        if (firstData['status'] == 'ok') {
          totalPages = int.tryParse(firstData['total_page']?.toString() ?? '1') ?? 1;
          final int totalLeadsCount = int.tryParse(firstData['total']?.toString() ?? '0') ?? 0;

          setState(() {
            _cachingTotal = totalPages;
            _cachingProgress = 1;
          });

          debugPrint('📊 Total pages to fetch: $totalPages');
          debugPrint('📊 Total leads available: $totalLeadsCount');

          // Add first page data
          if (firstData['data'] != null) {
            final List<dynamic> pageData = firstData['data'];
            allLeads.addAll(pageData.cast<Map<String, dynamic>>());
            debugPrint('✅ Page 1/$totalPages: ${pageData.length} leads added');
          }

          // Fetch remaining pages (2 to totalPages)
          for (currentPage = 2; currentPage <= totalPages; currentPage++) {
            try {
              debugPrint('📥 Fetching page $currentPage/$totalPages...');

              final response = await http.post(
                Uri.parse('$baseURL/api/lms/leads.php'),
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'Cache-Control': 'no-cache',
                  'Pragma': 'no-cache',
                },
                body: {
                  'action': 'list_all',
                  'api_auth_key': _apiAuthKey,
                  'wh_id': _warehouseId,
                  'sales_id': _salesId,
                  'source_id': widget.sourceId,
                  'status_id': widget.statusId,
                  'page': currentPage.toString(),
                  'per_page': '20',
                  'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                },
              ).timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  debugPrint('⏱️ Timeout on page $currentPage');
                  throw TimeoutException('Request timeout');
                },
              );

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);

                if (jsonData['status'] == 'ok' && jsonData['data'] != null) {
                  final List<dynamic> pageData = jsonData['data'];

                  if (pageData.isNotEmpty) {
                    allLeads.addAll(pageData.cast<Map<String, dynamic>>());
                    debugPrint('✅ Page $currentPage/$totalPages: ${pageData.length} leads (Total: ${allLeads.length})');
                    failureCount = 0; // Reset on success
                  } else {
                    debugPrint('⚠️ Page $currentPage returned empty data');
                    failureCount++;
                  }
                } else {
                  debugPrint('⚠️ Page $currentPage: Invalid response');
                  failureCount++;
                }
              } else {
                debugPrint('❌ Page $currentPage: HTTP ${response.statusCode}');
                failureCount++;
              }

              // Update progress
              if (mounted) {
                setState(() {
                  _cachingProgress = currentPage;
                });
              }

              // Stop if too many consecutive failures
              if (failureCount >= maxFailures) {
                debugPrint('❌ Too many failures ($failureCount), stopping at page $currentPage');
                break;
              }

              // Small delay between requests
              if (currentPage < totalPages) {
                await Future.delayed(const Duration(milliseconds: 200));
              }

            } catch (e) {
              debugPrint('❌ Error on page $currentPage: $e');
              failureCount++;

              if (failureCount >= maxFailures) {
                debugPrint('❌ Too many failures, stopping');
                break;
              }

              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        } else {
          debugPrint('❌ First page returned error status: ${firstData['status']}');
        }
      } else {
        debugPrint('❌ First page HTTP error: ${firstResponse.statusCode}');
      }

      // Update native cache with ALL collected leads
      if (allLeads.isNotEmpty) {
        await _updateNativeCache(allLeads);
        debugPrint('✅✅✅ Native cache updated with ${allLeads.length} total leads ✅✅✅');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Successfully cached ${allLeads.length} leads for auto-save'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('⚠️ No leads were fetched for cache');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Failed to fetch leads for cache'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _fetchAllPagesForCache: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Cache error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCachingInBackground = false;
          _cachingProgress = 0;
          _cachingTotal = 0;
        });
      }
    }
  }

  /// Update native cache with lead data
  Future<void> _updateNativeCache(List<Map<String, dynamic>> leads) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert to simplified format for native side
      final list = leads
          .map((lead) {
        final name = (lead['customer_name'] ?? '').toString().trim();
        final mobile = (lead['mobile'] ?? '').toString().trim();
        final normalized = _normalizePhone10(mobile);

        if (normalized.isEmpty) return null;

        return {
          'name': name.isEmpty ? normalized : name,
          'mobile': mobile,
          'lead_id': lead['id']?.toString() ?? lead['lead_no']?.toString(),
          'status': lead['status_name']?.toString() ?? '',
        };
      })
          .whereType<Map<String, dynamic>>()
          .toList();

      // Save to SharedPreferences
      await prefs.setString('leads_contacts_cache', jsonEncode(list));

      debugPrint('💾💾 Native cache saved: ${list.length} valid leads 💾💾');
      debugPrint('📱 First 3 cached leads:');
      for (int i = 0; i < (list.length < 3 ? list.length : 3); i++) {
        debugPrint('   [$i] ${list[i]['name']} - ${list[i]['mobile']}');
      }
    } catch (e) {
      debugPrint('❌ Failed to update native cache: $e');
    }
  }

  /// Fetch leads for current page (UI display)
  Future<void> _fetchFilteredLeads({int page = 1, bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _filteredLeads.clear();
        _currentPage = 1;
        _totalPages = 1;
        _totalLeads = 0;
        _hasMoreData = true;
        _isLoadingMore = false;
      });
    }

    try {
      debugPrint('=== Fetching Filtered Leads (Page $page for UI) ===');

      final response = await http.post(
        Uri.parse('$baseURL/api/lms/leads.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: {
          'action': 'list_all',
          'api_auth_key': _apiAuthKey,
          'wh_id': _warehouseId,
          'sales_id': _salesId,
          'source_id': widget.sourceId,
          'status_id': widget.statusId,
          'page': page.toString(),
          'per_page': '20',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      debugPrint('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'ok' && jsonData['data'] != null) {
          final List<dynamic> data = jsonData['data'];
          final int currentPageNum = int.tryParse(jsonData['current_page']?.toString() ?? '1') ?? page;
          final int totalPagesNum = int.tryParse(jsonData['total_page']?.toString() ?? '1') ?? 1;
          final int totalLeadsNum = int.tryParse(jsonData['total']?.toString() ?? '0') ?? 0;

          setState(() {
            if (loadMore) {
              _filteredLeads.addAll(data.cast<Map<String, dynamic>>());
            } else {
              _filteredLeads = data.cast<Map<String, dynamic>>();
            }
            _currentPage = currentPageNum;
            _totalPages = totalPagesNum;
            _totalLeads = totalLeadsNum;
            _hasMoreData = _currentPage < _totalPages;
            _isLoading = false;
            _isLoadingMore = false;
          });

          debugPrint('✅ UI Leads loaded: ${_filteredLeads.length} (Page $_currentPage/$_totalPages, Total: $_totalLeads)');

          // 🚀 Start background cache update on first page load
          if (!loadMore && page == 1 && _totalPages > 1) {
            debugPrint('🔄 Starting background cache for all $_totalPages pages...');
            _fetchAllPagesForCache();
          } else if (!loadMore && page == 1 && _totalPages == 1) {
            // Only 1 page, update cache immediately
            await _updateNativeCache(_filteredLeads);
            debugPrint('✅ Single page - Native cache updated');
          }
        } else {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
          debugPrint('⚠️ API returned no data or error status');
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        debugPrint('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching leads: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Load next page for UI
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _currentPage >= _totalPages) return;
    debugPrint('Loading more data - Page ${_currentPage + 1}');
    await _fetchFilteredLeads(page: _currentPage + 1, loadMore: true);
  }

  // ============ HELPERS ============

  Future<void> _ensureNativePermissionsOnce() async {
    try {
      await [
        Permission.contacts,
        Permission.phone,
      ].request();
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  String _normalizePhone10(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  Color _getStatusColor(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'converted':
        return Colors.green;
      case 'onhold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'noreply':
        return Colors.grey;
      case 'spam':
        return Colors.purple;
      case 'lowpriority':
        return Colors.brown;
      default:
        return AppTheme.primaryBrown;
    }
  }

  Future<void> _copyToClipboard(String text, String type) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type copied to clipboard'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not make phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open SMS app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '91${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('91')) {
      cleanNumber = '91$cleanNumber';
    }

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            Icon(icon, size: 20, color: color),
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
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.statusName);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtered Leads', style: AppTheme.headingSmall),
            Text(
              '${widget.sourceName} - ${widget.statusName}',
              style: AppTheme.bodySmall.copyWith(color: statusColor),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (_isCachingInBackground)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    if (_cachingTotal > 0)
                      Text(
                        '$_cachingProgress/$_cachingTotal',
                        style: TextStyle(fontSize: 8, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _forceRefresh,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.warmGradient),
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBrown),
              ),
              SizedBox(height: 16),
              Text('Loading filtered leads...', style: AppTheme.bodyMedium),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _forceRefresh,
          child: Column(
            children: [
              // Filter Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.filter_list, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source: ${widget.sourceName}',
                            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Status: ${widget.statusName}',
                            style: AppTheme.bodySmall.copyWith(color: statusColor),
                          ),
                          if (_isCachingInBackground)
                            Text(
                              '🔄 Caching: $_cachingProgress/$_cachingTotal pages',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _totalLeads > 0
                            ? '$_totalLeads total'
                            : '${_filteredLeads.length} leads',
                        style: AppTheme.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Leads List
              Expanded(
                child: _filteredLeads.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppTheme.primaryBrown.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No leads found',
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.primaryBrown.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'for ${widget.sourceName} - ${widget.statusName}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryBrown.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLeads.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredLeads.length && _isLoadingMore) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Loading more leads...',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    final lead = _filteredLeads[index];
                    final leadNo = lead['lead_no']?.toString() ?? '';
                    final customerName = (lead['customer_name'] ?? '').toString();
                    final mobile = (lead['mobile'] ?? '').toString();
                    final total = (lead['total'] ?? '').toString();
                    final date = (lead['date'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.cardDecoration,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeadDetailScreen(
                                  leadNo: leadNo,
                                  warehouseId: _warehouseId,
                                  salesId: _salesId,
                                  apiAuthKey: _apiAuthKey,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: statusColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName.isNotEmpty
                                                ? customerName
                                                : 'Unknown Customer',
                                            style: AppTheme.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.primaryBrown,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (mobile.isNotEmpty)
                                            Text(
                                              mobile,
                                              style: AppTheme.bodySmall.copyWith(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  date.isNotEmpty ? date : 'No date',
                                                  style: AppTheme.bodySmall.copyWith(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              if (total.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '₹$total',
                                                    style: AppTheme.bodySmall.copyWith(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (leadNo.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '#$leadNo',
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.copy,
                                      label: 'Copy',
                                      color: Colors.grey[600]!,
                                      onTap: () => _copyToClipboard(mobile, 'Phone number'),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.message,
                                      label: 'SMS',
                                      color: Colors.green[600]!,
                                      onTap: () => _sendSMS(mobile),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.chat,
                                      label: 'WhatsApp',
                                      color: Colors.green[700]!,
                                      onTap: () => _openWhatsApp(mobile),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.call,
                                      label: 'Call',
                                      color: Colors.blue[600]!,
                                      onTap: () => _makePhoneCall(mobile),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ DUMMY THEME (Replace with your actual AppTheme) ============
class AppTheme {
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color textSecondary = Color(0xFF666666);

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyLarge = TextStyle(fontSize: 16);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14);
  static const TextStyle bodySmall = TextStyle(fontSize: 12);

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFF8DC), Color(0xFFFFE4B5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}