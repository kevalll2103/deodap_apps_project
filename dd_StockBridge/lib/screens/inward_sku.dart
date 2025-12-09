import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'second_scanner.dart';

/// Distinguish base vs daily images for stock photos
enum ProductImageType { base, daily }

class InwardSku extends StatefulWidget {
  const InwardSku({super.key});

  @override
  State<InwardSku> createState() => _InwardSkuState();
}

class _InwardSkuState extends State<InwardSku> {
  // Controllers
  final TextEditingController orderIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State variables
  Map<String, dynamic>? orderData;
  Map<String, dynamic>? stockData; // Store stock details
  List<dynamic>? rackStockData; // OMSGuru rack-wise stock
  bool isRackLoading = false;

  // New: search result list for manual search
  List<Map<String, dynamic>>? _searchResults;
  bool _isSearchingSkus = false;

  String orderId = '';
  String returnCondition = 'good';

  // Return-order photos (existing flow)
  List<Uint8List> stickerPhotos = [];
  List<Uint8List> unboxPhotos = [];
  bool isUploading = false;
  double uploadProgress = 0.0;

  // ---------- STOCK IMAGE UPLOAD STATE ----------
  // Existing images from DB
  List<String> baseProductImages = []; // base_image (max 4)
  List<String> dailyProductImages = []; // daily_image (unlimited)

  // New images captured/selected on device
  List<Uint8List> newBaseImages = [];
  List<Uint8List> newDailyImages = [];

  bool isUploadingBaseImages = false;
  bool isUploadingDailyImages = false;

  static const int _maxBaseImages = 4;

  // Rack stock edit state
  // Store "added quantity" (delta) per rack index, as string from TextField
  final Map<int, String> _rackDeltaEdited = {};
  bool isUpdatingRackStock = false;

  // ======================= CONSTANTS =======================

  // Return API
  static const _apiBaseUrl = 'https://customprint.deodap.com/api_amzDD_return';

  // Stock fetch API (READ)
  static const _stockFetchBaseUrl =
      'https://customprint.deodap.com/stockbridge/all_data_fetch_oms_order.php';
  static const _stockFetchKey = 'DeoDap@2025Stock';

  // Stock image API (UPLOAD/DELETE)
  static const _stockImageApiUrl =
      'https://customprint.deodap.com/stock_base_image.php?key=DeoDap@2025Stock';

  // ---------- OMSGURU CONFIG ----------
  static const String kOmsRackWiseUrl =
      'https://client.omsguru.com/order_api/rack_wise_stock';
  static const String kOmsStockUpdateUrl =
      'https://client.omsguru.com/order_api/stock';
  static const String kOmsBearerToken =
      'Bearer 7DOHq0j6dbfNKYWIzyGBJtlEZaosxiUm'; // <-- replace if needed
  static const String kOmsCid = '33532'; // <-- replace if needed
  // ---------------------------------------------------

  // iOS-style color theme
  static const _primaryColor = Color(0xFF007AFF); // iOS blue
  static const _secondaryColor = Color(0xFF0A84FF);

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (orderData != null) {
      orderId = orderData!['id'].toString();
    }
  }

  @override
  void dispose() {
    orderIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetScreen() {
    setState(() {
      orderIdController.clear();
      orderData = null;
      stockData = null;
      rackStockData = null;

      baseProductImages = [];
      dailyProductImages = [];
      newBaseImages.clear();
      newDailyImages.clear();

      stickerPhotos.clear();
      unboxPhotos.clear();
      orderId = '';
      returnCondition = 'good';
      isUploading = false;
      uploadProgress = 0.0;
      isRackLoading = false;
      isUploadingBaseImages = false;
      isUploadingDailyImages = false;
      isUpdatingRackStock = false;
      _rackDeltaEdited.clear();

      _searchResults = null;
      _isSearchingSkus = false;
    });
  }

  Future<void> _handlePullToRefresh() async {
    _resetScreen();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ================= STOCK FETCH =================

  /// This is used for SCAN FLOW – always open single SKU details
  Future<void> fetchStockDetails(String skuCode) async {
    if (skuCode.isEmpty) return;

    // Clear any previous search list when scanning
    setState(() {
      _searchResults = null;
      _isSearchingSkus = false;
    });

    final overlayEntry = _createLoaderOverlay();
    Overlay.of(context).insert(overlayEntry);

    try {
      // Build URL with key + search
      final uri = Uri.parse(_stockFetchBaseUrl).replace(queryParameters: {
        'key': _stockFetchKey,
        'search': skuCode,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15),
          onTimeout: () {
        throw Exception('Request timeout');
      });

      debugPrint(
          'Stock API (scan) status: ${response.statusCode}, body: ${response.body}');

      overlayEntry.remove();

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (e) {
          _showErrorDialog('Invalid response format from stock API.');
          return;
        }

        if (decoded is Map<String, dynamic>) {
          _handleStockResponse(decoded);
        } else {
          _showErrorDialog('Unexpected response format from stock API.');
        }
      } else {
        _showErrorDialog(
            'Failed to fetch stock details! (HTTP ${response.statusCode})');
      }
    } catch (e) {
      overlayEntry.remove();
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Request timeout. Please check your internet connection.');
      } else {
        _showErrorDialog('Error fetching stock details!');
      }
    }
  }

  /// NEW: Manual search – show list of all matching SKUs
  Future<void> _searchSkuList(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearchingSkus = true;
      _searchResults = null;
    });

    final overlayEntry = _createLoaderOverlay();
    Overlay.of(context).insert(overlayEntry);

    try {
      final uri = Uri.parse(_stockFetchBaseUrl).replace(queryParameters: {
        'key': _stockFetchKey,
        'search': trimmed,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15),
          onTimeout: () {
        throw Exception('Request timeout');
      });

      debugPrint(
          'Stock API (manual search) status: ${response.statusCode}, body: ${response.body}');

      overlayEntry.remove();

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (e) {
          setState(() {
            _isSearchingSkus = false;
          });
          _showErrorDialog('Invalid response format from stock API.');
          return;
        }

        if (decoded is Map<String, dynamic> &&
            decoded['success'] == true &&
            decoded['data'] != null &&
            (decoded['data'] as List).isNotEmpty) {
          final List<dynamic> rawList = decoded['data'];
          final List<Map<String, dynamic>> list =
              rawList.map<Map<String, dynamic>>((e) {
            return Map<String, dynamic>.from(e as Map);
          }).toList();

          setState(() {
            _searchResults = list;
            _isSearchingSkus = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearchingSkus = false;
          });
          _showInfoDialog('No SKUs found for "$trimmed".');
        }
      } else {
        setState(() {
          _isSearchingSkus = false;
        });
        _showErrorDialog('Failed to fetch SKUs (HTTP ${response.statusCode}).');
      }
    } catch (e) {
      overlayEntry.remove();
      setState(() {
        _isSearchingSkus = false;
      });
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Request timeout. Please check your internet connection.');
      } else {
        _showErrorDialog('Error while searching SKUs.');
      }
    }
  }

  List<String> _parseImageList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        // fallback: comma separated
        return raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  /// Common method to apply a single SKU record to UI
  void _applyStockRecord(Map<String, dynamic> first) {
    // Expect backend to provide base_image and daily_image as JSON or array
    List<String> baseImagesFromApi = _parseImageList(first['base_image']);
    List<String> dailyImagesFromApi =
        _parseImageList(first['daily_image'] ?? first['images']);

    // Enforce max 4 for base images in UI as well (latest 4)
    if (baseImagesFromApi.length > _maxBaseImages) {
      baseImagesFromApi =
          baseImagesFromApi.sublist(baseImagesFromApi.length - _maxBaseImages);
    }

    setState(() {
      stockData = first;
      rackStockData = null; // clear previous rack data

      // Show latest upload first
      baseProductImages = baseImagesFromApi.reversed.toList();
      dailyProductImages = dailyImagesFromApi.reversed.toList();

      newBaseImages.clear();
      newDailyImages.clear();
      _rackDeltaEdited.clear();
    });

    _showSuccessDialog('Stock details loaded successfully.');

    final String? skuId = first['sku_id']?.toString();
    if (skuId != null && skuId.isNotEmpty) {
      fetchOmsRackStock(skuId);
    } else {
      _showErrorDialog('SKU ID not found in stock details.');
    }
  }

  // Handle stock API response for SCAN FLOW
  void _handleStockResponse(Map<String, dynamic> data) {
    if (data['success'] == true &&
        data['data'] != null &&
        data['data'].isNotEmpty) {
      final first = Map<String, dynamic>.from(data['data'][0]);
      _applyStockRecord(first);
    } else {
      setState(() {
        stockData = null;
        rackStockData = null;
        baseProductImages = [];
        dailyProductImages = [];
        newBaseImages.clear();
        newDailyImages.clear();
      });
      _showErrorDialog('Stock not found for this SKU code.');
    }
  }

  /// When user taps a SKU from manual search list
  void _openSkuFromResult(Map<String, dynamic> item) {
    FocusScope.of(context).unfocus();
    final record = Map<String, dynamic>.from(item);
    _applyStockRecord(record);

    // Hide the search list after selecting a SKU
    setState(() {
      _searchResults = null;
    });
  }

  // ================= OMSGURU RACK WISE =================

  Future<void> fetchOmsRackStock(String skuId) async {
    setState(() {
      isRackLoading = true;
      rackStockData = null;
      _rackDeltaEdited.clear();
    });

    // use warehouse_id from stockData if present; else default 7208
    final String warehouseIdToUse =
        stockData?['warehouse_id']?.toString().trim().isNotEmpty == true
            ? stockData!['warehouse_id'].toString()
            : '7208';

    final uri = Uri.parse(kOmsRackWiseUrl).replace(queryParameters: {
      'last_id': '0',
      'warehouse_id': warehouseIdToUse,
      'sku_ids': skuId,
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': kOmsBearerToken,
          'oms-cid': kOmsCid,
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] == 0 && data['data'] != null) {
          setState(() {
            rackStockData = List<dynamic>.from(data['data']);
          });
        } else {
          setState(() {
            rackStockData = [];
          });
          _showInfoDialog(
              data['message']?.toString() ?? 'No rack-wise stock found.');
        }
      } else {
        _showErrorDialog(
            'Failed to fetch rack-wise stock (HTTP ${response.statusCode}).');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Rack-wise stock request timeout. Please try again later.');
      } else {
        _showErrorDialog('Error while fetching rack-wise stock.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isRackLoading = false;
        });
      }
    }
  }

  Future<void> _updateOmsRackStock() async {
    if (rackStockData == null || rackStockData!.isEmpty || stockData == null) {
      _showErrorDialog('No rack stock loaded to update.');
      return;
    }

    final warehouseId = stockData!['warehouse_id']?.toString();
    final skuId = stockData!['sku_id']?.toString();

    if (warehouseId == null || skuId == null) {
      _showErrorDialog('Warehouse ID or SKU ID missing.');
      return;
    }

    final List<Map<String, dynamic>> payload = [];

    int totalBefore = 0;
    int totalAfter = 0;
    int totalAdded = 0;

    for (int i = 0; i < rackStockData!.length; i++) {
      final rack = rackStockData![i] as Map<String, dynamic>;
      final rackSpace =
          rack['rack_space_name']?.toString() ?? rack['rack_space']?.toString();

      if (rackSpace == null || rackSpace.isEmpty) continue;

      final originalInStock =
          int.tryParse(rack['in_stock']?.toString() ?? '0') ?? 0;
      final deltaStr = _rackDeltaEdited[i] ?? '0';
      final delta = int.tryParse(deltaStr) ?? 0;
      final newInStock = originalInStock + delta;

      totalBefore += originalInStock;
      totalAfter += newInStock;
      totalAdded += delta;

      payload.add({
        'warehouse_id': int.parse(warehouseId),
        'sku_id': int.parse(skuId),
        'rack_space': rackSpace,
        'in_stock': newInStock,
      });
    }

    if (payload.isEmpty) {
      _showErrorDialog('Nothing to update.');
      return;
    }

    setState(() {
      isUpdatingRackStock = true;
    });

    final overlay = _createLoaderOverlay();
    Overlay.of(context).insert(overlay);

    try {
      final response = await http
          .put(
            Uri.parse(kOmsStockUpdateUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': kOmsBearerToken,
              'oms-cid': kOmsCid,
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      overlay.remove();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['error'] == 0) {
          // Show explicit "added X, total Y" message
          final String addedText =
              totalAdded >= 0 ? 'Added $totalAdded units.' : 'Net $totalAdded units.';
          final String totalText =
              'Total stock: $totalBefore → $totalAfter.';

          _showSuccessDialog('$addedText\n$totalText');

          // Clear deltas after successful update and refresh rack stock
          _rackDeltaEdited.clear();
          final skuId = stockData!['sku_id'].toString();
          fetchOmsRackStock(skuId);
        } else {
          _showErrorDialog(
              body['message']?.toString() ?? 'Failed to update rack stock.');
        }
      } else {
        _showErrorDialog(
            'OMSGuru stock update failed (HTTP ${response.statusCode}).');
      }
    } catch (e) {
      overlay.remove();
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'OMSGuru stock update timeout. Please try again later.');
      } else {
        _showErrorDialog('Error while updating rack stock.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingRackStock = false;
        });
      }
    }
  }

  // ============= STOCK IMAGE PICK / UPLOAD / DELETE =============

  Future<void> _showProductImageSourceSheet(ProductImageType type) async {
    final String label =
        type == ProductImageType.base ? 'Base Images' : 'Daily Images';

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Add $label'),
        message: const Text('Choose image source'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickProductImage(ImageSource.camera, type);
            },
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickMultipleProductImages(type);
            },
            child: const Text('Gallery (multi-select)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickProductImage(
      ImageSource source, ProductImageType type) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        Uint8List finalBytes = imageBytes;
        if (imageBytes.length > 500000) {
          finalBytes = await _compressImage(imageBytes);
        }

        setState(() {
          if (type == ProductImageType.base) {
            newBaseImages.add(finalBytes);
          } else {
            newDailyImages.add(finalBytes);
          }
        });

        _showSuccessDialog(
            'Image added (${(finalBytes.length / 1024).toStringAsFixed(1)} KB).');
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image.');
    }
  }

  Future<void> _pickMultipleProductImages(ProductImageType type) async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 95,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFiles == null || pickedFiles.isEmpty) return;

      for (final file in pickedFiles) {
        final imageBytes = await file.readAsBytes();
        Uint8List finalBytes = imageBytes;
        if (imageBytes.length > 500000) {
          finalBytes = await _compressImage(imageBytes);
        }
        if (type == ProductImageType.base) {
          newBaseImages.add(finalBytes);
        } else {
          newDailyImages.add(finalBytes);
        }
      }

      setState(() {});
      _showSuccessDialog('${pickedFiles.length} images added.');
    } catch (e) {
      _showErrorDialog('Failed to pick images.');
    }
  }

  Future<void> _uploadProductImages(ProductImageType type) async {
    if (stockData == null) {
      _showErrorDialog('Load stock first, then upload images.');
      return;
    }

    final skuId = stockData!['sku_id']?.toString();
    final warehouseId = stockData!['warehouse_id']?.toString();

    if (skuId == null || warehouseId == null) {
      _showErrorDialog('SKU ID or Warehouse ID missing.');
      return;
    }

    final List<Uint8List> newImages =
        type == ProductImageType.base ? newBaseImages : newDailyImages;

    if (newImages.isEmpty) {
      _showErrorDialog('Please add at least 1 new image to upload.');
      return;
    }

    // Enforce max 4 base images at app level
    if (type == ProductImageType.base) {
      final existingCount = baseProductImages.length;
      final newCount = newBaseImages.length;

      if (existingCount >= _maxBaseImages) {
        _showErrorDialog(
            'You already have $_maxBaseImages base images. Delete some to add new.');
        return;
      }

      if (existingCount + newCount > _maxBaseImages) {
        _showErrorDialog(
            'Base images cannot be more than $_maxBaseImages. Existing: $existingCount, New: $newCount.');
        return;
      }
    }

    if (type == ProductImageType.base) {
      setState(() {
        isUploadingBaseImages = true;
      });
    } else {
      setState(() {
        isUploadingDailyImages = true;
      });
    }

    final String imageTypeStr =
        type == ProductImageType.base ? 'base' : 'daily';

    _showUploadProgressDialogForStockImages(imageTypeStr);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_stockImageApiUrl),
      );

      request.fields['sku_id'] = skuId;
      request.fields['warehouse_id'] = warehouseId;
      request.fields['image_type'] = imageTypeStr;
      request.fields['action'] = 'upload';

      int index = 0;
      for (final img in newImages) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images[]',
            img,
            filename: '${imageTypeStr}_img_$index.jpg',
          ),
        );
        index++;
      }

      final response = await request.send().timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw Exception('Upload timeout'),
          );

      final body = await response.stream.bytesToString();
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.pop(context); // close progress dialog
      }

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(body);
        if (jsonResp['status'] == true) {
          final dynamic imgs = jsonResp['images'];
          List<String> updated = [];
          if (imgs is List) {
            updated = imgs
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList();
          }

          // latest uploads first in UI
          updated = updated.reversed.toList();

          setState(() {
            if (type == ProductImageType.base) {
              baseProductImages = updated;
              newBaseImages.clear();
              isUploadingBaseImages = false;
            } else {
              dailyProductImages = updated;
              newDailyImages.clear();
              isUploadingDailyImages = false;
            }
          });
          _showSuccessDialog(
              '${imageTypeStr[0].toUpperCase()}${imageTypeStr.substring(1)} images uploaded successfully.');
        } else {
          setState(() {
            if (type == ProductImageType.base) {
              isUploadingBaseImages = false;
            } else {
              isUploadingDailyImages = false;
            }
          });
          _showErrorDialog(
              jsonResp['message']?.toString() ?? 'Image upload failed.');
        }
      } else {
        setState(() {
          if (type == ProductImageType.base) {
            isUploadingBaseImages = false;
          } else {
            isUploadingDailyImages = false;
          }
        });
        _showErrorDialog('Image upload failed (HTTP ${response.statusCode}).');
      }
    } catch (e) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.pop(context);
      }
      setState(() {
        if (type == ProductImageType.base) {
          isUploadingBaseImages = false;
        } else {
          isUploadingDailyImages = false;
        }
      });
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Upload timeout. Please try again with smaller images.');
      } else {
        _showErrorDialog('Image upload failed. Check your connection.');
      }
    }
  }

  Future<void> _confirmDeleteProductImage(
      ProductImageType type, String url) async {
    final imageTypeStr = type == ProductImageType.base ? 'base' : 'daily';

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete $imageTypeStr image?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('This image will be removed permanently.'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteProductImage(type, url);
    }
  }

  Future<void> _deleteProductImage(
      ProductImageType type, String imageUrl) async {
    if (stockData == null) {
      _showErrorDialog('Stock not loaded.');
      return;
    }

    final skuId = stockData!['sku_id']?.toString();
    final warehouseId = stockData!['warehouse_id']?.toString();

    if (skuId == null || warehouseId == null) {
      _showErrorDialog('SKU ID or Warehouse ID missing.');
      return;
    }

    final imageTypeStr = type == ProductImageType.base ? 'base' : 'daily';

    final overlay = _createLoaderOverlay();
    Overlay.of(context).insert(overlay);

    try {
      final response = await http.post(
        Uri.parse(_stockImageApiUrl),
        body: {
          'sku_id': skuId,
          'warehouse_id': warehouseId,
          'action': 'delete',
          'image_type': imageTypeStr,
          'image_url': imageUrl,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      overlay.remove();

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['status'] == true) {
          final dynamic imgs = jsonResp['images'];
          List<String> updated = [];
          if (imgs is List) {
            updated = imgs
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          updated = updated.reversed.toList();

          setState(() {
            if (type == ProductImageType.base) {
              baseProductImages = updated;
            } else {
              dailyProductImages = updated;
            }
          });

          _showSuccessDialog('Image deleted successfully.');
        } else {
          _showErrorDialog(
              jsonResp['message']?.toString() ?? 'Failed to delete image.');
        }
      } else {
        _showErrorDialog(
            'Failed to delete image (HTTP ${response.statusCode}).');
      }
    } catch (e) {
      overlay.remove();
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Delete timeout. Please check your internet connection.');
      } else {
        _showErrorDialog('Error while deleting image.');
      }
    }
  }

  void _showUploadProgressDialogForStockImages(String imageTypeLabel) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 16),
              Text(
                'Uploading $imageTypeLabel images...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 800,
        targetHeight: 800,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      // ignore and fallback
    }

    return imageBytes;
  }

  void _showImageProcessingDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text(
                'Processing image...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Optimizing for faster upload',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= RETURN FLOW (EXISTING) =================

  Future<void> findOrderID() async {
    FocusScope.of(context).unfocus();

    if (orderIdController.text.isEmpty) {
      return;
    }

    setState(() {
      orderData = null;
      orderId = '';
    });

    final overlayEntry = _createLoaderOverlay();
    Overlay.of(context).insert(overlayEntry);

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/get_completed_order.php'),
        body: {'tracking_id': orderIdController.text},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );

      overlayEntry.remove();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _handleFindOrderResponse(data);
      } else {
        _showErrorDialog('Server error, please try again later.');
      }
    } catch (e) {
      overlayEntry.remove();
      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Request timeout. Please check your internet connection.');
      } else {
        _showErrorDialog('No internet connection.');
      }
    }
  }

  void _handleFindOrderResponse(Map<String, dynamic> data) {
    if (data['status'] == 'success') {
      setState(() {
        orderData = data['data'][0];
        orderId = orderData!['id'].toString();
      });
    } else if (data['message'] ==
        'No pending orders found for this tracking ID') {
      setState(() {
        orderData = null;
        orderId = '';
      });
      _showInfoDialog('This tracking ID process is completed.');
    } else {
      setState(() {
        orderData = null;
        orderId = '';
      });
      _showErrorDialog('Tracking ID not found.');
    }
  }

  Future<void> submitScanOrder() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (orderIdController.text.isEmpty) {
      _showErrorDialog('Please enter Tracking ID.');
      return;
    }

    if (orderId.isEmpty) {
      _showErrorDialog('Order ID not found. Fetch it first.');
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    _showUploadProgressDialog();

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$_apiBaseUrl/updated_order.php"),
      );

      request.fields['id'] = orderId;
      request.fields['return_tracking_id'] = orderIdController.text;
      request.fields['bad_good_return'] = returnCondition;

      int totalFiles = stickerPhotos.length + unboxPhotos.length;
      int processedFiles = 0;

      for (int i = 0; i < stickerPhotos.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'sticker_photos[]',
            stickerPhotos[i],
            filename: "sticker_photo_$i.jpg",
          ),
        );
        processedFiles++;
        setState(() {
          uploadProgress =
              totalFiles == 0 ? 0.5 : (processedFiles / totalFiles) * 0.5;
        });
      }

      for (int i = 0; i < unboxPhotos.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'unbox_photos[]',
            unboxPhotos[i],
            filename: "unbox_photo_$i.jpg",
          ),
        );
        processedFiles++;
        setState(() {
          uploadProgress =
              totalFiles == 0 ? 0.5 : (processedFiles / totalFiles) * 0.5;
        });
      }

      setState(() {
        uploadProgress = 0.7;
      });

      var response = await request.send().timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Upload timeout'),
          );

      setState(() {
        uploadProgress = 0.9;
      });

      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.pop(context);
      }

      setState(() {
        isUploading = false;
        uploadProgress = 1.0;
      });

      if (jsonResponse['success'] == true) {
        _handleSuccessfulSubmission();
      } else {
        _showErrorDialog(jsonResponse['message'] ?? "Failed to update.");
      }
    } catch (e) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.pop(context);
      }
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });

      if (e.toString().contains('timeout')) {
        _showErrorDialog(
            'Upload timeout. Please try again with smaller images.');
      } else {
        _showErrorDialog('Upload failed. Check your internet connection.');
      }
    }
  }

  void _showUploadProgressDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Uploading images...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stickerPhotos.length + unboxPhotos.length} photos to upload',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${(uploadProgress * 100).toInt()}% complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSuccessfulSubmission() {
    _resetScreen();
    _showSuccessDialog('Order updated successfully.');
  }

  // ====================================================
  // ================= COMMON UI HELPERS ================
  // ====================================================

  OverlayEntry _createLoaderOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black12.withOpacity(0.3),
            child: const Center(
              child: CupertinoActivityIndicator(
                radius: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCupertinoAlert({
    required String title,
    required String message,
    Color? titleColor,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? CupertinoColors.label,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            isDefaultAction: true,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAutoDismissDialog({
    required String title,
    required String message,
    required Color titleColor,
    Duration duration = const Duration(seconds: 2),
  }) async {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
      ),
    );

    await Future.delayed(duration);

    if (!mounted) return;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showErrorDialog(String message) {
    _showCupertinoAlert(
      title: 'Error',
      message: message,
      titleColor: CupertinoColors.systemRed,
    );
  }

  void _showSuccessDialog(String message) {
    _showAutoDismissDialog(
      title: 'Success',
      message: message,
      titleColor: CupertinoColors.activeGreen,
    );
  }

  void _showInfoDialog(String message) {
    _showCupertinoAlert(
      title: 'Info',
      message: message,
      titleColor: CupertinoColors.activeBlue,
    );
  }

  // Image viewer (zoom in/out)
  void _openImageViewer({
    Uint8List? bytes,
    String? url,
  }) {
    if (bytes == null && url == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ImageViewer',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withOpacity(0.95),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child:
                    bytes != null ? Image.memory(bytes) : Image.network(url!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF718096),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: _primaryColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This tracking ID is in 'Completed' status. Select return condition and upload photos to update the order.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  CupertinoIcons.square_list,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Return Condition',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _buildReturnConditionButton(
                      "Good", 'good', Colors.green)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildReturnConditionButton("Bad", 'bad', Colors.red)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildReturnConditionButton(
                      "Used", 'used', Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnConditionButton(
      String label, String condition, Color color) {
    bool isSelected = returnCondition == condition;
    return GestureDetector(
      onTap: () {
        setState(() {
          returnCondition = condition;
          stickerPhotos.clear();
          unboxPhotos.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: 1.6,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                _getConditionIcon(condition),
                color: isSelected ? Colors.white : color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConditionIcon(String condition) {
    switch (condition) {
      case 'good':
        return CupertinoIcons.hand_thumbsup;
      case 'bad':
        return CupertinoIcons.hand_thumbsdown;
      case 'used':
        return CupertinoIcons.time;
      default:
        return CupertinoIcons.question;
    }
  }

  Widget _buildPhotoUploadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Photo Upload',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPhotoSection(
              'Sticker Photos', 'sticker', stickerPhotos, _primaryColor),
          const SizedBox(height: 16),
          _buildPhotoSection(
              'Unbox Photos', 'unbox', unboxPhotos, Colors.green.shade600),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(
      String title, String type, List<Uint8List> photos, Color color) {
    bool isMaxReached = photos.length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title (max 3)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            if (photos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "${photos.length}/3",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isMaxReached ? CupertinoColors.systemGrey3 : color,
            borderRadius: BorderRadius.circular(12),
            onPressed: isMaxReached ? null : () => _getImage(type),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMaxReached
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.camera,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isMaxReached ? "Maximum Reached" : "Capture Photo",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openImageViewer(bytes: photos[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            photos[index],
                            height: 96,
                            width: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (type == 'sticker') {
                                stickerPhotos.removeAt(index);
                              } else {
                                unboxPhotos.removeAt(index);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Existing image capture for returns
  Future<void> _getImage(String type) async {
    if (type == 'sticker' && stickerPhotos.length >= 3) {
      _showErrorDialog('You can upload a maximum of 3 sticker photos.');
      return;
    } else if (type == 'unbox' && unboxPhotos.length >= 3) {
      _showErrorDialog('You can upload a maximum of 3 unbox photos.');
      return;
    }

    _showImageProcessingDialog();

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();

        Uint8List finalImageBytes = imageBytes;
        if (imageBytes.length > 500000) {
          finalImageBytes = await _compressImage(imageBytes);
        }

        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.pop(context);
        }

        setState(() {
          if (type == 'sticker') {
            stickerPhotos.add(finalImageBytes);
          } else {
            unboxPhotos.add(finalImageBytes);
          }
        });

        _showSuccessDialog(
            'Image captured successfully (${(finalImageBytes.length / 1024).toStringAsFixed(1)} KB).');
      } else {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.pop(context);
      }
      _showErrorDialog('Failed to capture image. Please try again.');
    }
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: isUploading
            ? CupertinoColors.systemGrey3
            : CupertinoColors.systemGreen,
        borderRadius: BorderRadius.circular(14),
        onPressed: isUploading ? null : submitScanOrder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploading
                  ? CupertinoIcons.time
                  : CupertinoIcons.cloud_upload_fill,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isUploading ? "Uploading..." : "Update Order",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // ================== MAIN BUILD ======================
  // ====================================================

  @override
  Widget build(BuildContext context) {
    // Disable Android system back – user exits only via AppBar back
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: _primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Inward SKU',
            style: GoogleFonts.poppins(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _resetScreen,
              icon: const Icon(
                CupertinoIcons.refresh,
                color: _primaryColor,
              ),
              tooltip: 'Refresh / Clear',
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(82),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.7),
                ),
              ),
              child: _buildTopSearchRow(),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: _primaryColor,
          onRefresh: _handlePullToRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searchResults != null) _buildSearchResultsSection(),
                if (_searchResults != null) const SizedBox(height: 16),
                if (stockData != null) _buildStockDetailsSection(),
                if (stockData != null) const SizedBox(height: 16),
                if (stockData != null) _buildRackWiseStockSection(),
                if (orderData != null) const SizedBox(height: 20),
                if (orderData != null) _buildOrderDetailsSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== TOP SEARCH ROW ==================

  Widget _buildTopSearchRow() {
    return Row(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(12),
          onPressed: () async {
            final scannedSkuCode = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecondScanner(),
              ),
            );
            if (scannedSkuCode != null) {
              orderIdController.text = scannedSkuCode.toString();
              // SCAN FLOW – directly open specific SKU
              fetchStockDetails(scannedSkuCode.toString());
            }
          },
          child: const Icon(
            CupertinoIcons.qrcode_viewfinder,
            color: _primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextFormField(
              controller: orderIdController,
              focusNode: _focusNode,
              style: GoogleFonts.poppins(
                color: const Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (value) {
                final trimmed = value.trim();
                if (trimmed.isNotEmpty) {
                  // MANUAL SEARCH – show list
                  _searchSkuList(trimmed);
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter SKU Code / Name',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _primaryColor,
          borderRadius: BorderRadius.circular(12),
          onPressed: () {
            final code = orderIdController.text.trim();
            if (code.isNotEmpty) {
              // MANUAL SEARCH – show list
              _searchSkuList(code);
            }
          },
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.search,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                'Find',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ SEARCH RESULTS (MANUAL) SECTION ============

  Widget _buildSearchResultsSection() {
    final results = _searchResults ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  CupertinoIcons.search,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      _isSearchingSkus
                          ? 'Searching SKUs...'
                          : 'Tap a SKU to open details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSearchingSkus)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CupertinoActivityIndicator(),
              ),
            )
          else if (results.isEmpty)
            Text(
              'No SKUs found.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(
                height: 12,
                color: Color(0xFFE5E7EB),
              ),
              itemBuilder: (context, index) {
                final item = results[index];
                final skuCode = item['sku_code']?.toString() ?? 'N/A';
                final name = item['name']?.toString() ?? 'No name';
                final inStock = item['in_stock']?.toString() ?? '0';
                final warehouseId = item['warehouse_id']?.toString() ?? 'N/A';

                return InkWell(
                  onTap: () => _openSkuFromResult(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.cube_box,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skuCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'In Stock: $inStock',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF047857),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'WH: $warehouseId',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ================== STOCK SECTION ==================

  Widget _buildStockDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  CupertinoIcons.cube_box_fill,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Details',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Product information + Images',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildStockDetailRow('SKU Code', stockData!['sku_code']),
                _buildStockDetailRow('Product Name', stockData!['name']),
                _buildStockDetailRow(
                    'In Stock', stockData!['in_stock']?.toString() ?? '0'),
                _buildStockDetailRow(
                    'Bad Stock', stockData!['bad_stock']?.toString() ?? '0'),
                _buildStockDetailRow(
                    'Warehouse ID', stockData!['warehouse_id']?.toString()),
                _buildStockDetailRow(
                  'Status',
                  stockData!['blocked'] == '1' ? 'Blocked' : 'Active',
                ),
                _buildStockDetailRow(
                    'SKU ID', stockData!['sku_id']?.toString() ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildProductImageSection(),
        ],
      ),
    );
  }

  Widget _buildProductImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Base Images (max $_maxBaseImages)',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        _buildImageListSection(ProductImageType.base),
        const SizedBox(height: 18),
        Text(
          'Daily Images (unlimited)',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        _buildImageListSection(ProductImageType.daily),
      ],
    );
  }

  Widget _buildImageListSection(ProductImageType type) {
    final bool isBase = type == ProductImageType.base;

    final List<String> existing =
        isBase ? baseProductImages : dailyProductImages;
    final List<Uint8List> newOnes = isBase ? newBaseImages : newDailyImages;

    final bool isUploading =
        isBase ? isUploadingBaseImages : isUploadingDailyImages;

    final int maxBase = _maxBaseImages;
    final int totalBaseCount = baseProductImages.length + newBaseImages.length;

    final bool canAddMore = isBase ? totalBaseCount < maxBase : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (existing.isEmpty)
          Text(
            isBase
                ? 'No base images uploaded yet.'
                : 'No daily images uploaded yet.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existing.length,
              itemBuilder: (context, index) {
                final url = existing[index];
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openImageViewer(url: url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _confirmDeleteProductImage(type, url),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (newOnes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'New ${isBase ? 'Base' : 'Daily'} Images – ${newOnes.length}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemTeal,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newOnes.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openImageViewer(bytes: newOnes[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            newOnes[index],
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              newOnes.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                color: canAddMore
                    ? CupertinoColors.systemIndigo
                    : CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(12),
                onPressed: (!canAddMore || isUploading)
                    ? null
                    : () => _showProductImageSourceSheet(type),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBase ? 'Add Base' : 'Add Daily',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                color: isUploading
                    ? CupertinoColors.systemGrey3
                    : CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(12),
                onPressed:
                    isUploading ? null : () => _uploadProductImages(type),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUploading
                          ? CupertinoIcons.time
                          : CupertinoIcons.cloud_upload_fill,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUploading ? 'Uploading...' : 'Upload',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (isBase) ...[
          const SizedBox(height: 4),
          Text(
            'Maximum $_maxBaseImages base images allowed. Delete some to replace.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            'Daily images are unlimited. Use them for lifestyle / usage photos.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRackWiseStockSection() {
    // Pre-calc totals for summary
    int totalBefore = 0;
    int totalAdded = 0;
    int totalAfter = 0;

    if (rackStockData != null && rackStockData!.isNotEmpty) {
      for (int i = 0; i < rackStockData!.length; i++) {
        final rack = rackStockData![i] as Map<String, dynamic>;
        final originalInStock =
            int.tryParse(rack['in_stock']?.toString() ?? '0') ?? 0;
        final deltaStr = _rackDeltaEdited[i] ?? '0';
        final delta = int.tryParse(deltaStr) ?? 0;
        final newInStock = originalInStock + delta;

        totalBefore += originalInStock;
        totalAdded += delta;
        totalAfter += newInStock;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  CupertinoIcons.tray_full,
                  color: Color(0xFF059669),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rack-wise Stock (OMSGuru)',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Per rack current + added + new stock',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isRackLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CupertinoActivityIndicator(),
              ),
            )
          else if (rackStockData == null || rackStockData!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No rack-wise stock records found for this SKU.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            )
          else ...[
            // Column labels
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Rack',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Current',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Add',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'New',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rackStockData!.length,
              separatorBuilder: (_, __) => const Divider(
                height: 16,
                color: Color(0xFFE5E7EB),
              ),
              itemBuilder: (context, index) {
                final rack = rackStockData![index] as Map<String, dynamic>;
                final rackName = rack['rack_space_name'] ??
                    (rack['rack_space_id'] == '-1'
                        ? 'Unassigned'
                        : 'Rack ${rack['rack_space_id']}');

                final originalInStock =
                    int.tryParse(rack['in_stock']?.toString() ?? '0') ?? 0;
                final deltaStr = _rackDeltaEdited[index] ?? '';
                final delta = int.tryParse(deltaStr.isEmpty ? '0' : deltaStr) ?? 0;
                final newInStock = originalInStock + delta;

                final ctrl = TextEditingController(text: deltaStr);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rack info
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rackName.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rack ID: ${rack['rack_space_id']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bad: ${rack['bad_stock']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          originalInStock.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        width: 70,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.poppins(fontSize: 11),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _rackDeltaEdited[index] = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // New
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          newInStock.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            // Summary line
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current total: $totalBefore   •   Added: $totalAdded   •   New total: $totalAfter',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                color: isUpdatingRackStock
                    ? CupertinoColors.systemGrey3
                    : CupertinoColors.activeGreen,
                borderRadius: BorderRadius.circular(14),
                onPressed: isUpdatingRackStock ? null : _updateOmsRackStock,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUpdatingRackStock
                          ? CupertinoIcons.time
                          : CupertinoIcons.check_mark_circled_solid,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUpdatingRackStock
                          ? 'Updating...'
                          : 'Update Rack Stock in OMSGuru',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    return Column(
      children: [
        _buildOrderInfoCard(),
        const SizedBox(height: 16),
        _buildInstructionCard(),
        const SizedBox(height: 16),
        _buildReturnTypeSelector(),
        const SizedBox(height: 16),
        _buildPhotoUploadSection(),
        const SizedBox(height: 24),
        _buildScanButton(),
      ],
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed Order Found',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Ready for update processing',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildOrderDetailRow('Seller Name', orderData!['seller_name']),
                _buildOrderDetailRow('Order ID', orderData!['amazon_order_id']),
                _buildOrderDetailRow(
                    'Tracking ID', orderData!['return_tracking_id']),
                _buildOrderDetailRow('OTP', orderData!['otp']),
                _buildOrderDetailRow('Created', orderData!['created_at']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
