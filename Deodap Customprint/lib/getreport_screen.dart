import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CustomprintReportPage extends StatefulWidget {
  const CustomprintReportPage({Key? key}) : super(key: key);

  @override
  State<CustomprintReportPage> createState() => _CustomprintReportPageState();
}

class _CustomprintReportPageState extends State<CustomprintReportPage> {
  // ====== CONFIG ======
  static const String apiUrl =
      'https://customprint.deodap.com/api_customprint/get_product_email.php';
  static const int pageLimit = 20; // reserved if your API supports it later

  // ====== STATE ======
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = false;
  bool _initialLoaded = false;
  bool _fetchingMore = false;
  bool _hasMore = true;

  int _page = 1;
  int _totalPages = 1;
  int _totalRecords = 0;

  final List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Optional default: last 7 days. Comment these two lines if you prefer empty defaults.
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 6));
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ====== API ======
  Future<void> _loadFirstPage() async {
    // Require at least one date (matches PHP REQUIRE_DATE_FILTER behavior)
    if (_startDate == null && _endDate == null) {
      _showInfo('Pick at least one date to filter.');
      return;
    }

    setState(() {
      _loading = true;
      _initialLoaded = false;
      _page = 1;
      _hasMore = true;
      _rows.clear();
    });
    try {
      final data = await _fetch(page: _page);
      setState(() {
        _rows.addAll(data.items);
        _totalPages = data.totalPages;
        _totalRecords = data.totalRecords;
        _hasMore = _page < _totalPages;
        _initialLoaded = true;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_fetchingMore || !_hasMore) return;
    setState(() => _fetchingMore = true);
    try {
      _page += 1;
      final data = await _fetch(page: _page);
      setState(() {
        _rows.addAll(data.items);
        _totalPages = data.totalPages;
        _totalRecords = data.totalRecords;
        _hasMore = _page < _totalPages;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _fetchingMore = false);
    }
  }

  /// Builds the request body to match the server’s strict date rules:
  /// - If both dates empty -> server returns empty (we block this in UI).
  /// - If only one is set -> send both as same (single-day range).
  /// - If reversed -> auto-swap so start <= end.
  Map<String, String> _buildRequestBody(int page) {
    final body = <String, String>{
      'page': page.toString(),
      'search': _searchCtrl.text.trim(),
      // If you later add paging in API, include:
      // 'limit': pageLimit.toString(),
    };

    final df = DateFormat('yyyy-MM-dd');

    DateTime? s = _startDate;
    DateTime? e = _endDate;

    if (s == null && e == null) {
      return body; // UI already prevents call in this case
    }

    // Single-day fallback if only one provided
    if (s != null && e == null) e = s;
    if (s == null && e != null) s = e;

    // Swap if reversed
    if (s!.isAfter(e!)) {
      final tmp = s;
      s = e;
      e = tmp;
    }

    body['start_date'] = df.format(s);
    body['end_date'] = df.format(e);
    return body;
  }

  Future<_ApiPage> _fetch({required int page}) async {
    final body = _buildRequestBody(page);

    final resp = await http
        .post(Uri.parse(apiUrl), body: body)
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw 'Server returned ${resp.statusCode}';
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(resp.body);
    } catch (_) {
      throw 'Invalid JSON';
    }
    if (decoded is! Map) throw 'Invalid response';

    final status = decoded['status']?.toString() ?? 'error';
    if (status != 'success') {
      final err = decoded['errors']?.toString() ?? 'Unknown error';
      throw 'API error: $err';
    }

    final List items = (decoded['data'] ?? []) as List;
    final totalPages = (decoded['total_page'] is int)
        ? decoded['total_page'] as int
        : int.tryParse('${decoded['total_page'] ?? 1}') ?? 1;
    final totalRecords = (decoded['total_records'] is int)
        ? decoded['total_records'] as int
        : int.tryParse('${decoded['total_records'] ?? 0}') ?? 0;

    final parsed = items.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return m;
    }).toList();

    return _ApiPage(
        items: parsed, totalPages: totalPages, totalRecords: totalRecords);
  }

  // ====== UI HELPERS ======
  void _onScroll() {
    if (!_hasMore || _fetchingMore || _loading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _pickStartDate() async {
    await _showDatePicker(
      initial: _startDate ?? DateTime.now(),
      onPicked: (d) {
        setState(() {
          _startDate = DateTime(d.year, d.month, d.day);
          // Keep range valid
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        });
      },
    );
  }

  Future<void> _pickEndDate() async {
    await _showDatePicker(
      initial: _endDate ?? _startDate ?? DateTime.now(),
      onPicked: (d) {
        setState(() {
          _endDate = DateTime(d.year, d.month, d.day);
          // Keep range valid
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        });
      },
    );
  }

  Future<void> _showDatePicker({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    DateTime temp = initial;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(decoration: TextDecoration.none),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () {
                      onPicked(temp);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(decoration: TextDecoration.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select';
    return DateFormat('dd MMM yyyy').format(d);
  }

  Future<File> _buildCsvFile() async {
    // Build CSV from currently loaded _rows
    final List<String> cols = [
      'product_id',
      'product_unique_id',
      'product_name',
      'product_image',
      'created_at',
      'is_disabled',
      'disabled_at',
      'user_id',
      'fullname',
      'mobilenumber',
      'email_sent',
      'sent_email',
    ];

    final StringBuffer sb = StringBuffer();
    sb.writeln(cols.join(','));

    String esc(String? v) {
      final s = (v ?? '').replaceAll('"', '""');
      return '"$s"'; // wrap in quotes for commas/newlines
    }

    for (final r in _rows) {
      final List<String> line = [
        esc('${r['product_id'] ?? ''}'),
        esc('${r['product_unique_id'] ?? ''}'),
        esc('${r['product_name'] ?? ''}'),
        esc('${r['product_image'] ?? ''}'),
        esc('${r['created_at'] ?? ''}'),
        esc('${r['is_disabled'] ?? ''}'),
        esc('${r['disabled_at'] ?? ''}'),
        esc('${r['user_id'] ?? ''}'),
        esc('${r['fullname'] ?? ''}'),
        esc('${r['mobilenumber'] ?? ''}'),
        esc('${r['email_sent'] ?? ''}'),
        esc('${r['sent_email'] ?? ''}'),
      ];
      sb.writeln(line.join(','));
    }

    final dir = await getApplicationDocumentsDirectory();
    final df = DateFormat('yyyyMMdd_HHmmss');
    final file =
    File('${dir.path}/customprint_report_${df.format(DateTime.now())}.csv');
    await file.writeAsString(sb.toString(), flush: true);
    return file;
  }

  Future<void> _downloadCsv() async {
    try {
      if (_rows.isEmpty) {
        _showInfo('No rows to export.');
        return;
      }
      final file = await _buildCsvFile();
      _showInfo('Saved: ${file.path}');
    } catch (e) {
      _showError('Download failed: $e');
    }
  }

  Future<void> _shareCsv() async {
    try {
      if (_rows.isEmpty) {
        _showInfo('No rows to share.');
        return;
      }
      final file = await _buildCsvFile();
      await Share.shareXFiles([XFile(file.path)], text: 'CustomPrint Report');
    } catch (e) {
      _showError('Share failed: $e');
    }
  }

  void _showError(String msg) {
    _showSheet(msg, isError: true);
  }

  void _showInfo(String msg) {
    _showSheet(msg, isError: false);
  }

  void _showSheet(String msg, {required bool isError}) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          isError ? 'Error' : 'Info',
          style: const TextStyle(decoration: TextDecoration.none),
        ),
        message: Text(
          msg,
          style: const TextStyle(decoration: TextDecoration.none),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            isDefaultAction: true,
            child: const Text(
              'OK',
              style: TextStyle(decoration: TextDecoration.none),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
      ),
    );
  }

  Future<void> _onPullRefresh() async {
    await _loadFirstPage();
  }

  // ====== BUILD ======
  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemGroupedBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'CustomPrint Reports',
          style: TextStyle(decoration: TextDecoration.none),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _downloadCsv,
              child: const Icon(CupertinoIcons.arrow_down_doc),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _shareCsv,
              child: const Icon(CupertinoIcons.square_arrow_up),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: CupertinoScrollbar(
                controller: _scrollController,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _onPullRefresh),
                    SliverToBoxAdapter(child: _buildHeaderCounts()),
                    SliverList.builder(
                      itemCount: _rows.length + (_fetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _rows.length) {
                          return _buildLoadingRow();
                        }
                        final r = _rows[index];
                        return _ReportCell(row: r);
                      },
                    ),
                    if (_loading && !_initialLoaded)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CupertinoActivityIndicator()),
                        ),
                      ),
                    if (!_loading && _initialLoaded && _rows.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No data',
                              style:
                              TextStyle(decoration: TextDecoration.none),
                            ),
                          ),
                        ),
                      ),
                    if (!_hasMore && _rows.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              '— End —',
                              style:
                              TextStyle(decoration: TextDecoration.none),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: 'Start',
                  value: _fmtDate(_startDate),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateChip(
                  label: 'End',
                  value: _fmtDate(_endDate),
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadFirstPage(),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: () {
                  // quick guard to match backend rule
                  if (_startDate == null && _endDate == null) {
                    _showInfo('Pick at least one date to filter.');
                    return;
                  }
                  _loadFirstPage();
                },
                color: CupertinoColors.activeBlue.resolveFrom(context),
                child: const Text(
                  'Filter',
                  style: TextStyle(decoration: TextDecoration.none),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _startDate = null;
                    _endDate = null;
                  });
                },
                color: CupertinoColors.systemGrey.resolveFrom(context),
                child: const Text(
                  'Clear',
                  style: TextStyle(decoration: TextDecoration.none),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCounts() {
    return Container(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: DefaultTextStyle(
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
          decoration: TextDecoration.none,
        ),
        child: Row(
          children: [
            const Text('Total: ',
                style: TextStyle(decoration: TextDecoration.none)),
            Text('$_totalRecords',
                style: const TextStyle(decoration: TextDecoration.none)),
            const SizedBox(width: 12),
            const Text('Page: ',
                style: TextStyle(decoration: TextDecoration.none)),
            Text('$_page/$_totalPages',
                style: const TextStyle(decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingRow() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateChip({
    Key? key,
    required this.label,
    required this.value,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemGrey5.resolveFrom(context);
    final txt = CupertinoColors.label.resolveFrom(context);
    final sub = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                  color: sub, fontSize: 14, decoration: TextDecoration.none),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: txt, fontSize: 14, decoration: TextDecoration.none),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.calendar, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ReportCell extends StatelessWidget {
  final Map<String, dynamic> row;
  const _ReportCell({Key? key, required this.row}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemBackground.resolveFrom(context);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final sub = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: sep, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.cube_box, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line
                Text(
                  '${row['product_id'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                // Sub info
                Text(
                  'UID: ${row['product_unique_id'] ?? ''}   Name: ${row['product_name'] ?? ''}',
                  style: TextStyle(
                      color: sub, fontSize: 13, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 2),
                Text(
                  'Created: ${row['created_at'] ?? ''}',
                  style: TextStyle(
                      color: sub, fontSize: 13, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 2),
                Text(
                  'Disabled: ${row['is_disabled'] ?? ''}${row['disabled_at'] != null && row['disabled_at'].toString().isNotEmpty ? ' at ${row['disabled_at']}' : ''}',
                  style: TextStyle(
                      color: sub, fontSize: 13, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 2),
                Text(
                  'User: ${row['fullname'] ?? ''}  •  ${row['mobilenumber'] ?? ''}',
                  style: TextStyle(
                      color: sub, fontSize: 13, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 2),
                Text(
                  'Email Sent: ${row['email_sent'] ?? ''}${row['sent_email'] != null && row['sent_email'].toString().isNotEmpty ? ' (${row['sent_email']})' : ''}',
                  style: TextStyle(
                      color: sub, fontSize: 13, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiPage {
  final List<Map<String, dynamic>> items;
  final int totalPages;
  final int totalRecords;
  _ApiPage({
    required this.items,
    required this.totalPages,
    required this.totalRecords,
  });
}
