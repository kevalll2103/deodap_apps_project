import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EmployeeOrderscanScreenview extends StatefulWidget {
  const EmployeeOrderscanScreenview({super.key});

  @override
  State<EmployeeOrderscanScreenview> createState() => _EmployeeOrderscanScreenviewState();
}

class _EmployeeOrderscanScreenviewState extends State<EmployeeOrderscanScreenview> with TickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool noInternet = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

    String url = 'https://customprint.deodap.com/api_amzDD_return/all_sallertotalcountdata.php';

    try {
      var response = await Dio().get(url);
      var data = response.data;

      if (data['success'] && data['sellers'] is Map && data['sellers'].isNotEmpty) {
        List<Map<String, dynamic>> tempOrders = [];
        data['sellers'].forEach((sellerName, sellerOrders) {
          for (var order in sellerOrders) {
            tempOrders.add({
              'seller_name': sellerName,
              ...order,
            });
          }
        });
        setState(() {
          orders = tempOrders;
        });
        _animationController.forward();
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          "${order['seller_name']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Seller ID: ${order['seller_id'] ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order Details Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.confirmation_number,
                    "Order ID",
                    "${order['amazon_order_id'] ?? 'N/A'}",
                    Colors.blue.shade600,
                  ),
                  const Divider(color: Colors.blue, height: 16),
                  _buildInfoRow(
                    Icons.local_shipping,
                    "Tracking ID",
                    "${order['return_tracking_id'] ?? 'N/A'}",
                    Colors.purple.shade600,
                  ),
                  const Divider(color: Colors.blue, height: 16),
                  _buildInfoRow(
                    Icons.security,
                    "OTP",
                    "${order['otp'] ?? 'N/A'}",
                    Colors.red.shade600,
                  ),
                  const Divider(color: Colors.blue, height: 16),
                  _buildInfoRow(
                    Icons.access_time,
                    "Created At",
                    "${order['created_at'] ?? 'N/A'}",
                    Colors.teal.shade600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String imagePath, String title, String subtitle, Color titleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              imagePath == 'no_internet' ? Icons.wifi_off : Icons.inbox,
              size: 80,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (imagePath == 'no_internet') ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
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
          "All Pending Orders",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: fetchOrders,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [

              // Orders Count Badge
              if (!isLoading && !noInternet && orders.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Total Orders: ${orders.length}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade600,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loading Orders...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                )
                    : noInternet
                    ? _buildEmptyState(
                  'no_internet',
                  'No Internet Connection',
                  'Please check your internet connection\nand try again.',
                  Colors.red.shade600,
                )
                    : orders.isEmpty
                    ? _buildEmptyState(
                  'no_data',
                  'No Orders Found',
                  'There are no pending orders\nat the moment.',
                  Colors.blue.shade600,
                )
                    : RefreshIndicator(
                  color: Colors.blue.shade600,
                  backgroundColor: Colors.white,
                  onRefresh: fetchOrders,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: orders.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutBack,
                          child: _buildOrderCard(orders[index], index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}