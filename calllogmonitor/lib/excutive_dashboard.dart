import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'follow_up.dart';

class ExecutiveDashboard extends StatefulWidget {
  @override
  _ExecutiveDashboardState createState() => _ExecutiveDashboardState();
}

class _ExecutiveDashboardState extends State<ExecutiveDashboard> {
  bool _isLoading = true;
  String _executiveUsername = '';
  String _executiveName = '';
  String _warehouseId = '';
  String _warehouseLabel = '';
  String _salesId = '';
  String _apiAuthKey = '';

  List<Map<String, dynamic>> _leadsData = [];
  Map<String, int> _totalsByStatus = {};
  int _grandTotal = 0;

  static const String baseURL = "https://trackship.in";

  // Warm color scheme
  static const Color primaryWarm = Color(0xFFFCF7EF); // #FCF7EF - Main background
  static const Color warmAccent = Color(0xFFF5E6D3); // Slightly darker warm tone
  static const Color warmDark = Color(0xFFE8D5C4); // Darker warm for borders
  static const Color warmLight = Color(0xFFFEFBF7); // Lighter warm for cards

  // Complementary colors
  static const Color primaryBrown = Color(0xFF8B6F47); // Warm brown for text
  static const Color accentBrown = Color(0xFFA0845C); // Lighter brown
  static const Color darkBrown = Color(0xFF6B5139); // Dark brown for emphasis

  // Status colors with warm tones
  static const Color successWarm = Color(0xFF7D8471); // Warm green
  static const Color warningWarm = Color(0xFFD4A574); // Warm orange
  static const Color errorWarm = Color(0xFFB85450); // Warm red
  static const Color infoWarm = Color(0xFF6B8CAE); // Warm blue

  // Neutral colors
  static const Color textPrimary = Color(0xFF3C2E26); // Dark brown text
  static const Color textSecondary = Color(0xFF6B5139); // Medium brown text
  static const Color textTertiary = Color(0xFF8B6F47); // Light brown text
  static const Color dividerColor = Color(0xFFE8D5C4);

  @override
  void initState() {
    super.initState();
    _loadExecutiveData();
  }

  Future<void> _loadExecutiveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Get executive data from SharedPreferences
    _executiveUsername = prefs.getString('executive_username') ?? '';
    _executiveName = prefs.getString('executive_name') ?? '';
    _warehouseId = prefs.getString('executive_warehouse_id') ?? '';
    _warehouseLabel = prefs.getString('executive_warehouse_label') ?? '';
    _salesId = prefs.getInt('executive_id')?.toString() ?? '';
    _apiAuthKey = prefs.getString('executive_auth_key') ?? '';

    // Store sales_id and wh_id in SharedPreferences if they exist
    if (_salesId.isNotEmpty) {
      await prefs.setString('sales_id', _salesId);
    }
    if (_warehouseId.isNotEmpty) {
      await prefs.setString('wh_id', _warehouseId);
    }

    setState(() {
      // Update the UI with the loaded data
    });

    await _fetchLeadsData();
  }

  Future<void> _forceRefresh() async {
    setState(() {
      _isLoading = true;
      _leadsData.clear();
      _totalsByStatus.clear();
      _grandTotal = 0;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    await _fetchLeadsData();
  }

  Future<void> _fetchLeadsData() async {
    try {
      setState(() {
        _leadsData.clear();
        _totalsByStatus.clear();
        _grandTotal = 0;
      });

      final response = await http.post(
        Uri.parse('$baseURL/api/lms/leads.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: {
          'action': 'executive_dashboard',
          'wh_id': _warehouseId,
          'sales_id': _salesId,
          'api_auth_key': _apiAuthKey,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'ok' && jsonData['data'] != null) {
          final List<dynamic> data = jsonData['data'];

          setState(() {
            _leadsData = data.cast<Map<String, dynamic>>();
            _calculateTotals();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    _totalsByStatus.clear();
    _grandTotal = 0;

    for (var source in _leadsData) {
      final List<dynamic> statusList = source['status_list'] ?? [];

      for (var status in statusList) {
        final String statusName = status['status_name'] ?? '';
        final int totalLeads = int.tryParse(status['total_leads'].toString()) ?? 0;

        _totalsByStatus[statusName] = (_totalsByStatus[statusName] ?? 0) + totalLeads;
        _grandTotal += totalLeads;
      }
    }
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
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'converted':
        return Icons.check_circle_rounded;
      case 'onhold':
        return Icons.pause_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'noreply':
        return Icons.person_off_rounded;
      case 'spam':
        return Icons.report_rounded;
      case 'lowpriority':
        return Icons.low_priority_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('is_executive_logged_in');
    await prefs.remove('executive_id');
    await prefs.remove('executive_username');
    await prefs.remove('executive_name');
    await prefs.remove('executive_warehouse_id');
    await prefs.remove('executive_warehouse_label');
    await prefs.remove('executive_auth_key');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Executive logged out successfully'),
          ],
        ),
        backgroundColor: successWarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildStatusChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          height: 70, // Increased height to match width
          width: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryWarm,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: warmLight,
        foregroundColor: textPrimary,
        title: Text(
          'Executive Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: textPrimary,
          ),
        ),
        actions: [
          // Follow Up Button
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FollowUpScreen()),
                );
              },
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text(''),
              style: ElevatedButton.styleFrom(
                backgroundColor: warningWarm,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          // Refresh Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: _isLoading ? textTertiary : primaryBrown,
              ),
              onPressed: _isLoading ? null : _forceRefresh,
              style: IconButton.styleFrom(
                backgroundColor: warmAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              icon: Icon(Icons.more_vert_rounded, color: textPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: errorWarm, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(primaryBrown),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading dashboard data...',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _forceRefresh,
        color: primaryBrown,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Executive Info Card with Warm Colors
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBrown, darkBrown],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _executiveName.isNotEmpty ? _executiveName : _executiveUsername,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Warehouse: $_warehouseLabel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Enhanced Total Leads Card with Warm Colors
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [successWarm, successWarm.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: successWarm.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Leads',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _grandTotal.toString(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryBrown,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Leads by Source',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Sources List
            ..._leadsData.map((source) {
              final sourceName = source['source_name'] ?? '';
              final statusList = source['status_list'] as List<dynamic>? ?? [];

              // Calculate total for this source
              int sourceTotal = 0;
              for (var status in statusList) {
                sourceTotal += int.tryParse(status['total_leads'].toString()) ?? 0;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: warmLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: warmDark,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBrown.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: warmAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.business_center_rounded,
                            color: primaryBrown,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sourceName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: successWarm.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Total: $sourceTotal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: successWarm,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status List - Single Row with Horizontal Scroll
                    SizedBox(
                      height: 70, // Increased height to accommodate taller buttons
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: statusList.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = statusList[index];
                          final statusName = status['status_name'] ?? '';
                          final totalLeads = int.tryParse(status['total_leads'].toString()) ?? 0;

                          return _buildStatusChip(
                            label: statusName,
                            count: totalLeads,
                            color: _getStatusColor(statusName),
                            icon: _getStatusIcon(statusName),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/filtered_leads',
                                arguments: {
                                  'sourceId': source['source_id']?.toString() ?? '',
                                  'sourceName': source['source_name'] ?? '',
                                  'statusId': status['status_id']?.toString() ?? '',
                                  'statusName': statusName,
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Add some bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}