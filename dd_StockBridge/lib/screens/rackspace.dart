import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Icons, Divider, InkWell, Material, MaterialType;
import 'package:http/http.dart' as http;

/// ===============================
/// CONFIG
/// ===============================
const _rackBaseUrl = 'https://client.omsguru.com/order_api/rack_wise_stock';
const _warehouseId = '7208';
const _bearer = '7DOHq0j6dbfNKYWIzyGBJtlEZaosxiUm';
const _omsCid = '33532';

/// Your PHP search API
const _searchBaseUrl =
    'https://customprint.deodap.com/stockbridge/all_data_fetch.php';

/// ===============================
/// MAIN SCREEN
/// ===============================
class OmsRackWiseStockPage extends StatefulWidget {
  final String? initialSkuId;
  final String? initialSkuCode;
  final String? initialSkuName;

  const OmsRackWiseStockPage({
    this.initialSkuId,
    this.initialSkuCode,
    this.initialSkuName,
    super.key,
  });

  @override
  State<OmsRackWiseStockPage> createState() => _OmsRackWiseStockPageState();
}
class _OmsRackWiseStockPageState extends State<OmsRackWiseStockPage> {
  final List<RackItem> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _errorText = '';
  int _cursor = 0;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFirstPage();

    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchFirstPage() async {
    setState(() {
      _initialLoading = true;
      _errorText = '';
      _cursor = 0;
      _items.clear();
      _hasMore = true;
    });

    try {
      final page = await _fetchPage(_cursor);
      setState(() {
        _items.addAll(page);
        _initialLoading = false;
        _hasMore = page.isNotEmpty;
        if (_items.isNotEmpty) {
          _cursor = _nextCursorFrom(_items.last);
        }
      });
    } catch (e) {
      setState(() {
        _initialLoading = false;
        _errorText = e.toString();
      });
    }
  }

  Future<void> _pullToRefresh() async {
    await _fetchFirstPage();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading) return;

    setState(() => _loadingMore = true);
    try {
      final page = await _fetchPage(_cursor);
      setState(() {
        _items.addAll(page);
        _hasMore = page.isNotEmpty;
        if (_items.isNotEmpty) {
          _cursor = _nextCursorFrom(_items.last);
        }
      });
    } catch (e) {
      _showCupertinoToast(context, 'Load more failed: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  int _nextCursorFrom(RackItem last) {
    return last.idAsInt ?? 0;
  }

  Future<List<RackItem>> _fetchPage(int lastId) async {
    final params = {
      'last_id': lastId.toString(),
      'warehouse_id': _warehouseId,
    };

    final uri = Uri.parse(_rackBaseUrl).replace(queryParameters: params);

    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_bearer',
        'oms-cid': _omsCid,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final jsonBody = json.decode(res.body) as Map<String, dynamic>;
    if (jsonBody['error'] != 0) {
      throw Exception('API Error: ${jsonBody['message'] ?? 'unknown'}');
    }

    final list = (jsonBody['data'] as List?) ?? [];
    return list
        .map((e) => RackItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _onItemTap(RackItem item) {
    if (item.skuId == null || item.skuId!.isEmpty) {
      _showCupertinoToast(context, 'SKU ID not available');
      return;
    }
    _openSkuDetailsPopup(
      skuId: item.skuId!,
      skuCode: item.skuCode,
      skuName: null, // we don't have name from this API
    );
  }

  void _openSkuDetailsPopup({
    required String skuId,
    String? skuCode,
    String? skuName,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => SkuDetailsSheetWrapper(
        skuId: skuId,
        skuCode: skuCode,
        skuName: skuName,
      ),
    );
  }

  void _openSearchPage() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (ctx) => SkuSearchPage(
          onSelectSku: (skuId, skuCode, skuName) {
            Navigator.of(ctx).pop(); // close search page
            _openSkuDetailsPopup(
              skuId: skuId,
              skuCode: skuCode,
              skuName: skuName,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Rack-wise Stock',
          style: TextStyle(decoration: TextDecoration.none),
        ),
        border: null, // remove underline
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _openSearchPage,
          child: const Icon(CupertinoIcons.search),
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: _initialLoading
            ? const _InitialLoader()
            : _errorText.isNotEmpty
                ? _ErrorView(
                    message: _errorText,
                    onRetry: _fetchFirstPage,
                  )
                : CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: _pullToRefresh,
                      ),

                      // Section header
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Text(
                            'ALL RACKS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      // List
                      SliverList.separated(
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            return const SizedBox.shrink();
                          }
                          final it = _items[index];
                          return _RackItemTile(
                            item: it,
                            onTap: () => _onItemTap(it),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const Divider(height: 0, indent: 16),
                        itemCount: _items.length,
                      ),

                      // Footer / loaders
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            children: [
                              if (_loadingMore)
                                const CupertinoActivityIndicator(),
                              if (!_hasMore && _items.isNotEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    'No more results',
                                    style: TextStyle(
                                      color: CupertinoColors.inactiveGray,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              if (_items.isEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        CupertinoIcons.tray,
                                        size: 48,
                                        color: CupertinoColors.inactiveGray,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No data available',
                                        style: TextStyle(
                                          color: CupertinoColors
                                              .inactiveGray,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
      ),
    );
  }

  void _showCupertinoToast(BuildContext context, String msg) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          'Notice',
          style: TextStyle(decoration: TextDecoration.none),
        ),
        content: Text(
          msg,
          style: const TextStyle(decoration: TextDecoration.none),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// SEARCH PAGE (uses PHP API)
/// ===============================

typedef OnSelectSkuCallback = void Function(
  String skuId,
  String? skuCode,
  String? skuName,
);

class SkuSearchPage extends StatefulWidget {
  final OnSelectSkuCallback onSelectSku;

  const SkuSearchPage({
    required this.onSelectSku,
    super.key,
  });

  @override
  State<SkuSearchPage> createState() => _SkuSearchPageState();
}

class _SkuSearchPageState extends State<SkuSearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String _errorText = '';
  List<StockSearchItem> _results = [];

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _errorText = '';
      _results = [];
    });

    try {
      final uri = Uri.parse(_searchBaseUrl)
          .replace(queryParameters: {'search': query});

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final jsonBody = json.decode(res.body) as Map<String, dynamic>;
      final success = jsonBody['success'] == true;

      if (!success) {
        throw Exception(
            'API Error: ${jsonBody['error'] ?? jsonBody['message'] ?? 'unknown'}');
      }

      final list = (jsonBody['data'] as List?) ?? [];
      final items = list
          .map((e) => StockSearchItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _results = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  void _onResultTap(StockSearchItem item) {
    if (item.skuId == null || item.skuId!.isEmpty) {
      return;
    }
    widget.onSelectSku(
      item.skuId!,
      item.skuCode,
      item.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        border: null,
        middle: const Text(
          'Search SKU',
          style: TextStyle(decoration: TextDecoration.none),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _controller,
                      placeholder:
                          'Search by SKU code or name',
                      clearButtonMode:
                          OverlayVisibilityMode.editing,
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    onPressed: _runSearch,
                    child: const Text(
                      'Search',
                      style: TextStyle(decoration: TextDecoration.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const _InitialLoader()
                  : _errorText.isNotEmpty
                      ? _ErrorView(
                          message: _errorText,
                          onRetry: _runSearch,
                        )
                      : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'No results',
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 0, indent: 16),
                              itemBuilder: (ctx, index) {
                                final item = _results[index];
                                return _SearchResultTile(
                                  item: item,
                                  onTap: () => _onResultTap(item),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final StockSearchItem item;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skuCode = item.skuCode ?? '-';
    final name = (item.name?.isNotEmpty ?? false)
        ? item.name!
        : '(No name)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.cube_box,
                    size: 22,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          skuCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors
                                .secondaryLabel,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'SKU ID: ${item.skuId ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors
                                    .tertiaryLabel,
                                decoration:
                                    TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'In stock: ${item.inStock ?? '0'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors
                                    .tertiaryLabel,
                                decoration:
                                    TextDecoration.none,
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
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// SKU DETAILS SHEET WRAPPER (POPUP)
/// ===============================
class SkuDetailsSheetWrapper extends StatelessWidget {
  final String skuId;
  final String? skuCode;
  final String? skuName;

  const SkuDetailsSheetWrapper({
    required this.skuId,
    this.skuCode,
    this.skuName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: CupertinoColors.black.withOpacity(0.3),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // absorb sheet taps
              child: CupertinoPopupSurface(
                isSurfacePainted: true,
                child: SizedBox(
                  height: height,
                  child: SkuDetailsPage(
                    skuId: skuId,
                    skuCode: skuCode,
                    skuName: skuName,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// SKU DETAILS SCREEN (inside popup)
/// ===============================
class SkuDetailsPage extends StatefulWidget {
  final String skuId;
  final String? skuCode;
  final String? skuName;

  const SkuDetailsPage({
    required this.skuId,
    this.skuCode,
    this.skuName,
    super.key,
  });

  @override
  State<SkuDetailsPage> createState() => _SkuDetailsPageState();
}

class _SkuDetailsPageState extends State<SkuDetailsPage> {
  List<RackItem> _details = [];
  bool _loading = true;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _fetchSkuDetails();
  }

  Future<void> _fetchSkuDetails() async {
    setState(() {
      _loading = true;
      _errorText = '';
    });

    try {
      final params = {
        'last_id': '0',
        'warehouse_id': _warehouseId,
        'sku_ids': widget.skuId,
      };

      final uri = Uri.parse(_rackBaseUrl).replace(queryParameters: params);

      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_bearer',
          'oms-cid': _omsCid,
        },
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final jsonBody = json.decode(res.body) as Map<String, dynamic>;
      if (jsonBody['error'] != 0) {
        throw Exception('API Error: ${jsonBody['message'] ?? 'unknown'}');
      }

      final list = (jsonBody['data'] as List?) ?? [];
      final items = list
          .map((e) => RackItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _details = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  int _getTotalInStock() {
    return _details.fold(
      0,
      (sum, item) => sum + (int.tryParse(item.inStock ?? '0') ?? 0),
    );
  }

  int _getTotalBadStock() {
    return _details.fold(
      0,
      (sum, item) => sum + (int.tryParse(item.badStock ?? '0') ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Decide header title
    final String headerTitle;
    if (widget.skuName != null && widget.skuName!.isNotEmpty) {
      headerTitle = widget.skuName!;
    } else if (widget.skuCode != null && widget.skuCode!.isNotEmpty) {
      headerTitle = widget.skuCode!;
    } else if (_details.isNotEmpty &&
        (_details.first.skuCode?.isNotEmpty ?? false)) {
      headerTitle = _details.first.skuCode!;
    } else {
      headerTitle = 'SKU ${widget.skuId}';
    }

    final String subTitle = (widget.skuCode != null &&
            widget.skuCode!.isNotEmpty)
        ? 'SKU ID: ${widget.skuId} • Code: ${widget.skuCode}'
        : 'SKU ID: ${widget.skuId}';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        border: null,
        middle: const Text(
          'SKU Details',
          style: TextStyle(decoration: TextDecoration.none),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Icon(CupertinoIcons.clear),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const _InitialLoader()
            : _errorText.isNotEmpty
                ? _ErrorView(
                    message: _errorText,
                    onRetry: _fetchSkuDetails,
                  )
                : _details.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.tray,
                              size: 48,
                              color: CupertinoColors.inactiveGray,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No details found',
                              style: TextStyle(
                                color:
                                    CupertinoColors.inactiveGray,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CupertinoColors
                                    .secondarySystemGroupedBackground,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors
                                          .secondaryLabel,
                                      decoration:
                                          TextDecoration.none,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SummaryBox(
                                          icon: CupertinoIcons
                                              .cube_box_fill,
                                          iconColor: CupertinoColors
                                              .systemGreen,
                                          label: 'Total In Stock',
                                          value: _getTotalInStock()
                                              .toString(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _SummaryBox(
                                          icon: CupertinoIcons
                                              .xmark_octagon_fill,
                                          iconColor: CupertinoColors
                                              .systemRed,
                                          label: 'Total Bad Stock',
                                          value:
                                              _getTotalBadStock()
                                                  .toString(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _SummaryBox(
                                    icon: CupertinoIcons
                                        .location_fill,
                                    iconColor:
                                        CupertinoColors.systemBlue,
                                    label: 'Total Locations',
                                    value: _details.length
                                        .toString(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16, 4, 16, 8),
                              child: Text(
                                'RACK LOCATIONS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors
                                      .secondaryLabel,
                                  letterSpacing: 0.5,
                                  decoration:
                                      TextDecoration.none,
                                ),
                              ),
                            ),
                          ),

                          SliverList.separated(
                            itemCount: _details.length,
                            separatorBuilder: (_, __) =>
                                const Divider(
                                    height: 0, indent: 16),
                            itemBuilder: (context, index) {
                              final item = _details[index];
                              return _DetailItemTile(item: item);
                            },
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
                        ],
                      ),
      ),
    );
  }
}

/// ===============================
/// COMMON WIDGETS
/// ===============================
class _InitialLoader extends StatelessWidget {
  const _InitialLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(radius: 14),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 38,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(decoration: TextDecoration.none),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _RackItemTile extends StatelessWidget {
  final RackItem item;
  final VoidCallback onTap;

  const _RackItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (item.skuCode?.isNotEmpty ?? false)
        ? item.skuCode!
        : 'SKU: ${item.skuId}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CupertinoListTile.notched(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          additionalInfo: Text(
            '#${item.id ?? '-'}',
            style: const TextStyle(decoration: TextDecoration.none),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SKU ID: ${item.skuId ?? '-'}',
                style: const TextStyle(decoration: TextDecoration.none),
              ),
              Text(
                'Rack: ${item.rackSpaceId ?? '-'}'
                '${item.rackSpaceName != null ? ' (${item.rackSpaceName})' : ''}',
                style: const TextStyle(decoration: TextDecoration.none),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.cube_box,
                    size: 12,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.inStock ?? '0',
                    style: const TextStyle(decoration: TextDecoration.none),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    CupertinoIcons.xmark_octagon,
                    size: 12,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.badStock ?? '0',
                    style: const TextStyle(decoration: TextDecoration.none),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_forward,
            size: 18,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DetailItemTile extends StatelessWidget {
  final RackItem item;

  const _DetailItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasStock =
        (int.tryParse(item.inStock ?? '0') ?? 0) > 0 ||
            (int.tryParse(item.badStock ?? '0') ?? 0) > 0;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasStock
                      ? CupertinoColors.systemGreen.withOpacity(0.1)
                      : CupertinoColors.systemGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.location_solid,
                  size: 20,
                  color: hasStock
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.rackSpaceName ??
                                'Rack ${item.rackSpaceId ?? '-'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Text(
                          '#${item.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.tertiaryLabel,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rack ID: ${item.rackSpaceId ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color:
                            CupertinoColors.secondaryLabel,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StockBadge(
                          icon: CupertinoIcons.cube_box_fill,
                          label: 'In Stock',
                          value: item.inStock ?? '0',
                          color: CupertinoColors.systemGreen,
                        ),
                        const SizedBox(width: 12),
                        _StockBadge(
                          icon: CupertinoIcons
                              .xmark_octagon_fill,
                          label: 'Bad Stock',
                          value: item.badStock ?? '0',
                          color: CupertinoColors.systemRed,
                        ),
                      ],
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

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StockBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? additionalInfo;
  final VoidCallback? onTap;

  const CupertinoListTile.notched({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.additionalInfo,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 16,
            color: CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
          child: title,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
              decoration: TextDecoration.none,
            ),
            child: subtitle!,
          ),
        ]
      ],
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(child: content),
              if (additionalInfo != null) ...[
                const SizedBox(width: 8),
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.tertiaryLabel,
                    decoration: TextDecoration.none,
                  ),
                  child: additionalInfo!,
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// MODELS
/// ===============================
class RackItem {
  final String? id;
  final String? skuId;
  final String? skuCode;
  final String? warehouseId;
  final String? rackSpaceId;
  final String? rackSpaceName;
  final String? inStock;
  final String? badStock;

  const RackItem({
    this.id,
    this.skuId,
    this.skuCode,
    this.warehouseId,
    this.rackSpaceId,
    this.rackSpaceName,
    this.inStock,
    this.badStock,
  });

  int? get idAsInt => _toIntOrNull(id);
  int? get skuIdAsInt => _toIntOrNull(skuId);

  static int? _toIntOrNull(String? v) {
    if (v == null) return null;
    return int.tryParse(v);
  }

  factory RackItem.fromJson(Map<String, dynamic> j) {
    return RackItem(
      id: j['id']?.toString(),
      skuId: j['sku_id']?.toString(),
      skuCode: (j['sku_code'] ?? '').toString(),
      warehouseId: j['warehouse_id']?.toString(),
      rackSpaceId: j['rack_space_id']?.toString(),
      rackSpaceName: j['rack_space_name']?.toString(),
      inStock: j['in_stock']?.toString(),
      badStock: j['bad_stock']?.toString(),
    );
  }
}

class StockSearchItem {
  final String? id;
  final String? warehouseId;
  final String? skuId;
  final String? skuCode;
  final String? name;
  final String? blocked;
  final String? inStock;
  final String? badStock;

  const StockSearchItem({
    this.id,
    this.warehouseId,
    this.skuId,
    this.skuCode,
    this.name,
    this.blocked,
    this.inStock,
    this.badStock,
  });

  factory StockSearchItem.fromJson(Map<String, dynamic> j) {
    return StockSearchItem(
      id: j['id']?.toString(),
      warehouseId: j['warehouse_id']?.toString(),
      skuId: j['sku_id']?.toString(),
      skuCode: j['sku_code']?.toString(),
      name: j['name']?.toString(),
      blocked: j['blocked']?.toString(),
      inStock: j['in_stock']?.toString(),
      badStock: j['bad_stock']?.toString(),
    );
  }
}
