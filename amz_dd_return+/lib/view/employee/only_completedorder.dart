import 'dart:convert';

import 'package:amz/view/employee/scan_another_trackingID.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OnlyCompletedorder extends StatefulWidget {
  const OnlyCompletedorder({super.key});

  @override
  State<OnlyCompletedorder> createState() => _OnlyCompletedorderState();
}

class _OnlyCompletedorderState extends State<OnlyCompletedorder> with TickerProviderStateMixin {
  // Color constants - matching the design system
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.blueAccent;
  static const Color accentColor = Colors.blue;
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool noInternet = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchOrders();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      noInternet = false;
    });

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        noInternet = true;
        isLoading = false;
      });
      return;
    }

    String url = 'https://customprint.deodap.com/api_amzDD_return/only_completeorder.php';

    try {
      var response = await Dio().get(url);
      var data = response.data;

      if (data != null && data['status'] == 'success' && data['sellers'] != null && data['sellers'].isNotEmpty) {
        List<Map<String, dynamic>> tempOrders = [];

        data['sellers'].forEach((sellerId, sellerOrders) {
          for (var order in sellerOrders) {
            tempOrders.add({
              'seller_id': sellerId,
              ...order,
            });
          }
        });

        setState(() {
          orders = tempOrders;
        });
      } else {
        setState(() {
          orders = [];
        });
      }
    } catch (e) {
      print("API Error: $e");
      setState(() {
        noInternet = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  List<Map<String, dynamic>> get validOrders => orders.where((order) => 
    order['otp_status'] == 'right' || order['otp_status'] == 'correct' || order['otp_status'] == null).toList();

  void _showImageDialog(List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 450,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Images',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: primaryColor),
                      style: IconButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, imgIndex) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrls[imgIndex],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 50, color: errorColor),
                                    SizedBox(height: 8),
                                    Text('Failed to load image', style: TextStyle(color: errorColor)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (imageUrls.length > 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Swipe to view more images (${imageUrls.length} total)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['seller_name'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Seller ID', order['seller_id'] ?? 'N/A'),
                      _buildInfoRow('Order ID', order['amazon_order_id'] ?? 'N/A'),
                      _buildInfoRow('Tracking ID', order['return_tracking_id'] ?? 'N/A'),
                      _buildInfoRow('OTP', order['otp'] ?? 'N/A'),
                      _buildInfoRow('Created', order['created_at'] ?? 'N/A'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: successColor,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valid',
                        style: TextStyle(
                          color: successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayOrders = validOrders;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: cardColor),
        ),
        title: Text(
          "Completed Orders",
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: fetchOrders,
              icon: const Icon(Icons.refresh, color: cardColor),
              tooltip: 'Refresh Orders',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(color: primaryColor),
          )
              : noInternet
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: errorColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No Internet Connection",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please check your connection and try again",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: fetchOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          )
              : orders.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No Completed Orders",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "There are no completed orders at this time",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : RefreshIndicator(
            color: primaryColor,
            backgroundColor: cardColor,
            onRefresh: fetchOrders,
            child: Column(
              children: [
                // Orders Count Badge
                if (displayOrders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 16, color: successColor),
                              const SizedBox(width: 6),
                              Text(
                                '${displayOrders.length} Completed Order${displayOrders.length != 1 ? 's' : ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Orders List
                Expanded(
                  child: displayOrders.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.filter_list_off,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders match your filter',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: displayOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(displayOrders[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}