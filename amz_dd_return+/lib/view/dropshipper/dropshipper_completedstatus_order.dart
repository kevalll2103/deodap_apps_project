import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DropshipperCompletedstatusOrder extends StatefulWidget {
  const DropshipperCompletedstatusOrder({super.key});

  @override
  State<DropshipperCompletedstatusOrder> createState() => _DropshipperCompletedstatusOrderState();
}

class _DropshipperCompletedstatusOrderState extends State<DropshipperCompletedstatusOrder> {
  // Color constants - matching the design system
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Colors.blueAccent;
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  List<dynamic> orders = [];
  bool isLoading = true;
  bool noInternet = false;

  @override
  void initState() {
    super.initState();
    fetchOrders();
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
    String? sellerId = prefs.getString('seller_id'); // ✅ match your key here

    if (sellerId == null || sellerId.isEmpty) {
      print("Seller ID not found in SharedPreferences");
      setState(() {
        isLoading = false;
      });
      return;
    }

    String url = 'https://customprint.deodap.com/api_amzDD_return/saller_get_completedorder.php?seller_id=$sellerId';

    try {
      var response = await Dio().get(url);
      var data = response.data;

      if (data['success']) {
        setState(() {
          orders = data['data'] ?? [];
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


  @override
  Widget build(BuildContext context) {
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
      body: isLoading
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
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(orders[index], index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
      ),
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
                    Icons.check_circle,
                    color: successColor,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Done',
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
}
