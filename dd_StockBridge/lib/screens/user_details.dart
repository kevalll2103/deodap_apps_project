// lib/employees_list_screen.dart
// iOS-styled employee list with search, filters, paging, and pull-to-refresh.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'picked_order_userwise.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});
  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  // ====== CONFIG ======
  static const String _base = 'https://customprint.deodap.com/stockbridge';
  static const String _endpoint = '$_base/emp_details.php';
  static const int _pageSize = 50;

  // ====== STATE ======
  final List<Employee> _items = [];
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool _fetchingMore = false;
  bool _initialLoaded = false;

  String _q = '';
  int? _activeFilter; // null=All, 1=Active, 0=Inactive

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _attachScroll();
    _refresh(); // initial
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ====== MODEL ======
  static Employee fromJson(Map<String, dynamic> j) => Employee(
        id: _asInt(j['id']),
        empCode: (j['emp_code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        contactNumber: (j['contact_number'] ?? '').toString(),
        isActive: _asInt(j['is_active']) == 1,
        lastLoginIp: (j['last_login_ip'] ?? '').toString(),
        lastLoginTime: (j['last_login_time'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
        updatedAt: (j['updated_at'] ?? '').toString(),
      );

  // ====== HELPERS ======
  static int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  void _attachScroll() {
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 120 &&
          !_fetchingMore &&
          !_loading &&
          _page < _totalPages) {
        _loadMore();
      }
    });
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _refresh() async {
    _debounce?.cancel();
    setState(() {
      _loading = true;
      _page = 1;
      _total = 0;
      _totalPages = 1;
      _items.clear();
    });
    await _fetchPage(page: 1, replace: true);
    if (mounted) {
      setState(() {
        _loading = false;
        _initialLoaded = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_page >= _totalPages) return;
    setState(() => _fetchingMore = true);
    final next = _page + 1;
    await _fetchPage(page: next, replace: false);
    if (mounted) setState(() => _fetchingMore = false);
  }

  Future<void> _fetchPage({required int page, required bool replace}) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _showError('Missing session token — please login again.');
        return;
      }

      final qp = {
        'page': page.toString(),
        'per_page': _pageSize.toString(),
        if (_q.trim().isNotEmpty) 'q': _q.trim(),
        if (_activeFilter != null) 'active': _activeFilter.toString(),
      };

      final uri = Uri.parse(_endpoint).replace(queryParameters: qp);
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final obj = jsonDecode(res.body);
      if (res.statusCode != 200 || obj is! Map || obj['success'] != true) {
        final msg = (obj is Map ? obj['message'] : null)?.toString() ??
            'Server error (${res.statusCode}).';
        _showError(msg);
        return;
      }

      final data = List<Map<String, dynamic>>.from(obj['data'] as List);
      final models = data.map(fromJson).toList();

      if (replace) _items.clear();
      _items.addAll(models);

      _page = _asInt(obj['page']);
      _total = _asInt(obj['total']);
      _totalPages = _asInt(obj['total_pages']);
      if (mounted) setState(() {});
    } catch (_) {
      _showError('Network error. Please try again.');
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            msg,
            style: GoogleFonts.inter(
              decoration: TextDecoration.none,
              fontSize: 15,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
          )
        ],
      ),
    );
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _q = v;
      _refresh();
    });
  }

  void _setFilter(int? value) {
    if (_activeFilter == value) return;
    setState(() => _activeFilter = value);
    _refresh();
  }

  void _openEmpOrders(Employee emp) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => EmployeePickedOrdersScreen(employee: emp, userId: '',),
      ),
    );
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Employees',
          style: GoogleFonts.inter(
            color: CupertinoColors.label.resolveFrom(context),
            fontWeight: FontWeight.w600,
            fontSize: 17,
            decoration: TextDecoration.none,
          ),
        ),
        backgroundColor: CupertinoColors.white,
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
      ),
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // Pull to refresh
          CupertinoSliverRefreshControl(onRefresh: _refresh),

          SliverToBoxAdapter(child: _buildToolbar()),
          if (_initialLoaded) ...[
            if (_items.isEmpty && !_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No employees found',
                      style: GoogleFonts.inter(
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            SliverList.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) => _EmployeeTile(
                emp: _items[i],
                onTap: () => _openEmpOrders(_items[i]),
              ),
            ),
            SliverToBoxAdapter(child: _buildFooter()),
          ] else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Search
          CupertinoSearchTextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            placeholder: 'Search name / code / email / phone',
          ),
          const SizedBox(height: 10),

          // Filters + Count
          Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _activeFilter == null,
                onTap: () => _setFilter(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Active',
                selected: _activeFilter == 1,
                onTap: () => _setFilter(1),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Inactive',
                selected: _activeFilter == 0,
                onTap: () => _setFilter(0),
              ),
              const Spacer(),
              if (_initialLoaded)
                Text(
                  '$_total',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_fetchingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_page >= _totalPages && _items.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ====== MODELS & TILES ======

class Employee {
  final int id;
  final String empCode;
  final String name;
  final String email;
  final String username;
  final String contactNumber;
  final bool isActive;
  final String lastLoginIp;
  final String lastLoginTime;
  final String createdAt;
  final String updatedAt;

  Employee({
    required this.id,
    required this.empCode,
    required this.name,
    required this.email,
    required this.username,
    required this.contactNumber,
    required this.isActive,
    required this.lastLoginIp,
    required this.lastLoginTime,
    required this.createdAt,
    required this.updatedAt,
  });
}

class _EmployeeTile extends StatelessWidget {
  final Employee emp;
  final VoidCallback onTap;
  const _EmployeeTile({
    required this.emp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub =
        '${emp.email.isNotEmpty ? emp.email : emp.username} • ${emp.contactNumber}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 0.7,
          ),
        ),
        child: Row(
          children: [
            _Avatar(initials: _initials(emp.name)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${emp.name}  •  ${emp.empCode}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: CupertinoColors.label.resolveFrom(context),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.inter(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusPill(active: emp.isActive),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          emp.lastLoginTime.isNotEmpty
                              ? 'Last login: ${emp.lastLoginTime}'
                              : 'Never logged in',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      return s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: CupertinoColors.systemBlue,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});
  @override
  Widget build(BuildContext context) {
    final bgColor = active
        ? CupertinoColors.systemGreen.withOpacity(0.12)
        : CupertinoColors.systemRed.withOpacity(0.12);
    final fgColor =
        active ? CupertinoColors.systemGreen : CupertinoColors.systemRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fgColor,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? CupertinoColors.systemBlue.withOpacity(0.1)
        : CupertinoColors.systemGrey5.resolveFrom(context);
    final fg = selected
        ? CupertinoColors.systemBlue
        : CupertinoColors.label.resolveFrom(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
