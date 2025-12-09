import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

/// Shopify Orders Screen
/// - Two tabs: All Orders, Custom Orders
/// - Search bar (uses `search` query param)
/// - Uses your PHP API in grouped mode
/// - iOS-style look & feel with WHITE app bar
class ShopifyOrdersdailyScreen extends StatefulWidget {
  const ShopifyOrdersdailyScreen({Key? key}) : super(key: key);

  @override
  State<ShopifyOrdersdailyScreen> createState() => _ShopifyOrdersdailyScreenState();
}

enum OrdersTab { all, custom }

class _ShopifyOrdersdailyScreenState extends State<ShopifyOrdersdailyScreen> {
  static const String _baseUrl =
      'https://customprint.deodap.com/stockbridge/get_shopify_order.php';

  OrdersTab _currentTab = OrdersTab.all;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 50;

  List<ShopifyOrderGroup> _orders = [];

  @override
  void initState() {
    super.initState();
    _setupSearchListener();
    _fetchOrders(reset: true);
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _fetchOrders(reset: true);
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({bool reset = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        _currentPage = 1;
        _totalPages = 1;
        _orders.clear();
      });
    } else {
      if (_currentPage >= _totalPages) return;
      setState(() {
        _isLoadingMore = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final query = <String, String>{
        'mode': 'grouped',
        'page': _currentPage.toString(),
        'per_page': _perPage.toString(),
        'include_stats': '0',
      };

      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty) {
        query['search'] = searchText;
      }

      query['custom_only'] =
          _currentTab == OrdersTab.custom ? '1' : '0';

      final uri = Uri.parse(_baseUrl).replace(queryParameters: query);
      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid response format from server';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final jsonBody = decoded;

      if (jsonBody['ok'] != true) {
        setState(() {
          _hasError = true;
          _errorMessage =
              (jsonBody['error']?.toString() ?? 'API returned ok = false');
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final int totalPages = (jsonBody['total_pages'] is int)
          ? jsonBody['total_pages']
          : (jsonBody['total_pages'] is num
              ? (jsonBody['total_pages'] as num).toInt()
              : 1);

      final dataRaw = jsonBody['data'];
      if (dataRaw is! List) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid data format (expected list)';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final List<dynamic> data = dataRaw;

      final List<ShopifyOrderGroup> fetched = data
          .map((e) =>
              ShopifyOrderGroup.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        if (reset) {
          _orders = fetched;
        } else {
          _orders.addAll(fetched);
        }
        _totalPages = totalPages;
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _fetchOrders(reset: true);
  }

  void _loadMore() {
    if (_isLoading || _isLoadingMore) return;
    if (_currentPage >= _totalPages) return;
    setState(() {
      _currentPage += 1;
    });
    _fetchOrders(reset: false);
  }

  void _onTabChanged(OrdersTab tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
    });
    _fetchOrders(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildTabs(),
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // White iOS-style app bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            child: const Icon(
              CupertinoIcons.back,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shopify Daily Orders',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isLoading)
            const CupertinoActivityIndicator(
              radius: 10,
            ),
        ],
      ),
    );
  }

  /// Improved segmented tabs with NO BORDER + BLACK TEXT
Widget _buildTabs() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB), // Light grey background
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(3),
      child: CupertinoSegmentedControl<OrdersTab>(
        groupValue: _currentTab,
        onValueChanged: _onTabChanged,

        // 💥 Completely remove border
        borderColor: Colors.transparent,

        // ⭐ Selected tab background
        selectedColor: Colors.white,

        // ⭐ Unselected tab background
        unselectedColor: Colors.transparent,

        // Tap effect
        pressedColor: Colors.white.withOpacity(0.6),

        children: {
          OrdersTab.all: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text(
              'All Daily Orders',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black, // ⭐ ALWAYS BLACK TEXT
                fontWeight: _currentTab == OrdersTab.all
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),

          OrdersTab.custom: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text(
            'Custom Print Orders',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black, // ⭐ ALWAYS BLACK TEXT
                fontWeight: _currentTab == OrdersTab.custom
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        },
      ),
    ),
  );
}


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Search by order no, email, phone, SKU...',
        style: GoogleFonts.poppins(fontSize: 14),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
        suffixIcon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18),
        onSubmitted: (_) => _fetchOrders(reset: true),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 40,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                onPressed: () => _fetchOrders(reset: true),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _orders.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 14),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF0F172A),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        itemCount: _orders.length + 1, // +1 for "load more"
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return _buildLoadMore();
          }
          final group = _orders[index];
          return _buildOrderCard(group);
        },
      ),
    );
  }

  Widget _buildLoadMore() {
    if (_currentPage >= _totalPages) {
      return const SizedBox(height: 32);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: _isLoadingMore
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                onPressed: _loadMore,
                child: Text(
                  'Load more',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
      ),
    );
  }

  Widget _buildOrderCard(ShopifyOrderGroup group) {
    final o = group.order;
    final items = group.items;

    final orderNumber = o.orderNumber ?? '-';
    final name = o.name ?? '-';
    final email = o.email ?? '';
    final phone = o.phone ?? '';
    final totalPrice = o.totalPrice;
    final currency = o.currency ?? '';
    final createdAt = o.createdAt;
    final financialStatus = o.financialStatus ?? '-';
    final fulfillmentStatus = o.fulfillmentStatus ?? '-';

    final createdText =
        createdAt != null ? _formatDateTime(createdAt) : '—';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: ShopifyOrderDetailsSheet(group: group),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: order number + total
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$orderNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (totalPrice != null)
                  Text(
                    '$currency ${totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047857),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Customer + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Created',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      createdText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status chips
            Row(
              children: [
                _buildStatusChip(
                  label: financialStatus,
                  color: _statusColor(financialStatus),
                ),
                const SizedBox(width: 6),
                _buildStatusChip(
                  label: fulfillmentStatus,
                  color: _statusColor(fulfillmentStatus),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Items preview
            if (items.isNotEmpty) ...[
              const Divider(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0;
                      i < items.length && i < 3;
                      i++) // show max 3 items
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: _buildItemRow(items[i]),
                    ),
                  if (items.length > 3)
                    Text(
                      '+ ${items.length - 3} more items',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Tap for full details',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid') || s.contains('authorized')) {
      return const Color(0xFF047857);
    } else if (s.contains('pending') || s.contains('unpaid')) {
      return const Color(0xFFF97316);
    } else if (s.contains('cancel') || s.contains('refunded')) {
      return const Color(0xFFDC2626);
    } else if (s.contains('fulfilled') || s.contains('shipped')) {
      return const Color(0xFF2563EB);
    }
    return const Color(0xFF4B5563);
  }

  Widget _buildItemRow(ShopifyOrderItem item) {
    final title = item.name ?? item.title ?? 'Item';
    final sku = item.sku ?? '';
    final qty = item.quantity ?? 0;
    final price = item.price;
    final lineTotal =
        (price != null && qty != null) ? (price * qty) : null;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        if (sku.isNotEmpty)
          Text(
            sku,
            style:
                GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
        const SizedBox(width: 8),
        Text(
          'x$qty',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        if (lineTotal != null)
          Text(
            lineTotal.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final m = twoDigits(dt.month);
    final d = twoDigits(dt.day);
    final h = twoDigits(dt.hour);
    final min = twoDigits(dt.minute);
    return '$y-$m-$d $h:$min';
  }
}

/* ===========================
   DETAILS SHEET (BOTTOM SHEET)
   - 3 MAIN SECTIONS:
     1) Summary + Status/Payment
     2) Customer + Address + Tags/UTM
     3) Items
   =========================== */

class ShopifyOrderDetailsSheet extends StatelessWidget {
  final ShopifyOrderGroup group;

  const ShopifyOrderDetailsSheet({Key? key, required this.group})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final o = group.order;
    final items = group.items;
    final orderNumber = o.orderNumber ?? '-';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: const Color(0xFFF2F2F7),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildSheetHeader(context, orderNumber),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: Summary + Status/Payment
                      _buildSummaryAndStatusCard(o),

                      const SizedBox(height: 12),

                      // SECTION 2: Customer + Address + Tags/UTM
                      _buildCustomerAndAddressCard(o),

                      const SizedBox(height: 12),

                      // SECTION 3: Items
                      _buildItemsCard(items, o.currency),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context, String orderNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '#$orderNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SECTION 1: Order Summary + Status & Payment
  Widget _buildSummaryAndStatusCard(ShopifyOrder o) {
    final total = o.totalPrice;
    final subtotal = o.subtotalPrice;
    final tax = o.totalTax;
    final discounts = o.totalDiscounts;
    final shipping = o.totalShipping;
    final currency = o.currency ?? '';
    final createdAt = o.createdAt;
    final updatedAt = o.updatedAt;
    final syncedAt = o.syncedAt;

    String _fmtDate(DateTime? dt) {
      if (dt == null) return '—';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Summary'),
          const SizedBox(height: 8),
          _keyValueRow(
            'Total',
            total != null ? '$currency ${total.toStringAsFixed(2)}' : '—',
            isBold: true,
          ),
          if (subtotal != null)
            _keyValueRow(
              'Subtotal',
              '$currency ${subtotal.toStringAsFixed(2)}',
            ),
          if (shipping != null)
            _keyValueRow(
              'Shipping',
              '$currency ${shipping.toStringAsFixed(2)}',
            ),
          if (tax != null)
            _keyValueRow(
              'Tax',
              '$currency ${tax.toStringAsFixed(2)}',
            ),
          if (discounts != null)
            _keyValueRow(
              'Discounts',
              '$currency ${discounts.toStringAsFixed(2)}',
            ),
          const SizedBox(height: 8),
          _keyValueRow('Created', _fmtDate(createdAt)),
          _keyValueRow('Updated', _fmtDate(updatedAt)),
          _keyValueRow('Synced At', _fmtDate(syncedAt)),
          const SizedBox(height: 12),
          const Divider(height: 16),
          _sectionTitle('Status & Payment'),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip('Financial', o.financialStatus ?? '-'),
              const SizedBox(width: 6),
              _statusChip('Fulfillment', o.fulfillmentStatus ?? '-'),
            ],
          ),
          const SizedBox(height: 10),
          _keyValueRow('Payment Gateway', o.paymentGateway ?? '—'),
          _keyValueRow('Currency', o.currency ?? '—'),
          _keyValueRow('Order Name', o.name ?? '—'),
          _keyValueRow('Customer Email', o.customerEmail ?? o.email ?? '—'),
        ],
      ),
    );
  }

  /// SECTION 2: Customer + Address + Tags & UTM
  Widget _buildCustomerAndAddressCard(ShopifyOrder o) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Customer'),
          const SizedBox(height: 8),
          _keyValueRow('Customer ID', o.customerId?.toString() ?? '—'),
          _keyValueRow('Name', o.name ?? '—'),
          _keyValueRow('Email', o.email ?? '—'),
          _keyValueRow('Phone', o.phone ?? '—'),
          if ((o.customerTags ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _label('Customer Tags'),
            const SizedBox(height: 4),
            _chipsFromString(o.customerTags!),
          ],
          const SizedBox(height: 12),
          const Divider(height: 18),
          _sectionTitle('Billing & Shipping'),
          const SizedBox(height: 8),
          _label('Billing Address'),
          const SizedBox(height: 4),
          _addressLines(
            o.billingCity,
            o.billingProvince,
            o.billingCountry,
            o.billingZip,
          ),
          const SizedBox(height: 12),
          _label('Shipping Address'),
          const SizedBox(height: 4),
          _addressLines(
            o.shippingCity,
            o.shippingProvince,
            o.shippingCountry,
            o.shippingZip,
          ),
          if ((o.orderTags ?? '').isNotEmpty ||
              (o.utmSource ?? '').isNotEmpty ||
              (o.utmMedium ?? '').isNotEmpty ||
              (o.utmCampaign ?? '').isNotEmpty ||
              (o.utmContent ?? '').isNotEmpty ||
              (o.utmTerm ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 18),
          ],
          if ((o.orderTags ?? '').isNotEmpty) ...[
            _sectionTitle('Order Tags'),
            const SizedBox(height: 4),
            _chipsFromString(o.orderTags!),
          ],
          if ((o.utmSource ?? '').isNotEmpty ||
              (o.utmMedium ?? '').isNotEmpty ||
              (o.utmCampaign ?? '').isNotEmpty ||
              (o.utmContent ?? '').isNotEmpty ||
              (o.utmTerm ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionTitle('UTM Parameters'),
            if ((o.utmSource ?? '').isNotEmpty)
              _keyValueRow('Source', o.utmSource!),
            if ((o.utmMedium ?? '').isNotEmpty)
              _keyValueRow('Medium', o.utmMedium!),
            if ((o.utmCampaign ?? '').isNotEmpty)
              _keyValueRow('Campaign', o.utmCampaign!),
            if ((o.utmContent ?? '').isNotEmpty)
              _keyValueRow('Content', o.utmContent!),
            if ((o.utmTerm ?? '').isNotEmpty)
              _keyValueRow('Term', o.utmTerm!),
          ],
        ],
      ),
    );
  }

  /// SECTION 3: Items
  Widget _buildItemsCard(List<ShopifyOrderItem> items, String? currency) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Items (${items.length})'),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'No items found',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            )
          else
            Column(
              children: items.map((item) {
                final price = item.price;
                final qty = item.quantity ?? 0;
                final lineTotal =
                    (price != null) ? (price * qty) : null;
                final currencyText = currency ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? item.title ?? 'Item',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if ((item.sku ?? '').isNotEmpty ||
                          (item.vendor ?? '').isNotEmpty)
                        Text(
                          [
                            if ((item.sku ?? '').isNotEmpty) 'SKU: ${item.sku}',
                            if ((item.vendor ?? '').isNotEmpty)
                              'Vendor: ${item.vendor}',
                          ].join(' • '),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Qty: $qty',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (price != null)
                            Text(
                              'Price: $currencyText ${price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          if (lineTotal != null)
                            Text(
                              'Total: $currencyText ${lineTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                        ],
                      ),
                      if ((item.fulfillmentStatus ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Fulfillment: ${item.fulfillmentStatus}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /* ---- reusable mini widgets ---- */

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _keyValueRow(String key, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final color = _statusColor(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid') || s.contains('authorized')) {
      return const Color(0xFF047857);
    } else if (s.contains('pending') || s.contains('unpaid')) {
      return const Color(0xFFF97316);
    } else if (s.contains('cancel') || s.contains('refunded')) {
      return const Color(0xFFDC2626);
    } else if (s.contains('fulfilled') || s.contains('shipped')) {
      return const Color(0xFF2563EB);
    }
    return const Color(0xFF4B5563);
  }

  Widget _chipsFromString(String tags) {
    final parts = tags
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return Text(
        '—',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: parts
          .map(
            (tag) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[800],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _addressLines(
      String? city, String? province, String? country, String? zip) {
    final lines = <String>[];
    if ((city ?? '').isNotEmpty) lines.add(city!);
    if ((province ?? '').isNotEmpty) lines.add(province!);
    if ((country ?? '').isNotEmpty) lines.add(country!);
    if ((zip ?? '').isNotEmpty) lines.add('PIN: $zip');

    if (lines.isEmpty) {
      return Text(
        'No address info',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (l) => Text(
              l,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          )
          .toList(),
    );
  }
}

/* ===========================
   MODELS
   =========================== */

class ShopifyOrderGroup {
  final ShopifyOrder order;
  final List<ShopifyOrderItem> items;

  ShopifyOrderGroup({
    required this.order,
    required this.items,
  });

  factory ShopifyOrderGroup.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'] as Map<String, dynamic>? ?? {};
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return ShopifyOrderGroup(
      order: ShopifyOrder.fromJson(orderJson),
      items: itemsJson
          .map((e) => ShopifyOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShopifyOrder {
  final Map<String, dynamic> rawMap;

  final int? id;
  final String? orderNumber;
  final String? name;
  final String? email;
  final String? phone;
  final String? financialStatus;
  final String? fulfillmentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final String? currency;
  final double? totalPrice;
  final double? subtotalPrice;
  final double? totalTax;
  final double? totalDiscounts;
  final double? totalShipping;
  final String? orderTags;
  final int? customerId;
  final String? customerEmail;
  final String? customerTags;
  final String? utmSource;
  final String? utmCampaign;
  final String? utmMedium;
  final String? utmContent;
  final String? utmTerm;
  final String? paymentGateway;
  final String? billingCity;
  final String? billingProvince;
  final String? billingCountry;
  final String? billingZip;
  final String? shippingCity;
  final String? shippingProvince;
  final String? shippingCountry;
  final String? shippingZip;
  final DateTime? syncedAt;

  ShopifyOrder({
    required this.rawMap,
    this.id,
    this.orderNumber,
    this.name,
    this.email,
    this.phone,
    this.financialStatus,
    this.fulfillmentStatus,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.currency,
    this.totalPrice,
    this.subtotalPrice,
    this.totalTax,
    this.totalDiscounts,
    this.totalShipping,
    this.orderTags,
    this.customerId,
    this.customerEmail,
    this.customerTags,
    this.utmSource,
    this.utmCampaign,
    this.utmMedium,
    this.utmContent,
    this.utmTerm,
    this.paymentGateway,
    this.billingCity,
    this.billingProvince,
    this.billingCountry,
    this.billingZip,
    this.shippingCity,
    this.shippingProvince,
    this.shippingCountry,
    this.shippingZip,
    this.syncedAt,
  });

  factory ShopifyOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return ShopifyOrder(
      rawMap: json,
      id: parseInt(json['id']),
      orderNumber: json['order_number']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      financialStatus: json['financial_status']?.toString(),
      fulfillmentStatus: json['fulfillment_status']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      closedAt: parseDate(json['closed_at']),
      currency: json['currency']?.toString(),
      totalPrice: parseDouble(json['total_price']),
      subtotalPrice: parseDouble(json['subtotal_price']),
      totalTax: parseDouble(json['total_tax']),
      totalDiscounts: parseDouble(json['total_discounts']),
      totalShipping: parseDouble(json['total_shipping']),
      orderTags: json['order_tags']?.toString(),
      customerId: parseInt(json['customer_id']),
      customerEmail: json['customer_email']?.toString(),
      customerTags: json['customer_tags']?.toString(),
      utmSource: json['utm_source']?.toString(),
      utmCampaign: json['utm_campaign']?.toString(),
      utmMedium: json['utm_medium']?.toString(),
      utmContent: json['utm_content']?.toString(),
      utmTerm: json['utm_term']?.toString(),
      paymentGateway: json['payment_gateway']?.toString(),
      billingCity: json['billing_city']?.toString(),
      billingProvince: json['billing_province']?.toString(),
      billingCountry: json['billing_country']?.toString(),
      billingZip: json['billing_zip']?.toString(),
      shippingCity: json['shipping_city']?.toString(),
      shippingProvince: json['shipping_province']?.toString(),
      shippingCountry: json['shipping_country']?.toString(),
      shippingZip: json['shipping_zip']?.toString(),
      syncedAt: parseDate(json['synced_at']),
    );
  }
}

class ShopifyOrderItem {
  final Map<String, dynamic> rawMap;

  final int? id;
  final int? orderId;
  final int? productId;
  final int? variantId;
  final String? sku;
  final String? name;
  final String? title;
  final String? variantTitle;
  final String? vendor;
  final int? quantity;
  final double? price;
  final double? totalDiscount;
  final String? fulfillmentStatus;

  ShopifyOrderItem({
    required this.rawMap,
    this.id,
    this.orderId,
    this.productId,
    this.variantId,
    this.sku,
    this.name,
    this.title,
    this.variantTitle,
    this.vendor,
    this.quantity,
    this.price,
    this.totalDiscount,
    this.fulfillmentStatus,
  });

  factory ShopifyOrderItem.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ShopifyOrderItem(
      rawMap: json,
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']),
      productId: parseInt(json['product_id']),
      variantId: parseInt(json['variant_id']),
      sku: json['sku']?.toString(),
      name: json['name']?.toString(),
      title: json['title']?.toString(),
      variantTitle: json['variant_title']?.toString(),
      vendor: json['vendor']?.toString(),
      quantity: parseInt(json['quantity']),
      price: parseDouble(json['price']),
      totalDiscount: parseDouble(json['total_discount']),
      fulfillmentStatus: json['fulfillment_status']?.toString(),
    );
  }
}
