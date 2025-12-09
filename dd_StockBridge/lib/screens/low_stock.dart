import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;



const String kCriticalStockApiUrl =
    "https://customprint.deodap.com/stockbridge/get_low_stock.php";

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  // Filters
  final TextEditingController _searchController = TextEditingController();
  int _selectedDays = 7; // 1 = per day, 7, 30
  double _minAvgPerDay = 0; // optional filter

  // Pagination
  int _page = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isMoreLoading = false;
  String? _errorMessage;

  // Data
  final List<CriticalStockItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchData(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool reset = false}) async {
    if (_isLoading || _isMoreLoading) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _totalPages = 1;
        _items.clear();
      });
    } else {
      if (_page >= _totalPages) return;
      setState(() {
        _isMoreLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final queryParams = {
        'days': _selectedDays.toString(),
        'page': _page.toString(),
        'min_avg_per_day': _minAvgPerDay.toString(),
      };

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(kCriticalStockApiUrl).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final Map<String, dynamic> jsonBody = json.decode(response.body);

      if (jsonBody['success'] != true) {
        throw Exception(jsonBody['error'] ?? 'Unknown API error');
      }

      final int newPage = (jsonBody['page'] ?? 1) as int;
      final int totalPages = (jsonBody['total_pages'] ?? 1) as int;
      final List<dynamic> data = (jsonBody['data'] ?? []) as List<dynamic>;

      final List<CriticalStockItem> fetched = data
          .map((e) => CriticalStockItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _page = newPage;
        _totalPages = totalPages;
        _items.addAll(fetched);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (reset) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isMoreLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchData(reset: true);
  }

  void _onApplyFilters() {
    _fetchData(reset: true);
  }

  void _loadMore() {
    if (_page < _totalPages && !_isMoreLoading) {
      setState(() {
        _page += 1;
      });
      _fetchData(reset: false);
    }
  }

  String _daysLabel(int days) {
    switch (days) {
      case 1:
        return "Per day";
      case 7:
        return "Last 7 days";
      case 30:
        return "Last 30 days";
      default:
        return "$days days";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: CupertinoNavigationBarBackButton(
          color: theme.colorScheme.primary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Critical Stock',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFiltersCard(context),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _onApplyFilters(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Search by SKU code / name",
              hintStyle: GoogleFonts.poppins(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDaysDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMinAvgPerDayField(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton.filled(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              onPressed: _isLoading ? null : _onApplyFilters,
              child: Text(
                'Get Critical Stock',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Period",
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedDays,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text("Per day"),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text("Last 7 days"),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text("Last 30 days"),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedDays = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinAvgPerDayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Min avg / day",
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: _minAvgPerDay.toStringAsFixed(0),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null && parsed >= 0) {
              setState(() {
                _minAvgPerDay = parsed;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Error",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                onPressed: () => _fetchData(reset: true),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                "No critical SKUs found for this period.",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: _items.length + 1, // +1 for Load More row
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadMoreRow();
          }
          final item = _items[index];
          return _buildStockCard(item);
        },
      ),
    );
  }

  Widget _buildLoadMoreRow() {
    if (_page >= _totalPages) {
      return const SizedBox.shrink();
    }
    if (_isMoreLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: CupertinoButton(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          onPressed: _loadMore,
          child: Text(
            "Load more ($_page / $_totalPages)",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(CriticalStockItem item) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(item),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCardDetails(item),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(CriticalStockItem item) {
    final baseImage = item.baseImage;

    if (baseImage == null || baseImage.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        baseImage,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.image_not_supported_outlined,
            size: 28,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetails(CriticalStockItem item) {
    final daysLabel = _daysLabel(item.daysWindow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.skuCode,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: -4,
          children: [
            _buildChip(
              label: "Stock: ${item.inStock}",
              color: Colors.orange.shade50,
              textColor: Colors.deepOrange,
            ),
            _buildChip(
              label: "$daysLabel: ${item.lastNDaysOrders}",
              color: Colors.blue.shade50,
              textColor: Colors.blue.shade800,
            ),
            _buildChip(
              label: "Avg/day: ${item.avgDailyOrders.toStringAsFixed(1)}",
              color: Colors.teal.shade50,
              textColor: Colors.teal.shade800,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "To purchase:",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              item.purchaseQuantity.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// ---------------------------
/// MODEL
/// ---------------------------
class CriticalStockItem {
  final int id;
  final int warehouseId;
  final int skuId;
  final String skuCode;
  final String name;
  final int inStock;
  final int badStock;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final List<String> images;
  final String? baseImage;

  final int lastNDaysOrders;
  final double avgDailyOrders;
  final int daysWindow;
  final int purchaseQuantity;

  CriticalStockItem({
    required this.id,
    required this.warehouseId,
    required this.skuId,
    required this.skuCode,
    required this.name,
    required this.inStock,
    required this.badStock,
    required this.updatedAt,
    required this.createdAt,
    required this.images,
    required this.baseImage,
    required this.lastNDaysOrders,
    required this.avgDailyOrders,
    required this.daysWindow,
    required this.purchaseQuantity,
  });

  factory CriticalStockItem.fromJson(Map<String, dynamic> json) {
    // Handle images from PHP: images is array of URLs, base_image is single URL
    final List<String> images = [];
    if (json['images'] is List) {
      for (final e in (json['images'] as List)) {
        if (e is String && e.isNotEmpty) {
          images.add(e);
        }
      }
    }

    DateTime? parseDate(val) {
      if (val == null || val.toString().isEmpty) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return CriticalStockItem(
      id: toInt(json['id']),
      warehouseId: toInt(json['warehouse_id']),
      skuId: toInt(json['sku_id']),
      skuCode: json['sku_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      inStock: toInt(json['in_stock']),
      badStock: toInt(json['bad_stock']),
      updatedAt: parseDate(json['updated_at']),
      createdAt: parseDate(json['created_at']),
      images: images,
      baseImage: json['base_image']?.toString(),
      lastNDaysOrders: toInt(json['last_n_days_orders']),
      avgDailyOrders: toDouble(json['avg_daily_orders']),
      daysWindow: toInt(json['days_window']),
      purchaseQuantity: toInt(json['purchase_quantity']),
    );
  }
}
