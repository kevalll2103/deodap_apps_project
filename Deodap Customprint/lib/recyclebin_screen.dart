// lib/recyclebin_cupertino.dart
// iOS Cupertino-styled Recycle Bin screen (full, self-contained)

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

// If you have a details page, keep this import.
// Otherwise you can comment it out and the code will show a fallback dialog.
// import 'package:Deodap_Customprint/view/recyclebin_productdetails_screen_view.dart' as recyclebin_details;


class RecyclebinscreenView extends StatefulWidget {
  const RecyclebinscreenView({super.key});

  @override
  State<RecyclebinscreenView> createState() => _RecyclebinscreenViewState();
}

class _RecyclebinscreenViewState extends State<RecyclebinscreenView> {
  // ====== STATE ======
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isConnected = true;
  bool _busyOverlay = false;

  String? _startDate; // yyyy-mm-dd
  String? _endDate;   // yyyy-mm-dd

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ====== CONNECTIVITY ======
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  // ====== API ======
  Future<void> _fetchProducts() async {
    _clearDates();
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No Internet Connection. Please check your connection.';
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://customprint.deodap.com/get_recyclebin_all_order.php'),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data is Map<String, dynamic> &&
            data['message'] != null &&
            data['message'] == 'No products found') {
          setState(() {
            _products = [];
            _filteredProducts = [];
            _isLoading = false;
          });
        } else {
          final list = (data as List).toList();

          // Sort by disabled_at (desc) then created_at (desc)
          list.sort((a, b) {
            DateTime dA = DateTime.tryParse(a['disabled_at'] ?? '') ??
                DateTime.tryParse(a['created_at'] ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            DateTime dB = DateTime.tryParse(b['disabled_at'] ?? '') ??
                DateTime.tryParse(b['created_at'] ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return dB.compareTo(dA);
          });

          setState(() {
            _products = list;
            _filteredProducts = list;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load products (HTTP ${res.statusCode})');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load products: $e';
      });
    }
  }

  Future<void> _deleteAllOrders() async {
    setState(() => _busyOverlay = true);
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://customprint.deodap.com/delete_all_order.php'),
      );
      final resp = await req.send();
      final stringResp = await http.Response.fromStream(resp);

      if (resp.statusCode == 200) {
        final jsonResp = json.decode(stringResp.body);
        if (jsonResp['error'] != null) {
          await _fetchProducts();
          await _showInfoDialog('No Orders Available');
        } else {
          await _fetchProducts();
          await _showInfoDialog('All orders deleted successfully.');
        }
      } else {
        await _showErrorDialog('Server error, please try again.');
      }
    } on SocketException {
      await _showErrorDialog('No Internet, please try again.');
    } catch (e) {
      await _showErrorDialog('Something went wrong: $e');
    } finally {
      setState(() => _busyOverlay = false);
    }
  }

  Future<void> _recoverAllOrders() async {
    setState(() => _busyOverlay = true);
    try {
      final req = http.MultipartRequest(
        'GET',
        Uri.parse('https://customprint.deodap.com/enabled_all_order.php'),
      );
      final resp = await req.send();
      final stringResp = await http.Response.fromStream(resp);

      if (resp.statusCode == 200) {
        final jsonResp = json.decode(stringResp.body);
        if (jsonResp['error'] != null &&
            jsonResp['error'] == 'No order available') {
          await _fetchProducts();
          await _showInfoDialog('No Orders Available');
        } else {
          await _fetchProducts();
          await _showInfoDialog('All orders recovered successfully.');
        }
      } else {
        await _showErrorDialog('Server error, please try again.');
      }
    } on SocketException {
      await _showErrorDialog('No Internet, please try again.');
    } catch (e) {
      await _showErrorDialog('Something went wrong: $e');
    } finally {
      setState(() => _busyOverlay = false);
    }
  }

  // ====== FILTERING ======
  void _clearDates() {
    _startDate = null;
    _endDate = null;
  }

  void _filterText(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final productName = (product['product_name'] as String?) ?? '';
          final productId = (product['product_unique_id'] as String?) ?? '';
          return productId.contains(query) ||
              productName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _filterByDateRange(String startDate, String? endDate) {
    setState(() {
      _filteredProducts = _products.where((product) {
        final created = DateTime.tryParse(product['created_at'] ?? '');
        if (created == null) return false;
        final start = DateTime.parse(startDate);
        if (endDate == null) {
          return !created.isBefore(start);
        }
        final end = DateTime.parse(endDate).add(const Duration(days: 1));
        return (created.isAfter(start) || created.isAtSameMomentAs(start)) &&
            created.isBefore(end);
      }).toList();
    });
  }

  // ====== DIALOGS (Cupertino) ======
  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            isDefaultAction: true,
            child: const Text('Yes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog(String message) async {
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDefaultAction: true,
            child: const Text('OK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Error', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
        content: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDestructiveAction: true,
            child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  // ====== DATE PICKERS (Cupertino bottom sheet) ======
  Future<void> _openDateFilterSheet() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        DateTime tempStart = _startDate != null
            ? DateTime.parse(_startDate!)
            : DateTime.now();
        DateTime tempEnd =
        _endDate != null ? DateTime.parse(_endDate!) : DateTime.now();

        return CupertinoActionSheet(
          title: const Text('Filter by Date Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          message: const Text('Select Start and End dates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          actions: [
            _DatePickerRow(
              title: 'Start Date',
              initial: tempStart,
              onChanged: (d) => tempStart = d,
            ),
            _DatePickerRow(
              title: 'End Date',
              initial: tempEnd,
              onChanged: (d) => tempEnd = d,
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _startDate = "${tempStart.toLocal()}".split(' ')[0];
                  _endDate = "${tempEnd.toLocal()}".split(' ')[0];
                });
                Navigator.of(ctx).pop();
                if (_startDate != null) {
                  // Ensure end >= start
                  if (_endDate != null &&
                      DateTime.parse(_endDate!)
                          .isBefore(DateTime.parse(_startDate!))) {
                    _showErrorDialog('End date cannot be before start date.');
                  } else {
                    _filterByDateRange(_startDate!, _endDate);
                  }
                }
              },
              child: const Text('Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _filteredProducts = _products;
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Clear', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDefaultAction: false,
            child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          ),
        );
      },
    );
  }

  // ====== UI BUILDERS ======
  Widget _buildNavBar() {
    return CupertinoNavigationBar(
      middle: const Text('Recycle Bin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.maybePop(context),
        child: const Icon(CupertinoIcons.back, size: 24),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showConfirmDialog(
              title: 'Delete All Orders',
              message: 'Are you sure you want to delete all the orders?',
              onConfirm: _deleteAllOrders,
            ),
            child: const Icon(CupertinoIcons.trash, size: 24),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showConfirmDialog(
              title: 'Recover All Orders',
              message:
              'Recover all orders (they will be re-enabled from Recycle Bin).',
              onConfirm: _recoverAllOrders,
            ),
            child: const Icon(CupertinoIcons.arrow_2_circlepath, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Filter Order…',
              onChanged: _filterText,
              onSuffixTap: () {
                _searchController.clear();
                _filterText('');
              },
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: _openDateFilterSheet,
            child: const Icon(CupertinoIcons.calendar, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    // Simple iOS-like shimmering blocks (static, minimal)
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, idx) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              color: CupertinoColors.systemGrey5,
            ),
          ),
        ),
        childCount: 8,
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isConnected ? CupertinoIcons.exclamationmark_circle
                    : CupertinoIcons.wifi_slash,
                size: 64,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                _isConnected ? 'Something went wrong' : 'No Internet Connection',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, decoration: TextDecoration.none),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey, decoration: TextDecoration.none),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _fetchProducts,
                child: const Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(CupertinoIcons.trash, size: 80, color: CupertinoColors.inactiveGray),
            SizedBox(height: 12),
            Text('Empty Recycle Bin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final product = _filteredProducts[index];
          final imageUrl = (product['product_image'] as String?) ?? '';
          final orderId = (product['product_unique_id'] as String?) ?? '';
          final createdAt = (product['created_at'] as String?) ?? '';
          final disabledAt = (product['disabled_at'] as String?) ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () async {
                await _showInfoDialog('Order: $orderId\nCreated: $createdAt\nDeleted: $disabledAt');
                await _fetchProducts();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: CupertinoColors.systemGrey5,
                            child: const Center(
                              child: Icon(CupertinoIcons.photo, size: 32, color: CupertinoColors.inactiveGray),
                            ),
                          ),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: CupertinoColors.systemGrey5,
                              child: const Center(child: CupertinoActivityIndicator()),
                            );
                          },
                        )
                      else
                        Container(
                          color: CupertinoColors.systemGrey5,
                          child: const Center(
                            child: Icon(CupertinoIcons.photo, size: 32, color: CupertinoColors.inactiveGray),
                          ),
                        ),

                      // Gradient overlay (bottom)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00000000),
                                Color(0xAA000000),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Order ID: $orderId',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Created: $createdAt',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Deleted: $disabledAt',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: _filteredProducts.length,
      ),
    );
  }

  // ====== BUILD ======
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavBar() as ObstructingPreferredSizeWidget,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Pull to refresh (iOS style)
              CupertinoSliverRefreshControl(
                onRefresh: _fetchProducts,
              ),

              SliverToBoxAdapter(child: _buildSearchBar()),

              if (_isLoading) _buildLoadingSkeleton()
              else if (_hasError) _buildErrorState()
              else if (_filteredProducts.isEmpty) _buildEmptyState()
                else _buildList(),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),

          // Busy overlay for long actions (delete/recover all)
          if (_busyOverlay)
            Container(
              color: const Color(0x33000000),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 16),
              ),
            ),
        ],
      ),
    );
  }
}

// ====== SUPPORT WIDGETS ======
class _DatePickerRow extends StatefulWidget {
  final String title;
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerRow({
    required this.title,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_DatePickerRow> createState() => _DatePickerRowState();
}

class _DatePickerRowState extends State<_DatePickerRow> {
  late DateTime _temp;

  @override
  void initState() {
    super.initState();
    _temp = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheetAction(
      onPressed: () async {
        await showCupertinoModalPopup(
          context: context,
          builder: (ctx) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
                      ),
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, decoration: TextDecoration.none)),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () {
                          widget.onChanged(_temp);
                          Navigator.of(ctx).pop();
                          setState(() {}); // refresh label
                        },
                        child: const Text('Done', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, decoration: TextDecoration.none)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _temp,
                    minimumDate: DateTime(2000),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (d) => _temp = d,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.calendar, size: 18),
          const SizedBox(width: 6),
          Text(
            '${widget.title}: ${_fmtDate(_temp)}',
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13, decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => "${d.toLocal()}".split(' ')[0];
}
