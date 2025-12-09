// lib/screens/oms_all_order.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'second_scanner.dart';

// --- Utility Extensions for Colors ---
extension DarkColor on Color {
  Color get darkColor => Color.alphaBlend(
        Colors.black.withOpacity(0.4),
        this,
      );
}

// =====================
// DATA MODELS
// =====================
class OMSOrder {
  final int id;
  final String? invoiceId;
  final String? invoiceDate;
  final String? orderDate;
  final String? shipmentDate;
  final String? deliveredDate;
  final String? warehouse;
  final String? channel;
  final String? company;
  final String? buyerName;
  final String? buyerAddress1;
  final String? buyerAddress2;
  final String? buyerState;
  final String? buyerCity;
  final String? buyerPincode;
  final String? buyerPhone;
  final String? buyerEmail;
  final String? gstName;
  final String? gstNumber;
  final String? billingName;
  final String? billingAddress1;
  final String? billingAddress2;
  final String? billingCity;
  final String? billingState;
  final String? billingPincode;
  final String? billingPhone;
  final String? billingEmail;
  final String? shippingCompany;
  final String? shipmentTracker;
  final String? orderType;
  final String? packLog;
  int? _pickStatus;

  OMSOrder({
    required this.id,
    this.invoiceId,
    this.invoiceDate,
    this.orderDate,
    this.shipmentDate,
    this.deliveredDate,
    this.warehouse,
    this.channel,
    this.company,
    this.buyerName,
    this.buyerAddress1,
    this.buyerAddress2,
    this.buyerState,
    this.buyerCity,
    this.buyerPincode,
    this.buyerPhone,
    this.buyerEmail,
    this.gstName,
    this.gstNumber,
    this.billingName,
    this.billingAddress1,
    this.billingAddress2,
    this.billingCity,
    this.billingState,
    this.billingPincode,
    this.billingPhone,
    this.billingEmail,
    this.shippingCompany,
    this.shipmentTracker,
    this.orderType,
    this.packLog,
    int? pickStatus = 0,
  }) : _pickStatus = pickStatus;

  int? get pickStatus => _pickStatus;

  set pickStatus(int? value) {
    _pickStatus = value;
  }

  factory OMSOrder.fromJson(Map<String, dynamic> json) {
    return OMSOrder(
      id: _parseInt(json['o_id']) ?? 0,
      invoiceId: json['o_invoice_id']?.toString(),
      invoiceDate: json['o_invoice_date']?.toString(),
      orderDate: json['o_order_date']?.toString(),
      shipmentDate: json['o_shipment_date']?.toString(),
      deliveredDate: json['o_delivered_date']?.toString(),
      warehouse: json['o_warehouse']?.toString(),
      channel: json['o_channel']?.toString(),
      company: json['o_company']?.toString(),
      buyerName: json['o_buyer_name']?.toString(),
      buyerAddress1: json['o_buyer_address1']?.toString(),
      buyerAddress2: json['o_buyer_address2']?.toString(),
      buyerState: json['o_buyer_state']?.toString(),
      buyerCity: json['o_buyer_city']?.toString(),
      buyerPincode: json['o_buyer_pincode']?.toString(),
      buyerPhone: json['o_buyer_phone']?.toString(),
      buyerEmail: json['o_buyer_email']?.toString(),
      gstName: json['o_gst_name']?.toString(),
      gstNumber: json['o_gst_number']?.toString(),
      billingName: json['o_billing_name']?.toString(),
      billingAddress1: json['o_billing_address1']?.toString(),
      billingAddress2: json['o_billing_address2']?.toString(),
      billingCity: json['o_billing_city']?.toString(),
      billingState: json['o_billing_state']?.toString(),
      billingPincode: json['o_billing_pincode']?.toString(),
      billingPhone: json['o_billing_phone']?.toString(),
      billingEmail: json['o_billing_email']?.toString(),
      shippingCompany: json['o_shipping_company']?.toString(),
      shipmentTracker: json['o_shipment_tracker']?.toString(),
      orderType: json['o_order_type']?.toString(),
      packLog: json['o_pack_log']?.toString(),
      pickStatus: _parseInt(json['o_pick_status']) ?? 0,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}

class OMSOrderItem {
  final int id;
  final int orderId;
  final String? channelOrderId;
  final String? channelSubOrderId;
  final String? skuCode;
  final int? qty;
  final double? sellingPrice;
  final double? shippingCharge;
  final double? promoDiscounts;
  final double? giftWrapCharges;
  final double? transactionCharges;
  final double? invoiceAmount;
  final String? currencyCode;
  final double? taxRate;
  final double? taxAmount;
  final double? igstRate;
  final double? igstAmount;
  final double? cgstRate;
  final double? cgstAmount;
  final double? sgstRate;
  final double? sgstAmount;
  final String? status;
  final double? settlementAmount;
  final String? skuUpc;
  final String? listingSku;
  final String? createdAt;
  final String? updatedAt;

  OMSOrderItem({
    required this.id,
    required this.orderId,
    this.channelOrderId,
    this.channelSubOrderId,
    this.skuCode,
    this.qty,
    this.sellingPrice,
    this.shippingCharge,
    this.promoDiscounts,
    this.giftWrapCharges,
    this.transactionCharges,
    this.invoiceAmount,
    this.currencyCode,
    this.taxRate,
    this.taxAmount,
    this.igstRate,
    this.igstAmount,
    this.cgstRate,
    this.cgstAmount,
    this.sgstRate,
    this.sgstAmount,
    this.status,
    this.settlementAmount,
    this.skuUpc,
    this.listingSku,
    this.createdAt,
    this.updatedAt,
  });

  factory OMSOrderItem.fromJson(Map<String, dynamic> json) {
    return OMSOrderItem(
      id: json['i_id'] ?? 0,
      orderId: json['i_order_id'] ?? 0,
      channelOrderId: json['i_channel_order_id']?.toString(),
      channelSubOrderId: json['i_channel_sub_order_id']?.toString(),
      skuCode: json['i_sku_code'],
      qty: _parseInt(json['i_qty']),
      sellingPrice: _parseDouble(json['i_selling_price_per_item']),
      shippingCharge: _parseDouble(json['i_shipping_charge_per_item']),
      promoDiscounts: _parseDouble(json['i_promo_discounts']),
      giftWrapCharges: _parseDouble(json['i_gift_wrap_charges']),
      transactionCharges: _parseDouble(json['i_transaction_charges']),
      invoiceAmount: _parseDouble(json['i_invoice_amount']),
      currencyCode: json['i_currency_code'],
      taxRate: _parseDouble(json['i_tax_rate']),
      taxAmount: _parseDouble(json['i_tax_amount']),
      igstRate: _parseDouble(json['i_igst_rate']),
      igstAmount: _parseDouble(json['i_igst_amount']),
      cgstRate: _parseDouble(json['i_cgst_rate']),
      cgstAmount: _parseDouble(json['i_cgst_amount']),
      sgstRate: _parseDouble(json['i_sgst_rate']),
      sgstAmount: _parseDouble(json['i_sgst_amount']),
      status: json['i_status'],
      settlementAmount: _parseDouble(json['i_settlement_amount']),
      skuUpc: json['i_sku_upc'],
      listingSku: json['i_listing_sku'],
      createdAt: json['i_created_at']?.toString(),
      updatedAt: json['i_updated_at']?.toString(),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class OMSOrderWithItem {
  final OMSOrder order;
  final OMSOrderItem? item;

  OMSOrderWithItem(this.order, this.item);

  factory OMSOrderWithItem.fromJson(Map<String, dynamic> json) {
    return OMSOrderWithItem(
      OMSOrder.fromJson(json),
      json['i_id'] != null ? OMSOrderItem.fromJson(json) : null,
    );
  }
}

// Stock Data Model (from all_data_fetch.php + used for rack-wise stock)
class StockData {
  final int id;
  final int warehouseId;
  final int skuId;
  final String skuCode;
  final String name;
  final int blocked;
  final int inStock;
  final int badStock;
  final String? updatedAt;
  final String? createdAt;
  final List<String> baseImages;
  final List<String> dailyImages;
  final List<String> allImages;

  StockData({
    required this.id,
    required this.warehouseId,
    required this.skuId,
    required this.skuCode,
    required this.name,
    required this.blocked,
    required this.inStock,
    required this.badStock,
    this.updatedAt,
    this.createdAt,
    this.baseImages = const [],
    this.dailyImages = const [],
    this.allImages = const [],
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    List<String> _parseImageList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      if (v is String && v.isNotEmpty) {
        return [v];
      }
      return <String>[];
    }

    return StockData(
      id: _parseInt(json['id']),
      warehouseId: _parseInt(json['warehouse_id']),
      skuId: _parseInt(json['sku_id']),
      skuCode: json['sku_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      blocked: _parseInt(json['blocked']),
      inStock: _parseInt(json['in_stock']),
      badStock: _parseInt(json['bad_stock']),
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      baseImages: _parseImageList(json['base_image']),
      dailyImages: _parseImageList(json['daily_image']),
      allImages: _parseImageList(json['images']),
    );
  }

  bool get hasStock => inStock > 0;
  bool get isBlocked => blocked > 0;
}

class RackStock {
  final String id;
  final String skuId;
  final String skuCode;
  final String rackSpaceId;
  final String? rackSpaceName;
  final int inStock;
  final int badStock;

  RackStock({
    required this.id,
    required this.skuId,
    required this.skuCode,
    required this.rackSpaceId,
    this.rackSpaceName,
    required this.inStock,
    required this.badStock,
  });

  factory RackStock.fromJson(Map<String, dynamic> json) {
    return RackStock(
      id: json['id']?.toString() ?? '',
      skuId: json['sku_id']?.toString() ?? '',
      skuCode: json['sku_code']?.toString() ?? '',
      rackSpaceId: json['rack_space_id']?.toString() ?? '',
      rackSpaceName: json['rack_space_name']?.toString(),
      inStock: int.tryParse(json['in_stock']?.toString() ?? '0') ?? 0,
      badStock: int.tryParse(json['bad_stock']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isUnassigned =>
      rackSpaceId == '-1' || rackSpaceName == null || rackSpaceName!.isEmpty;
}

class ChildSKU {
  final String? code;
  final String? qty;
  final String? price;

  ChildSKU({this.code, this.qty, this.price});

  bool get isValid => code != null && code!.isNotEmpty;
}

class ComboSKUBreakdown {
  final String orderId;
  final String? skuCode;
  final String? shipmentTracker;
  final String? comboSkuCode;
  final List<ChildSKU> childSkus;

  ComboSKUBreakdown({
    required this.orderId,
    this.skuCode,
    this.shipmentTracker,
    this.comboSkuCode,
    required this.childSkus,
  });

  factory ComboSKUBreakdown.fromJson(Map<String, dynamic> json) {
    final List<ChildSKU> children = [];

    for (int i = 1; i <= 10; i++) {
      final code = json['child_sku_code_$i']?.toString();
      final qty = json['child_sku_qty_$i']?.toString();
      final price = json['child_sku_price_$i']?.toString();

      if (code != null && code.isNotEmpty) {
        children.add(ChildSKU(code: code, qty: qty, price: price));
      }
    }

    return ComboSKUBreakdown(
      orderId: json['order_id']?.toString() ?? '',
      skuCode: json['sku_code']?.toString(),
      shipmentTracker: json['shipment_tracker']?.toString(),
      comboSkuCode: json['combo_sku_code']?.toString(),
      childSkus: children,
    );
  }
}

/// Represents a single child SKU returned by combo_sku_rack_space.php
class ComboRackChild {
  final int skuId;
  final String skuCode;

  ComboRackChild({
    required this.skuId,
    required this.skuCode,
  });

  factory ComboRackChild.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ComboRackChild(
      skuId: _parseInt(json['sku_id']),
      skuCode: json['sku_code']?.toString() ?? '',
    );
  }
}

/// Holds rack-wise stock for one child SKU (Option A grouping)
class ComboSkuRackInfo {
  final ComboRackChild child;
  final List<RackStock> racks;

  ComboSkuRackInfo({
    required this.child,
    required this.racks,
  });
}

// =====================
// API SERVICE
// =====================
class OMSApiService {
  static const String listBaseUrl =
      'https://customprint.deodap.com/stockbridge/get_oms_daily_order.php';

  static const String syncUrl =
      'https://customprint.deodap.com/stockbridge/oms_live_order.php?key=DeoDap@2025Sync&mode=incremental';

  static const String childSkuBaseUrl =
      'https://customprint.deodap.com/stockbridge/child_sku_list.php';

  // NOTE: base URL only, key + search are passed as query parameters
  static const String stockBaseUrl =
      'https://customprint.deodap.com/stockbridge/all_data_fetch.php';

  static const String omsStockUrl =
      'https://client.omsguru.com/order_api/stocks';

  static const String rackWiseBaseUrl =
      'https://client.omsguru.com/order_api/rack_wise_stock';

  static const String pickMarkUrl =
      'https://customprint.deodap.com/stockbridge/order_pick_mark.php';

  static const String comboRackBaseUrl =
      'https://customprint.deodap.com/stockbridge/combo_sku_rack_space.php';

  static Future<Map<String, dynamic>> fetchOrders({
    String mode = 'flat',
    int page = 1,
    int perPage = 20,
    String? instantSearch,
    String? searchField,
    bool cpOnly = false,
    String sortBy = 'order_date',
    String sortDir = 'DESC',
    bool includeStats = false,
  }) async {
    final params = <String, String>{
      'mode': mode,
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort_by': sortBy,
      'sort_dir': sortDir,
      'include_stats': includeStats ? '1' : '0',
      'cp_only': cpOnly ? '1' : '0',
    };

    if (instantSearch != null && instantSearch.trim().isNotEmpty) {
      params['instant_search'] = instantSearch.trim();
      params['search_field'] = searchField ?? 'auto';
    }

    final uri = Uri.parse(listBaseUrl).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  }

  /// NEW METHOD: Fetch all orders matching a specific shipment tracker.
  static Future<List<OMSOrderWithItem>> fetchOrdersByTracker(
      String shipmentTracker) async {
    final resp = await fetchOrders(
      // Max page size to grab all orders at once for one tracker.
      perPage: 100,
      instantSearch: shipmentTracker.trim(),
      searchField: 'tracker',
      // Assuming a tracker might span both CP and non-CP orders, but you may
      // need to adjust this based on your API logic. For now, fetch all.
      cpOnly: false,
      sortBy: 'order_date',
      sortDir: 'ASC',
    );

    if (resp['ok'] == true && resp['data'] is List) {
      final List<dynamic> data = resp['data'] as List<dynamic>;
      return data.map((e) => OMSOrderWithItem.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> triggerLiveSync() async {
    final resp = await http.get(Uri.parse(syncUrl));
    if (resp.statusCode != 200) return false;

    try {
      final body = json.decode(resp.body);
      if (body is Map && (body['ok'] == true || body['status'] == 'ok')) {
        return true;
      }
      if (body is String && body.toUpperCase().contains('OK')) return true;
    } catch (_) {
      if (resp.body.toUpperCase().contains('OK')) return true;
    }
    return true;
  }

  static Future<List<ComboSKUBreakdown>> fetchChildSkus(int orderId) async {
    final uri = Uri.parse('$childSkuBaseUrl?order_id=$orderId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);

      if (body['error'] == 0 && body['data'] != null) {
        final List<dynamic> data = body['data'] as List<dynamic>;
        return data
            .map((e) => ComboSKUBreakdown.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load child SKUs: ${response.statusCode}');
    }
  }

  /// Fetch stock + base image using all_data_fetch.php
  /// Now more robust to JSON shape differences and always trims the SKU code.
  static Future<StockData?> fetchStockBySku(String skuCode) async {
    final searchCode = skuCode.trim();
    if (searchCode.isEmpty) return null;

    final uri = Uri.parse(stockBaseUrl).replace(queryParameters: {
      'key': 'DeoDap@2025Stock',
      'search': searchCode,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load stock: HTTP ${response.statusCode}');
    }

    final body = json.decode(response.body);
    Map<String, dynamic>? candidate;

    if (body is Map<String, dynamic>) {
      dynamic data =
          body['data'] ?? body['rows'] ?? body['result'] ?? body['results'];

      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          candidate = first;
        }
      } else if (data is Map<String, dynamic>) {
        candidate = data;
      } else if (body['sku'] is Map<String, dynamic>) {
        candidate = body['sku'] as Map<String, dynamic>;
      }
    } else if (body is List && body.isNotEmpty) {
      final first = body.first;
      if (first is Map<String, dynamic>) {
        candidate = first;
      }
    }

    if (candidate != null) {
      return StockData.fromJson(candidate);
    }

    return null;
  }

  static Future<List<RackStock>> fetchRackWiseStock(
    int skuId, {
    int lastId = 0,
    int warehouseId = 7208,
  }) async {
    final uri = Uri.parse(
        '$rackWiseBaseUrl?last_id=$lastId&warehouse_id=$warehouseId&sku_ids=$skuId');

    final resp = await http.get(
      uri,
      headers: const {
        'Authorization': 'Bearer 7DOHq0j6dbfNKYWIzyGBJtlEZaosxiUm',
        'oms-cid': '33532',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to load rack-wise stock: ${resp.statusCode}');
    }

    final body = json.decode(resp.body);
    if (body is Map<String, dynamic> &&
        body['success'] == true &&
        body['data'] is List) {
      final list = body['data'] as List;
      return list
          .map((e) => RackStock.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// For a combo SKU, get all underlying child SKUs (sku_id + sku_code)
  /// using combo_sku_rack_space.php
  static Future<List<ComboRackChild>> fetchComboRackChildren(
    String comboSkuCode, {
    int warehouseId = 7208,
    String type = 'daily',
  }) async {
    final code = comboSkuCode.trim();
    if (code.isEmpty) return [];

    final uri = Uri.parse(comboRackBaseUrl);

    // This endpoint is used as POST in Postman; we'll send the minimal fields.
    final resp = await http.post(
      uri,
      body: {
        'sku': code,
        'warehouse_id': warehouseId.toString(),
        'type': type,
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to load combo rack children: ${resp.statusCode}');
    }

    final body = json.decode(resp.body);
    if (body is Map<String, dynamic> && body['data'] is List) {
      final list = body['data'] as List;
      return list
          .map((e) => ComboRackChild.fromJson(e as Map<String, dynamic>))
          .where((c) => c.skuId != 0 && c.skuCode.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Uses your API:
  /// POST order_pick_mark.php
  /// Body: { "shipment_tracker": "...", "emp_code": "...", "status": "picked"/"unpicked" }
  /// Response: { "status": true/false, "message": "...", "data": {...} }
  static Future<bool> markAsPicked(
    String shipmentTracker,
    String empCode,
    bool picked,
  ) async {
    final uri = Uri.parse(pickMarkUrl);
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({
        'shipment_tracker': shipmentTracker,
        'emp_code': empCode,
        'status': picked ? 'picked' : 'unpicked',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark order as picked: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    // Note: The API should update ALL orders linked to the same tracker
    return body is Map<String, dynamic> && body['status'] == true;
  }
}

enum SearchFilterType {
  auto,
  orderId,
  channel,
  sku,
  buyer,
  warehouse,
  tracker,
}

extension SearchFilterTypeExt on SearchFilterType {
  String get value {
    switch (this) {
      case SearchFilterType.auto:
        return 'auto';
      case SearchFilterType.orderId:
        return 'order_id';
      case SearchFilterType.channel:
        return 'channel';
      case SearchFilterType.sku:
        return 'sku';
      case SearchFilterType.buyer:
        return 'buyer';
      case SearchFilterType.warehouse:
        return 'warehouse';
      case SearchFilterType.tracker:
        return 'tracker';
    }
  }

  String get label {
    switch (this) {
      case SearchFilterType.auto:
        return 'Auto Detect';
      case SearchFilterType.orderId:
        return 'Order ID';
      case SearchFilterType.channel:
        return 'Channel';
      case SearchFilterType.sku:
        return 'SKU';
      case SearchFilterType.buyer:
        return 'Buyer';
      case SearchFilterType.warehouse:
        return 'Warehouse';
      case SearchFilterType.tracker:
        return 'Tracker';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchFilterType.auto:
        return CupertinoIcons.search;
      case SearchFilterType.orderId:
        return CupertinoIcons.doc_text_fill;
      case SearchFilterType.channel:
        return CupertinoIcons.cube_box;
      case SearchFilterType.sku:
        return CupertinoIcons.barcode;
      case SearchFilterType.buyer:
        return CupertinoIcons.person_fill;
      case SearchFilterType.warehouse:
        return CupertinoIcons.building_2_fill;
      case SearchFilterType.tracker:
        return CupertinoIcons.airplane;
    }
  }
}

// =====================
// MAIN SCREEN
// =====================
class OMSDailyOrdersScreen extends StatefulWidget {
  const OMSDailyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<OMSDailyOrdersScreen> createState() => _OMSDailyOrdersScreenState();
}

class _OMSDailyOrdersScreenState extends State<OMSDailyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final List<OMSOrderWithItem> _orders = [];
  String? _error;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int _page = 1;
  final int _perPage = 20;
  int _totalRows = 0;

  String _sortBy = 'order_date';
  String _sortDir = 'DESC';

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  bool _cpOnly = false;
  SearchFilterType _searchFilter = SearchFilterType.auto;
  bool _showFilterMenu = false;

  final ScrollController _scrollCtrl = ScrollController();

  late TabController _tabController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollCtrl.addListener(_onScroll);
    _initialLoad();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _triggerLiveSync({bool showToast = true}) async {
    setState(() => _isSyncing = true);
    try {
      final ok = await OMSApiService.triggerLiveSync();
      if (!mounted) return;
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ok ? 'Sync started (incremental).' : 'Sync call failed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newCpOnly = _tabController.index == 1;
    if (newCpOnly != _cpOnly) {
      setState(() {
        _cpOnly = newCpOnly;
        _page = 1;
        _hasMore = true;
      });
      _fetchPage(reset: true);
    }
  }

  Future<void> _handleScan(String? scannedText) async {
    if (scannedText != null && scannedText.trim().isNotEmpty) {
      // Pass the scanned tracker for merged lookup
      await _handleScannedShipment(
        scannedText,
        searchField: 'tracker',
      );
    }
  }

  /// Refactored to fetch ALL orders linked to the scanned code (expected to be a tracker)
  Future<void> _handleScannedShipment(
    String scannedText, {
    String searchField = 'tracker', // Force search by tracker
  }) async {
    final code = scannedText.trim();
    if (code.isEmpty) return;

    // Remove local cache search as it's insufficient for a merged view

    if (!mounted) return;

    // Show loading dialog
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Searching'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            CupertinoActivityIndicator(),
            SizedBox(height: 8),
            Text(
              'Looking up shipment tracker...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      final List<OMSOrderWithItem> foundOrders =
          await OMSApiService.fetchOrdersByTracker(code);

      if (!mounted) return;
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (foundOrders.isNotEmpty) {
        // Show the new Merged Order Details Sheet
        _showMergedOrderSheet(context, foundOrders);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No orders found for tracker: $code'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching order: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _initialLoad() async {
    setState(() => _isFirstLoad = true);
    _page = 1;
    _orders.clear();
    _hasMore = true;
    await _fetchPage(reset: true);
    if (mounted) setState(() => _isFirstLoad = false);
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (!_hasMore && !reset) return;
    if (_isLoadingMore && !reset) return;

    setState(() {
      _error = null;
      if (!reset) _isLoadingMore = true;
    });

    final searchText = _searchCtrl.text.trim();

    try {
      final resp = await OMSApiService.fetchOrders(
        page: _page,
        perPage: _perPage,
        instantSearch: searchText.isEmpty ? null : searchText,
        searchField: _searchFilter.value,
        cpOnly: _cpOnly,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );

      if (resp['ok'] == true) {
        final List<dynamic> data = (resp['data'] ?? []) as List<dynamic>;
        final newItems = data.map((e) => OMSOrderWithItem.fromJson(e)).toList();

        if (reset) {
          _orders.clear();
          _totalRows = (resp['total_rows'] ?? 0) as int;
        }
        _orders.addAll(newItems);

        final totalPages = (resp['total_pages'] ?? 0) as int;
        final chunkHadLess = newItems.length < _perPage;
        _hasMore = totalPages == 0
            ? !chunkHadLess && _orders.length < _totalRows
            : _page < totalPages;

        if (_hasMore) _page += 1;
      } else {
        _error = 'Server error';
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
      _hasMore = false;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent * 0.92) {
      _fetchPage();
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _page = 1;
      _hasMore = true;
      _fetchPage(reset: true);
    });
  }

  String _formatDate(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return '';
    try {
      final timestamp = int.tryParse(timestampStr);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        return DateFormat('dd/MM/yyyy hh.mm a').format(date);
      }
      return timestampStr;
    } catch (_) {
      return timestampStr;
    }
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      isScrollable: false,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
      indicatorColor: Theme.of(context).colorScheme.primary,
      tabs: const [
        Tab(text: 'All Orders'),
        Tab(text: 'CP Only'),
      ],
    );
  }

  Widget _buildFilterMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: SearchFilterType.values.map((filter) {
          final isActive = _searchFilter == filter;
          return FilterChip(
            selected: isActive,
            onSelected: (selected) {
              setState(() {
                _searchFilter = filter;
                _showFilterMenu = false;
              });
              _page = 1;
              _hasMore = true;
              _fetchPage(reset: true);
            },
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(filter.icon, size: 14),
                const SizedBox(width: 4),
                Text(filter.label),
              ],
            ),
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withOpacity(0.3),
            ),
            labelStyle: TextStyle(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              fontSize: 12,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Tooltip(
                message: 'Scan Shipment Tracker',
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondScanner(),
                      ),
                    );

                    await _handleScan(result as String?);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  placeholder: 'Search orders...',
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) {
                    _page = 1;
                    _hasMore = true;
                    _fetchPage(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Filter',
                child: IconButton(
                  icon: const Icon(CupertinoIcons.slider_horizontal_3),
                  onPressed: () {
                    setState(() => _showFilterMenu = !_showFilterMenu);
                  },
                ),
              ),
            ],
          ),
          if (_showFilterMenu) ...[
            const SizedBox(height: 8),
            _buildFilterMenu(context),
          ],
        ],
      ),
    );
  }

  /// Original method to show single order details
  void _showOrderSheet(BuildContext context, OMSOrderWithItem ow) {
    // Wrap single order in a list for compatibility
    _showMergedOrderSheet(context, [ow]);
  }

  /// NEW METHOD to show merged order details
  void _showMergedOrderSheet(
      BuildContext context, List<OMSOrderWithItem> orders) {
    if (orders.isEmpty) return;

    // Use the renamed, refactored bottom sheet
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return _MergedOrderDetailsSheet(
          orders: orders,
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: CupertinoColors.systemBlue,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.secondarySystemBackground,
      appBar: AppBar(
        title: const Text('OMS Orders'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Manual Sync',
            onPressed: _isSyncing
                ? null
                : () async {
                    await _triggerLiveSync();
                    _page = 1;
                    _hasMore = true;
                    await _fetchPage(reset: true);
                  },
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.refresh_bold),
          ),
        ],
        bottom: _buildTabBar(context),
      ),
      body: Column(
        children: [
          _buildToolbar(context),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                  color: Colors.black.withOpacity(0.05),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.list_bullet,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Total: $_totalRows orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Showing ${_orders.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isFirstLoad
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.exclamationmark_circle,
                                size: 48, color: Colors.red.withOpacity(0.6)),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initialLoad,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.folder_open,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text('No orders found'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              _page = 1;
                              _hasMore = true;
                              await _fetchPage(reset: true);
                            },
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: _orders.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _orders.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                        child: CupertinoActivityIndicator()),
                                  );
                                }
                                final ow = _orders[index];
                                return _OrderRowCard(
                                  orderWithItem: ow,
                                  onTap: () => _showOrderSheet(context, ow),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// =====================
// MERGED ORDER DETAILS SHEET (Refactored from _OrderDetailsSheet)
// =====================

class _MergedOrderDetailsSheet extends StatefulWidget {
  final List<OMSOrderWithItem> orders;
  // Consolidated properties for display clarity
  final String? tracker;
  final String title;
  final bool isSingleOrder;
  final bool initialIsPicked;

  _MergedOrderDetailsSheet({
    Key? key,
    required this.orders,
  })  : isSingleOrder = orders.length == 1,
        tracker = orders.isNotEmpty ? orders.first.order.shipmentTracker : null,
        title = orders.length == 1
            ? 'Order #${orders.first.order.id}'
            : (orders.isNotEmpty && orders.first.order.shipmentTracker != null
                ? 'Tracker: ${orders.first.order.shipmentTracker}'
                : 'Multiple Orders'),
        // An order is marked as 'picked' only if ALL linked orders are picked.
        initialIsPicked =
            orders.isNotEmpty && orders.every((o) => o.order.pickStatus == 1),
        super(key: key);

  @override
  State<_MergedOrderDetailsSheet> createState() =>
      _MergedOrderDetailsSheetState();
}

class _MergedOrderDetailsSheetState extends State<_MergedOrderDetailsSheet> {
  List<ComboSKUBreakdown>? _allChildSkus;
  bool _isLoadingChildSkus = false;
  String? _childSkuError;

  // Use a map to consolidate stock data by SKU code
  Map<String, StockData>? _allStockData;
  bool _isLoadingStock = false;
  String? _stockError;

  // Use a map to consolidate rack stocks by SKU ID
  Map<int, List<RackStock>>? _allRackStocks; // base SKU rack-wise
  bool _isLoadingRackStocks = false;
  String? _rackStocksError;

  // NEW: combo → child SKU rack-wise stock (Option A)
  List<ComboSkuRackInfo>? _comboRackStocks;
  bool _isLoadingComboRackStocks = false;
  String? _comboRackStocksError;

  late bool _isPicked;
  bool _isUpdatingPickStatus = false;
  String? _empCode; // from SharedPreferences

  // Collapsible sections
  bool _showBuyer = false;
  bool _showItem = true;
  bool _showPricing = false;
  bool _showTax = false;
  bool _showOrderInfo = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isPicked = widget.initialIsPicked;
    _loadEmpCode();
    _loadAllChildSkus();
    _loadAllStockData();
    // Rack stocks are loaded after stock data is fetched
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('employee_emp_code') ?? '';
    if (!mounted) return;
    setState(() {
      _empCode = code;
    });
  }

  Future<void> _loadAllStockData() async {
    // 1. Collect all unique SKU codes from all items across all orders
    final Set<String> uniqueSkus = {};
    final Map<String, int> skuToIdMap = {};

    for (final orderWithItem in widget.orders) {
      final item = orderWithItem.item;
      if (item == null) continue;

      if (item.skuCode != null && item.skuCode!.trim().isNotEmpty) {
        uniqueSkus.add(item.skuCode!.trim());
      }
      if (item.listingSku != null && item.listingSku!.trim().isNotEmpty) {
        uniqueSkus.add(item.listingSku!.trim());
      }
      if (item.skuUpc != null && item.skuUpc!.trim().isNotEmpty) {
        uniqueSkus.add(item.skuUpc!.trim());
      }
    }

    if (uniqueSkus.isEmpty) {
      setState(() => _isLoadingStock = false);
      return;
    }

    setState(() {
      _isLoadingStock = true;
      _stockError = null;
      _allStockData = null;
    });

    final Map<String, StockData> consolidatedStock = {};
    Object? lastError;

    // 2. Fetch stock data for each unique SKU
    for (final code in uniqueSkus) {
      try {
        final stock = await OMSApiService.fetchStockBySku(code);
        if (stock != null) {
          // Store by main SKU code found in stock
          consolidatedStock[stock.skuCode] = stock;
          skuToIdMap[stock.skuCode] = stock.skuId;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) return;

    setState(() {
      _allStockData = consolidatedStock;
      _isLoadingStock = false;
      if (consolidatedStock.isEmpty && lastError != null) {
        _stockError = lastError.toString();
      }
    });

    // 3. Trigger rack stock loading for all valid SKU IDs
    final Set<int> uniqueSkuIds = skuToIdMap.values.toSet();
    if (uniqueSkuIds.isNotEmpty) {
      _loadAllRackStocks(uniqueSkuIds);
    }
  }

  Future<void> _loadAllRackStocks(Set<int> skuIds) async {
    setState(() {
      _isLoadingRackStocks = true;
      _rackStocksError = null;
      _allRackStocks = null;
    });

    final Map<int, List<RackStock>> consolidatedRacks = {};
    Object? lastError;

    for (final skuId in skuIds) {
      if (skuId == 0) continue;
      try {
        final racks = await OMSApiService.fetchRackWiseStock(skuId);
        if (racks.isNotEmpty) {
          consolidatedRacks[skuId] = racks;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) return;

    setState(() {
      _allRackStocks = consolidatedRacks;
      _isLoadingRackStocks = false;
      if (consolidatedRacks.isEmpty && lastError != null) {
        _rackStocksError = lastError.toString();
      }
    });
  }

  Future<void> _loadAllChildSkus() async {
    setState(() {
      _isLoadingChildSkus = true;
      _childSkuError = null;
    });

    try {
      final List<ComboSKUBreakdown> allSkus = [];
      final Set<String> comboCodes = {};

      for (final orderWithItem in widget.orders) {
        final skus = await OMSApiService.fetchChildSkus(orderWithItem.order.id);
        allSkus.addAll(skus);
        comboCodes.addAll(skus
            .map((e) => e.comboSkuCode?.trim())
            .where((c) => c != null && c!.isNotEmpty)
            .cast<String>());
      }

      if (!mounted) return;

      setState(() {
        _allChildSkus = allSkus;
        _isLoadingChildSkus = false;
      });

      if (comboCodes.isNotEmpty) {
        await _loadComboRackStocks(comboCodes.toList());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _childSkuError = e.toString();
        _isLoadingChildSkus = false;
      });
    }
  }

  Future<void> _loadComboRackStocks(List<String> comboCodes) async {
    if (comboCodes.isEmpty) return;

    setState(() {
      _isLoadingComboRackStocks = true;
      _comboRackStocksError = null;
      _comboRackStocks = null;
    });

    try {
      final List<ComboSkuRackInfo> allInfos = [];

      for (final comboCode in comboCodes) {
        final children = await OMSApiService.fetchComboRackChildren(comboCode);
        for (final child in children) {
          if (child.skuId == 0) continue;
          final racks = await OMSApiService.fetchRackWiseStock(child.skuId);
          if (racks.isNotEmpty) {
            // Group by the combo code (not strictly necessary but useful for display)
            allInfos.add(ComboSkuRackInfo(child: child, racks: racks));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _comboRackStocks = allInfos;
        _isLoadingComboRackStocks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _comboRackStocksError = e.toString();
        _isLoadingComboRackStocks = false;
      });
    }
  }

  Future<void> _handlePickStatusChange() async {
    if (widget.tracker == null || widget.tracker!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No shipment tracker available')),
        );
      }
      return;
    }

    if (_empCode == null || _empCode!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee code not found. Please login again.')),
        );
      }
      return;
    }

    setState(() {
      _isUpdatingPickStatus = true;
    });

    try {
      final newStatus = !_isPicked;

      // Crucially, we mark ALL orders under this tracker as picked/unpicked
      final success = await OMSApiService.markAsPicked(
        widget.tracker!,
        _empCode!.trim(),
        newStatus,
      );

      if (success && mounted) {
        setState(() {
          _isPicked = newStatus;
          // Update local models for immediate visual feedback
          for (final ow in widget.orders) {
            ow.order.pickStatus = newStatus ? 1 : 0;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All ${widget.orders.length} orders under tracker ${widget.tracker} marked as ${newStatus ? 'picked' : 'unpicked'}',
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update pick status')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update pick status: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPickStatus = false;
        });
      }
    }
  }

  /// Robust date formatter - final format: 12/06/2025 10.28 am
  String _formatDate(String? value) {
    if (value == null) return '';
    final v = value.trim();
    if (v.isEmpty) return '';

    final ts = int.tryParse(v);
    if (ts != null) {
      DateTime dt;
      if (v.length == 10) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      } else if (v.length == 13) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else {
        dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      }
      return DateFormat('dd/MM/yyyy hh.mm a').format(dt);
    }

    try {
      final dt = DateTime.parse(v);
      return DateFormat('dd/MM/yyyy hh.mm a').format(dt);
    } catch (_) {
      return v;
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: CupertinoColors.systemBlue,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String? value, {
    bool highlight = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleHeader(
    String title,
    bool expanded,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
            Icon(
              expanded
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  // --- Consolidated Stock + Rack sections --- //

  Widget _buildStockSection() {
    if (_isLoadingStock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Stock Information (Consolidated)',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CupertinoColors.systemBlue),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          ),
        ],
      );
    }

    if (_stockError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Stock Information (Consolidated)'),
          _buildErrorContainer(
              'Error loading stock: $_stockError', CupertinoColors.systemRed),
        ],
      );
    }

    final consolidatedStocks = _allStockData?.values.toList() ?? [];

    if (consolidatedStocks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Stock Information (Consolidated)'),
          _buildInfoContainer('No stock information found for linked SKUs',
              CupertinoColors.systemGrey),
        ],
      );
    }

    // Aggregate overall stock summary
    final int totalInStock =
        consolidatedStocks.fold(0, (sum, s) => sum + s.inStock);
    final int totalBadStock =
        consolidatedStocks.fold(0, (sum, s) => sum + s.badStock);
    final int totalBlocked =
        consolidatedStocks.fold(0, (sum, s) => sum + s.blocked);
    final bool overallHasStock = totalInStock > 0;
    final Color overallStockColor = overallHasStock
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Stock Information (Consolidated)'),
        // Overall Summary Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: overallStockColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: overallStockColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    overallHasStock
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.xmark_seal_fill,
                    color: overallStockColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    overallHasStock ? 'OVERALL IN STOCK' : 'OUT OF STOCK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: overallStockColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStockInfoCard(
                      'Available',
                      totalInStock.toString(),
                      CupertinoIcons.cube_box_fill,
                      CupertinoColors.systemGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStockInfoCard(
                      'Bad Stock',
                      totalBadStock.toString(),
                      CupertinoIcons.xmark_circle_fill,
                      CupertinoColors.systemOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStockInfoCard(
                      'Blocked',
                      totalBlocked.toString(),
                      CupertinoIcons.lock_fill,
                      CupertinoColors.systemRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Individual SKU Stock Details (for the first few, or an expandable list)
        _sectionTitle('Individual SKU Stock Details'),
        ...consolidatedStocks
            .take(5)
            .map((stock) => _buildIndividualStockCard(stock)),
        if (consolidatedStocks.length > 5)
          Center(
            child: Text('...and ${consolidatedStocks.length - 5} more SKUs.',
                style: const TextStyle(color: CupertinoColors.systemGrey)),
          ),
      ],
    );
  }

  Widget _buildIndividualStockCard(StockData stock) {
    final stockColor = stock.hasStock
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.barcode, size: 14, color: stockColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SKU: ${stock.skuCode}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: stockColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickBadge('Available', stock.inStock.toString()),
              _quickBadge('Bad Stock', stock.badStock.toString()),
              _quickBadge('Blocked', stock.blocked.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRackWiseSection() {
    final bool hasComboRack =
        _comboRackStocks != null && _comboRackStocks!.isNotEmpty;
    final bool hasBaseRack =
        _allRackStocks != null && _allRackStocks!.isNotEmpty;

    if (_isLoadingRackStocks || _isLoadingComboRackStocks) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 16),
          Text(
            'Rack-wise Stock',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: CupertinoColors.systemBlue,
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          ),
        ],
      );
    }

    final List<Widget> children = [];

    // --- Combo Rack Stock (Grouped by child SKU) ---
    if (hasComboRack) {
      children.addAll([
        const SizedBox(height: 16),
        _sectionTitle('Rack-wise Stock (Combo Children)'),
      ]);

      for (final info in _comboRackStocks!) {
        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.cube_box_fill,
                      size: 18,
                      color: CupertinoColors.systemGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Child SKU: ${info.child.skuCode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (info.racks.isEmpty)
                  const Text(
                    'No rack-wise data for this child SKU',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  )
                else
                  ...info.racks.map((r) {
                    final title = r.isUnassigned
                        ? 'Unassigned Rack'
                        : (r.rackSpaceName ?? 'Rack ${r.rackSpaceId}');
                    final subtitle = 'Rack ID: ${r.rackSpaceId}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                r.isUnassigned
                                    ? CupertinoIcons.exclamationmark_circle
                                    : CupertinoIcons.cube_box_fill,
                                size: 18,
                                color: r.isUnassigned
                                    ? CupertinoColors.systemOrange
                                    : CupertinoColors.systemBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _rackBadge(
                                label: 'In Stock',
                                value: r.inStock.toString(),
                                color: CupertinoColors.systemGreen,
                              ),
                              const SizedBox(width: 8),
                              _rackBadge(
                                label: 'Bad Stock',
                                value: r.badStock.toString(),
                                color: CupertinoColors.systemRed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      }
    }

    // --- Base/Single SKU Rack Stock (Grouped by SKU code) ---
    if (hasBaseRack) {
      children.addAll([
        const SizedBox(height: 16),
        _sectionTitle(
            hasComboRack ? 'Base SKU Rack-wise Stock' : 'Rack-wise Stock'),
      ]);

      // Iterate through unique SKU IDs that have rack stock
      _allRackStocks!.forEach((skuId, racks) {
        final stock = _allStockData?.values.cast<StockData>().firstWhere(
              (s) => s.skuId == skuId,
              orElse: () => null as dynamic,
            ) as StockData?;
        final skuCode = stock?.skuCode ?? skuId.toString();

        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.barcode,
                      size: 18,
                      color: CupertinoColors.systemPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SKU: $skuCode (ID: $skuId)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: CupertinoColors.systemPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...racks.map((r) {
                  final title = r.isUnassigned
                      ? 'Unassigned Rack'
                      : (r.rackSpaceName ?? 'Rack ${r.rackSpaceId}');
                  final subtitle = 'Rack ID: ${r.rackSpaceId}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              r.isUnassigned
                                  ? CupertinoIcons.exclamationmark_circle
                                  : CupertinoIcons.cube_box_fill,
                              size: 18,
                              color: r.isUnassigned
                                  ? CupertinoColors.systemOrange
                                  : CupertinoColors.systemBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _rackBadge(
                              label: 'In Stock',
                              value: r.inStock.toString(),
                              color: CupertinoColors.systemGreen,
                            ),
                            const SizedBox(width: 8),
                            _rackBadge(
                              label: 'Bad Stock',
                              value: r.badStock.toString(),
                              color: CupertinoColors.systemRed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      });
    }

    if (children.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _sectionTitle('Rack-wise Stock'),
          _buildInfoContainer(
              'No rack-wise distribution available for these SKUs',
              CupertinoColors.systemGrey),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildErrorContainer(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rackBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSkuSection() {
    if (_isLoadingChildSkus) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 16),
          Text(
            'Combo → Child SKU Breakdown',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CupertinoColors.systemBlue),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          ),
        ],
      );
    }

    if (_childSkuError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _sectionTitle('Combo → Child SKU Breakdown'),
          _buildErrorContainer('Error loading child SKUs: $_childSkuError',
              CupertinoColors.systemRed),
        ],
      );
    }

    if (_allChildSkus == null || _allChildSkus!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _sectionTitle('Combo → Child SKU Breakdown'),
          _buildInfoContainer(
              'No combo/child SKU breakdown available for these orders',
              CupertinoColors.systemGrey),
        ],
      );
    }

    // Group by combo SKU code to display breakdowns for each combo
    final Map<String, List<ComboSKUBreakdown>> groupedBreakdowns = {};
    for (final breakdown in _allChildSkus!) {
      final key = breakdown.comboSkuCode ?? 'SKU: ${breakdown.skuCode}';
      if (key == 'SKU: null') continue;
      groupedBreakdowns.putIfAbsent(key, () => []).add(breakdown);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('Combo → Child SKU Breakdown'),
        ...groupedBreakdowns.entries.map((entry) {
          final comboKey = entry.key;
          final breakdowns = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGreen.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.cube_box_fill,
                      size: 16,
                      color: CupertinoColors.systemGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Combo: $comboKey (${breakdowns.length} orders)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Child SKUs:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 8),
                // Display the aggregated list of unique child SKUs/quantities.
                // Note: Exact aggregation logic can be complex (e.g., if one
                // child SKU is in multiple orders). Here we list them simply.
                ...breakdowns.first.childSkus.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final child = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    CupertinoColors.systemBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                child.code ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (child.qty?.isNotEmpty == true)
                              _quickBadge('Qty', child.qty!),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildOrderListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle('Orders in this Shipment (${widget.orders.length})'),
        ...widget.orders.map((ow) {
          final o = ow.order;
          final i = ow.item;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Order ID', o.id.toString(), highlight: true),
                _infoRow('SKU Code', i?.skuCode, highlight: true),
                _infoRow('Quantity', i?.qty?.toString()),
                _infoRow('Channel', o.channel),
                _infoRow('Invoice ID', o.invoiceId),
                _infoRow(
                    'Picked Status', o.pickStatus == 1 ? 'Picked' : 'Unpicked',
                    highlight: o.pickStatus == 1),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSectionStrip() {
    const sections = [
      'Orders in Shipment',
      'Stock Information',
      'Rack-wise Stock',
      'Combo → Child SKU',
      'Buyer Details',
      'Pricing Details',
      'Tax Details',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: sections
            .map(
              (s) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _quickBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtonsRow(BuildContext context) {
    final pickedColor =
        _isPicked ? CupertinoColors.systemGreen : CupertinoColors.systemGrey3;

    final pickedTextColor =
        _isPicked ? CupertinoColors.white : CupertinoColors.label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              borderRadius: BorderRadius.circular(10),
              color: CupertinoColors.systemGrey5,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              borderRadius: BorderRadius.circular(10),
              color: _isUpdatingPickStatus
                  ? CupertinoColors.systemGrey4
                  : pickedColor,
              onPressed: _isUpdatingPickStatus ? null : _handlePickStatusChange,
              child: _isUpdatingPickStatus
                  ? const CupertinoActivityIndicator()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPicked
                              ? CupertinoIcons.checkmark_alt
                              : CupertinoIcons.circle,
                          size: 16,
                          color: pickedTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPicked ? 'Mark Unpicked' : 'Mark Picked',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: pickedTextColor,
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

  @override
  Widget build(BuildContext context) {
    // Only use the first order for top-level information like dates/buyer info
    // as it should be consistent across all orders in the same shipment.
    final o = widget.orders.first.order;
    // Item details are unique per item, so display only in dedicated section

    final deliveredDateStr = _formatDate(o.deliveredDate);

    return CupertinoActionSheet(
      title: Text(widget.title),
      message: SafeArea(
        top: false,
        child: SizedBox(
          height: 520,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) ORDER LIST SECTION
                      _buildOrderListSection(),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 2) STOCK INFORMATION (Consolidated)
                      _buildStockSection(),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 3) RACK-WISE STOCK (Base + Combo)
                      _buildRackWiseSection(),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 4) COMBO CHILD SKU BREAKDOWN
                      _buildChildSkuSection(),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 5) SECTION STRIP + QUICK SUMMARY (using first order)
                      _buildSectionStrip(),
                      const SizedBox(height: 12),

                      // 6) BUYER
                      _buildCollapsibleHeader(
                        'Buyer Details',
                        _showBuyer,
                        () => setState(() => _showBuyer = !_showBuyer),
                      ),
                      if (_showBuyer) ...[
                        _infoRow('Name', o.buyerName, highlight: true),
                        _infoRow('Phone', o.buyerPhone, highlight: true),
                        _infoRow('Email', o.buyerEmail),
                        _infoRow('Address 1', o.buyerAddress1),
                        _infoRow('Address 2', o.buyerAddress2),
                        _infoRow('City', o.buyerCity),
                        _infoRow('State', o.buyerState),
                        _infoRow('Pincode', o.buyerPincode),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),

                      // NOTE: We omit detailed Item/Pricing/Tax info for now
                      // as they vary per item/order. A proper solution would list
                      // or aggregate this data clearly for all orders.
                      // For simplicity, we only include the essential
                      // logistics/stock info above.

                      const SizedBox(height: 16),
                      _sectionTitle('Shipment Information'),
                      _infoRow('Shipping Company', o.shippingCompany),
                      _infoRow(
                        'Shipment Tracker',
                        o.shipmentTracker,
                        highlight: true,
                      ),
                      _infoRow('Order Type', o.orderType),
                      _infoRow('Warehouse', o.warehouse),
                      _infoRow('Delivery Date', deliveredDateStr),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 14) PACK LOG (using first order)
                      if (o.packLog?.isNotEmpty == true) ...[
                        _sectionTitle('Pack Log'),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.packLog ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom row: Close + Picked/Unpicked
              _buildBottomButtonsRow(context),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }
}

/// =====================
/// ROW CARD
/// =====================
class _OrderRowCard extends StatelessWidget {
  final OMSOrderWithItem orderWithItem;
  final VoidCallback onTap;

  const _OrderRowCard({
    Key? key,
    required this.orderWithItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final o = orderWithItem.order;
    final i = orderWithItem.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delivered = o.deliveredDate?.isNotEmpty == true;
    final isPicked = o.pickStatus == 1;

    final statusColor = delivered
        ? CupertinoColors.systemGreen
        : o.shipmentDate?.isNotEmpty == true
            ? CupertinoColors.systemBlue
            : CupertinoColors.systemOrange;

    final statusText = delivered
        ? 'Delivered'
        : o.shipmentDate?.isNotEmpty == true
            ? 'Shipped'
            : 'Processing';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
              spreadRadius: 1,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${o.id}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                delivered
                                    ? CupertinoIcons.checkmark_seal_fill
                                    : o.shipmentDate?.isNotEmpty == true
                                        ? CupertinoIcons.cube_box_fill
                                        : CupertinoIcons.clock_fill,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPicked)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  CupertinoColors.systemGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemGreen
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_alt,
                                  size: 12,
                                  color: CupertinoColors.systemGreen,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Picked',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemGreen,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (o.buyerName?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: CupertinoIcons.person_fill,
                    label: o.buyerName!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                ],
                if (o.buyerCity?.isNotEmpty == true ||
                    o.buyerState?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: CupertinoIcons.location_fill,
                    label: [o.buyerCity, o.buyerState]
                        .where((s) => s?.isNotEmpty == true)
                        .join(', '),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                ],
                if (o.buyerPhone?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: CupertinoIcons.phone_fill,
                    label: o.buyerPhone!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                ],
                if (o.orderDate?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: CupertinoIcons.calendar,
                    label: 'Ordered: ${_formatDate(o.orderDate)}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                ],
                if (o.deliveredDate?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: CupertinoIcons.checkmark_shield_fill,
                    label: 'Delivered: ${_formatDate(o.deliveredDate)}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                ] else if (o.shipmentDate?.isNotEmpty == true) ...[
                  _buildDetailRow(
                    icon: CupertinoIcons.cube_box_fill,
                    label: 'Shipped: ${_formatDate(o.shipmentDate)}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (o.channel?.isNotEmpty == true)
                      _buildPill(
                        o.channel!,
                        CupertinoIcons.cube_box,
                        CupertinoColors.systemBlue,
                        isDark,
                      ),
                    if (o.warehouse?.isNotEmpty == true)
                      _buildPill(
                        o.warehouse!,
                        CupertinoIcons.building_2_fill,
                        CupertinoColors.systemIndigo,
                        isDark,
                      ),
                    if (i?.skuCode?.isNotEmpty == true)
                      _buildPill(
                        'SKU: ${i!.skuCode}',
                        CupertinoIcons.barcode,
                        CupertinoColors.systemPurple,
                        isDark,
                      ),
                    if (o.invoiceId?.isNotEmpty == true)
                      _buildPill(
                        'INV: ${o.invoiceId}',
                        CupertinoIcons.doc_text_fill,
                        CupertinoColors.systemGreen,
                        isDark,
                      ),
                    if (i?.qty != null)
                      _buildPill(
                        'Qty: ${i!.qty}',
                        CupertinoIcons.number,
                        CupertinoColors.systemTeal,
                        isDark,
                      ),
                    if (i?.invoiceAmount != null)
                      _buildPill(
                        '₹${i!.invoiceAmount!.toStringAsFixed(2)}',
                        CupertinoIcons.money_dollar_circle_fill,
                        CupertinoColors.systemOrange,
                        isDark,
                      ),
                    if (o.company?.isNotEmpty == true)
                      _buildPill(
                        o.company!,
                        CupertinoIcons.briefcase_fill,
                        CupertinoColors.systemPink,
                        isDark,
                      ),
                    if (o.shipmentTracker?.isNotEmpty == true)
                      _buildPill(
                        'TRK: ${o.shipmentTracker!}',
                        CupertinoIcons.airplane,
                        CupertinoColors.systemCyan,
                        isDark,
                      ),
                    if (o.shippingCompany?.isNotEmpty == true)
                      _buildPill(
                        o.shippingCompany!,
                        CupertinoIcons.cube_box,
                        CupertinoColors.systemRed,
                        isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: CupertinoColors.systemGrey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return 'N/A';
    final ts = int.tryParse(timestampStr);
    if (ts != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return DateFormat('dd/MM/yyyy hh.mm a').format(d);
    }
    return timestampStr;
  }

  Widget _buildPill(String text, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? CupertinoColors.white.withOpacity(0.9)
                  : CupertinoColors.black,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
