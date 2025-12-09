import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UpdatedOrdersScreen extends StatefulWidget {
  final String sellerId; // Add sellerId as a required parameter

  const UpdatedOrdersScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  _UpdatedOrdersScreenState createState() => _UpdatedOrdersScreenState();
}

class _UpdatedOrdersScreenState extends State<UpdatedOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  final ScrollController _scrollController = ScrollController();

  // Enhanced Color Palette with white background theme
  static const Color primaryColor = Color(0xFF1A365D);
  static const Color secondaryColor = Color(0xFF2C5AA0);
  static const Color accentColor = Color(0xFF3182CE);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);
  static const Color warningColor = Color(0xFFED8936);
  static const Color onSurfaceColor = Color(0xFF2D3748);
  static const Color mutedColor = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://customprint.deodap.com/api_amzDD_return/seller_updated_order.php?seller_id=${widget.sellerId}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          setState(() {
            _orders = data;
            _filteredOrders = List.from(_orders);
            _isLoading = false;
          });
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch orders');
        }
      } else {
        throw HttpException('Server error: ${response.statusCode}');
      }
    } on SocketException {
      _handleError('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      _handleError(e.message);
    } on FormatException {
      _handleError('Invalid data format received from server.');
    } catch (e) {
      _handleError('Failed to load orders. Please try again.');
    }
  }

  void _filterOrders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = List.from(_orders);
      } else {
        _filteredOrders = _orders.where((order) {
          final orderId = order['amazon_order_id']?.toString().toLowerCase() ?? '';
          final trackingId = order['return_tracking_id']?.toString().toLowerCase() ?? '';
          final queryLower = query.toLowerCase();

          return orderId.contains(queryLower) ||
              trackingId.contains(queryLower);
        }).toList();
      }
    });
  }



  void _clearSearch() {
    _searchController.clear();
    _filterOrders('');
    _searchFocusNode.unfocus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return successColor;
      case 'pending':
      case 'processing':
        return warningColor;
      case 'rejected':
      case 'cancelled':
        return errorColor;
      case 'shipped':
        return accentColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }



  Widget _buildOrderDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final images = order['images'] as List<dynamic>? ?? [];
    final status = order['status']?.toString() ?? 'UPDATED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['amazon_order_id'] ?? 'N/A'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: onSurfaceColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Order Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildOrderDetailRow(
                        Icons.local_shipping_rounded,
                        'Tracking',
                        order['return_tracking_id'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildOrderDetailRow(
                        Icons.info_outline_rounded,
                        'Condition',
                        order['bad_good_return'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildOrderDetailRow(
                        Icons.access_time_rounded,
                        'Updated',
                        _formatDate(order['updated_at']),
                      ),
                    ],
                  ),
                ),
                // Images Preview
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Images',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length > 4 ? 4 : images.length,
                      itemBuilder: (_, i) => Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                images[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.broken_image, color: mutedColor),
                                ),
                              ),
                            ),
                            if (i == 3 && images.length > 4)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${images.length - 4}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // Tap to view more indicator
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 60,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or date filters',
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order as Map<String, dynamic>);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Updated Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetchOrders,
              tooltip: 'Refresh Orders',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(color: onSurfaceColor),
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID, Seller, or Tracking ID...',
                      hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: mutedColor),
                        onPressed: _clearSearch,
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: Icon(Icons.search_rounded, color: mutedColor),
                    ),
                    onChanged: _filterOrders,
                  ),
                ),

              ],
            ),
          ),
          // Orders List
          Expanded(
            child: RefreshIndicator(
              backgroundColor: primaryColor,
              color: Colors.white,
              onRefresh: _fetchOrders,
              child: _buildOrderList(),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  // Colors matching the main screen
  static const Color primaryColor = Color(0xFF1A365D);
  static const Color secondaryColor = Color(0xFF2C5AA0);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);
  static const Color warningColor = Color(0xFFED8936);
  static const Color onSurfaceColor = Color(0xFF2D3748);
  static const Color mutedColor = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE2E8F0);

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return successColor;
      case 'pending':
      case 'processing':
        return warningColor;
      case 'rejected':
      case 'cancelled':
        return errorColor;
      case 'shipped':
        return const Color(0xFF4FC3F7);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'N/A';
    final isEmpty = displayValue == 'N/A' || displayValue.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: mutedColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: isEmpty ? mutedColor : onSurfaceColor,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                fontWeight: isEmpty ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = order['images'] ?? [];
    final String status = order['status']?.toString() ?? 'UNKNOWN';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(bottom: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['amazon_order_id'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Order Details
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Amazon Order ID', order['amazon_order_id']),
                  _buildDetailRow('Return Tracking ID', order['return_tracking_id']),
                  _buildDetailRow('OTP', order['otp']),
                  _buildDetailRow('Delivery Date', _formatDate(order['out_for_delivery_date'])),
                  _buildDetailRow('Condition', order['bad_good_return']),
                  _buildDetailRow('Created At', _formatDate(order['created_at'])),
                  _buildDetailRow('Updated At', _formatDate(order['updated_at'])),
                  if (order['remarks'] != null && order['remarks'].toString().isNotEmpty)
                    _buildDetailRow('Remarks', order['remarks']),
                ],
              ),
            ),
            // Images Section
            if (images.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Images (${images.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, i) {
                        return GestureDetector(
                          onTap: () => _showImageDialog(context, images[i]),
                          child: Hero(
                            tag: 'image_$i',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor.withOpacity(0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  images[i],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.broken_image, color: mutedColor),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}