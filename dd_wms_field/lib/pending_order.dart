// lib/pending_order.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, RefreshIndicator;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'qr_scanner.dart';

// Brand color (replaces any systemBlue usage)
const Color kIOSBlue = Color(0xFF007E9B);

class PendingOrdersScreen extends StatefulWidget {
  final int warehouseId;
  final String warehouseLabel;

  const PendingOrdersScreen({
    Key? key,
    required this.warehouseId,
    required this.warehouseLabel,
  }) : super(key: key);

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  // APIs
  static const String _listApi =
      'https://api.vacalvers.com/api-wms-field-app/club_orders/pending_pickup_orders_list';
  static const String _markLateApi =
      'https://api.vacalvers.com/api-wms-field-app/club_orders/mark_all_late_as_delayed';
  static const int _appId = 1;
  static const String _apiKey = 'd5e61e52-fd9d-4ac9-a953-fde5fe5f6e5e';

  // paging
  static const int _perPage = 100;
  final List<String> _keys = const ['recent', 'late', 'delayed'];
  int _tabIndex = 0; // 0: recent, 1: late, 2: delayed
  String get _tab => _keys[_tabIndex];

  // data
  final Map<String, List<Map<String, dynamic>>> _lists = {
    'recent': [],
    'late': [],
    'delayed': [],
  };
  final Map<String, int> _page = {'recent': 1, 'late': 1, 'delayed': 1};
  final Map<String, bool> _hasNext = {'recent': false, 'late': false, 'delayed': false};

  String? _token;
  bool _loading = true;
  bool _loadingMore = false;
  bool _marking = false;
  String? _error;
  String _search = '';

  // scanned count (per warehouse)
  int _scanCount = 0;
  String get _scanKey => 'scan_count_${widget.warehouseId}';

  final ScrollController _scroll = ScrollController();
  final PageController _pageCtrl = PageController();

  static const double _bottomActionHeight = 64;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _bootstrap();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ---------- Google Fonts helpers ----------
  TextStyle g14w6([Color? c]) => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: c, decoration: TextDecoration.none);
  TextStyle g18w7([Color? c]) => GoogleFonts.inter(
      fontSize: 18, fontWeight: FontWeight.w700, color: c, decoration: TextDecoration.none);
  TextStyle g12([Color? c]) => GoogleFonts.inter(fontSize: 12, color: c, decoration: TextDecoration.none);
  TextStyle g13([Color? c]) => GoogleFonts.inter(fontSize: 13, color: c, decoration: TextDecoration.none);
  TextStyle g11([Color? c]) => GoogleFonts.inter(fontSize: 11, color: c, decoration: TextDecoration.none);
  TextStyle g10([Color? c]) => GoogleFonts.inter(fontSize: 10, color: c, decoration: TextDecoration.none);
  TextStyle g16w7([Color? c]) => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w700, color: c, decoration: TextDecoration.none);

  Future<void> _bootstrap() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('authToken');
    _scanCount = p.getInt(_scanKey) ?? 0;
    if (mounted) setState(() {});
    await _fetch(reset: true);
  }

  // ===== fetch list with real pagination (GET + JSON body) =====
  Future<void> _fetch({required bool reset}) async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing auth token. Please login again.';
      });
      return;
    }

    final type = _tab;
    final nextPage = reset ? 1 : (_page[type]! + 1);

    setState(() {
      if (reset) _loading = true;
      _error = null;
    });

    try {
      // Build a GET request with JSON body (matches your Postman setup)
      final req = http.Request('GET', Uri.parse(_listApi))
        ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
        ..headers[HttpHeaders.acceptHeader] = 'application/json'
        ..body = jsonEncode({
          'app_id': _appId, // numbers are fine
          'api_key': _apiKey,
          'token': _token,
          'filter_warehouse_id': '${widget.warehouseId}',
          'filter_list_type': type, // 'recent' | 'late' | 'delayed'
          'paging_items_per_page': '$_perPage', // keep as string to match server
          'paging_current_page': '$nextPage',   // keep as string to match server
        });

      final client = http.Client();
      final streamed = await client.send(req).timeout(const Duration(seconds: 25));
      final resp = await http.Response.fromStream(streamed);
      client.close();

      if (resp.statusCode != 200) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = 'Server responded with ${resp.statusCode}.';
        });
        return;
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic> || decoded['status_flag'] != 1) {
        final msg = (decoded is Map &&
            decoded['status_messages'] is List &&
            (decoded['status_messages'] as List).isNotEmpty)
            ? (decoded['status_messages'] as List).join('\n')
            : 'API error.';
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = msg;
        });
        return;
      }

      final List<dynamic> raw = (decoded['data'] is List) ? decoded['data'] as List : [];
      final List<Map<String, dynamic>> newItems =
      raw.map((e) => (e is Map<String, dynamic>) ? e : <String, dynamic>{}).toList();

      // hasNext: prefer server flag; otherwise infer by page size
      bool hasNext = false;
      final md = decoded['meta_data'];
      if (md is Map && md['paging'] is Map) {
        final Map paging = md['paging'] as Map;
        hasNext = paging['has_next_page'] == true ||
            paging['hasNext'] == true ||
            paging['has_more'] == true;
      }
      hasNext = hasNext || (newItems.length == _perPage);

      // Merge & de-dupe by order_no
      final current = reset ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(_lists[type]!);
      final seen = <String>{for (final m in current) (m['order_no'] ?? '').toString()};
      for (final m in newItems) {
        final k = (m['order_no'] ?? '').toString();
        if (k.isEmpty || seen.contains(k)) continue;
        seen.add(k);
        current.add(m);
      }

      if (!mounted) return;
      setState(() {
        _lists[type] = current;
        _page[type] = nextPage;
        _hasNext[type] = hasNext;
        _loading = false;
        _loadingMore = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Request timed out.';
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'No internet connection.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Error: $e';
      });
    }
  }

  // ===== action: mark late → delayed (GET + JSON body) =====
  Future<void> _markAllLateAsDelayed() async {
    if (_token == null || _token!.isEmpty || _marking) return;

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Move all LATE to DELAYED?', style: g16w7()),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('This affects all LATE orders for this warehouse.',
              style: g13(CupertinoColors.secondaryLabel)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: g14w6(kIOSBlue)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text('Proceed', style: g14w6(CupertinoColors.destructiveRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _marking = true);
    try {
      final req = http.Request('GET', Uri.parse(_markLateApi))
        ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
        ..headers[HttpHeaders.acceptHeader] = 'application/json'
        ..body = jsonEncode({
          'app_id': _appId,
          'api_key': _apiKey,
          'token': _token,
          'filter_warehouse_id': '${widget.warehouseId}',
        });

      final client = http.Client();
      final streamed = await client.send(req).timeout(const Duration(seconds: 25));
      final resp = await http.Response.fromStream(streamed);
      client.close();

      final ok = resp.statusCode == 200;
      final decoded = ok ? jsonDecode(resp.body) : null;
      final success = ok && decoded is Map && decoded['status_flag'] == 1;
      final msg = (decoded is Map &&
          decoded['status_messages'] is List &&
          (decoded['status_messages'] as List).isNotEmpty)
          ? (decoded['status_messages'] as List).join('\n')
          : (success ? 'All LATE orders moved to DELAYED.' : 'Failed.');

      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(success ? 'Success' : 'Error', style: g16w7()),
          content: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(msg, style: g13(CupertinoColors.secondaryLabel)),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: g14w6(kIOSBlue)),
            ),
          ],
        ),
      );

      if (success) {
        await _fetch(reset: true);
        final keep = _tabIndex;
        setState(() => _tabIndex = 2);
        await _fetch(reset: true);
        if (mounted) setState(() => _tabIndex = keep);
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  // ===== NEW: Aggregate counts across ALL tabs =====
  ({int total, int verified, int newly}) _aggregateCounts() {
    int total = 0;
    int verified = 0;
    int newly = 0;

    for (final key in _keys) {
      final list = _lists[key] ?? const <Map<String, dynamic>>[];
      total += list.length;
      for (final e in list) {
        final s = (e['status'] ?? '').toString().toLowerCase();
        if (s == 'verified') verified++;
        if (s == 'new') newly++;
      }
    }
    return (total: total, verified: verified, newly: newly);
  }

  Future<void> _openAllCountsSheet() async {
    final agg = _aggregateCounts();

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('All Tabs — Combined Counts', style: g16w7()),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _CountRow(label: 'Total', value: '${agg.total}', color: kIOSBlue, g13: g13, g14w6: g14w6),
            const SizedBox(height: 6),
            _CountRow(
                label: 'Verified',
                value: '${agg.verified}',
                color: CupertinoColors.systemGreen,
                g13: g13,
                g14w6: g14w6),
            const SizedBox(height: 6),
            _CountRow(
                label: 'New',
                value: '${agg.newly}',
                color: CupertinoColors.systemOrange,
                g13: g13,
                g14w6: g14w6),
          ],
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: Text('Close', style: g14w6(kIOSBlue)),
        ),
      ),
    );
  }

  // helpers
  void _maybeLoadMore() {
    final hasNext = _hasNext[_tab] ?? false;
    if (_loading || _loadingMore || !hasNext) return;

    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      setState(() => _loadingMore = true);
      _fetch(reset: false);
    }
  }

  List<Map<String, dynamic>> get _visible {
    final list = _lists[_tab] ?? const <Map<String, dynamic>>[];
    if (_search.trim().isEmpty) return list;
    final q = _search.toLowerCase();
    return list.where((o) {
      final no = (o['order_no'] ?? '').toString().toLowerCase();
      return no.contains(q);
    }).toList();
  }

  Color _statusColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'verified':
        return CupertinoColors.systemGreen;
      case 'new':
        return CupertinoColors.systemOrange;
      default:
        return kIOSBlue;
    }
  }

  Future<void> _onRefresh() async => _fetch(reset: true);

  void _setTab(int index) {
    if (_tabIndex == index) return;
    setState(() {
      _tabIndex = index;
      _error = null;
      _loading = true;
    });
    _pageCtrl.animateToPage(index,
        duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    _fetch(reset: true);
  }

  int get _countTotal => (_lists[_tab] ?? []).length;
  int get _countVerified => (_lists[_tab] ?? [])
      .where((e) => (e['status'] ?? '').toString().toLowerCase() == 'verified')
      .length;
  int get _countNew => (_lists[_tab] ?? [])
      .where((e) => (e['status'] ?? '').toString().toLowerCase() == 'new')
      .length;

  bool get _showBottomAction =>
      _tabIndex == 1 && _error == null && !_loading && (_lists[_tab]?.isNotEmpty ?? false);

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ClubOrderScanScreen(
          warehouseId: widget.warehouseId,
          warehouseLabel: widget.warehouseLabel,
        ),
      ),
    );
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _scanCount = p.getInt(_scanKey) ?? 0);
  }

  Future<void> _resetScannedCount() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Reset scanned count?', style: g16w7()),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('This will set the scanned count for this warehouse to 0.',
              style: g13(CupertinoColors.secondaryLabel)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: g14w6(kIOSBlue)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset', style: g14w6(CupertinoColors.destructiveRed)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_scanKey, 0);
    if (!mounted) return;
    setState(() => _scanCount = 0);
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoTheme(
      data: theme.copyWith(
        primaryColor: kIOSBlue,
        textTheme: theme.textTheme.copyWith(
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            color: CupertinoColors.label.resolveFrom(context),
            decoration: TextDecoration.none,
          ),
          navTitleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label.resolveFrom(context),
            decoration: TextDecoration.none,
          ),
          navLargeTitleTextStyle: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.label.resolveFrom(context),
            decoration: TextDecoration.none,
          ),
          actionTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kIOSBlue,
            decoration: TextDecoration.none,
          ),
          tabLabelTextStyle: GoogleFonts.inter(fontSize: 11, decoration: TextDecoration.none),
        ),
      ),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.warehouseLabel, style: g14w6()),
              const SizedBox(height: 2),
              Text('Pending Pickup Orders', style: g12(CupertinoColors.secondaryLabel)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NEW: 3-dot menu to show combined counts across ALL tabs
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openAllCountsSheet,
                child: const Icon(CupertinoIcons.ellipsis_vertical, size: 20, color: kIOSBlue),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openScanner,
                child: const Icon(CupertinoIcons.qrcode_viewfinder, size: 22, color: kIOSBlue),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _scanCount == 0 ? null : _resetScannedCount,
                child: Icon(
                  CupertinoIcons.refresh_circled_solid,
                  size: 22,
                  color: _scanCount == 0
                      ? CupertinoColors.inactiveGray
                      : CupertinoColors.destructiveRed,
                ),
              ),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // Segmented control
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _tabIndex,
                      onValueChanged: (v) => _setTab(v ?? 0),
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Text('Recent', style: g13()),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Text('Late', style: g13()),
                        ),
                        2: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Text('Delayed', style: g13()),
                        ),
                      },
                    ),
                  ),

                  // Tiny counts + Scanned (current tab only)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TinyDotLabel(label: 'Total', value: '$_countTotal', color: kIOSBlue, g10: g10),
                        const SizedBox(width: 10),
                        _TinyDotLabel(
                            label: 'Verified',
                            value: '$_countVerified',
                            color: CupertinoColors.systemGreen,
                            g10: g10),
                        const SizedBox(width: 10),
                        _TinyDotLabel(
                            label: 'New',
                            value: '$_countNew',
                            color: CupertinoColors.systemOrange,
                            g10: g10),
                        const SizedBox(width: 10),
                        _TinyDotLabel(
                            label: 'Scanned',
                            value: _scanCount.toString().padLeft(2, '0'),
                            color: CupertinoColors.activeBlue,
                            g10: g10),
                      ],
                    ),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: CupertinoSearchTextField(
                      placeholder: 'Search by order number…',
                      style: g13(),
                      placeholderStyle: g13(CupertinoColors.placeholderText),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),

                  // Body (swipe between tabs)
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      onPageChanged: (i) async {
                        if (_tabIndex != i) {
                          setState(() => _tabIndex = i);
                          await _fetch(reset: true);
                        }
                        final p = await SharedPreferences.getInstance();
                        if (!mounted) return;
                        setState(() => _scanCount = p.getInt(_scanKey) ?? 0);
                      },
                      children: List.generate(3, (_) => _buildListBody()),
                    ),
                  ),
                ],
              ),

              // Late tab bottom action
              if (_showBottomAction)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        height: 44,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: CupertinoColors.destructiveRed,
                          borderRadius: BorderRadius.circular(22),
                          onPressed: _marking ? null : _markAllLateAsDelayed,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.arrow_right_circle_fill,
                                  size: 18, color: CupertinoColors.white),
                              const SizedBox(width: 8),
                              Text(
                                _marking ? 'Working…' : 'Mark Late → Delayed',
                                style: g14w6(CupertinoColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: () => _fetch(reset: true), g14w6: g14w6, g13: g13);
    }
    if (_visible.isEmpty) {
      return _EmptyState(tab: _tab, g14w6: g14w6, g13: g13);
    }
    final bottomPad = _tabIndex == 1 ? (_bottomActionHeight + 24) : 16;
    final showLoadMoreButton = (_hasNext[_tab] ?? false) && !_loadingMore;

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad.toDouble()),
        itemCount: _visible.length + (_loadingMore ? 1 : 0) + (showLoadMoreButton ? 1 : 0),
        itemBuilder: (context, i) {
          final spinnerIndex = _visible.length;
          final buttonIndex = _visible.length + (_loadingMore ? 1 : 0);

          if (_loadingMore && i == spinnerIndex) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }

          if (showLoadMoreButton && i == buttonIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CupertinoButton(
                onPressed: () {
                  if (_loadingMore) return;
                  setState(() => _loadingMore = true);
                  _fetch(reset: false);
                },
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                child: Text('Load more', style: g14w6(kIOSBlue)),
              ),
            );
          }

          if (i >= _visible.length) return const SizedBox.shrink();

          final o = _visible[i];
          return _OrderCard(
            orderNo: o['order_no']?.toString() ?? 'N/A',
            status: o['status']?.toString() ?? 'N/A',
            createdAt: o['created_at']?.toString() ?? '—',
            color: _statusColor(o['status']),
            g14w6: g14w6,
            g12: g12,
            onTap: () {},
          );
        },
      ),
    );
  }
}

// ===== small widgets =====

class _TinyDotLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextStyle Function([Color?]) g10;

  const _TinyDotLabel({
    required this.label,
    required this.value,
    required this.color,
    required this.g10,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $value', style: g10(secondary)),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderNo;
  final String status;
  final String createdAt;
  final Color color;
  final VoidCallback onTap;

  final TextStyle Function([Color?]) g14w6;
  final TextStyle Function([Color?]) g12;

  const _OrderCard({
    required this.orderNo,
    required this.status,
    required this.createdAt,
    required this.color,
    required this.onTap,
    required this.g14w6,
    required this.g12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.cube_box_fill, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderNo, maxLines: 1, overflow: TextOverflow.ellipsis, style: g14w6(CupertinoColors.label)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status, style: g12(color).copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.calendar, size: 12, color: CupertinoColors.systemGrey),
                        const SizedBox(width: 4),
                        Text(createdAt, style: g12(CupertinoColors.secondaryLabel)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String tab;
  final TextStyle Function([Color?]) g14w6;
  final TextStyle Function([Color?]) g13;
  const _EmptyState({required this.tab, required this.g14w6, required this.g13});

  @override
  Widget build(BuildContext context) {
    final label = {
      'recent': 'No recent orders',
      'late': 'No late orders',
      'delayed': 'No delayed orders',
    }[tab]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text_search,
              size: 56, color: CupertinoColors.systemGrey.resolveFrom(context)),
          const SizedBox(height: 10),
          Text(label, style: g13(CupertinoColors.secondaryLabel)),
          const SizedBox(height: 2),
          Text('Try pulling to refresh.', style: g13(CupertinoColors.tertiaryLabel)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final TextStyle Function([Color?]) g14w6;
  final TextStyle Function([Color?]) g13;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.g14w6,
    required this.g13,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(message, textAlign: TextAlign.center, style: g13(CupertinoColors.destructiveRed)),
        ),
        const SizedBox(height: 10),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onPressed: onRetry,
          child: Text('Retry', style: g14w6(CupertinoColors.white)),
        ),
      ]),
    );
  }
}

// ===== NEW: Reusable row for the ActionSheet counts =====
class _CountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextStyle Function([Color?]) g13;
  final TextStyle Function([Color?]) g14w6;

  const _CountRow({
    required this.label,
    required this.value,
    required this.color,
    required this.g13,
    required this.g14w6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: g13(CupertinoColors.secondaryLabel))),
        Text(value, style: g14w6(CupertinoColors.label)),
      ],
    );
  }
}
