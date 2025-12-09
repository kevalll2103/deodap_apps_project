// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------
/// CONFIG - update these
/// ---------------------------
const String PHP_STOCK_URL =
    "https://customprint.deodap.com/stockbridge/get_oms_stock.php";

const String OMS_RACKWISE_BASE =
    "https://client.omsguru.com/order_api/rack_wise_stock";

const Map<String, String> OMS_HEADERS = {
  "Accept": "application/json",
  "oms-cid": "33532",
  // TODO: replace with actual Bearer token
  "Authorization": "Bearer 7DOHq0j6dbfNKYWIzyGBJtlEZaosxiUm",
};

/// ---------------------------
/// MODELS
/// ---------------------------
class StockSummary {
  final int totalRecords;
  final int totalInStock;
  final int totalBadStock;
  final int grandTotalStock;

  StockSummary({
    required this.totalRecords,
    required this.totalInStock,
    required this.totalBadStock,
    required this.grandTotalStock,
  });

  factory StockSummary.empty() => StockSummary(
        totalRecords: 0,
        totalInStock: 0,
        totalBadStock: 0,
        grandTotalStock: 0,
      );

  factory StockSummary.fromMap(Map<String, dynamic> m) {
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return StockSummary(
      totalRecords: _asInt(m['total_records']),
      totalInStock: _asInt(m['total_in_stock_sum']),
      totalBadStock: _asInt(m['total_bad_stock_sum']),
      grandTotalStock: _asInt(m['grand_total_stock']),
    );
  }
}

class Stock {
  final String id;
  final String warehouseId;
  final String skuId;
  final String skuCode;
  final String name;
  final int inStock;
  final int badStock;
  final int totalStock;
  final String updatedAt;
  final String createdAt;

  // lazy-loaded rack wise info
  List<RackItem>? rackItems;
  bool rackLoading = false;
  String? rackError;

  Stock({
    required this.id,
    required this.warehouseId,
    required this.skuId,
    required this.skuCode,
    required this.name,
    required this.inStock,
    required this.badStock,
    required this.totalStock,
    required this.updatedAt,
    required this.createdAt,
    this.rackItems,
  });

  factory Stock.fromMap(Map<String, dynamic> m) {
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return Stock(
      id: m['id']?.toString() ?? '',
      warehouseId: m['warehouse_id']?.toString() ?? '',
      skuId: m['sku_id']?.toString() ?? '',
      skuCode: m['sku_code']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      inStock: _asInt(m['in_stock']),
      badStock: _asInt(m['bad_stock']),
      totalStock: _asInt(
        m.containsKey('total_stock')
            ? m['total_stock']
            : _asInt(m['in_stock']) + _asInt(m['bad_stock']),
      ),
      updatedAt: m['updated_at']?.toString() ?? '',
      createdAt: m['created_at']?.toString() ?? '',
    );
  }
}

class RackItem {
  final String id;
  final String skuId;
  final String rackSpaceId;
  final String rackSpaceName;
  final int inStock;
  final int badStock;

  RackItem({
    required this.id,
    required this.skuId,
    required this.rackSpaceId,
    required this.rackSpaceName,
    required this.inStock,
    required this.badStock,
  });

  factory RackItem.fromMap(Map<String, dynamic> m) {
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return RackItem(
      id: m['id']?.toString() ?? '',
      skuId: m['sku_id']?.toString() ?? '',
      rackSpaceId: m['rack_space_id']?.toString() ?? '',
      rackSpaceName: m['rack_space_name']?.toString() ?? '',
      inStock: _asInt(m['in_stock']),
      badStock: _asInt(m['bad_stock']),
    );
  }
}

class StockResult {
  final List<Stock> stocks;
  final StockSummary summary;

  StockResult({required this.stocks, required this.summary});
}

/// ---------------------------
/// API SERVICE
/// ---------------------------
class ApiService {
  static Future<StockResult> fetchStocks({String search = ''}) async {
    final uri = Uri.parse(PHP_STOCK_URL).replace(
      queryParameters: search.isNotEmpty ? {'search': search} : null,
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception("Failed to fetch stocks: ${res.statusCode}");
    }

    final jsonBody = jsonDecode(res.body);
    if (jsonBody == null || jsonBody is! Map) {
      throw Exception("Bad JSON from PHP API");
    }

    final Map body = jsonBody as Map;

    if (body['status'] != true) {
      throw Exception(body['message']?.toString() ?? "PHP API error");
    }

    StockSummary summary = StockSummary.empty();
    if (body['summary'] is Map) {
      summary =
          StockSummary.fromMap(Map<String, dynamic>.from(body['summary']));
    }

    final dataRaw = body['data'];
    if (dataRaw == null) {
      return StockResult(stocks: [], summary: summary);
    }

    if (dataRaw is! List) {
      throw Exception("PHP API: data is not a list");
    }

    final stocks = dataRaw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Stock.fromMap(m);
    }).toList();

    return StockResult(stocks: stocks, summary: summary);
  }

  static Future<List<RackItem>> fetchOmsRackWise({
    required String skuId,
    required String warehouseId,
  }) async {
    final map = {
      'last_id': '0',
      'warehouse_id': warehouseId,
      'sku_ids': skuId,
    };
    final uri = Uri.parse(OMS_RACKWISE_BASE).replace(queryParameters: map);

    final res = await http.get(uri, headers: OMS_HEADERS);
    if (res.statusCode != 200) {
      throw Exception("OMS API error ${res.statusCode}");
    }

    final dynamic jsonBody = jsonDecode(res.body);

    dynamic rawData;

    if (jsonBody is List) {
      rawData = jsonBody;
    } else if (jsonBody is Map<String, dynamic>) {
      final dynamic d = jsonBody['data'];

      if (d is List) {
        rawData = d;
      } else if (d is String) {
        try {
          final parsed = jsonDecode(d);
          if (parsed is List) {
            rawData = parsed;
          } else {
            rawData = <dynamic>[];
          }
        } catch (_) {
          rawData = <dynamic>[];
        }
      } else {
        rawData = <dynamic>[];
      }
    } else {
      rawData = <dynamic>[];
    }

    final list = <RackItem>[];
    if (rawData is List) {
      for (final e in rawData) {
        if (e is Map) {
          list.add(RackItem.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    return list;
  }
}

/// ---------------------------
/// MAIN APP (iOS style)
/// ---------------------------
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock with RackWise',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: const StockHomePage(),
    );
  }
}

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  List<Stock> _allStocks = [];
  List<Stock> _visibleStocks = [];
  StockSummary? _summary;

  bool _loading = false;
  String? _error;

  final int _pageSize = 50;
  int _currentPage = 0;
  bool _hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _showSearch = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _loadMorePage();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial({String search = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
      _allStocks = [];
      _visibleStocks = [];
      _currentPage = 0;
      _hasMore = true;
      _summary = null;
    });

    try {
      final result = await ApiService.fetchStocks(search: search);
      setState(() {
        _allStocks = result.stocks;
        _summary = result.summary;
      });
      _loadMorePage();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _loadMorePage() {
    if (!_hasMore) return;
    final start = _currentPage * _pageSize;
    if (start >= _allStocks.length) {
      setState(() => _hasMore = false);
      return;
    }
    final end = (start + _pageSize) > _allStocks.length
        ? _allStocks.length
        : (start + _pageSize);
    final nextChunk = _allStocks.sublist(start, end);
    setState(() {
      _visibleStocks.addAll(nextChunk);
      _currentPage += 1;
      if (_visibleStocks.length >= _allStocks.length) _hasMore = false;
    });
  }

  Future<void> _onRefresh() async {
    await _loadInitial(search: _searchController.text.trim());
  }

  void _onSearchChanged(String q) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadInitial(search: q.trim());
    });
  }

  int _rackInTotal(Stock s) {
    if (s.rackItems == null || s.rackItems!.isEmpty) return s.inStock;
    return s.rackItems!.fold<int>(0, (sum, r) => sum + r.inStock);
  }

  int _rackBadTotal(Stock s) {
    if (s.rackItems == null || s.rackItems!.isEmpty) return s.badStock;
    return s.rackItems!.fold<int>(0, (sum, r) => sum + r.badStock);
  }

  int _rackGrandTotal(Stock s) {
    final inT = _rackInTotal(s);
    final badT = _rackBadTotal(s);
    return inT + badT;
  }

  Future<void> _ensureRackLoaded(Stock stock) async {
    if (stock.rackItems != null && stock.rackItems!.isNotEmpty) return;

    setState(() {
      stock.rackLoading = true;
      stock.rackError = null;
    });

    try {
      final racks = await ApiService.fetchOmsRackWise(
        skuId: stock.skuId,
        warehouseId: stock.warehouseId,
      );
      setState(() {
        stock.rackItems = racks;
      });
    } catch (e) {
      setState(() {
        stock.rackError = e.toString();
      });
    } finally {
      setState(() {
        stock.rackLoading = false;
      });
    }
  }

  Future<void> _openRackSheet(Stock s) async {
    await _ensureRackLoaded(s);
    if (!mounted) return;

    final racks = s.rackItems ?? [];
    final inT = _rackInTotal(s);
    final badT = _rackBadTotal(s);
    final totalT = _rackGrandTotal(s);

    final media = MediaQuery.of(context);
    final double sheetHeight =
        math.min(media.size.height * 0.55, 420); // smaller popup height

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return CupertinoPopupSurface(
          isSurfacePainted: true,
          child: SafeArea(
            top: false,
            child: Container(
              height: sheetHeight,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
              ),
              child: Column(
                children: [
                  // Grab handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.skuCode.isNotEmpty ? s.skuCode : s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: CupertinoColors.label,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU ID: ${s.skuId} • WH: ${s.warehouseId}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 28,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 22,
                          color: CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Rack-wise Summary Box
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rack-wise Summary',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.secondaryLabel,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'In: $inT  •  Bad: $badT  •  Total: $totalT',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: s.rackLoading
                        ? const Center(child: CupertinoActivityIndicator())
                        : s.rackError != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons
                                          .exclamationmark_triangle_fill,
                                      color: CupertinoColors.systemRed,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading racks',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.systemRed,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.rackError ?? 'Unknown error',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color:
                                            CupertinoColors.secondaryLabel,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : racks.isEmpty
                                ? Center(
                                    child: Text(
                                      'No rack-wise data found.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color:
                                            CupertinoColors.secondaryLabel,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(top: 4),
                                    itemCount: racks.length,
                                    separatorBuilder: (_, __) => Container(
                                      height: 0.5,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      color: CupertinoColors.systemGrey4,
                                    ),
                                    itemBuilder: (_, index) {
                                      final r = racks[index];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.rackSpaceName.isNotEmpty
                                                  ? r.rackSpaceName
                                                  : 'Rack: ${r.rackSpaceId}',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: CupertinoColors.label,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'In: ${r.inStock}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: CupertinoColors
                                                      .secondaryLabel,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                              ),
                                              Text(
                                                'Bad: ${r.badStock}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: CupertinoColors
                                                      .secondaryLabel,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      borderRadius: BorderRadius.circular(12),
                      color: CupertinoColors.systemBlue,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockTile(Stock s) {
    final inT = _rackInTotal(s);
    final badT = _rackBadTotal(s);
    final totalT = _rackGrandTotal(s);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + counters
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.skuCode.isNotEmpty ? s.skuCode : s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: CupertinoColors.label,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'In: $inT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    'Bad: $badT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    'Tot: $totalT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SKU ID: ${s.skuId}   •   WH: ${s.warehouseId}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Updated: ${s.updatedAt}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CupertinoColors.systemGrey2,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minSize: 26,
              borderRadius: BorderRadius.circular(999),
              color: CupertinoColors.systemBlue.withOpacity(0.12),
              disabledColor: CupertinoColors.systemGrey5,
              onPressed: s.rackLoading ? null : () => _openRackSheet(s),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.square_stack_3d_up,
                    size: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.rackLoading ? "Loading..." : "Rack-wise",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemBlue,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _visibleStocks.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 32,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 10),
              Text(
                'Something went wrong',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 14),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                borderRadius: BorderRadius.circular(12),
                onPressed: _onRefresh,
                child: Text(
                  "Retry",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _visibleStocks.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _visibleStocks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        final s = _visibleStocks[index];
        return _buildStockTile(s);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalShown = _visibleStocks.length;
    final summary = _summary ?? StockSummary.empty();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Stock with RackWise",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            decoration: TextDecoration.none,
          ),
        ),
        border: null, // removes bottom hairline for cleaner iOS look
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 30,
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _onSearchChanged('');
                  }
                });
              },
              child: const Icon(
                CupertinoIcons.search,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 30,
              onPressed: _onRefresh,
              child: const Icon(
                CupertinoIcons.refresh,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_showSearch)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  placeholder: 'Search by sku_code or name',
                ),
              ),
            // Summary pill
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total SKUs: ${summary.totalRecords}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'In: ${summary.totalInStock}   •   Bad: ${summary.totalBadStock}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Grand Tot: ${summary.grandTotalStock}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Shown: $totalShown',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
