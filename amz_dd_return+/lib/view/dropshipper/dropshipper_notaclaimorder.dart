import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DropshippernotclaimorderView extends StatefulWidget {
  const DropshippernotclaimorderView({super.key});

  @override
  State<DropshippernotclaimorderView> createState() => _DropshipperCompletedstatusOrderState();
}

class _DropshipperCompletedstatusOrderState extends State<DropshippernotclaimorderView> with TickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool noInternet = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    fetchOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Future<void> fetchOrders() async {
  //   setState(() {
  //     isLoading = true;
  //     noInternet = false;
  //   });
  //
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   if (connectivityResult == ConnectivityResult.none) {
  //     setState(() {
  //       noInternet = true;
  //       isLoading = false;
  //     });
  //     return;
  //   }
  //
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String sellerId = prefs.getString('userId') ?? 'N/A';
  //   print("Seller ID from SharedPreferences: $sellerId");
  //
  //   String url = 'https://customprint.deodap.com/api_amzDD_return/saller_get_completedorder.php?seller_id=$sellerId';
  //
  //   try {
  //     var response = await Dio().get(url);
  //     var data = response.data;
  //
  //     if (data['success']) {
  //       setState(() {
  //         orders = data['data'] ?? [];
  //       });
  //     } else {
  //       setState(() {
  //         orders = [];
  //       });
  //     }
  //   } catch (e) {
  //     print("API Error: $e");
  //     setState(() {
  //       noInternet = true; // Agar API call fail ho to internet issue samjho
  //     });
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sellerId = prefs.getString('seller_id');

    if (sellerId == null || sellerId.isEmpty) {
      print("Seller ID not found in SharedPreferences");
      setState(() {
        isLoading = false;
      });
      return;
    }

    String url = 'https://customprint.deodap.com/api_amzDD_return/seller_get_notclaim_order.php?seller_id=$sellerId';

    try {
      var response = await Dio().get(url);
      var data = response.data;

      if (data['success']) {
        List<Map<String, dynamic>> tempOrders = [];
        if (data['data'] != null) {
          for (var order in data['data']) {
            tempOrders.add(Map<String, dynamic>.from(order));
          }
        }
        setState(() {
          orders = tempOrders;
        });
        if (tempOrders.isNotEmpty) {
          _animationController.forward();
        }
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

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    bool hasImages = order['images'] != null && order['images'].isNotEmpty;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onLongPress: hasImages ? () => _showImageDialog(order['images']) : null,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          // Order Number Badge
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade500, Colors.blue.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // Seller Info (if available)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order['seller_name'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange.shade200, Colors.orange.shade100],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: Text(
                                      "${order['seller_name']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (order['seller_id'] != null)
                                  Row(
                                    children: [
                                      Icon(Icons.store, size: 14, color: Colors.blue.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        "ID: ${order['seller_id']}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Status & Action Icons
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (hasImages)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: Colors.purple.shade600,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Order Details Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.confirmation_number,
                              "Order ID",
                              "${order['amazon_order_id'] ?? 'N/A'}",
                              Colors.indigo.shade600,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.local_shipping,
                              "Tracking ID",
                              "${order['return_tracking_id'] ?? 'N/A'}",
                              Colors.teal.shade600,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.security,
                              "OTP",
                              "${order['otp'] ?? 'N/A'}",
                              Colors.deepOrange.shade600,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.access_time,
                              "Created At",
                              "${order['created_at'] ?? 'N/A'}",
                              Colors.purple.shade600,
                            ),
                          ],
                        ),
                      ),

                      // Action Hint
                      if (hasImages) ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, size: 16, color: Colors.purple.shade600),
                              const SizedBox(width: 6),
                              Text(
                                "Long press to view images",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  void _showImageDialog(dynamic images) {
    List<String> imageUrls = [];

    if (images != null && images.isNotEmpty) {
      for (var img in images) {
        if (img is String && img.trim().startsWith('[')) {
          try {
            final decoded = List<String>.from(jsonDecode(img));
            imageUrls.addAll(decoded);
          } catch (e) {
            imageUrls.add(img);
          }
        } else {
          imageUrls.add(img.toString());
        }
      }
    }

    if (imageUrls.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Order Images (${imageUrls.length})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Images
                Expanded(
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, imgIndex) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrls[imgIndex],
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blue.shade600,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.error, size: 50, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${imgIndex + 1} of ${imageUrls.length}",
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(String type, String title, String subtitle, Color color, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.blue.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (type == 'no_internet') ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text(
          'Not a Claim Orders',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: fetchOrders,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Content Area
            Expanded(
              child: isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: CircularProgressIndicator(
                        color: Colors.blue.shade600,
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Loading Orders...",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              )
                  : noInternet
                  ? _buildEmptyState(
                'no_internet',
                'Connection Lost',
                'Please check your internet connection\nand try again.',
                Colors.red.shade600,
                Icons.wifi_off_rounded,
              )
                  : orders.isEmpty
                  ? _buildEmptyState(
                'no_data',
                'No Claims Found',
                'There are no "Not a Claim" orders\navailable at the moment.',
                Colors.blue.shade600,
                Icons.inbox_rounded,
              )
                  : RefreshIndicator(
                color: Colors.blue.shade600,
                backgroundColor: Colors.white,
                onRefresh: fetchOrders,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: orders.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    return _buildOrderCard(orders[index], index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
