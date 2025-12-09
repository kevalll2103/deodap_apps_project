import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_filter_service.dart';

class thresholdScreen extends StatefulWidget {
  const thresholdScreen({super.key});
  @override
    State<thresholdScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<thresholdScreen> {
  // ===== API config =====
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-app';
  static const String appId = '1';
  static const String apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  static const List<String> _imageBases = [
    'https://d3np62i3isvr1h.cloudfront.net/',
    'https://vacalvers.com/storage/',
  ];

  // ===== Enhanced Color Palette =====
  static const Color _brandPrimary = Color(0xFF6B52A3);
  static const Color _brandLight = Color(0xFF8B7AB8);
  static const Color _successGreen = Color(0xFF34C759);
  static const Color _warningOrange = Color(0xFFFF9500);
  static const Color _dangerRed = Color(0xFFFF3B30);
  static const Color _infoBlue = Color(0xFF007AFF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF2F2F7);

  // ===== Typography helper (NO underlines, optimized heights) =====
  TextStyle _t({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    final base = CupertinoTheme.of(context).textTheme.textStyle;
    return base.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? base.color,
      height: height ?? 1.2, // Reduced default height
      decoration: TextDecoration.none, // NO underlines
      decorationStyle: TextDecorationStyle.solid,
    );
  }

  // ===== State =====
  String _token = '';
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  int _totalRecords = 0;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _allLocations = [];
  List<String> _allSubLocations = [];
  bool _isLoadingSubLocations = true;

  // Check if any filters are active
  bool get _hasActiveFilters {
    return _location.isNotEmpty ||
        _subLocation.isNotEmpty ||
        _stockFilter != _StockFilter.all ||
        _stockRangeFilter != _StockRangeFilter.all ||
        _sortField.isNotEmpty ||
        _filterStockType.isNotEmpty ||
        _searchCtrl.text.trim().isNotEmpty;
  }

  // ===== Filters =====
  String _location = '';
  String _subLocation = '';
  _StockFilter _stockFilter = _StockFilter.all;
  String _sortField = '';
  String _sortOrder = 'ASC';
  String _filterStockType = '';
  _StockRangeFilter _stockRangeFilter = _StockRangeFilter.all;
  int _customStockMin = 0;
  int _customStockMax = 0;

  // ===== Filter Persistence =====
  static const String _filterPrefsKey = 'threshold_products_filters';
  static const String _searchPrefsKey = 'threshold_products_search';

  Future<void> _loadPersistedFilters(SharedPreferences sp) async {
    try {
      final filtersJson = sp.getString(_filterPrefsKey);
      if (filtersJson != null) {
        final Map<String, dynamic> filters = jsonDecode(filtersJson);
        setState(() {
          _location = filters['location'] ?? '';
          _subLocation = filters['subLocation'] ?? '';
          _stockFilter = _parseStock(filters['stockFilter'] ?? 'all');
          _sortField = filters['sortField'] ?? '';
          _sortOrder = filters['sortOrder'] ?? 'ASC';
          _filterStockType = filters['filterStockType'] ?? '';
          _stockRangeFilter = _parseStockRange(filters['stockRangeFilter'] ?? 'all');
          _customStockMin = filters['customStockMin'] ?? 0;
          _customStockMax = filters['customStockMax'] ?? 0;
        });
      }

      // Load search text
      final searchText = sp.getString(_searchPrefsKey) ?? '';
      if (searchText.isNotEmpty) {
        setState(() {
          _searchCtrl.text = searchText;
        });
      }
    } catch (e) {
      print('Error loading persisted filters: $e');
    }
  }

  Future<void> _savePersistedFilters() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final filters = {
        'location': _location,
        'subLocation': _subLocation,
        'stockFilter': _stockFilter.name,
        'sortField': _sortField,
        'sortOrder': _sortOrder,
        'filterStockType': _filterStockType,
        'stockRangeFilter': _stockRangeFilter.name,
        'customStockMin': _customStockMin,
        'customStockMax': _customStockMax,
      };
      await sp.setString(_filterPrefsKey, jsonEncode(filters));

      // Save search text
      await sp.setString(_searchPrefsKey, _searchCtrl.text);

      // Also save location to shared service
      await LocationFilterService.saveSelectedLocation(_location);
      print('Threshold: Saved location "$_location" to shared service');
    } catch (e) {
      print('Error saving persisted filters: $e');
    }
  }

  Future<void> _clearPersistedFilters() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_filterPrefsKey);
      await sp.remove(_searchPrefsKey);
    } catch (e) {
      print('Error clearing persisted filters: $e');
    }
  }

  // ===== Outward API Integration =====
  Future<Map<String, dynamic>> _processOutward({
    required String productId,
    required int quantity,
    required String remarks,
    required List<File> images,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/catalog_products/outward'),
      );

      // Add form fields
      request.fields['app_id'] = appId;
      request.fields['api_key'] = apiKey;
      request.fields['token'] = _token;
      request.fields['product_id'] = productId;
      request.fields['qty'] = quantity.toString();
      request.fields['remarks'] = remarks;

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
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

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
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ===== Banner overlay =====
  OverlayEntry? _bannerEntry;
  void _showBanner(String msg, {bool isError = false}) {
    _bannerEntry?.remove();
    _bannerEntry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.of(ctx).padding.top + 8;
        return Positioned(
          left: 16,
          right: 16,
          top: top,
          child: _Banner(msg: msg, isError: isError, t: _t),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_bannerEntry!);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _bannerEntry?.remove();
      _bannerEntry = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _restoreTokenAndLoad();
    _scrollCtrl.addListener(_infiniteScrollListener);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _bannerEntry?.remove();
    super.dispose();
  }

  Future<void> _restoreTokenAndLoad() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    _token = sp.getString('authToken') ?? '';
    if (_token.isEmpty) {
      _showDialog(
        title: 'Login Required',
        message: 'Please login again to continue.',
        type: _DialogType.error,
      );
      return;
    }

    // Load locations from shared service
    _allLocations = await LocationFilterService.getAvailableLocations();

    // Load shared location filter
    _location = await LocationFilterService.getSelectedLocation();
    print('Threshold: Loaded shared location filter: "$_location"');

    // Load persisted filters
    await _loadPersistedFilters(sp);

    // Start fetching sub-locations in background (non-blocking)
    _fetchAllSubLocations();

    // Load products immediately
    await _fetchList(refresh: true);
  }

  // Fetch sub-locations more efficiently - limit to first few pages only
  Future<void> _fetchAllSubLocations() async {
    try {
      final Set<String> subLocationSet = {};

      // Only fetch first 3 pages (450 products) to get most sub-locations quickly
      // This prevents hanging and provides good coverage
      for (int page = 1; page <= 3; page++) {
        final queryParams = {
          'app_id': appId,
          'api_key': apiKey,
          'token': _token,
          'list_preset': 'threshold_reached',
          'paging_current_page': page.toString(),
          'paging_items_per_page': '500',
        };

        final uri = Uri.parse('$baseUrl/catalog_products/list').replace(
          queryParameters: queryParams,
        );

        final res = await http.get(uri, headers: {'Accept': 'application/json'});

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json['status_flag'] == 1) {
            final List data = (json['data'] ?? []) as List;
            print('Page $page: API returned ${data.length} products for sub-location extraction');

            // Extract all unique sub-locations from this page
            for (final product in data) {
              final subLoc = (product['stock_physical_sub_location'] ?? '').toString().trim();
              if (subLoc.isNotEmpty) {
                subLocationSet.add(subLoc);
              }
            }

            // If no more data, break early
            final paging = json['meta_data']?['paging'] ?? {};
            if (!(paging['has_next_page'] ?? false)) {
              print('No more pages, stopping sub-location fetch');
              break;
            }
          } else {
            print('Page $page: API returned status_flag != 1');
            break;
          }
        } else {
          print('Page $page: API returned status code: ${res.statusCode}');
          break;
        }

        // Small delay to prevent overwhelming the API
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _allSubLocations = subLocationSet.toList()..sort();
      _isLoadingSubLocations = false;
      print('Found ${_allSubLocations.length} unique sub-locations: $_allSubLocations');

      // Refresh UI if filter dialog is open
      if (mounted) setState(() {});
    } catch (e) {
      // If API call fails, we'll fall back to collecting sub-locations from loaded products
      print('Error fetching sub-locations: $e');
      _isLoadingSubLocations = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchList({bool refresh = false, String? searchQuery}) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _products.clear();
      _filtered.clear();
    }
    if (!_hasMore) return;

    setState(() => _loading = true);

    try {
      final queryParams = {
        'app_id': appId,
        'api_key': apiKey,
        'token': _token,
        'list_preset': 'threshold_reached',
      };

      // Add search query if provided - use filter_sku without pagination
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['filter_sku'] = searchQuery;
        print('Applying SKU filter: $searchQuery');
      } else {
        // Only add pagination for non-search queries
        queryParams['paging_current_page'] = _page.toString();
        queryParams['paging_items_per_page'] = '500';
      }

      print('DEBUG: All API Query Parameters: $queryParams');
      final uri = Uri.parse('$baseUrl/catalog_products/list').replace(
        queryParameters: queryParams,
      );
      print('DEBUG: Full API URL: $uri');

      if (_location.isNotEmpty) {
        queryParams['filter_physical_location'] = _location;
        print('Applying location filter: $_location');
      }
      if (_subLocation.isNotEmpty) {
        queryParams['filter_physical_sub_location'] = _subLocation;
        print('Applying sub-location filter: $_subLocation');
      }
      if (_filterStockType.isNotEmpty) {
        queryParams['filter_stock_type'] = _filterStockType;
      }
      if (_sortField.isNotEmpty) {
        queryParams['sort_field'] = _sortField;
      }
      if (_sortOrder.isNotEmpty) {
        queryParams['sort_order'] = _sortOrder;
      }

      final apiUri = Uri.parse('$baseUrl/catalog_products/list').replace(
        queryParameters: queryParams,
      );

      final res = await http.get(apiUri, headers: {'Accept': 'application/json'});

      if (!mounted) return;

      if (res.statusCode != 200) {
        _showDialog(
          title: 'Server Error',
          message: 'Server responded with status ${res.statusCode}. Please try again.',
          type: _DialogType.error,
        );
        return;
      }

      final json = jsonDecode(res.body);
      if (json['status_flag'] != 1) {
        _showDialog(
          title: 'Load Failed',
          message: 'Unable to load products. Please check your connection.',
          type: _DialogType.error,
        );
        return;
      }

      final List data = (json['data'] ?? []) as List;
      final paging = json['meta_data']?['paging'] ?? {};
      _totalRecords =
          paging['total_records'] ?? (_totalRecords == 0 ? data.length : _totalRecords);
      _hasMore = paging['has_next_page'] ?? false;

      _products.addAll(data.cast<Map<String, dynamic>>());

      // Handle search results differently
      final currentSearch = _searchCtrl.text.trim();
      if (currentSearch.isEmpty) {
        // Normal flow: apply local filters
        _applyFilters();
      } else {
        // Search flow: show API results directly (no pagination for search)
        _filtered = List.from(_products);
        // Set _hasMore to false when searching since there's no pagination
        _hasMore = false;
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showDialog(
        title: 'Network Error',
        message: 'Please check your internet connection and try again.',
        type: _DialogType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _infiniteScrollListener() {
    if (!_hasMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 160) {
      final searchQuery = _searchCtrl.text.trim().toLowerCase();
      // When searching, don't load more pages (no pagination for search)
      if (searchQuery.isNotEmpty) {
        return;
      }
      _page++;
      _fetchList(searchQuery: null);
    }
  }

  Timer? _searchTimer;

  void _onSearchChanged() {
    final currentText = _searchCtrl.text.trim();

    // Save search text to preferences
    _savePersistedFilters();

    // If search field is cleared, automatically refresh to restore default list
    if (currentText.isEmpty) {
      _searchTimer?.cancel();
      _fetchList(refresh: true);
      return;
    }

    // For non-empty search, use the existing debounced logic
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();

    // If there's a search query, use debounced API call
    if (q.isNotEmpty) {
      _searchTimer?.cancel();
      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        _fetchList(refresh: true, searchQuery: q);
      });
      return;
    }

    // If no search query, apply local filters only
    _filtered = _products.where((p) {
      // Apply location filter
      if (_location.isNotEmpty) {
        final productLocation = (p['stock_physical_location'] ?? '').toString();
        if (productLocation != _location) return false;
      }

      // Apply sub-location filter (trim and case-insensitive)
      if (_subLocation.isNotEmpty) {
        final productSubLocation = (p['stock_physical_sub_location'] ?? '').toString().trim();
        if (productSubLocation.toLowerCase() != _subLocation.toLowerCase().trim()) {
          // Debug: Print when product doesn't match selected sub-location
          print('Filter: Product sub-location "$productSubLocation" != selected "$_subLocation"');
          return false;
        }
      }

      final int stock = (p['stock'] ?? 0) is int
          ? p['stock']
          : int.tryParse('${p['stock'] ?? 0}') ?? 0;
      final int threshold = (p['stock_reserve_threshold'] ?? 0) is int
          ? p['stock_reserve_threshold']
          : int.tryParse('${p['stock_reserve_threshold'] ?? 0}') ?? 0;

      switch (_stockFilter) {
        case _StockFilter.inStock:
          if (stock <= 0) return false;
          break;
        case _StockFilter.lowStock:
          if (stock <= 0 || stock > threshold) return false;
          break;
        case _StockFilter.outOfStock:
          if (stock > 0) return false;
          break;
        case _StockFilter.all:
          break;
      }

      // Apply stock range filter
      if (!_isInStockRange(stock, _stockRangeFilter)) {
        return false;
      }

      return true;
    }).toList();

    if (mounted) setState(() {});
  }

  // ===== ENHANCED Filter & Sort Dialog =====
  void _showFiltersDialog() {
    // Use saved locations from SharedPreferences instead of extracting from products
    final locations = _allLocations.isNotEmpty
        ? (List<String>.from(_allLocations)..sort())
        : (_products
        .map((e) => (e['stock_physical_location'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort());

    // Always use _allSubLocations since we're fetching them from API
    // If API call failed, fall back to extracting from current products
    print('_allSubLocations has ${_allSubLocations.length} items: $_allSubLocations');
    print('_isLoadingSubLocations: $_isLoadingSubLocations');

    // Debug: Check what sub-locations are actually in current products
    final currentProductSubLocations = _products
        .map((e) => (e['stock_physical_sub_location'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    print('Current products have sub-locations: $currentProductSubLocations');

    List<String> subLocations;
    if (_allSubLocations.isNotEmpty) {
      subLocations = List<String>.from(_allSubLocations);
    } else if (_isLoadingSubLocations) {
      // Show loading message while sub-locations are being fetched
      subLocations = ['Loading sub-locations...'];
    } else {
      // Fallback to extracting from current products
      subLocations = currentProductSubLocations;
    }
    print('Final subLocations list has ${subLocations.length} items: $subLocations');

    String tmpLocation = _location;
    String tmpSubLocation = _subLocation;
    String tmpStock = _stockFilter.name;
    String tmpSortField = _sortField;
    String tmpSortOrder = _sortOrder;
    String tmpFilterStockType = _filterStockType;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _EnhancedDialog(
        maxWidth: 520,
        maxHeight: 0.88,
        child: StatefulBuilder(
          builder: (ctx, setSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Header
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_brandPrimary, _brandLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                            CupertinoIcons.slider_horizontal_3,
                            color: CupertinoColors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Filters & Sort',
                            style: _t(
                              size: 20,
                              weight: FontWeight.w700,
                              color: CupertinoColors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                          onPressed: () {
                            // Apply temporary filter values before closing
                            setState(() {
                              _location = tmpLocation;
                              _subLocation = tmpSubLocation;
                              _stockFilter = _parseStock(tmpStock);
                              _sortField = tmpSortField;
                              _sortOrder = tmpSortOrder;
                              _filterStockType = tmpFilterStockType;
                            });
                            Navigator.pop(ctx);
                            _applyFilters();
                          },
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

                // Content with better spacing
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _FilterSection(
                          title: 'Physical Location',
                          icon: CupertinoIcons.location_fill,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SelectButton(
                                label: tmpLocation.isEmpty ? 'All Locations' : tmpLocation,
                                icon: CupertinoIcons.building_2_fill,
                                onTap: () => _showBottomPicker(
                                  context: ctx,
                                  title: 'Select Location',
                                  items: ['', ...locations],
                                  labels: ['All Locations', ...locations],
                                  selected: tmpLocation,
                                  onSelect: (val) async {
                                    setSB(() => tmpLocation = val);
                                    setState(() => _location = val);
                                    await _savePersistedFilters();
                                    _fetchList(refresh: true);
                                  },
                                ),
                              ),
                              if (tmpLocation.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _infoBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _infoBlue.withOpacity(0.3), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.info_circle, size: 14, color: _infoBlue),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'This filter is shared across all screens. Change it in Profile to apply everywhere.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: _infoBlue,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                         _FilterSection(
                          title: 'Physical Sub-Location',
                          icon: CupertinoIcons.placemark_fill,
                          child: _SelectButton(
                            label: _isLoadingSubLocations
                                ? 'Loading...'
                                : (tmpSubLocation.isEmpty
                                ? 'All Sub-Locations'
                                : tmpSubLocation),
                            icon: _isLoadingSubLocations
                                ? CupertinoIcons.clock
                                : CupertinoIcons.map_pin,
                            onTap: () {
                              if (_isLoadingSubLocations) {
                                // Show loading message if still loading
                                _showDialog(
                                  title: 'Loading',
                                  message: 'Sub-locations are still loading. Please wait...',
                                  type: _DialogType.info,
                                );
                                return;
                              }
                              _showBottomPicker(
                                context: ctx,
                                title: 'Select Sub-Location',
                                items: ['', ...subLocations],
                                labels: ['All Sub-Locations', ...subLocations],
                                selected: tmpSubLocation,
                                onSelect: (val) async {
                                  print('Selected sub-location: "$val"');
                                  setSB(() => tmpSubLocation = val);
                                  setState(() => _subLocation = val);
                                  print('Set _subLocation to: "$_subLocation"');
                                  await _savePersistedFilters();
                                  _fetchList(refresh: true);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FilterSection(
                          title: 'Stock Status',
                          icon: CupertinoIcons.chart_bar_alt_fill,
                          child: _SelectButton(
                            label: _stockStatusLabel(tmpStock),
                            icon: _stockStatusIcon(tmpStock),
                            onTap: () => _showBottomPicker(
                              context: ctx,
                              title: 'Select Stock Status',
                              items: const [
                                'all',
                                'inStock',
                                'lowStock',
                                'outOfStock',
                              ],
                              labels: const [
                                'All Products',
                                'In Stock',
                                'Low Stock',
                                'Out of Stock',
                              ],
                              selected: tmpStock,
                              onSelect: (val) async {
                                setSB(() => tmpStock = val);
                                setState(() => _stockFilter = _parseStock(val));
                                await _savePersistedFilters();
                                _applyFilters();
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        _FilterSection(
                          title: 'Stock Range',
                          icon: CupertinoIcons.chart_bar_fill,
                          child: _SelectButton(
                            label: _stockRangeLabel(_stockRangeFilter.name),
                            icon: _stockRangeIcon(_stockRangeFilter.name),
                            onTap: () => _showBottomPicker(
                              context: ctx,
                              title: 'Select Stock Range',
                              items: const [
                                'all',
                                'range0',
                                'range1to10',
                                'range11to50',
                                'range51to100',
                                'range101to500',
                                'range501plus',

                              ],
                              labels: const [
                                'All Ranges',
                                'Out of Stock (0)',
                                '1-10 units',
                                '11-50 units',
                                '51-100 units',
                                '101-500 units',
                                '500+ units',
                              ],
                              selected: _stockRangeFilter.name,
                              onSelect: (val) async {
                                if (val == 'custom') {
                                  Navigator.pop(ctx);
                                  await _showCustomRangeDialog();
                                } else {
                                  setSB(() => _stockRangeFilter = _parseStockRange(val));
                                  setState(() => _stockRangeFilter = _parseStockRange(val));
                                  await _savePersistedFilters();
                                  _applyFilters();
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        _FilterSection(
                          title: 'Sort Options',
                          icon: CupertinoIcons.sort_down,
                          child: Column(
                            children: [
                              // 🔹 First dropdown: Sort By Field
                              _SelectButton(
                                label: tmpSortField.isEmpty
                                    ? 'Select Field'
                                    : _formatSortField(tmpSortField),
                                icon: CupertinoIcons.arrow_up_arrow_down,
                                onTap: () => _showBottomPicker(
                                  context: ctx,
                                  title: 'Sort By Field',
                                  items: const [
                                    'sku',
                                    'stock',
                                    'threshold',
                                    'working_stock',
                                    'stock_physical_sub_location'
                                  ],
                                  labels: const [
                                    'SKU',
                                    'Stock Quantity',
                                    'Threshold',
                                    'Working Stock',
                                    'Sub-Location'
                                  ],
                                  selected: tmpSortField,
                                  onSelect: (val) async {
                                    setSB(() => tmpSortField = val);
                                    setState(() => _sortField = val);
                                    await _savePersistedFilters();
                                    _fetchList(refresh: true);
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 🔹 Second dropdown: Sort Order
                              _SelectButton(
                                label: tmpSortOrder == 'ASC'
                                    ? 'Ascending (A→Z)'
                                    : 'Descending (Z→A)',
                                icon: tmpSortOrder == 'ASC'
                                    ? CupertinoIcons.arrow_up
                                    : CupertinoIcons.arrow_down,
                                onTap: () => _showBottomPicker(
                                  context: ctx,
                                  title: 'Sort Order',
                                  items: const ['ASC', 'DESC'],
                                  labels: const ['Ascending (A→Z)', 'Descending (Z→A)'],
                                  selected: tmpSortOrder,
                                  onSelect: (val) async {
                                    setSB(() => tmpSortOrder = val);
                                    setState(() => _sortOrder = val);
                                    await _savePersistedFilters();
                                    _fetchList(refresh: true);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),


                        const SizedBox(height: 18),
                        _FilterSection(
                          title: 'Stock Type',
                          icon: CupertinoIcons.cube_box_fill,
                          child: _SelectButton(
                            label: tmpFilterStockType.isEmpty
                                ? 'All Types'
                                : _formatStockType(tmpFilterStockType),
                            icon: CupertinoIcons.square_stack_3d_up,
                            onTap: () => _showBottomPicker(
                              context: ctx,
                              title: 'Select Stock Type',
                              items: const ['', 'regular_stock', 'working_stock'],
                              labels: const ['All Types', 'Regular Stock', 'Working Stock'],
                              selected: tmpFilterStockType,
                              onSelect: (val) async {
                                setSB(() => tmpFilterStockType = val);
                                setState(() => _filterStockType = val);
                                await _savePersistedFilters();
                                _fetchList(refresh: true);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // _FilterSection(
                        //   title: 'Physical Location',
                        //   icon: CupertinoIcons.location_fill,
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       _SelectButton(
                        //         label: tmpLocation.isEmpty ? 'All Locations' : tmpLocation,
                        //         icon: CupertinoIcons.building_2_fill,
                        //         onTap: () => _showBottomPicker(
                        //           context: ctx,
                        //           title: 'Select Location',
                        //           items: ['', ...locations],
                        //           labels: ['All Locations', ...locations],
                        //           selected: tmpLocation,
                        //           onSelect: (val) async {
                        //             setSB(() => tmpLocation = val);
                        //             setState(() => _location = val);
                        //             await _savePersistedFilters();
                        //             _fetchList(refresh: true);
                        //           },
                        //         ),
                        //       ),
                        //       if (tmpLocation.isNotEmpty) ...[
                        //         const SizedBox(height: 8),
                        //         Container(
                        //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        //           decoration: BoxDecoration(
                        //             color: _infoBlue.withOpacity(0.1),
                        //             borderRadius: BorderRadius.circular(8),
                        //             border: Border.all(color: _infoBlue.withOpacity(0.3), width: 1),
                        //           ),
                        //           child: Row(
                        //             children: [
                        //               Icon(CupertinoIcons.info_circle, size: 14, color: _infoBlue),
                        //               const SizedBox(width: 6),
                        //               Expanded(
                        //                 child: Text(
                        //                   'This filter is shared across all screens. Change it in Profile to apply everywhere.',
                        //                   style: GoogleFonts.inter(
                        //                     fontSize: 11,
                        //                     color: _infoBlue,
                        //                     fontWeight: FontWeight.w500,
                        //                     decoration: TextDecoration.none,
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ],
                        //     ],
                        //   ),
                        // ),


                        // const SizedBox(height: 18),

                        // _FilterSection(
                        //   title: 'Physical Sub-Location',
                        //   icon: CupertinoIcons.placemark_fill,
                        //   child: _SelectButton(
                        //     label: _isLoadingSubLocations
                        //         ? 'Loading...'
                        //         : (tmpSubLocation.isEmpty
                        //         ? 'All Sub-Locations'
                        //         : tmpSubLocation),
                        //     icon: _isLoadingSubLocations
                        //         ? CupertinoIcons.clock
                        //         : CupertinoIcons.map_pin,
                        //     onTap: () {
                        //       if (_isLoadingSubLocations) {
                        //         // Show loading message if still loading
                        //         _showDialog(
                        //           title: 'Loading',
                        //           message: 'Sub-locations are still loading. Please wait...',
                        //           type: _DialogType.info,
                        //         );
                        //         return;
                        //       }
                        //       _showBottomPicker(
                        //         context: ctx,
                        //         title: 'Select Sub-Location',
                        //         items: ['', ...subLocations],
                        //         labels: ['All Sub-Locations', ...subLocations],
                        //         selected: tmpSubLocation,
                        //         onSelect: (val) async {
                        //           print('Selected sub-location: "$val"');
                        //           setSB(() => tmpSubLocation = val);
                        //           setState(() => _subLocation = val);
                        //           print('Set _subLocation to: "$_subLocation"');
                        //           await _savePersistedFilters();
                        //           _fetchList(refresh: true);
                        //         },
                        //       );
                        //     },
                        //   ),
                        // )

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
                            label: 'Clear All',
                            icon: CupertinoIcons.clear_circled,
                            onPressed: () async {
                              setState(() {
                                _location = '';
                                _subLocation = '';
                                _stockFilter = _StockFilter.all;
                                _stockRangeFilter = _StockRangeFilter.all;
                                _customStockMin = 0;
                                _customStockMax = 0;
                                _sortField = '';
                                _sortOrder = 'ASC';
                                _filterStockType = '';
                                _searchCtrl.clear();
                              });
                              await _clearPersistedFilters();
                              Navigator.pop(ctx);
                              _fetchList(refresh: true);
                              _showDialog(
                                title: 'Filters Cleared',
                                message: 'All filters have been reset.',
                                type: _DialogType.info,
                              );
                            },
                            isSecondary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Apply',
                            icon: CupertinoIcons.checkmark_alt,
                            onPressed: () async {
                              // Apply temporary filter values before closing
                              setState(() {
                                _location = tmpLocation;
                                _subLocation = tmpSubLocation;
                                _stockFilter = _parseStock(tmpStock);
                                _sortField = tmpSortField;
                                _sortOrder = tmpSortOrder;
                                _filterStockType = tmpFilterStockType;
                              });
                              await _savePersistedFilters();
                              Navigator.pop(ctx);
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _stockStatusIcon(String key) {
    switch (key) {
      case 'inStock':
        return CupertinoIcons.checkmark_circle_fill;
      case 'lowStock':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'outOfStock':
        return CupertinoIcons.xmark_circle_fill;
      default:
        return CupertinoIcons.square_grid_2x2;
    }
  }

  String _formatSortField(String field) {
    switch (field) {
      case 'sku':
        return 'SKU';
      case 'stock':
        return 'Stock Quantity';
      case 'threshold':
        return 'Threshold';
      case 'working_stock':
        return 'Working Stock';
      case 'stock_physical_sub_location':
        return 'Sub-Location';
      default:
        return field;
    }
  }

  String _formatStockType(String type) {
    switch (type) {
      case 'regular_stock':
        return 'Regular Stock';
      case 'working_stock':
        return 'Working Stock';
      default:
        return 'All Types';
    }
  }

  String _stockStatusLabel(String key) {
    switch (key) {
      case 'inStock':
        return 'In Stock';
      case 'lowStock':
        return 'Low Stock';
      case 'outOfStock':
        return 'Out of Stock';
      default:
        return 'All Products';
    }
  }

  _StockFilter _parseStock(String key) {
    switch (key) {
      case 'inStock':
        return _StockFilter.inStock;
      case 'lowStock':
        return _StockFilter.lowStock;
      case 'outOfStock':
        return _StockFilter.outOfStock;
      default:
        return _StockFilter.all;
    }
  }

  String _stockRangeLabel(String key) {
    // Handle null or empty key
    if (key.isEmpty) {
      return 'All Ranges';
    }

    switch (key) {
      case 'range0':
        return 'Out of Stock (0)';
      case 'range1to10':
        return '1-10 units';
      case 'range11to50':
        return '11-50 units';
      case 'range51to100':
        return '51-100 units';
      case 'range101to500':
        return '101-500 units';
      case 'range501plus':
        return '500+ units';
      case 'custom':
      // Safely handle custom range values
        final min = _customStockMin >= 0 ? _customStockMin : 0;
        final max = _customStockMax >= 0 ? _customStockMax : 0;

        if (min == 0 && max == 0) {
          return 'Custom Range...';
        }
        return max == 0
            ? 'Custom: $min+'
            : 'Custom: $min-$max';
      default:
        return 'All Ranges';
    }
  }

  IconData _stockRangeIcon(String key) {
    // Handle null or empty key
    if (key.isEmpty) {
      return CupertinoIcons.square_grid_2x2;
    }

    switch (key) {
      case 'range0':
        return CupertinoIcons.xmark_circle_fill;
      case 'range1to10':
        return CupertinoIcons.number;
      case 'range11to50':
        return CupertinoIcons.chart_bar;
      case 'range51to100':
        return CupertinoIcons.chart_bar_alt_fill;
      case 'range101to500':
        return CupertinoIcons.chart_bar_square_fill;
      case 'range501plus':
        return CupertinoIcons.chart_bar_fill;
      case 'custom':
        return CupertinoIcons.slider_horizontal_3;
      default:
        return CupertinoIcons.square_grid_2x2;
    }
  }

  _StockRangeFilter _parseStockRange(String key) {
    // Handle null or empty key
    if (key.isEmpty) {
      return _StockRangeFilter.all;
    }

    switch (key) {
      case 'range0':
        return _StockRangeFilter.range0;
      case 'range1to10':
        return _StockRangeFilter.range1to10;
      case 'range11to50':
        return _StockRangeFilter.range11to50;
      case 'range51to100':
        return _StockRangeFilter.range51to100;
      case 'range101to500':
        return _StockRangeFilter.range101to500;
      case 'range501plus':
        return _StockRangeFilter.range501plus;
      case 'custom':
        return _StockRangeFilter.custom;
      default:
        return _StockRangeFilter.all;
    }
  }

  bool _isInStockRange(int stock, _StockRangeFilter range) {
    switch (range) {
      case _StockRangeFilter.range0:
        return stock == 0;
      case _StockRangeFilter.range1to10:
        return stock >= 1 && stock <= 10;
      case _StockRangeFilter.range11to50:
        return stock >= 11 && stock <= 50;
      case _StockRangeFilter.range51to100:
        return stock >= 51 && stock <= 100;
      case _StockRangeFilter.range101to500:
        return stock >= 101 && stock <= 500;
      case _StockRangeFilter.range501plus:
        return stock >= 501;
      case _StockRangeFilter.custom:
      // Fix: Ensure proper handling of custom range
        if (_customStockMin < 0 || _customStockMax < 0) {
          return false; // Invalid range
        }
        if (_customStockMax == 0) {
          return stock >= _customStockMin;
        } else {
          return stock >= _customStockMin && stock <= _customStockMax;
        }
      case _StockRangeFilter.all:
        return true;
    }
  }

  // ===== Custom Range Dialog =====
  Future<void> _showCustomRangeDialog() async {
    final minCtrl = TextEditingController(text: _customStockMin.toString());
    final maxCtrl = TextEditingController(text: _customStockMax.toString());

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _EnhancedDialog(
        maxWidth: 480,
        maxHeight: 0.65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandPrimary, _brandLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                        CupertinoIcons.slider_horizontal_3,
                        size: 22,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Custom Stock Range',
                        style: _t(
                          size: 20,
                          weight: FontWeight.w700,
                          color: CupertinoColors.white,
                          height: 1.2,
                        ),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormField(
                      label: 'Minimum Stock',
                      icon: CupertinoIcons.minus_circle,
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      placeholder: 'Enter minimum quantity',
                      t: _t,
                    ),
                    const SizedBox(height: 18),
                    _FormField(
                      label: 'Maximum Stock',
                      icon: CupertinoIcons.plus_circle,
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      placeholder: 'Enter maximum quantity',
                      t: _t,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _infoBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _infoBlue.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            color: _infoBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enter 0 in maximum field for no upper limit',
                              style: _t(size: 12, color: CupertinoColors.systemGrey, height: 1.3),
                            ),
                          ),
                        ],
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
                        label: 'Apply Range',
                        icon: CupertinoIcons.checkmark_alt,
                        onPressed: () async {
                          final min = int.tryParse(minCtrl.text) ?? 0;
                          final max = int.tryParse(maxCtrl.text) ?? 0;

                          if (min < 0) {
                            _showDialog(
                              title: 'Invalid Range',
                              message: 'Minimum stock cannot be negative.',
                              type: _DialogType.warning,
                            );
                            return;
                          }

                          if (max < 0) {
                            _showDialog(
                              title: 'Invalid Range',
                              message: 'Maximum stock cannot be negative.',
                              type: _DialogType.warning,
                            );
                            return;
                          }

                          if (max > 0 && min > max) {
                            _showDialog(
                              title: 'Invalid Range',
                              message: 'Minimum stock cannot be greater than maximum stock.',
                              type: _DialogType.warning,
                            );
                            return;
                          }

                          setState(() {
                            _customStockMin = min;
                            _customStockMax = max;
                            _stockRangeFilter = _StockRangeFilter.custom;
                          });
                          await _savePersistedFilters();
                          Navigator.pop(ctx);
                          // Apply filters after state is updated
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _applyFilters();
                          });
                          _showDialog(
                            title: 'Custom Range Applied',
                            message: 'Filtering products with stock between $min and ${max == 0 ? 'unlimited' : max}',
                            type: _DialogType.info,
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
    );
  }

  // ===== Enhanced Bottom Sheet Picker =====
  void _showBottomPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    List<String>? labels,
    String? selected,
    required Function(String) onSelect,
  }) {
    int selectedIndex = math.max(0, items.indexOf(selected ?? ''));

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      minimumSize: const Size(32, 32),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: _t(size: 16, color: _infoBlue, height: 1.2),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: _t(size: 16, weight: FontWeight.w600, height: 1.2),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      onPressed: () {
                        onSelect(items[selectedIndex]);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: _t(
                            size: 16,
                            color: _infoBlue,
                            weight: FontWeight.w600,
                            height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                  FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: List.generate(
                    items.length,
                        (i) => Center(
                      child: Text(
                        (labels != null ? labels[i] : items[i]).toString(),
                        style: _t(size: 16, height: 1.2),
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

  // ===== Enhanced Product Menu =====
  void _openProductMenu(Map<String, dynamic> p) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          (p['name'] ?? 'Product').toString(),
          style: _t(
              size: 14,
              weight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              height: 1.3),
        ),
        message: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'SKU: ${p['sku'] ?? 'N/A'}',
            style: _t(size: 13, color: CupertinoColors.systemGrey, height: 1.2),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openDetails(p);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.info_circle, size: 20, color: _infoBlue),
                const SizedBox(width: 10),
                Text('View Details', style: _t(size: 17, height: 1.2)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openUpdateDialog(p);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.pencil_circle, size: 20, color: _successGreen),
                const SizedBox(width: 10),
                Text('Update Stock', style: _t(size: 17, height: 1.2)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openOutwardDialog(p);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.arrow_up_circle, size: 20, color: _dangerRed),
                const SizedBox(width: 10),
                Text('Outward Stock', style: _t(size: 17, height: 1.2)),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child:
          Text('Cancel', style: _t(size: 17, weight: FontWeight.w600, height: 1.2)),
        ),
      ),
    );
  }

  // ===== Enhanced Details Dialog =====
  Future<void> _openDetails(Map<String, dynamic> basic) async {
    try {
      _showLoadingDialog();

      final uri = Uri.parse('$baseUrl/catalog_products/details').replace(
        queryParameters: {
          'app_id': appId,
          'api_key': apiKey,
          'token': _token,
          'product_id': '${basic['id']}',
        },
      );

      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

      if (res.statusCode != 200) {
        _showDialog(
          title: 'Details Error',
          message: 'Could not load product details. Please try again.',
          type: _DialogType.error,
        );
        return;
      }

      final j = jsonDecode(res.body);
      if (j['status_flag'] != 1) {
        final errorMsg = j['status_messages']?.isNotEmpty == true
            ? j['status_messages'][0]
            : 'Could not load product details.';
        _showDialog(title: 'Error', message: errorMsg, type: _DialogType.error);
        return;
      }

      final Map<String, dynamic> d = j['data'] ?? {};
      if (d.isEmpty) {
        _showBasicDetails(basic);
        return;
      }

      final String img = _resolveImageUrl(d['image'] ?? '');
      final List extras = (d['extra_images'] ?? []) as List;
      final List whStock = (d['stock'] ?? []) as List;

      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => _EnhancedDialog(
          maxWidth: 600,
          maxHeight: 0.92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header with Gradient
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brandPrimary, _brandLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                          CupertinoIcons.cube_box,
                          size: 22,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Product Details',
                          style: _t(
                            size: 20,
                            weight: FontWeight.w700,
                            color: CupertinoColors.white,
                            height: 1.2,
                          ),
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Image Gallery
                      if (img.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CachedNetworkImage(
                              imageUrl: img,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                              const Center(child: CupertinoActivityIndicator()),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(
                                  CupertinoIcons.photo,
                                  size: 56,
                                  color: CupertinoColors.systemGrey3,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (extras.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: extras.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) {
                              final e = extras[i] as Map<String, dynamic>;
                              final u = _resolveImageUrl(e['image'] ?? '');
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 72,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6,
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: u,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                    const Center(child: CupertinoActivityIndicator()),
                                    errorWidget: (_, __, ___) => const Icon(
                                      CupertinoIcons.photo,
                                      size: 28,
                                      color: CupertinoColors.systemGrey3,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      _DetailGroup(
                        title: 'BASIC INFORMATION',
                        icon: CupertinoIcons.info_circle_fill,
                        items: [
                          _DetailItem('Product ID', '${d['id'] ?? basic['id'] ?? ''}'),
                          _DetailItem('Name', (d['name'] ?? basic['name'] ?? '').toString()),
                          _DetailItem('SKU', (d['sku'] ?? basic['sku'] ?? '').toString()),
                          _DetailItem('Warehouse ID',
                              '${d['warehouse_id'] ?? basic['warehouse_id'] ?? ''}'),
                        ],
                        t: _t,
                      ),
                      const SizedBox(height: 18),
                          _DetailGroup(
                        title: 'STOCK & LOCATION',
                        icon: CupertinoIcons.chart_bar_circle_fill,
                        items: [
                          _DetailItem('Current Stock', '${basic['stock'] ?? 0}', highlight: true),
                          _DetailItem('Working Stock', '${basic['working_stock'] ?? 0}'),
                          _DetailItem('Reserve Threshold',
                              '${d['stock_reserve_threshold'] ?? basic['stock_reserve_threshold'] ?? 0}'),
                          _DetailItem(
                              'Physical Location',
                              (d['stock_physical_location'] ??
                                  basic['stock_physical_location'] ??
                                  '—')
                                  .toString()),
                          _DetailItem(
                              'Sub Location',
                              (d['stock_physical_sub_location'] ??
                                  basic['stock_physical_sub_location'] ??
                                  '—')
                                  .toString()),
                        ],
                        t: _t,
                      ),

                      if (whStock.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _DetailGroup(
                          title: 'PER-WAREHOUSE STOCK',
                          icon: CupertinoIcons.building_2_fill,
                          items: whStock.map((s) {
                            final stock = s as Map<String, dynamic>;
                            return _DetailItem(
                              '${stock['warehouse'] ?? '-'}',
                              '${stock['stock'] ?? 0}',
                              highlight: true,
                            );
                          }).toList(),
                          t: _t,
                        ),
                      ],
                      const SizedBox(height: 18),

                      _DetailGroup(
                        title: 'PACKAGING & DIMENSIONS',
                        icon: CupertinoIcons.cube_box_fill,
                        items: [
                          _DetailItem('Packaging Type', (d['packaging_type'] ?? '—').toString()),
                          _DetailItem('Inner Carton Qty', '${d['inner_carton_qty'] ?? '—'}'),
                          _DetailItem('Master Carton Qty', '${d['master_carton_qty'] ?? '—'}'),
                          _DetailItem('Weight (g)', '${d['weight'] ?? '—'}'),
                          _DetailItem('Length (cm)', '${d['length'] ?? '—'}'),
                          _DetailItem('Width (cm)', '${d['width'] ?? '—'}'),
                          _DetailItem('Height (cm)', '${d['height'] ?? '—'}'),
                        ],
                        t: _t,
                      ),

                      const SizedBox(height: 18),

                      // _DetailGroup(
                      //   title: 'STOCK & LOCATION',
                      //   icon: CupertinoIcons.chart_bar_circle_fill,
                      //   items: [
                      //     _DetailItem('Current Stock', '${basic['stock'] ?? 0}', highlight: true),
                      //     _DetailItem('Working Stock', '${basic['working_stock'] ?? 0}'),
                      //     _DetailItem('Reserve Threshold',
                      //         '${d['stock_reserve_threshold'] ?? basic['stock_reserve_threshold'] ?? 0}'),
                      //     _DetailItem(
                      //         'Physical Location',
                      //         (d['stock_physical_location'] ??
                      //             basic['stock_physical_location'] ??
                      //             '—')
                      //             .toString()),
                      //     _DetailItem(
                      //         'Sub Location',
                      //         (d['stock_physical_sub_location'] ??
                      //             basic['stock_physical_sub_location'] ??
                      //             '—')
                      //             .toString()),
                      //   ],
                      //   t: _t,
                      // ),

                      // if (whStock.isNotEmpty) ...[
                      //   const SizedBox(height: 18),
                      //   _DetailGroup(
                      //     title: 'PER-WAREHOUSE STOCK',
                      //     icon: CupertinoIcons.building_2_fill,
                      //     items: whStock.map((s) {
                      //       final stock = s as Map<String, dynamic>;
                      //       return _DetailItem(
                      //         '${stock['warehouse'] ?? '-'}',
                      //         '${stock['stock'] ?? 0}',
                      //         highlight: true,
                      //       );
                      //     }).toList(),
                      //     t: _t,
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      _showDialog(
        title: 'Network Error',
        message: 'Could not fetch details. Please check your connection.',
        type: _DialogType.error,
      );
    }
  }

  // ===== Basic Details Dialog =====
  void _showBasicDetails(Map<String, dynamic> p) {
    final String img = _resolveImageUrl(p['image'] ?? '');
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _EnhancedDialog(
        maxWidth: 600,
        maxHeight: 0.88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Header
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandPrimary, _brandLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                        CupertinoIcons.cube_box,
                        size: 22,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Product Details',
                        style: _t(
                          size: 20,
                          weight: FontWeight.w700,
                          color: CupertinoColors.white,
                          height: 1.2,
                        ),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (img.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                            const Center(child: CupertinoActivityIndicator()),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                size: 56,
                                color: CupertinoColors.systemGrey3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),

                    _DetailGroup(
                      title: 'BASIC INFORMATION',
                      icon: CupertinoIcons.info_circle_fill,
                      items: [
                        _DetailItem('Product ID', '${p['id'] ?? ''}'),
                        _DetailItem('Name', (p['name'] ?? '').toString()),
                        _DetailItem('SKU', (p['sku'] ?? '').toString()),
                        _DetailItem('Warehouse ID', '${p['warehouse_id'] ?? ''}'),
                      ],
                      t: _t,
                    ),

                    const SizedBox(height: 18),

                    _DetailGroup(
                      title: 'STOCK & LOCATION',
                      icon: CupertinoIcons.chart_bar_circle_fill,
                      items: [
                        _DetailItem('Current Stock', '${p['stock'] ?? 0}', highlight: true),
                        _DetailItem('Working Stock', '${p['working_stock'] ?? 0}'),
                        _DetailItem('Reserve Threshold', '${p['stock_reserve_threshold'] ?? 0}'),
                        _DetailItem(
                            'Physical Location', (p['stock_physical_location'] ?? '—').toString()),
                        _DetailItem('Sub Location', (p['stock_physical_sub_location'] ?? '—').toString()),
                      ],
                      t: _t,
                    ),

                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _warningOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _warningOrange.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            color: _warningOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Limited details available. Full product information could not be loaded.',
                              style: _t(size: 12, color: CupertinoColors.systemGrey, height: 1.3),
                            ),
                          ),
                        ],
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

  // ===== Enhanced Update Dialog =====
  void _openUpdateDialog(Map<String, dynamic> p) {
    final stockCtrl = TextEditingController(text: '0');
    final subLocCtrl =
    TextEditingController(text: (p['stock_physical_sub_location'] ?? '').toString());
    final thrCtrl = TextEditingController(text: '${p['stock_reserve_threshold'] ?? 0}');

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _EnhancedDialog(
        maxWidth: 520,
        maxHeight: 0.72,
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
                            style: _t(
                              size: 20,
                              weight: FontWeight.w700,
                              color: CupertinoColors.white,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'SKU: ${p['sku'] ?? 'N/A'}',
                            style: _t(
                              size: 12,
                              color: CupertinoColors.white.withOpacity(0.9),
                              height: 1.2,
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
            Flexible(
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
                      t: _t,
                    ),
                    const SizedBox(height: 18),
                    _FormField(
                      label: 'Sub-Location',
                      icon: CupertinoIcons.placemark_fill,
                      controller: subLocCtrl,
                      placeholder: 'e.g., A003, Shelf-5',
                      t: _t,
                    ),
                    const SizedBox(height: 18),
                    _FormField(
                      label: 'Reserve Threshold',
                      icon: CupertinoIcons.flag_fill,
                      controller: thrCtrl,
                      keyboardType: TextInputType.number,
                      placeholder: 'Minimum stock level',
                      t: _t,
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
                          Navigator.pop(ctx);
                          await _doUpdate(
                            productId: p['id'],
                            addStock: int.tryParse(stockCtrl.text) ?? 0,
                            newSubLoc: subLocCtrl.text.trim(),
                            newThreshold: int.tryParse(thrCtrl.text) ?? 0,
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
    );
  }

  Future<void> _doUpdate({
    required int productId,
    required int addStock,
    required String newSubLoc,
    required int newThreshold,
  }) async {
    try {
      _showLoadingDialog();
      final uri = Uri.parse('$baseUrl/catalog_products/update');
      final body = jsonEncode({
        'app_id': appId,
        'api_key': apiKey,
        'token': _token,
        'product_id': productId,
        'add_stock': addStock,
        'new_stock_physical_sub_location': newSubLoc,
        'new_stock_reserve_threshold': newThreshold,
      });
      final res = await http.post(
        uri,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: body,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['status_flag'] == 1) {
          _showDialog(
            title: 'Update Successful',
            message: 'Product updated successfully.',
            type: _DialogType.info,
          );
          await _fetchList(refresh: true);
          return;
        }
      }
      _showDialog(
        title: 'Update Failed',
        message: 'Could not update product. Please try again.',
        type: _DialogType.error,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      _showDialog(
        title: 'Network Error',
        message: 'Please check your connection and try again.',
        type: _DialogType.error,
      );
    }
  }

  // ===== Enhanced Outward Dialog with Image Upload =====
  void _openOutwardDialog(Map<String, dynamic> p) {
    final qtyCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    final int currentStock = p['stock'] ?? 0;
    final List<File> _selectedImages = [];
    bool _isProcessing = false;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => _EnhancedDialog(
          maxWidth: 520,
          maxHeight: 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_dangerRed, _dangerRed.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                              'Outward Product',
                              style: _t(
                                size: 20,
                                weight: FontWeight.w700,
                                color: CupertinoColors.white,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'SKU: ${p['sku'] ?? 'N/A'}',
                              style: _t(
                                size: 12,
                                color: CupertinoColors.white.withOpacity(0.9),
                                height: 1.2,
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _brandPrimary.withOpacity(0.08),
                              _brandLight.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _brandPrimary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _brandPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.cube_box_fill,
                                color: _brandPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Stock',
                                  style: _t(
                                      size: 12,
                                      color: CupertinoColors.systemGrey,
                                      height: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currentStock units',
                                  style: _t(
                                      size: 22,
                                      weight: FontWeight.w800,
                                      color: _brandPrimary,
                                      height: 1.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Quantity',
                        icon: CupertinoIcons.number,
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        placeholder: 'Enter quantity to remove',
                        isRequired: true,
                        t: _t,
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Remarks (Optional)',
                        icon: CupertinoIcons.text_bubble_fill,
                        controller: remarkCtrl,
                        placeholder: 'Add notes or reason',
                        maxLines: 3,
                        t: _t,
                      ),
                      const SizedBox(height: 18),

                      // Image Upload Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _infoBlue.withOpacity(0.08),
                              _infoBlue.withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _infoBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.camera_fill,
                                  color: _infoBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Upload Images (Optional)',
                                  style: _t(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: _infoBlue,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_selectedImages.length}/2',
                                  style: _t(
                                    size: 12,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedImages.isEmpty)
                              Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: CupertinoColors.separator.withOpacity(0.5),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.photo,
                                      size: 32,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add images',
                                      style: _t(
                                        size: 12,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_selectedImages.length, (index) {
                                  final image = _selectedImages[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _infoBlue.withOpacity(0.3),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: _dangerRed,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: CupertinoColors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.xmark,
                                              color: CupertinoColors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            const SizedBox(height: 8),
                            if (_selectedImages.length < 2)
                              SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (pickedFile != null) {
                                      setDialogState(() {
                                        _selectedImages.add(File(pickedFile.path));
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _infoBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _infoBlue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.add,
                                          color: _infoBlue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Add Image',
                                          style: _t(
                                            size: 12,
                                            weight: FontWeight.w600,
                                            color: _infoBlue,
                                          ),
                                        ),
                                      ],
                                    ),
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
                          label: _isProcessing ? 'Processing...' : 'Confirm Outward',
                          icon: _isProcessing ? CupertinoIcons.clock : CupertinoIcons.checkmark_alt,
                          onPressed: _isProcessing ? null : () async {
                            final qty = int.tryParse(qtyCtrl.text) ?? 0;
                            if (qty <= 0) {
                              _showDialog(
                                title: 'Invalid Quantity',
                                message: 'Please enter a quantity greater than 0.',
                                type: _DialogType.warning,
                              );
                              return;
                            }
                            if (qty > currentStock) {
                              _showDialog(
                                title: 'Insufficient Stock',
                                message:
                                'Quantity exceeds available stock ($currentStock units).',
                                type: _DialogType.warning,
                              );
                              return;
                            }

                            // Show processing state
                            setDialogState(() {
                              _isProcessing = true;
                            });

                            try {
                              final result = await _processOutward(
                                productId: p['id'].toString(),
                                quantity: qty,
                                remarks: remarkCtrl.text.trim(),
                                images: _selectedImages,
                              );

                              Navigator.pop(ctx);

                              if (result['success']) {
                                _showDialog(
                                  title: 'Outward Successful',
                                  message: result['message'],
                                  type: _DialogType.info,
                                );
                                await _fetchList(refresh: true);
                              } else {
                                _showDialog(
                                  title: 'Outward Failed',
                                  message: result['message'],
                                  type: _DialogType.error,
                                );
                              }
                            } catch (e) {
                              Navigator.pop(ctx);
                              _showDialog(
                                title: 'Network Error',
                                message: 'Failed to process outward. Please try again.',
                                type: _DialogType.error,
                              );
                            }
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
            mainAxisAlignment: MainAxisAlignment.center, // Center the row
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: _t(size: 17, weight: FontWeight.w600, height: 1.2),
                ),
              ),
            ],
          ),
        ),
        content: Text(
          message,
          style: _t(size: 13, height: 1.3),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: _t(size: 17, weight: FontWeight.w600, color: _infoBlue, height: 1.2),
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

  String _resolveImageUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final b = _imageBases.first;
    return b + (v.startsWith('/') ? v.substring(1) : v);
  }

  Color _stockColor(int stock, int threshold) {
    if (stock <= 0) return _dangerRed;
    if (stock <= threshold) return _warningOrange;
    return _successGreen;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _screenBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: _cardBg,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        middle: Text(
          'Product Below Threshold',
          style: _t(size: 17, weight: FontWeight.w600, height: 1.2),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: _showFiltersDialog,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: _brandPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: () => _fetchList(refresh: true),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.arrow_clockwise,
                  color: _brandPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Enhanced Search Bar with Search Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: _cardBg,
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        CupertinoSearchTextField(
                          controller: _searchCtrl,
                          placeholder: 'Search by name or SKU',
                          onChanged: (_) => _applyFilters(),
                          style: _t(size: 16, height: 1.2),
                          prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                          decoration: BoxDecoration(
                            color: _screenBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.separator.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        if (_loading && _searchCtrl.text.isNotEmpty)
                          Positioned(
                            right: 50,
                            top: 0,
                            bottom: 0,
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CupertinoActivityIndicator(
                                  radius: 8,
                                  animating: true,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _cardBg,
              child: Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _brandPrimary.withOpacity(0.12),
                          _brandLight.withOpacity(0.12)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _brandPrimary.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.cube_box,
                            size: 16, color: _brandPrimary),
                        const SizedBox(width: 6),
                        Text(
                          _searchCtrl.text.isNotEmpty
                              ? '${_filtered.length} results for "${_searchCtrl.text}"${_hasMore ? ' (loading more...)' : ''}'
                              : '${_filtered.length} of $_totalRecords',
                          style: _t(
                              size: 13,
                              weight: FontWeight.w700,
                              color: _brandPrimary,
                              height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_searchCtrl.text.isNotEmpty ||
                      _location.isNotEmpty ||
                      _subLocation.isNotEmpty ||
                      _stockFilter != _StockFilter.all ||
                      _stockRangeFilter != _StockRangeFilter.all ||
                      _sortField.isNotEmpty ||
                      _filterStockType.isNotEmpty)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: Size.zero,
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _location = '';
                          _subLocation = '';
                          _stockFilter = _StockFilter.all;
                          _stockRangeFilter = _StockRangeFilter.all;
                          _customStockMin = 0;
                          _customStockMax = 0;
                          _sortField = '';
                          _sortOrder = 'ASC';
                          _filterStockType = '';
                        });
                        _fetchList(refresh: true);
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _dangerRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _dangerRed.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.clear_circled_solid,
                                size: 16, color: _dangerRed),
                            const SizedBox(width: 6),
                            Text(
                              'Clear',
                              style: _t(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: _dangerRed,
                                  height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: _loading && _products.isEmpty
                  ? const Center(child: CupertinoActivityIndicator(radius: 18))
                  : CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () => _fetchList(refresh: true),
                  ),
                  // Show filtered count when filters are active
                  if (_hasActiveFilters && _filtered.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _brandPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _brandPrimary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.slider_horizontal_3,
                              color: _brandPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hasActiveFilters
                                    ? '${_filtered.length} of $_totalRecords products found'
                                    : '$_totalRecords total products',
                                style: _t(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: _brandPrimary,
                                ),
                              ),
                            ),
                            if (_location.isNotEmpty || _subLocation.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _brandPrimary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_location.isNotEmpty ? _location : ""}${_location.isNotEmpty && _subLocation.isNotEmpty ? " > " : ""}${_subLocation.isNotEmpty ? _subLocation : ""}',
                                  style: _t(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: _filtered.isEmpty
                        ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(t: _t),
                    )
                        : SliverList.builder(
                      itemCount: _filtered.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }
                        return _ProductCard(
                          product: _filtered[i],
                          stockColor: _stockColor,
                          resolveImage: _resolveImageUrl,
                          onTap: () => _openProductMenu(_filtered[i]),
                          t: _t,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== ENHANCED PROFESSIONAL WIDGETS =====

class _EnhancedDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const _EnhancedDialog({
    required this.child,
    this.maxWidth = 600,
    this.maxHeight = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = math.min(size.width * 0.95, maxWidth);
    final height = size.height * maxHeight;

    return Center(
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: height),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B52A3).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF6B52A3)),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.label.resolveFrom(context),
                letterSpacing: 0.6,
                height: 1.2,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SelectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B52A3)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
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
        ? CupertinoColors.systemGrey5.resolveFrom(context)
        : const Color(0xFF6B52A3);

    final textColor = isSecondary
        ? CupertinoColors.label.resolveFrom(context)
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_DetailItem> items;
  final TextStyle Function(
      {double size, FontWeight weight, Color? color, double? height}) t;

  const _DetailGroup({
    required this.title,
    required this.icon,
    required this.items,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B52A3).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF6B52A3)),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                letterSpacing: 0.8,
                height: 1.2,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        item.label,
                        style: t(
                          size: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          height: 1.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: t(
                          size: 13,
                          weight: item.highlight ? FontWeight.w700 : FontWeight.w500,
                          color: item.highlight
                              ? const Color(0xFF6B52A3)
                              : CupertinoColors.label.resolveFrom(context),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final bool highlight;

  _DetailItem(this.label, this.value, {this.highlight = false});
}

class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? placeholder;
  final bool isRequired;
  final int maxLines;
  final TextStyle Function(
      {double size, FontWeight weight, Color? color, double? height}) t;

  const _FormField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.t,
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
              style: t(
                size: 13,
                weight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
                height: 1.2,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: t(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xFFFF3B30),
                  height: 1.2,
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
          style: TextStyle(
            fontSize: 15,
            height: 1.3,
            decoration: TextDecoration.none,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final void Function() onTap;
  final Color Function(int stock, int threshold) stockColor;
  final String Function(String) resolveImage;
  final TextStyle Function(
      {double size, FontWeight weight, Color? color, double? height}) t;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.stockColor,
    required this.resolveImage,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final stock = product['stock'] ?? 0;
    final threshold = product['stock_reserve_threshold'] ?? 0;
    final working = product['working_stock'] ?? 0;
    final loc = (product['stock_physical_location'] ?? '').toString();
    final subLoc = (product['stock_physical_sub_location'] ?? '').toString();
    final String img = resolveImage('${product['image'] ?? ''}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.separator.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: img.isEmpty
                      ? const Icon(CupertinoIcons.cube_box,
                      color: CupertinoColors.systemGrey3, size: 30)
                      : CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                    const Center(child: CupertinoActivityIndicator()),
                    errorWidget: (_, __, ___) => const Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.systemGrey3,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: stockColor(
                                stock is int ? stock : 0, threshold is int ? threshold : 0),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: stockColor(
                                    stock is int ? stock : 0, threshold is int ? threshold : 0)
                                    .withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            (product['name'] ?? 'Unknown Product').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t(size: 15, weight: FontWeight.w700, height: 1.25),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6B52A3).withOpacity(0.12),
                                const Color(0xFF8B7AB8).withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF6B52A3).withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$stock',
                            style: t(
                                size: 15,
                                weight: FontWeight.w800,
                                color: const Color(0xFF6B52A3),
                                height: 1.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'SKU: ${product['sku'] ?? 'N/A'}',
                      style: t(size: 12, color: CupertinoColors.systemGrey, height: 1.2),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      runSpacing: 7,
                      spacing: 7,
                      children: [
                        _Chip(
                          icon: CupertinoIcons.cube_box,
                          label: 'Stock',
                          value: '$stock',
                          color: const Color(0xFF34C759),
                          t: t,
                        ),
                        _Chip(
                          icon: CupertinoIcons.chart_bar,
                          label: 'Working',
                          value: '$working',
                          color: const Color(0xFF007AFF),
                          t: t,
                        ),
                        _Chip(
                          icon: CupertinoIcons.flag,
                          label: 'Threshold',
                          value: '$threshold',
                          color: const Color(0xFFFF9500),
                          t: t,
                        ),
                        if (loc.isNotEmpty)
                          _Chip(
                            icon: CupertinoIcons.location,
                            label: 'Location',
                            value: subLoc.isNotEmpty ? '$loc-$subLoc' : loc,
                            color: const Color(0xFF5856D6),
                            t: t,
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final TextStyle Function(
      {double size, FontWeight weight, Color? color, double? height}) t;

  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text('$label: ', style: t(size: 10, color: color, weight: FontWeight.w500, height: 1.2)),
          Text(value, style: t(size: 10, weight: FontWeight.w800, color: color, height: 1.2)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TextStyle Function(
      {double size, FontWeight weight, Color? color, double? height}) t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGrey6.withOpacity(0.5),
                CupertinoColors.systemGrey6.withOpacity(0.3),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.cube_box,
            size: 64,
            color: CupertinoColors.systemGrey3,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No products found',
          style: t(size: 18, weight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your search or filters',
          style: t(size: 14, color: CupertinoColors.systemGrey, height: 1.2),
        ),
      ],
    );
  }
}

class _Banner extends StatefulWidget {
  final String msg;
  final bool isError;
  final TextStyle Function(
      {double size, FontWeight weight, Color? color, double? height}) t;
  const _Banner({required this.msg, required this.isError, required this.t});

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final Animation<double> _opacity =
  CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.98),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (widget.isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759))
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isError ? CupertinoIcons.xmark : CupertinoIcons.checkmark,
                  size: 16,
                  color: widget.isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.msg,
                  style: widget.t(size: 14, weight: FontWeight.w500, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StockFilter { all, inStock, lowStock, outOfStock }

enum _StockRangeFilter { all, range0, range1to10, range11to50, range51to100, range101to500, range501plus, custom }

enum _DialogType { info, warning, error }
