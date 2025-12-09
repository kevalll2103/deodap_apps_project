import 'dart:convert';
import 'package:Deodap_Customprint/model.dart';
import 'package:http/http.dart' as http;

/// Central API config/helpers
class ApiService {
  static const String baseUrl = 'https://customprint.deodap.com';
  static const Duration defaultTimeout = Duration(seconds: 30);

  // Error -> readable string
  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  // Validate HTTP + JSON
  static Map<String, dynamic> _validateResponse(String body, int statusCode) {
    if (statusCode != 200) {
      throw Exception(
          'API request failed with status: $statusCode. Response: ${body.length > 200 ? body.substring(0, 200) + '...' : body}');
    }
    try {
      final data = json.decode(body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Root JSON is not an object');
    } catch (e) {
      throw Exception('Invalid JSON response: ${e.toString()}');
    }
  }
}

/// -------- PRODUCT MANAGEMENT (no pagination) --------

/// Fetch ALL products (server now returns full set with optional filters)
Future<List<Product>> fetchProducts({
  String? search,
  String? fromDate,
  String? toDate,
}) async {
  try {
    final url = Uri.parse('${ApiService.baseUrl}/api_customprint/get_products.php');

    final req = http.MultipartRequest('POST', url);
    if (search != null && search.trim().isNotEmpty) {
      req.fields['search'] = search.trim();
    }
    if (fromDate != null && fromDate.isNotEmpty) req.fields['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) req.fields['to_date'] = toDate;

    final streamed = await req.send().timeout(ApiService.defaultTimeout);
    final body = await streamed.stream.bytesToString();
    final data = ApiService._validateResponse(body, streamed.statusCode);

    if (data['data'] == null || data['data'] is! List) {
      throw Exception('Invalid API response: missing or malformed "data" field');
    }

    final list = (data['data'] as List)
        .where((e) => e != null)
        .map((e) => Product.fromJson(e))
        .toList();

    return list;
  } catch (e) {
    throw Exception('Failed to fetch products: ${ApiService._getErrorMessage(e)}');
  }
}

/// Delete a single product (by product_id from row)
Future<bool> deleteProductById(String productId) async {
  try {
    if (productId.isEmpty) {
      throw Exception('Product ID cannot be empty');
    }

    final res = await http
        .get(
      Uri.parse('${ApiService.baseUrl}/delete_one_order_by_ID.php?id=$productId'),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App/1.0',
      },
    )
        .timeout(ApiService.defaultTimeout);

    final data = ApiService._validateResponse(res.body, res.statusCode);
    if (data.containsKey('success')) return true;
    if (data.containsKey('error')) throw Exception(data['error']);
    throw Exception('Unknown response format');
  } catch (e) {
    throw Exception('Failed to delete product: ${ApiService._getErrorMessage(e)}');
  }
}

/// Delete multiple by product_id (returns a small summary map)
Future<Map<String, dynamic>> deleteMultipleProducts(List<String> productIds) async {
  int success = 0;
  int fail = 0;
  final errors = <String>[];

  if (productIds.isEmpty) throw Exception('No product IDs provided');

  for (final id in productIds) {
    try {
      final ok = await deleteProductById(id);
      if (ok) {
        success++;
      } else {
        fail++;
        errors.add('Product $id: Deletion failed');
      }
    } catch (e) {
      fail++;
      errors.add('Product $id: ${ApiService._getErrorMessage(e)}');
    }
  }

  return {
    'success_count': success,
    'fail_count': fail,
    'errors': errors,
    'total': productIds.length,
  };
}

/// -------- RECYCLE BIN (unchanged endpoints) --------

Future<void> moveOrderToRecycleBin(String orderId, String userId) async {
  try {
    if (orderId.isEmpty || userId.isEmpty) {
      throw Exception('Order ID and User ID cannot be empty');
    }

    final url = Uri.parse('${ApiService.baseUrl}/api_customprint/recycle_bin.php');
    final req = http.MultipartRequest('POST', url);
    req.fields['action'] = 'move_to_recycle_bin';
    req.fields['order_id'] = orderId;
    req.fields['user_id'] = userId;

    final r = await req.send().timeout(ApiService.defaultTimeout);
    final body = await r.stream.bytesToString();
    final data = ApiService._validateResponse(body, r.statusCode);

    if (data['status'] != 'success') {
      throw Exception('Failed to move order: ${data['message'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('Failed to move order to recycle bin: ${ApiService._getErrorMessage(e)}');
  }
}

Future<Map<String, dynamic>> fetchDeletedOrders(String userId) async {
  try {
    if (userId.isEmpty) throw Exception('User ID cannot be empty');

    final url = Uri.parse('${ApiService.baseUrl}/api_customprint/recycle_bin.php');
    final req = http.MultipartRequest('POST', url);
    req.fields['action'] = 'get_deleted_orders';
    req.fields['user_id'] = userId;

    final r = await req.send().timeout(ApiService.defaultTimeout);
    final body = await r.stream.bytesToString();
    final data = ApiService._validateResponse(body, r.statusCode);

    if (data['data'] == null || data['data'] is! List) {
      throw Exception('Invalid API response: missing data field');
    }

    final orders = (data['data'] as List)
        .where((e) => e != null)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return {'orders': orders, 'total_count': orders.length};
  } catch (e) {
    throw Exception('Failed to fetch deleted orders: ${ApiService._getErrorMessage(e)}');
  }
}

Future<void> restoreOrderFromRecycleBin(String orderId, String userId) async {
  try {
    if (orderId.isEmpty || userId.isEmpty) {
      throw Exception('Order ID and User ID cannot be empty');
    }

    final url = Uri.parse('${ApiService.baseUrl}/api_customprint/recycle_bin.php');
    final req = http.MultipartRequest('POST', url);
    req.fields['action'] = 'restore_order';
    req.fields['order_id'] = orderId;
    req.fields['user_id'] = userId;

    final r = await req.send().timeout(ApiService.defaultTimeout);
    final body = await r.stream.bytesToString();
    final data = ApiService._validateResponse(body, r.statusCode);

    if (data['status'] != 'success') {
      throw Exception('Failed to restore order: ${data['message'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('Failed to restore order: ${ApiService._getErrorMessage(e)}');
  }
}

Future<void> permanentlyDeleteOrder(String orderId, String userId) async {
  try {
    if (orderId.isEmpty || userId.isEmpty) {
      throw Exception('Order ID and User ID cannot be empty');
    }

    final url = Uri.parse('${ApiService.baseUrl}/api_customprint/recycle_bin.php');
    final req = http.MultipartRequest('POST', url);
    req.fields['action'] = 'permanent_delete';
    req.fields['order_id'] = orderId;
    req.fields['user_id'] = userId;

    final r = await req.send().timeout(ApiService.defaultTimeout);
    final body = await r.stream.bytesToString();
    final data = ApiService._validateResponse(body, r.statusCode);

    if (data['status'] != 'success') {
      throw Exception('Failed to permanently delete order: ${data['message'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('Failed to permanently delete order: ${ApiService._getErrorMessage(e)}');
  }
}

Future<Map<String, dynamic>> moveMultipleOrdersToRecycleBin(
    List<String> orderIds, String userId) async {
  int success = 0, fail = 0;
  final errors = <String>[];

  if (orderIds.isEmpty) throw Exception('No order IDs provided');
  if (userId.isEmpty) throw Exception('User ID cannot be empty');

  for (final id in orderIds) {
    try {
      await moveOrderToRecycleBin(id, userId);
      success++;
    } catch (e) {
      fail++;
      errors.add('Order $id: ${ApiService._getErrorMessage(e)}');
    }
  }

  return {
    'success_count': success,
    'fail_count': fail,
    'errors': errors,
    'total': orderIds.length,
  };
}

Future<Map<String, dynamic>> restoreMultipleOrdersFromRecycleBin(
    List<String> orderIds, String userId) async {
  int success = 0, fail = 0;
  final errors = <String>[];

  if (orderIds.isEmpty) throw Exception('No order IDs provided');
  if (userId.isEmpty) throw Exception('User ID cannot be empty');

  for (final id in orderIds) {
    try {
      await restoreOrderFromRecycleBin(id, userId);
      success++;
    } catch (e) {
      fail++;
      errors.add('Order $id: ${ApiService._getErrorMessage(e)}');
    }
  }

  return {
    'success_count': success,
    'fail_count': fail,
    'errors': errors,
    'total': orderIds.length,
  };
}

/// -------- UTIL --------

Future<bool> checkApiConnection() async {
  try {
    final r = await http
        .get(
      Uri.parse('${ApiService.baseUrl}/api_customprint/health_check.php'),
      headers: {'User-Agent': 'Flutter-App/1.0'},
    )
        .timeout(const Duration(seconds: 10));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<Map<String, dynamic>> getApiStatus() async {
  try {
    final r = await http
        .get(
      Uri.parse('${ApiService.baseUrl}/api_customprint/status.php'),
      headers: {'Accept': 'application/json', 'User-Agent': 'Flutter-App/1.0'},
    )
        .timeout(const Duration(seconds: 10));

    final data = ApiService._validateResponse(r.body, r.statusCode);
    return {
      'status': data['status'] ?? 'unknown',
      'version': data['version'] ?? '1.0',
      'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
    };
  } catch (e) {
    throw Exception('Failed to get API status: ${ApiService._getErrorMessage(e)}');
  }
}
