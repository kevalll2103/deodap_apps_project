// lead_detail_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ===== AppTheme Definition =====
class AppTheme {
  static const primaryBrown = Color(0xFF6D4C41);
  static const warmLight = Color(0xFFFFF8F2);
  static const warmDark = Color(0xFFCCB7A8);
  static const primaryWarm = Color(0xFFFFE6D5);
  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF6F6F6F);
  static const warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBF8), Color(0xFFFFF2E7)],
  );

  static const headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
  static const bodyLarge = TextStyle(fontSize: 16, color: textPrimary);
  static const bodyMedium = TextStyle(fontSize: 14, color: textPrimary);
  static const bodySmall = TextStyle(fontSize: 12, color: textSecondary);

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.black12),
    boxShadow: const [
      BoxShadow(
        color: Color(0x11000000),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  static InputDecoration getInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: primaryBrown) : null,
      filled: true,
      fillColor: warmLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: warmDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: warmDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBrown, width: 1.5),
      ),
    );
  }
}

class LeadDetailScreen extends StatefulWidget {
  final String leadNo;
  final String warehouseId;
  final String salesId;
  final String apiAuthKey;

  const LeadDetailScreen({
    Key? key,
    required this.leadNo,
    required this.warehouseId,
    required this.salesId,
    required this.apiAuthKey,
  }) : super(key: key);

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String baseURL = "https://trackship.in";

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _leadData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Helpers for tolerant JSON parsing (handles HTML/banners/BOM) ---
  dynamic _safeDecode(String body) {
    // Strip BOM if present
    String b = body.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    // If it's wrapped in HTML, try to extract the first JSON object
    if (!b.startsWith('{') && !b.startsWith('[')) {
      final start = b.indexOf('{');
      final end = b.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        b = b.substring(start, end + 1);
      }
    }
    return json.decode(b);
  }

  // ---------- API: Lead Detail ----------
  Future<void> _fetchLeadDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      debugPrint('=== Fetching Lead Details ===');
      debugPrint('Lead No: ${widget.leadNo}');
      debugPrint('Warehouse ID: ${widget.warehouseId}');
      debugPrint('Sales ID: ${widget.salesId}');

      final response = await http
          .post(
        Uri.parse('$baseURL/api/lms/leads.php'),
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json,*/*',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: {
          'action': 'lead_detail',
          'lead_no': widget.leadNo,
          'wh_id': widget.warehouseId,
          'sales_id': widget.salesId,
          'api_auth_key': widget.apiAuthKey,
          // avoid weird caches
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      )
          .timeout(const Duration(seconds: 25));

      debugPrint('Lead detail HTTP: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final raw = response.body;
        debugPrint('Lead detail raw len: ${raw.length}');
        try {
          final jsonData = _safeDecode(raw);
          final status = (jsonData is Map) ? (jsonData['status'] ?? '').toString() : '';
          debugPrint('Lead detail JSON status: $status');

          if (status == 'ok' && jsonData['data'] != null) {
            setState(() {
              _leadData = Map<String, dynamic>.from(jsonData['data']);
              _isLoading = false;
            });
            debugPrint('✅ Lead data loaded');
          } else {
            final errorMsg =
            (jsonData is Map ? (jsonData['errors'] ?? 'Failed to load') : 'Failed to load').toString();
            setState(() {
              _error = errorMsg;
              _isLoading = false;
            });
            debugPrint('❌ API Error: $errorMsg');
          }
        } catch (e) {
          debugPrint('❌ Parse error: $e');
          debugPrint('Body (first 300): ${raw.substring(0, raw.length > 300 ? 300 : raw.length)}');
          setState(() {
            _error = 'Failed to parse response. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'Request timed out. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading lead details. ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ---------- API: Update Status (hardened) ----------
  Future<void> _updateLeadStatus({
    required String statusId,
    String? comment,
    String? reminderDateTime,
    String? reminderNotes,
  }) async {
    try {
      final Map<String, String> body = {
        'action': 'update_status',
        'wh_id': widget.warehouseId,
        'sales_id': widget.salesId,
        'api_auth_key': widget.apiAuthKey,
        'lead_no': widget.leadNo,
        'status_id': statusId,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(), // bust caches
      };

      if ((comment ?? '').trim().isNotEmpty) {
        body['comment'] = comment!.trim();
      }

      // Only send reminder fields if BOTH are available (API rejects partials silently)
      if ((reminderDateTime ?? '').trim().isNotEmpty) {
        body['reminder_date_time'] = reminderDateTime!.trim();
        if ((reminderNotes ?? '').trim().isNotEmpty) {
          body['reminder_notes'] = reminderNotes!.trim();
        }
      }

      debugPrint('=== Update Status POST ===');
      debugPrint('Body: $body');

      final resp = await http
          .post(
        Uri.parse('$baseURL/api/lms/leads.php'),
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json,*/*',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      final responseBody = resp.body.trim();
      debugPrint('Update HTTP: ${resp.statusCode}');
      debugPrint('Update raw len: ${responseBody.length}');
      if (resp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${resp.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      try {
        final data = _safeDecode(responseBody);
        if (data is Map && (data['status']?.toString() == 'ok')) {
          final msg = (data['msg'] ?? 'Lead status updated successfully').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // small wait to allow backend to persist, then refresh
          await Future.delayed(const Duration(milliseconds: 300));
          await _fetchLeadDetails();
        } else {
          final err = (data is Map ? (data['errors'] ?? data['msg'] ?? 'Unknown error') : 'Unknown error').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: $err'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          debugPrint('❌ Update error payload: $data');
        }
      } catch (e) {
        // likely HTML or malformed JSON
        debugPrint('❌ Update parse error: $e');
        debugPrint('Update body (first 300): ${responseBody.substring(0, responseBody.length > 300 ? 300 : responseBody.length)}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error: Invalid response format'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } on http.ClientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _statusIdFromName(String name) {
    final map = {
      'new': '1',
      'converted': '2',
      'onhold': '3',
      'on hold': '3',
      'cancelled': '4',
      'noreply': '5',
      'no reply': '5',
      'spam': '6',
      'exassigned': '7',
      'ex assigned': '7',
      'lowpriority': '8',
      'low priority': '8',
    };
    return map[name.toLowerCase().trim()] ?? '1';
  }

  void _openUpdateStatus() {
    final statusName = (_leadData?['lead_detail']?['status_name'] ?? 'New').toString();
    final currentId = _statusIdFromName(statusName);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _UpdateLeadStatusScreen(
          leadNo: widget.leadNo,
          currentStatus: statusName,
          currentStatusId: currentId,
          onUpdate: (id, c, d, n) {
            _updateLeadStatus(
              statusId: id,
              comment: c,
              reminderDateTime: d,
              reminderNotes: n,
            );
          },
        ),
      ),
    );
  }

  // Call UI Helpers
  IconData _callTypeIcon(String t) {
    final s = t.toLowerCase();
    if (s.contains('out')) return Icons.call_made_rounded;
    if (s.contains('in')) return Icons.call_received_rounded;
    if (s.contains('miss')) return Icons.call_missed_rounded;
    if (s.contains('npc') || s.contains('reject')) return Icons.phone_missed_rounded;
    if (s.contains('block')) return Icons.block;
    return Icons.phone;
  }

  Color _callTypeColor(String t) {
    final s = t.toLowerCase();
    if (s.contains('out')) return Colors.blue;
    if (s.contains('in')) return Colors.green;
    if (s.contains('miss')) return Colors.red;
    if (s.contains('npc') || s.contains('reject')) return Colors.orange;
    if (s.contains('block')) return Colors.grey;
    return AppTheme.primaryBrown;
  }

  String _callTypeLabel(String t) {
    final s = t.toLowerCase();
    if (s.contains('out')) return 'Outgoing';
    if (s.contains('in')) return 'Incoming';
    if (s.contains('miss')) return 'Missed';
    if (s.contains('npc')) return 'Not Picked';
    if (s.contains('reject')) return 'Rejected';
    if (s.contains('block')) return 'Blocked';
    return t;
  }

  Future<void> _copyToClipboard(String text, String label) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _toastErr('Could not make phone call');
      }
    } catch (e) {
      _toastErr('Error making call: ${e.toString()}');
    }
  }

  Future<void> _sendSMS(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'sms', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _toastErr('Could not open SMS app');
      }
    } catch (e) {
      _toastErr('Error opening SMS: ${e.toString()}');
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    if (clean.startsWith('0')) {
      clean = '91${clean.substring(1)}';
    } else if (!clean.startsWith('91') && clean.length == 10) {
      clean = '91$clean';
    }
    final uri = Uri.parse('https://wa.me/$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _toastErr('Could not open WhatsApp');
      }
    } catch (e) {
      _toastErr('Error opening WhatsApp: ${e.toString()}');
    }
  }

  void _toastErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // Reusable UI Components
  Widget _chipAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.15)),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBrown),
        ),
      ),
    );
  }

  Widget _quickActionsRow(String phone) {
    if (phone.trim().isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, cs) {
      final spacing = cs.maxWidth < 360 ? 8.0 : 12.0;
      return Row(
        children: [
          _chipAction(Icons.call, 'Call', () => _makePhoneCall(phone)),
          SizedBox(width: spacing),
          _chipAction(FontAwesomeIcons.whatsapp, 'WhatsApp', () => _openWhatsApp(phone)),
          SizedBox(width: spacing),
          _chipAction(Icons.message, 'SMS', () => _sendSMS(phone)),
        ],
      );
    });
  }

  Widget _deviceBadge(String deviceNo) {
    if (deviceNo.trim().isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _copyToClipboard(deviceNo, 'Device'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBrown.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.devices_other, size: 12, color: Colors.black87),
            SizedBox(width: 4),
            // Text added below in _callTileCompact.
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required Widget child,
    IconData? icon,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor ?? AppTheme.primaryBrown, size: 18),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBrown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool copyable = false}) {
    final v = value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 88, maxWidth: 120),
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    v.isNotEmpty ? v : 'N/A',
                    style: AppTheme.bodyMedium.copyWith(
                      color: v.isNotEmpty ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
                if (copyable && v.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _copyToClipboard(v, label),
                    child: const Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'converted':
        return Colors.green;
      case 'onhold':
      case 'on hold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'noreply':
      case 'no reply':
        return Colors.grey;
      case 'spam':
        return Colors.purple;
      case 'lowpriority':
      case 'low priority':
        return Colors.brown;
      case 'exassigned':
      case 'ex assigned':
        return Colors.teal;
      default:
        return AppTheme.primaryBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final pad = isTablet ? 20.0 : 14.0;

    final leadDetail = _leadData?['lead_detail'] ?? {};
    final clientDetail = _leadData?['client_detail'] ?? {};
    final itemList = (_leadData?['item_list'] as List?) ?? [];
    final callSummary = (_leadData?['call_summary'] as List?) ?? [];
    final callList = (_leadData?['call_list'] as List?) ?? [];

    final tabHeight = math.min(440.0, mq.size.height * (isTablet ? 0.55 : 0.50));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Details', style: AppTheme.headingSmall),
        elevation: 0,
        backgroundColor: AppTheme.primaryWarm,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Update Lead',
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _openUpdateStatus,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchLeadDetails,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.warmGradient),
        child: SafeArea(
          child: _isLoading
              ? const _Loading()
              : _error.isNotEmpty
              ? _ErrorView(
            message: _error,
            onRetry: _fetchLeadDetails,
          )
              : RefreshIndicator(
            onRefresh: _fetchLeadDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lead Card
                  if (leadDetail.isNotEmpty)
                    _infoCard(
                      title: 'Lead Information',
                      icon: Icons.assignment,
                      iconColor: _statusColor(
                        (leadDetail['status_name'] ?? '').toString(),
                      ),
                      child: Column(
                        children: [
                          _detailRow('Lead No', (leadDetail['lead_no'] ?? '').toString(), copyable: true),
                          _detailRow('Warehouse', (leadDetail['warehouse_name'] ?? '').toString()),
                          _detailRow('Sales Person', (leadDetail['sales_person'] ?? '').toString()),
                          _detailRow('Source', (leadDetail['source_name'] ?? '').toString()),
                          _detailRow('Status', (leadDetail['status_name'] ?? '').toString()),
                          _detailRow('Total Amount', '₹${leadDetail['total'] ?? '0'}'),
                          _detailRow('Date', (leadDetail['date'] ?? '').toString()),
                          _detailRow('Lead Tags', (leadDetail['lead_tags'] ?? '').toString()),
                          _detailRow('Reminder At', (leadDetail['reminder_at'] ?? '').toString()),
                          _detailRow('Reminder Notes', (leadDetail['reminder_notes'] ?? '').toString()),
                        ],
                      ),
                    ),

                  // Client Card
                  if (clientDetail.isNotEmpty)
                    _infoCard(
                      title: 'Client Information',
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Name', (clientDetail['name'] ?? '').toString()),
                          _detailRow('Mobile', (clientDetail['mobile'] ?? '').toString(), copyable: true),
                          _detailRow('Address', (clientDetail['address'] ?? '').toString()),
                          Row(
                            children: [
                              Expanded(
                                child: _detailRow('City', (clientDetail['city'] ?? '').toString()),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _detailRow('State', (clientDetail['state'] ?? '').toString()),
                              ),
                            ],
                          ),
                          _detailRow('Pincode', (clientDetail['pincode'] ?? '').toString()),
                          const SizedBox(height: 10),
                          _quickActionsRow((clientDetail['mobile'] ?? '').toString()),
                        ],
                      ),
                    ),

                  // Call Summary
                  if (callSummary.isNotEmpty)
                    _infoCard(
                      title: 'Call Summary',
                      icon: Icons.phone,
                      iconColor: Colors.orange,
                      child: Column(
                        children: [
                          for (final c in callSummary)
                            _compactSummaryTile(
                              type: (c['call_type'] ?? '').toString(),
                              total: (c['total'] ?? '0').toString(),
                              duration: (c['duration'] ?? '0s').toString(),
                            ),
                        ],
                      ),
                    ),

                  // Tabs
                  if (itemList.isNotEmpty || callList.isNotEmpty)
                    Container(
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.warmLight,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: AppTheme.primaryBrown,
                              unselectedLabelColor: AppTheme.textSecondary,
                              indicatorColor: AppTheme.primaryBrown,
                              indicatorWeight: 3,
                              tabs: [
                                Tab(
                                  icon: const Icon(Icons.shopping_cart, size: 18),
                                  text: 'Items (${itemList.length})',
                                ),
                                Tab(
                                  icon: const Icon(Icons.history, size: 18),
                                  text: 'Calls (${callList.length})',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: tabHeight,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Items
                                  itemList.isNotEmpty
                                      ? ListView.separated(
                                    itemCount: itemList.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final item = itemList[i] as Map? ?? {};
                                      return _itemTile(item);
                                    },
                                  )
                                      : const _EmptyTab(
                                      icon: Icons.shopping_cart_outlined, text: 'No items found'),

                                  // Calls
                                  callList.isNotEmpty
                                      ? ListView.separated(
                                    itemCount: callList.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final call = callList[i] as Map? ?? {};
                                      return _callTileCompact(call);
                                    },
                                  )
                                      : const _EmptyTab(
                                      icon: Icons.phone_disabled, text: 'No call history found'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactSummaryTile(
      {required String type, required String total, required String duration}) {
    final color = _callTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warmLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_callTypeIcon(type), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _callTypeLabel(type),
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('Count: $total', style: AppTheme.bodySmall.copyWith(fontSize: 11)),
          const SizedBox(width: 10),
          Text('Dur: $duration', style: AppTheme.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _itemTile(Map item) {
    final sku = (item['sku'] ?? '').toString();
    final weight = (item['weight'] ?? '0').toString();
    final rate = (item['rate'] ?? '0').toString();
    final qty = (item['qty'] ?? '0').toString();
    final total = (item['total'] ?? '0').toString();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warmLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sku,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('Weight: $weight kg', style: AppTheme.bodySmall)),
              Expanded(child: Text('Rate: ₹$rate', style: AppTheme.bodySmall)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text('Qty: $qty', style: AppTheme.bodySmall)),
              Text(
                'Total: ₹$total',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _callTileCompact(Map call) {
    final callType = (call['call_type'] ?? '').toString();
    final deviceNo = (call['device_no'] ?? '').toString();
    final callerName = (call['caller_name'] ?? 'Unknown').toString();
    final callerNo = (call['caller_no'] ?? '').toString();
    final duration = (call['duration'] ?? '0s').toString();
    final date = (call['date'] ?? '').toString();
    final time = (call['time'] ?? '').toString();

    final color = _callTypeColor(callType);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_callTypeIcon(callType), size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_callTypeLabel(callType)} • $duration',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (deviceNo.isNotEmpty)
                InkWell(
                  onTap: () => _copyToClipboard(deviceNo, 'Device'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrown.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.devices_other, size: 12, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text('Device: $deviceNo',
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, size: 11, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppTheme.primaryBrown),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  callerName,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (callerNo.isNotEmpty) ...[
                Text(
                  callerNo,
                  style: AppTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _copyToClipboard(callerNo, 'Phone'),
                  child: const Icon(Icons.copy, size: 14, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$date • $time',
                  style: AppTheme.bodySmall.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _quickActionsRow(callerNo),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBrown)),
            SizedBox(height: 12),
            Text('Loading lead details...', style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Error', style: AppTheme.headingSmall.copyWith(color: Colors.red)),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyTab({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(text, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ===================== UPDATE STATUS SCREEN =====================
class _UpdateLeadStatusScreen extends StatefulWidget {
  final String leadNo;
  final String currentStatus;
  final String currentStatusId;
  final Function(String statusId, String? comment, String? reminderDateTime, String? reminderNotes) onUpdate;

  const _UpdateLeadStatusScreen({
    Key? key,
    required this.leadNo,
    required this.currentStatus,
    required this.currentStatusId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<_UpdateLeadStatusScreen> createState() => _UpdateLeadStatusScreenState();
}

class _UpdateLeadStatusScreenState extends State<_UpdateLeadStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentC = TextEditingController();
  final TextEditingController _reminderNotesC = TextEditingController();

  late String _selectedStatusId;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  bool _isLoading = false;
  bool _enableReminder = false;

  final List<Map<String, dynamic>> _statusOptions = const [
    {'id': '1', 'name': 'New', 'icon': Icons.fiber_new, 'color': Colors.blue},
    {'id': '2', 'name': 'Converted', 'icon': Icons.check_circle, 'color': Colors.green},
    {'id': '3', 'name': 'On Hold', 'icon': Icons.pause_circle, 'color': Colors.orange},
    {'id': '4', 'name': 'Cancelled', 'icon': Icons.cancel, 'color': Colors.red},
    {'id': '5', 'name': 'No Reply', 'icon': Icons.no_accounts, 'color': Colors.grey},
    {'id': '6', 'name': 'Spam', 'icon': Icons.report, 'color': Colors.purple},
    {'id': '7', 'name': 'Ex Assigned', 'icon': Icons.assignment_ind, 'color': Colors.teal},
    {'id': '8', 'name': 'Low Priority', 'icon': Icons.low_priority, 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatusId = widget.currentStatusId;
  }

  @override
  void dispose() {
    _commentC.dispose();
    _reminderNotesC.dispose();
    super.dispose();
  }

  Color _statusColor() {
    final s = _statusOptions.firstWhere(
          (e) => e['id'] == _selectedStatusId,
      orElse: () => _statusOptions.first,
    );
    return (s['color'] as Color);
  }

  String _statusName() {
    final s = _statusOptions.firstWhere(
          (e) => e['id'] == _selectedStatusId,
      orElse: () => _statusOptions.first,
    );
    return (s['name'] as String);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _reminderDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _submit() {
    setState(() => _isLoading = true);

    String? reminderDT;
    if (_enableReminder && _reminderDate != null && _reminderTime != null) {
      final dt = DateTime(
        _reminderDate!.year,
        _reminderDate!.month,
        _reminderDate!.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
      reminderDT =
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
    }

    Navigator.of(context).pop();
    widget.onUpdate(
      _selectedStatusId,
      _commentC.text.trim().isEmpty ? null : _commentC.text.trim(),
      reminderDT, // only sent if both date & time chosen
      _enableReminder && _reminderNotesC.text.trim().isNotEmpty ? _reminderNotesC.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final pad = isTablet ? 22.0 : 14.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Lead Status', style: AppTheme.headingSmall),
        elevation: 0,
        backgroundColor: AppTheme.primaryWarm,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: Text('UPDATE', style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.warmGradient),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.assignment, color: AppTheme.primaryBrown, size: 18),
                        const SizedBox(width: 8),
                        Text('Lead #${widget.leadNo}',
                            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text('Current Status: ', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.currentStatus,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.primaryBrown,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.swap_horiz, color: AppTheme.primaryBrown, size: 18),
                        const SizedBox(width: 8),
                        Text('Select New Status', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedStatusId,
                        decoration: AppTheme.getInputDecoration('Select Status', icon: Icons.flag),
                        items: _statusOptions
                            .map(
                              (s) => DropdownMenuItem(
                            value: s['id'] as String,
                            child: Row(
                              children: [
                                Icon(s['icon'] as IconData, size: 18, color: s['color'] as Color),
                                const SizedBox(width: 10),
                                Text(s['name'] as String, style: AppTheme.bodyMedium),
                              ],
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedStatusId = v ?? _selectedStatusId),
                        dropdownColor: AppTheme.warmLight,
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.comment, color: AppTheme.primaryBrown, size: 18),
                        const SizedBox(width: 8),
                        Text('Comment (Optional)', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _commentC,
                        decoration: AppTheme.getInputDecoration(
                          'Enter your comment about this status change...',
                          icon: Icons.edit,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.alarm, color: AppTheme.primaryBrown, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Set Reminder (Optional)',
                              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Switch(
                          value: _enableReminder,
                          onChanged: (v) {
                            setState(() {
                              _enableReminder = v;
                              if (!v) {
                                _reminderDate = null;
                                _reminderTime = null;
                                _reminderNotesC.clear();
                              }
                            });
                          },
                          activeColor: _statusColor(),
                        ),
                      ]),
                      if (_enableReminder) ...[
                        const SizedBox(height: 10),
                        isTablet
                            ? Row(
                          children: [
                            Expanded(child: _dateBox(onTap: _pickDate, date: _reminderDate)),
                            const SizedBox(width: 10),
                            Expanded(child: _timeBox(onTap: _pickTime, time: _reminderTime, context: context)),
                          ],
                        )
                            : Column(
                          children: [
                            _dateBox(onTap: _pickDate, date: _reminderDate),
                            const SizedBox(height: 10),
                            _timeBox(onTap: _pickTime, time: _reminderTime, context: context),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _reminderNotesC,
                          decoration: AppTheme.getInputDecoration('Enter reminder notes...', icon: Icons.note),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text('Update to ${_statusName()}',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBox({required VoidCallback onTap, required DateTime? date}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.warmLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warmDark),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryBrown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : 'Select Date',
                style: AppTheme.bodyMedium.copyWith(
                  color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox({
    required VoidCallback onTap,
    required TimeOfDay? time,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.warmLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warmDark),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppTheme.primaryBrown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time != null ? time.format(context) : 'Select Time',
                style: AppTheme.bodyMedium.copyWith(
                  color: time != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
