import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lead_detail_screen.dart';

// ===== Warm theme =====
const Color _primaryWarm = Color(0xFFFCF7EF);
const Color _warmDark = Color(0xFFE8D5C4);
const Color _primaryBrown = Color(0xFF8B6F47);
const Color _textPrimary = Color(0xFF3C2E26);
const Color _textSecondary = Color(0xFF6B5139);
const Color _textTertiary = Color(0xFF8B6F47);
const Color _warningWarm = Color(0xFFD4A574);
const Color _errorWarm = Color(0xFFB85450);
const Color _successWarm = Color(0xFF7FA650);

class FollowUpLead {
  final String leadNo;
  final String remindNotes;
  final String remindTime;

  const FollowUpLead({
    required this.leadNo,
    required this.remindNotes,
    required this.remindTime,
  });

  factory FollowUpLead.fromJson(Map<String, dynamic> json) {
    return FollowUpLead(
      leadNo: (json['lead_no'] ?? '').toString(),
      remindNotes: (json['remind_notes'] ?? '').toString(),
      remindTime: (json['remind_time'] ?? '').toString(),
    );
  }
}

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({Key? key}) : super(key: key);

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final List<FollowUpLead> _leads = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  int _currentPage = 1;
  int _totalPages = 1;

  late String _salesId;
  late String _whId;
  late String _apiAuthKey;

  // Date filters
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _salesId = prefs.getString('sales_id') ?? '';
    _whId = prefs.getString('wh_id') ?? '';
    _apiAuthKey = prefs.getString('executive_auth_key') ?? '';

    if (_salesId.isEmpty || _whId.isEmpty) {
      setState(() {
        _errorMessage =
        'Missing required IDs. Please ensure sales_id and wh_id are saved in SharedPreferences.';
        _isLoadingFirstPage = false;
      });
      return;
    }

    await _reloadFirstPage();
  }

  Future<void> _reloadFirstPage() async {
    setState(() {
      _leads.clear();
      _currentPage = 1;
      _totalPages = 1;
      _errorMessage = '';
      _isLoadingFirstPage = true;
    });
    await _fetchFollowUpLeads(page: 1, append: false);
    if (mounted) {
      setState(() {
        _isLoadingFirstPage = false;
      });
    }
  }

  Future<void> _fetchFollowUpLeads({required int page, required bool append}) async {
    try {
      final url = Uri.parse('https://trackship.in/api/lms/leads.php');

      final body = {
        'action': 'follow_up',
        'wh_id': _whId,
        'sales_id': _salesId,
        'page': '$page',
      };

      // Add date filters if set
      if (_fromDate != null) {
        body['from_date'] = _formatDate(_fromDate!);
      }
      if (_toDate != null) {
        body['to_date'] = _formatDate(_toDate!);
      }

      final response = await http
          .post(url, body: body)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out after 30 seconds');
      });

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final apiErrors = (decoded['errors'] ?? '').toString().trim();
      final status = (decoded['status'] ?? '').toString().toLowerCase();

      if (apiErrors.isNotEmpty) {
        throw Exception(apiErrors);
      }
      if (status != 'ok' && status != 'true' && status != 'success') {
        final message = (decoded['message'] ?? 'API returned status=$status').toString();
        throw Exception(message);
      }

      final int current = _asInt(decoded['current_page']) ?? page;
      final int total = _asInt(decoded['total_page']) ?? current;

      final List<dynamic> list = (decoded['data'] as List?) ?? const [];
      List<FollowUpLead> parsed = list.map((e) => FollowUpLead.fromJson(e as Map<String, dynamic>)).toList();

      // Sort in descending order by remind_time (newest first)
      parsed.sort((a, b) {
        if (a.remindTime.isEmpty && b.remindTime.isEmpty) return 0;
        if (a.remindTime.isEmpty) return 1;
        if (b.remindTime.isEmpty) return -1;
        return b.remindTime.compareTo(a.remindTime);
      });

      if (!mounted) return;

      setState(() {
        _currentPage = current;
        _totalPages = total;
        if (append) {
          _leads.addAll(parsed);
        } else {
          _leads
            ..clear()
            ..addAll(parsed);
        }
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading follow-up leads: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isLoadingFirstPage = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  void _onScroll() {
    if (_isLoadingMore || _isLoadingFirstPage || _errorMessage.isNotEmpty) return;
    if (_currentPage >= _totalPages) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final threshold = 200;
    if (position.maxScrollExtent - position.pixels <= threshold) {
      setState(() => _isLoadingMore = true);
      final next = _currentPage + 1;
      _fetchFollowUpLeads(page: next, append: true);
    }
  }

  Future<void> _onRefresh() async {
    await _reloadFirstPage();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryBrown,
              onPrimary: Colors.white,
              surface: _primaryWarm,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryBrown,
              onPrimary: Colors.white,
              surface: _primaryWarm,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _reloadFirstPage();
  }

  void _applyFilters() {
    _reloadFirstPage();
    setState(() {
      _showFilters = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryWarm,
      appBar: AppBar(
        backgroundColor: _primaryWarm,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text(
          'Follow Up Leads',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: _textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: (_fromDate != null || _toDate != null) ? _primaryBrown : _textTertiary,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoadingFirstPage ? null : _reloadFirstPage,
            color: _isLoadingFirstPage ? _textTertiary : _primaryBrown,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          if (_fromDate != null || _toDate != null) _buildActiveFiltersChip(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _warmDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _warmDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, color: _primaryBrown, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filter by Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'From Date',
                  date: _fromDate,
                  onTap: _selectFromDate,
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'To Date',
                  date: _toDate,
                  onTap: _selectToDate,
                  icon: Icons.event,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _errorWarm,
                    side: BorderSide(color: _errorWarm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBrown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primaryWarm,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _warmDark, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: _textTertiary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDate(date) : 'Select date',
              style: TextStyle(
                fontSize: 14,
                color: date != null ? _textPrimary : _textSecondary,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryBrown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryBrown.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, size: 16, color: _primaryBrown),
          const SizedBox(width: 6),
          Text(
            'Filtered: ${_fromDate != null ? _formatDate(_fromDate!) : 'All'} to ${_toDate != null ? _formatDate(_toDate!) : 'All'}',
            style: TextStyle(
              fontSize: 12,
              color: _primaryBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _clearFilters,
            child: Icon(Icons.close, size: 16, color: _primaryBrown),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingFirstPage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryBrown),
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            const Text(
              'Loading follow-up leads...',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _errorWarm.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: _errorWarm, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _reloadFirstPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBrown,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: _textTertiary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No follow-up leads found',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_fromDate != null || _toDate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(foregroundColor: _primaryBrown),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: _primaryBrown,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _leads.length + 1,
        itemBuilder: (context, index) {
          if (index == _leads.length) {
            if (_currentPage < _totalPages) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingMore)
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryBrown),
                        ),
                      ),
                    if (_isLoadingMore) const SizedBox(width: 12),
                    Text(
                      _isLoadingMore ? 'Loading more...' : 'Page $_currentPage of $_totalPages',
                      style: const TextStyle(color: _textSecondary),
                    ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'End of list — ${_leads.length} lead${_leads.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                ),
              );
            }
          }

          final lead = _leads[index];
          return _buildLeadCard(lead, index);
        },
      ),
    );
  }

  Widget _buildLeadCard(FollowUpLead lead, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: _warmDark.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _warmDark.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeadDetailScreen(
                leadNo: lead.leadNo,
                warehouseId: _whId,
                salesId: _salesId,
                apiAuthKey: _apiAuthKey,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lead #${lead.leadNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _primaryBrown,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: _textTertiary),
                ],
              ),
              if (lead.remindNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryWarm,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _warmDark.withOpacity(0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_outlined, size: 18, color: _textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lead.remindNotes,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _warningWarm.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 16, color: _warningWarm),
                    const SizedBox(width: 6),
                    Text(
                      lead.remindTime.isEmpty ? 'No reminder set' : lead.remindTime,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _warningWarm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}