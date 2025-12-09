// lib/low_stock_alerts_screen.dart
// iOS-polished Low Stock Alerts with Google Fonts
// - Real iOS large-title nav bar (CupertinoSliverNavigationBar)
// - Google Fonts integration for better typography
// - iOS-style popup dialog with total count display
// - Filter location UI with iOS design patterns
// - Removed text decoration/underline from all text elements
// - Tighter list layout (smaller gaps between cards)
// - Full-screen iOS sheet for Items (bigger height/width)
// - Cleaner, denser cards with less outer padding, no extra space
// - Fixed update and outward functionality with proper error handling

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider, BoxShadow, CircleAvatar, InkWell, Material;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_filter_service.dart';

/// ===== API CONFIG =====
const String _baseUrl = 'https://api.vacalvers.com/api-wms-app';
const String _appId   = '1';
const String _apiKey  = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

/// ===== Update API Integration =====
Future<Map<String, dynamic>> _processUpdate({
  required String productId,
  required int addStock,
  required String newSubLoc,
  required int newThreshold,
  required String token,
}) async {
  try {
    final uri = Uri.parse('$_baseUrl/catalog_products/update');
    final body = jsonEncode({
      'app_id': _appId,
      'api_key': _apiKey,
      'token': token,
      'product_id': productId,
      'add_stock': addStock,
      'new_stock_physical_sub_location': newSubLoc,
      'new_stock_reserve_threshold': newThreshold,
    });

    print('DEBUG: Update API URL: $uri');
    print('DEBUG: Update API Body: $body');

    final res = await http.post(
      uri,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: body,
    );

    print('DEBUG: Update API Status: ${res.statusCode}');
    print('DEBUG: Update API Response: ${res.body}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      if (responseData['status_flag'] == 1) {
        return {
          'success': true,
          'message': responseData['status_messages']?.first ?? 'Product updated successfully',
          'data': responseData['data'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': responseData['status_messages']?.first ?? 'Failed to update product',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'HTTP ${res.statusCode}: ${res.reasonPhrase}',
      };
    }
  } catch (e) {
    print('DEBUG: Update API Exception: $e');
    return {
      'success': false,
      'message': 'Network error: ${e.toString()}',
    };
  }
}

/// ===== Outward API Integration =====
Future<Map<String, dynamic>> _processOutward({
  required String productId,
  required int quantity,
  required String remarks,
  required List<File> images,
  required String token,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/catalog_products/outward'),
    );

    // Add form fields
    request.fields['app_id'] = _appId;
    request.fields['api_key'] = _apiKey;
    request.fields['token'] = token;
    request.fields['product_id'] = productId;
    request.fields['qty'] = quantity.toString();
    request.fields['remarks'] = remarks;

    print('DEBUG: Outward API URL: ${request.url}');
    print('DEBUG: Outward API Fields: ${request.fields}');

    // Add images (optional, max 2)
    for (int i = 0; i < images.length && i < 2; i++) {
      final imageFile = images[i];
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image_${i + 1}',
        stream,
        length,
        filename: 'outward_image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);
      print('DEBUG: Added image ${i + 1}: ${imageFile.path}');
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final responseData = jsonDecode(responseBody);

    print('DEBUG: Outward API Status: ${response.statusCode}');
    print('DEBUG: Outward API Response: $responseBody');

    if (response.statusCode == 200 && responseData['status_flag'] == 1) {
      return {
        'success': true,
        'message': responseData['status_messages']?.first ?? 'Outward processed successfully',
        'data': responseData['data'] ?? {},
      };
    } else {
      return {
        'success': false,
        'message': responseData['status_messages']?.first ?? 'Failed to process outward',
      };
    }
  } catch (e) {
    print('DEBUG: Outward API Exception: $e');
    return {
      'success': false,
      'message': 'Network error: ${e.toString()}',
    };
  }
}

/// ===== Brand palette =====
const Color _brandPrimary = Color(0xFF6B52A3);
const Color _brandLight   = Color(0xFF8B7AB8);
const Color _cardBg       = Color(0xFFFFFFFF);
const Color _screenBg     = Color(0xFFF2F2F7);
const Color _successGreen = Color(0xFF34C759);
const Color _warningOrange = Color(0xFFFF9500);
const Color _dangerRed = Color(0xFFFF3B30);
const Color _infoBlue = Color(0xFF007AFF);

class LowStockAlertsScreen extends StatefulWidget {
  const LowStockAlertsScreen({super.key});
  @override
  State<LowStockAlertsScreen> createState() => _LowStockAlertsScreenState();
}

class _LowStockAlertsScreenState extends State<LowStockAlertsScreen> {
  TextStyle _t({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? CupertinoColors.label,
      height: height ?? 1.2,
      decoration: TextDecoration.none,
    );
  }

  // ===== State: alerts list =====
  final List<Map<String, dynamic>> _alerts = [];
  bool _firstLoad = true;
  bool _loadingMore = false;
  bool _hasNext = true;
  int _page = 1;
  static const int _perPage = 150;
  String? _error;
  int? _totalRecords;

  // Auth + saved locations
  String? _token;
  List<String> _savedLocations = []; // from SharedPreferences -> 'stockLocations'

  // ===== Filter Persistence =====
  static const String _lowStockFilterPrefsKey = 'low_stock_filters';
  static const String _lowStockSearchPrefsKey = 'low_stock_search';

  Future<void> _loadPersistedFilters() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final filtersJson = sp.getString(_lowStockFilterPrefsKey);
      if (filtersJson != null) {
        final Map<String, dynamic> filters = jsonDecode(filtersJson);
        // We'll use these when opening item popups
      }

      // Load search text
      final searchText = sp.getString(_lowStockSearchPrefsKey) ?? '';
      if (searchText.isNotEmpty) {
        // We'll use this when opening item popups
      }
    } catch (e) {
      print('Error loading persisted low stock filters: $e');
    }
  }

  Future<void> _saveLowStockFilter(String location, String searchQuery) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final filters = {
        'lastLocation': location,
        'lastSearchQuery': searchQuery,
      };
      await sp.setString(_lowStockFilterPrefsKey, jsonEncode(filters));
      await sp.setString(_lowStockSearchPrefsKey, searchQuery);

      // Also save location to shared service
      await LocationFilterService.saveSelectedLocation(location);
      print('LowStock: Saved location "$location" to shared service');
    } catch (e) {
      print('Error saving low stock filters: $e');
    }
  }

  Future<String> _getLastLocation() async {
    try {
      // Use shared location filter service
      final location = await LocationFilterService.getSelectedLocation();
      print('LowStock: Loaded shared location filter: "$location"');
      return location;
    } catch (e) {
      print('Error getting last location: $e');
    }
    return '';
  }

  Future<String> _getLastSearchQuery() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(_lowStockSearchPrefsKey) ?? '';
    } catch (e) {
      print('Error getting last search query: $e');
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('authToken') ?? '';
    if ((_token ?? '').isEmpty) {
      setState(() {
        _error = 'Missing auth token. Please login again.';
        _firstLoad = false;
      });
      return;
    }

    // Load locations from shared service
    _savedLocations = await LocationFilterService.getAvailableLocations();
    print('LowStock: Loaded ${_savedLocations.length} locations from shared service');

    // Load persisted filters
    await _loadPersistedFilters();

    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _alerts.clear();
      _page = 1;
      _hasNext = true;
      _firstLoad = true;
      _error = null;
      _totalRecords = null;
    });
    await _fetchPage(_page);
    if (mounted) setState(() => _firstLoad = false);
  }

  Future<void> _fetchPage(int page) async {
    if (!_hasNext || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final qp = {
        'app_id': _appId,
        'api_key': _apiKey,
        'token': _token ?? '',
        'paging_items_per_page': '$_perPage',
        'paging_current_page': '$page',
      };
      final uri = Uri.parse('$_baseUrl/stock_alerts/list').replace(queryParameters: qp);
      final res = await http.get(uri, headers: const {'Accept': 'application/json'});
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
      final j = jsonDecode(res.body);

      if (j['status_flag'] != 1) {
        final msg = (j['status_messages'] is List && j['status_messages'].isNotEmpty)
            ? j['status_messages'][0].toString()
            : 'API error';
        throw Exception(msg);
      }

      final List data = (j['data'] ?? []) as List;
      final meta = (j['meta_data']?['paging'] ?? {}) as Map;
      final bool hasNext = meta['has_next_page'] == true;
      final int? total = meta['total_records'] is int
          ? meta['total_records'] as int
          : int.tryParse('${meta['total_records'] ?? ''}');

      setState(() {
        _alerts.addAll(data.cast<Map<String, dynamic>>());
        _hasNext = hasNext;
        _page = page;
        _totalRecords = total ?? _totalRecords;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load alerts: $e');
      _hasNext = false;
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _maybeTriggerLoadMore() {
    if (_hasNext && !_loadingMore) _fetchPage(_page + 1);
  }

  // ===== Google Font iOS-style Popup Dialog with Total Count =====
  Future<void> _showGoogleFontItemPopup({
    required String alertId,
    required String createdAt,
    required String warehouseId,
  }) async {
    String query = '';
    String selectedLocation = '';
    List<Map<String, dynamic>> items = [];
    bool loading = true;
    bool loadingMore = false;
    bool hasNext = true;
    int page = 1;
    String? localError;
    int? totalCount;
    Timer? searchTimer;

    // Load persisted filters for this popup
    selectedLocation = await _getLastLocation();
    query = await _getLastSearchQuery();

    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse('${v ?? 0}') ?? 0;
    }

    Future<void> fetchItemsPage(int pno, {bool reset = false}) async {
      if (loadingMore) return;
      if (reset) {
        items.clear();
        hasNext = true;
        page = 1;
      }
      if (!hasNext) return;

      loadingMore = true;
      try {
        final qp = {
          'app_id': _appId,
          'api_key': _apiKey,
          'token': _token ?? '',
          'stock_alert_id': alertId,
          if (selectedLocation.isNotEmpty) 'filter_physical_location': selectedLocation,
          if (query.trim().isNotEmpty) 'search': query.trim(),
          'paging_items_per_page': '$_perPage',
          'paging_current_page': '$pno',
        };

        print('DEBUG: API Query Parameters: $qp');
        print('DEBUG: Selected Location: "$selectedLocation"');
        final uri = Uri.parse('$_baseUrl/stock_alerts/items').replace(queryParameters: qp);
        print('DEBUG: API URL: $uri');
        final res = await http.get(uri, headers: const {'Accept': 'application/json'});
        if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
        final j = jsonDecode(res.body);

        if (j['status_flag'] != 1) {
          final msg = (j['status_messages'] is List && j['status_messages'].isNotEmpty)
              ? j['status_messages'][0].toString()
              : 'API error';
          throw Exception(msg);
        }

        final List data = (j['data'] ?? []) as List;
        final meta = j['meta_data']?['paging'] ?? {};
        hasNext = meta['has_next_page'] == true;
        page = pno;
        totalCount = meta['total_records'] is int
            ? meta['total_records'] as int
            : int.tryParse('${meta['total_records'] ?? ''}');
        items.addAll(data.cast<Map<String, dynamic>>());
      } catch (e) {
        localError = 'Failed to load items: $e';
        hasNext = false;
      } finally {
        loadingMore = false;
      }
    }

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        // First load
        fetchItemsPage(1).then((_) {
          loading = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        });

        return LayoutBuilder(
          builder: (ctx, _) {
            final mq = MediaQuery.of(ctx);
            final sheetH = mq.size.height * 0.92;
            final sheetW = mq.size.width * 0.98;

            return SafeArea(
              top: false,
              child: Center(
                child: Container(
                  height: sheetH,
                  width: sheetW,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(ctx),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: StatefulBuilder(
                    builder: (ctx, setSheet) {
                      final filtered = query.trim().isEmpty
                          ? items
                          : items.where((e) => (e['sku'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(query.toLowerCase())).toList();

                      Future<void> loadMore() async {
                        if (hasNext && !loadingMore) {
                          await fetchItemsPage(page + 1);
                          setSheet(() {});
                        }
                      }

                      Future<void> chooseLocation() async {
                        await _showGoogleFontLocationPicker(
                          context: ctx,
                          title: 'Select Location',
                          items: ['', ..._savedLocations],
                          labels: const ['All Locations'],
                          selected: selectedLocation,
                          onSelect: (val) async {
                            selectedLocation = val;
                            // Save selected location
                            await _saveLowStockFilter(val, query);
                            setSheet(() {
                              loading = true;
                            });
                            await fetchItemsPage(1, reset: true);
                            setSheet(() {
                              loading = false;
                            });
                          },
                        );
                      }

                      return CupertinoPageScaffold(
                        navigationBar: CupertinoNavigationBar(
                          backgroundColor: CupertinoColors.systemBackground.withOpacity(0.96),
                          middle: Text(
                            'Alert #$alertId',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(ctx),
                            child: const Icon(CupertinoIcons.xmark_circle_fill, size: 26, color: CupertinoColors.systemGrey),
                          ),
                          border: null,
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // Total Count Display with Google Fonts
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_brandPrimary.withOpacity(0.1), _brandLight.withOpacity(0.1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _brandPrimary.withOpacity(0.2), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.cube_box_fill, color: _brandPrimary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        totalCount != null ? '$totalCount Total Items' : 'Loading...',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _brandPrimary,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    if (selectedLocation.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _brandPrimary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          selectedLocation,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _brandPrimary,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Search and Filter UI
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CupertinoTextField(
                                        placeholder: 'Search by SKU or name',
                                        placeholderStyle: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: CupertinoColors.placeholderText,
                                          decoration: TextDecoration.none,
                                        ),
                                        prefix: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Icon(CupertinoIcons.search, size: 18, color: Color(0xFF6B7280)),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        onChanged: (v) {
                                          setSheet(() {
                                            query = v;
                                            // Save search query
                                            _saveLowStockFilter(selectedLocation, v);
                                            // Debounced search
                                            searchTimer?.cancel();
                                            searchTimer = Timer(const Duration(milliseconds: 500), () {
                                              fetchItemsPage(1, reset: true);
                                              setSheet(() {});
                                            });
                                          });
                                        },
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        clearButtonMode: OverlayVisibilityMode.editing,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      onPressed: chooseLocation,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_brandPrimary, _brandLight],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(CupertinoIcons.location_solid, size: 14, color: CupertinoColors.white),
                                            const SizedBox(width: 6),
                                            Text(
                                              selectedLocation.isEmpty ? 'Filter' : selectedLocation,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: CupertinoColors.white,
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

                              if (localError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    localError!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: CupertinoColors.systemRed,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),

                              Expanded(
                                child: loading
                                    ? const Center(child: CupertinoActivityIndicator())
                                    : (filtered.isEmpty
                                    ? Center(
                                  child: Text(
                                    'No items found',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                )
                                    : NotificationListener<ScrollNotification>(
                                  onNotification: (n) {
                                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 40) {
                                      loadMore();
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                    itemCount: filtered.length + (loadingMore ? 1 : 0),
                                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                                    itemBuilder: (_, i) {
                                      if (i >= filtered.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Center(child: CupertinoActivityIndicator()),
                                        );
                                      }
                                      final m = filtered[i];
                                      final sku = (m['sku'] ?? '').toString();
                                      final stock = _asInt(m['alert_time_stock']);
                                      final thr = _asInt(m['alert_time_threshold']);
                                      final working = _asInt(m['alert_time_working_stock']);
                                      final delta = stock - thr;
                                      final bad = stock <= thr || working <= 0;

                                      final loc = (m['alert_time_stock_physical_location'] ??
                                          m['physical_location'] ??
                                          m['location'] ??
                                          '')
                                          .toString();
                                      final subLoc = (m['alert_time_stock_physical_sub_location'] ??
                                          m['physical_sub_location'] ??
                                          m['sub_location'] ??
                                          '')
                                          .toString();

                                      return _GoogleFontItemRow(
                                        sku: sku,
                                        stock: stock,
                                        threshold: thr,
                                        working: working,
                                        delta: delta,
                                        bad: bad,
                                        location: loc,
                                        subLocation: subLoc,
                                        productId: m['product_id']?.toString() ?? m['id']?.toString() ?? '',
                                        productName: m['name']?.toString() ?? sku,
                                        onTap: () => _openItemMenu(m),
                                      );
                                    },
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===== Google Font Location Picker =====
  Future<void> _showGoogleFontLocationPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    List<String>? labels,
    String? selected,
    required Function(String) onSelect,
  }) async {
    final shownLabels = <String>[];
    if (labels != null && labels.isNotEmpty) {
      shownLabels.add(labels.first);
      if (items.length > 1) shownLabels.addAll(items.skip(1));
    } else {
      shownLabels.addAll(items);
    }

    int selectedIndex = items.indexOf(selected ?? '');

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: CupertinoColors.systemBlue,
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        onSelect(items[selectedIndex]);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          color: CupertinoColors.systemBlue,
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex < 0 ? 0 : selectedIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: List.generate(
                    shownLabels.length,
                        (i) => Center(
                          child: Text(
                            shownLabels[i].toString(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              decoration: TextDecoration.none,
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



  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Low Stock Alerts',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
      backgroundColor: _screenBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),

          CupertinoSliverRefreshControl(onRefresh: _refresh),

          // Summary row under header (compact, no hint chip)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          _totalRecords == null ? '—' : '${_totalRecords!} alerts',
                          style: _t(size: 16, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text('Page $_page', style: _t(size: 13, color: CupertinoColors.systemGrey)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _ErrorBanner(text: _error!),
              ),
            ),

          if (_firstLoad)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_alerts.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onRetry: _refresh))
          else
            SliverList.separated(
              itemCount: _alerts.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 6), // tighter gap between cards
              itemBuilder: (_, i) {
                if (i >= _alerts.length) {
                  _maybeTriggerLoadMore();
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: CupertinoActivityIndicator()),
                  );
                }
                final a = _alerts[i];
                final id = a['id']?.toString() ?? '-';
                final wh = a['warehouse_id']?.toString() ?? '-';
                final count = a['items_count']?.toString() ??
                    a['items_per_page']?.toString() ??
                    '-';
                final created = a['created_at_formatted']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), // compact outer padding
                  child: _AlertTile(
                    id: id,
                    warehouseId: wh,
                    itemsCount: count,
                    createdAt: created,
                    onTap: () => _showGoogleFontItemPopup(
                      alertId: id,
                      createdAt: created,
                      warehouseId: wh,
                    ),
                  ),
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  // ===== Enhanced Outward Dialog =====
  void _openOutwardDialog(Map<String, dynamic> p) {
    final qtyCtrl = TextEditingController(text: '1');
    final remarksCtrl = TextEditingController();
    final List<File> selectedImages = [];
    String? validationError;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        width: MediaQuery.of(ctx).size.width * 0.9,
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_dangerRed, _dangerRed.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          size: 22,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outward Stock',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              'SKU: ${p['sku'] ?? 'N/A'}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CupertinoColors.white.withOpacity(0.9),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                        onPressed: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'Quantity',
                        icon: CupertinoIcons.number,
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        placeholder: 'Enter quantity to outward',

                      ),
                      if (validationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            validationError!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _dangerRed,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Remarks',
                        icon: CupertinoIcons.text_bubble,
                        controller: remarksCtrl,
                        placeholder: 'Enter remarks (optional)',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 18),
                      // Image Upload Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B52A3).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(CupertinoIcons.photo, size: 15, color: Color(0xFF6B52A3)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Images (Optional)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${selectedImages.length}/2',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedImages.isEmpty)
                            Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: CupertinoColors.separator.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 800,
                                    maxHeight: 600,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setSheet(() {
                                      selectedImages.add(File(image.path));
                                    });
                                  }
                                },
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.photo_camera, size: 32, color: CupertinoColors.systemGrey),
                                    SizedBox(height: 8),
                                    Text('Tap to add image', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...selectedImages.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: CupertinoColors.separator),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            file,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              CupertinoIcons.photo,
                                              size: 32,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          minSize: 24,
                                          onPressed: () {
                                            setSheet(() {
                                              selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: CupertinoColors.systemRed,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.xmark,
                                              size: 12,
                                              color: CupertinoColors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                if (selectedImages.length < 2)
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 800,
                                        maxHeight: 600,
                                        imageQuality: 80,
                                      );
                                      if (image != null) {
                                        setSheet(() {
                                          selectedImages.add(File(image.path));
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CupertinoColors.separator.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(CupertinoIcons.plus, size: 24, color: CupertinoColors.systemGrey),
                                          Text('Add', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Enhanced Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Cancel',
                          icon: CupertinoIcons.xmark,
                          onPressed: () => Navigator.pop(ctx),
                          isSecondary: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Process Outward',
                          icon: CupertinoIcons.arrow_up_circle,
                          onPressed: () async {
                            final quantity = int.tryParse(qtyCtrl.text) ?? 0;

                            // Clear previous validation error
                            validationError = null;

                            // Validation
                            if (quantity <= 0) {
                              validationError = 'Please enter a valid quantity greater than 0';
                              setSheet(() {});
                              return;
                            }

                            Navigator.pop(ctx);
                            await _doOutward(
                              productId: p['product_id'] ?? p['id'],
                              quantity: quantity,
                              remarks: remarksCtrl.text.trim(),
                              images: selectedImages,
                            );
                          },
                          isDanger: true,
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
    );
  }

  Future<void> _doOutward({
    required dynamic productId,
    required int quantity,
    required String remarks,
    required List<File> images,
  }) async {
    // Validation
    if (quantity <= 0) {
      _showDialog(
        title: 'Invalid Quantity',
        message: 'Please enter a valid quantity greater than 0.',
        type: _DialogType.error,
      );
      return;
    }

    if (productId == null || productId.toString().isEmpty) {
      _showDialog(
        title: 'Invalid Product',
        message: 'Product information is missing.',
        type: _DialogType.error,
      );
      return;
    }

    try {
      _showLoadingDialog();
      print('DEBUG: Sending outward request - Product ID: ${productId.toString()}, Quantity: $quantity, Remarks: $remarks, Images: ${images.length}');

      final result = await _processOutward(
        productId: productId.toString(),
        quantity: quantity,
        remarks: remarks.isEmpty ? 'Outward processed' : remarks,
        images: images,
        token: _token ?? '',
      );

      print('DEBUG: Outward response: $result');

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

      if (result['success'] == true) {
        _showDialog(
          title: 'Outward Successful',
          message: result['message'] ?? 'Outward processed successfully',
          type: _DialogType.info,
        );
        await _refresh();
      } else {
        _showDialog(
          title: 'Outward Failed',
          message: result['message'] ?? 'Unknown error occurred',
          type: _DialogType.error,
        );
      }
    } catch (e) {
      print('DEBUG: Outward error: $e');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      _showDialog(
        title: 'Network Error',
        message: 'Failed to process outward: ${e.toString()}',
        type: _DialogType.error,
      );
    }
  }

  // ===== Enhanced Update Dialog =====
  void _openUpdateDialog(Map<String, dynamic> p) {
    final stockCtrl = TextEditingController(text: '0');
    final subLocCtrl =
    TextEditingController(text: (p['alert_time_stock_physical_sub_location'] ?? p['stock_physical_sub_location'] ?? '').toString());
    final thrCtrl = TextEditingController(text: '${p['alert_time_threshold'] ?? p['stock_reserve_threshold'] ?? 0}');
    String? validationError;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          width: MediaQuery.of(ctx).size.width * 0.9,
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(ctx),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_successGreen, _successGreen.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil_circle_fill,
                          size: 22,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Product',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              'SKU: ${p['sku'] ?? 'N/A'}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CupertinoColors.white.withOpacity(0.9),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                        onPressed: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'Add Stock',
                        icon: CupertinoIcons.plus_circle_fill,
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        placeholder: 'Enter quantity to add',
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Sub-Location',
                        icon: CupertinoIcons.placemark_fill,
                        controller: subLocCtrl,
                        placeholder: 'e.g., A003, Shelf-5',
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Reserve Threshold',
                        icon: CupertinoIcons.flag_fill,
                        controller: thrCtrl,
                        keyboardType: TextInputType.number,
                        placeholder: 'Minimum stock level',
                      ),
                      if (validationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            validationError!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _dangerRed,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Enhanced Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Cancel',
                          icon: CupertinoIcons.xmark,
                          onPressed: () => Navigator.pop(ctx),
                          isSecondary: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Save Changes',
                          icon: CupertinoIcons.checkmark_alt,
                          onPressed: () async {
                            final addStock = int.tryParse(stockCtrl.text) ?? 0;
                            final newSubLoc = subLocCtrl.text.trim();
                            final newThreshold = int.tryParse(thrCtrl.text) ?? 0;

                            // Clear previous validation error
                            validationError = null;

                            // Validation
                            if (addStock < 0) {
                              validationError = 'Stock amount cannot be negative';
                              setSheet(() {});
                              return;
                            }

                            if (newSubLoc.isEmpty) {
                              validationError = 'Please enter a valid sub-location';
                              setSheet(() {});
                              return;
                            }

                            if (newThreshold < 0) {
                              validationError = 'Threshold cannot be negative';
                              setSheet(() {});
                              return;
                            }

                            Navigator.pop(ctx);
                            await _doUpdate(
                              productId: p['product_id'] ?? p['id'],
                              addStock: addStock,
                              newSubLoc: newSubLoc,
                              newThreshold: newThreshold,
                            );
                          },
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
    );
  }

  Future<void> _doUpdate({
    required dynamic productId,
    required int addStock,
    required String newSubLoc,
    required int newThreshold,
  }) async {
    // Validation
    if (productId == null || productId.toString().isEmpty) {
      _showDialog(
        title: 'Invalid Product',
        message: 'Product information is missing.',
        type: _DialogType.error,
      );
      return;
    }

    if (addStock < 0) {
      _showDialog(
        title: 'Invalid Stock Amount',
        message: 'Stock amount cannot be negative.',
        type: _DialogType.error,
      );
      return;
    }

    if (newThreshold < 0) {
      _showDialog(
        title: 'Invalid Threshold',
        message: 'Threshold cannot be negative.',
        type: _DialogType.error,
      );
      return;
    }

    if (newSubLoc.trim().isEmpty) {
      _showDialog(
        title: 'Invalid Sub-Location',
        message: 'Please enter a valid sub-location.',
        type: _DialogType.error,
      );
      return;
    }

    try {
      _showLoadingDialog();
      print('DEBUG: Sending update request - Product ID: ${productId.toString()}, Add Stock: $addStock, Sub Loc: $newSubLoc, Threshold: $newThreshold');

      final result = await _processUpdate(
        productId: productId.toString(),
        addStock: addStock,
        newSubLoc: newSubLoc.trim(),
        newThreshold: newThreshold,
        token: _token ?? '',
      );

      print('DEBUG: Update response: $result');

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

      if (result['success'] == true) {
        _showDialog(
          title: 'Update Successful',
          message: result['message'] ?? 'Product updated successfully',
          type: _DialogType.info,
        );
        await _refresh();
      } else {
        _showDialog(
          title: 'Update Failed',
          message: result['message'] ?? 'Unknown error occurred',
          type: _DialogType.error,
        );
      }
    } catch (e) {
      print('DEBUG: Update error: $e');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      _showDialog(
        title: 'Network Error',
        message: 'Failed to update product: ${e.toString()}',
        type: _DialogType.error,
      );
    }
  }

  // ===== Item Menu Handler =====
  void _openItemMenu(Map<String, dynamic> item) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          item['name'] ?? item['sku'] ?? 'Product',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
            decoration: TextDecoration.none,
          ),
        ),
        message: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'SKU: ${item['sku'] ?? 'N/A'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openUpdateDialog(item);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.pencil_circle, size: 20, color: _successGreen),
                const SizedBox(width: 10),
                Text('Update Stock', style: GoogleFonts.inter(
                  fontSize: 17,
                  decoration: TextDecoration.none,
                )),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openOutwardDialog(item);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.arrow_up_circle, size: 20, color: _dangerRed),
                const SizedBox(width: 10),
                Text('Outward Stock', style: GoogleFonts.inter(
                  fontSize: 17,
                  decoration: TextDecoration.none,
                )),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          )),
        ),
      ),
    );
  }

  // ===== Enhanced Alert Dialog =====
  void _showDialog({
    required String title,
    required String message,
    _DialogType type = _DialogType.info,
  }) {
    final IconData icon;
    final Color iconColor;

    switch (type) {
      case _DialogType.error:
        icon = CupertinoIcons.xmark_circle_fill;
        iconColor = _dangerRed;
        break;
      case _DialogType.warning:
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        iconColor = _warningOrange;
        break;
      case _DialogType.info:
        icon = CupertinoIcons.info_circle_fill;
        iconColor = _infoBlue;
        break;
    }

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            decoration: TextDecoration.none,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _infoBlue,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const CupertinoActivityIndicator(radius: 18),
        ),
      ),
    );
  }

  // iOS bottom picker (reusable)
  Future<void> _showBottomPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    List<String>? labels, // optional label for ''
    String? selected,
    required Function(String) onSelect,
  }) async {
    final shownLabels = <String>[];
    if (labels != null && labels.isNotEmpty) {
      shownLabels.add(labels.first);
      if (items.length > 1) shownLabels.addAll(items.skip(1));
    } else {
      shownLabels.addAll(items);
    }

    int selectedIndex = items.indexOf(selected ?? '');

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: CupertinoColors.systemBlue)),
                    ),
                    const Spacer(),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        onSelect(items[selectedIndex]);
                        Navigator.pop(context);
                      },
                      child: const Text('Done',
                          style: TextStyle(color: CupertinoColors.systemBlue)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex < 0 ? 0 : selectedIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: List.generate(
                    shownLabels.length,
                        (i) => Center(child: Text(shownLabels[i].toString(), style: const TextStyle(fontSize: 16))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== HELPER WIDGETS =====

class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? placeholder;
  final bool isRequired;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.placeholder,
    this.isRequired = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF6B52A3).withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 15, color: const Color(0xFF6B52A3)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF3B30),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          placeholder: placeholder,
          maxLines: maxLines,
          padding: const EdgeInsets.all(13),
          style: GoogleFonts.inter(
            fontSize: 15,
            decoration: TextDecoration.none,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isDanger;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDanger
        ? const Color(0xFFFF3B30)
        : isSecondary
        ? CupertinoColors.systemGrey5
        : const Color(0xFF6B52A3);

    final textColor = isSecondary
        ? CupertinoColors.label
        : CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSecondary
              ? null
              : [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DialogType { info, warning, error }

/// ===== UI bits =====

class _AlertTile extends StatelessWidget {
  final String id;
  final String warehouseId;
  final String itemsCount;
  final String createdAt;
  final VoidCallback onTap;
  const _AlertTile({
    required this.id,
    required this.warehouseId,
    required this.itemsCount,
    required this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(14), // denser content
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brandPrimary.withOpacity(0.15), _brandLight.withOpacity(0.15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.bell_circle_fill, color: _brandPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Alert #$id • WH $warehouseId',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: TextDecoration.none,
                        color: CupertinoColors.label,
                        height: 1.2,
                      )),
                  const SizedBox(height: 2),
                  Text(createdAt,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                        decoration: TextDecoration.none,
                        height: 1.2,
                      )),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brandPrimary, _brandLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('$itemsCount',
                    style: GoogleFonts.inter(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    )),
              ),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_right, size: 18, color: CupertinoColors.systemGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRowMini extends StatelessWidget {
  final String sku;
  final int stock;
  final int threshold;
  final int working;
  final int delta;
  final bool bad;
  final String location;
  final String subLocation;
  const _ItemRowMini({
    required this.sku,
    required this.stock,
    required this.threshold,
    required this.working,
    required this.delta,
    required this.bad,
    required this.location,
    required this.subLocation,
  });

  @override
  Widget build(BuildContext context) {
    final color = bad ? CupertinoColors.systemRed : _brandPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.7),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              bad ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.cube_box_fill,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sku,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  )),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _Chip(
                  icon: CupertinoIcons.cube_box,
                  label: 'Stock',
                  value: '$stock',
                  color: const Color(0xFF34C759),
                ),
                _Chip(
                  icon: CupertinoIcons.chart_bar,
                  label: 'Working',
                  value: '$working',
                  color: const Color(0xFF007AFF),
                ),
                _Chip(
                  icon: CupertinoIcons.flag,
                  label: 'Threshold',
                  value: '$threshold',
                  color: const Color(0xFFFF9500),
                ),
                _Chip(
                  icon: CupertinoIcons.location,
                  label: 'Location',
                  value: subLocation.isNotEmpty ? '$location-$subLocation' : (location.isNotEmpty ? location : 'N/A'),
                  color: const Color(0xFF5856D6),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _EmptyState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandPrimary.withOpacity(0.1), _brandLight.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _brandPrimary.withOpacity(0.3), width: 1),
            ),
            child: const Icon(CupertinoIcons.bell_slash_fill, color: _brandPrimary, size: 44),
          ),
          const SizedBox(height: 16),
          Text('No Alerts',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                decoration: TextDecoration.none,
                color: CupertinoColors.label,
                height: 1.2,
              )),
          const SizedBox(height: 6),
          Text('Everything looks good right now.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CupertinoColors.systemGrey,
                decoration: TextDecoration.none,
                height: 1.3,
              )),
          const SizedBox(height: 18),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            onPressed: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_brandPrimary, _brandLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Refresh',
                  style: GoogleFonts.inter(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFFFF3B30), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: const Color(0xFFFF3B30),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleFontItemRow extends StatelessWidget {
  final String sku;
  final int stock;
  final int threshold;
  final int working;
  final int delta;
  final bool bad;
  final String location;
  final String subLocation;
  final String productId;
  final String productName;
  final VoidCallback onTap;

  const _GoogleFontItemRow({
    required this.sku,
    required this.stock,
    required this.threshold,
    required this.working,
    required this.delta,
    required this.bad,
    required this.location,
    required this.subLocation,
    required this.productId,
    required this.productName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = bad ? CupertinoColors.systemRed : _brandPrimary;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                bad ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.cube_box_fill,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sku,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: CupertinoColors.label,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _GoogleFontChip(
                        icon: CupertinoIcons.cube_box,
                        label: 'Stock',
                        value: '$stock',
                        color: const Color(0xFF34C759),
                      ),
                      _GoogleFontChip(
                        icon: CupertinoIcons.chart_bar,
                        label: 'Working',
                        value: '$working',
                        color: const Color(0xFF007AFF),
                      ),
                      _GoogleFontChip(
                        icon: CupertinoIcons.flag,
                        label: 'Threshold',
                        value: '$threshold',
                        color: const Color(0xFFFF9500),
                      ),
                      _GoogleFontChip(
                        icon: CupertinoIcons.location,
                        label: 'Location',
                        value: subLocation.isNotEmpty ? '$location-$subLocation' : (location.isNotEmpty ? location : 'N/A'),
                        color: const Color(0xFF5856D6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: Icon(
                CupertinoIcons.ellipsis_vertical,
                color: CupertinoColors.systemGrey,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleFontChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GoogleFontChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color.withOpacity(0.8),
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
