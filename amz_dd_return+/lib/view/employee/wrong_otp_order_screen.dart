import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WrongOtpOrderScreen extends StatefulWidget {
  const WrongOtpOrderScreen({super.key});

  @override
  State<WrongOtpOrderScreen> createState() => _WrongOtpOrderScreenState();
}

class _WrongOtpOrderScreenState extends State<WrongOtpOrderScreen>
    with TickerProviderStateMixin {
  // Enhanced Color Palette
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF1D4ED8);
  static const Color backgroundColor = Color(0xFFF1F5F9);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color onSurfaceColor = Color(0xFF334155);
  static const Color mutedColor = Color(0xFF64748B);

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

    String url = 'https://customprint.deodap.com/api_amzDD_return/get_wrongotp_orders.php';

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

  void _showImageDialog(List<String> imageUrls) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Order Images',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
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
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrls[imgIndex],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 3,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading image...',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: errorColor.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: errorColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: errorColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Failed to load image',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: errorColor,
                                      ),
                                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe, color: mutedColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Swipe to view ${imageUrls.length} images',
                        style: GoogleFonts.inter(
                          color: mutedColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(20),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                if (order['images'] != null && order['images'].isNotEmpty) {
                  List<String> imageUrls = [];
                  for (var img in order['images']) {
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

                  if (imageUrls.isNotEmpty) {
                    _showImageDialog(imageUrls);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [errorColor, errorColor.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: errorColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order['seller_name'] ?? 'Unknown Seller',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: warningColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Order #${order['amazon_order_id'] ?? 'N/A'}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: onSurfaceColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: errorColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('Seller ID', order['seller_id'] ?? 'N/A', Icons.store),
                          const SizedBox(height: 12),
                          _buildInfoRow('Tracking ID', order['return_tracking_id'] ?? 'N/A', Icons.local_shipping),
                          const SizedBox(height: 12),
                          _buildInfoRow('OTP', order['otp'] ?? 'N/A', Icons.lock_outline),
                          const SizedBox(height: 12),
                          _buildInfoRow('Created', _formatDate(order['created_at']), Icons.schedule),
                        ],
                      ),
                    ),
                    if (order['images'] != null && order['images'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Long press to view images',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: primaryColor,
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
      ),
    );
  }




  Widget _buildInfoRow(String label, String value, IconData icon) {
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
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString == 'N/A') return 'N/A';
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: (iconColor ?? primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor ?? primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: mutedColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 32),
              action,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          "Wrong OTP Orders",
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                fetchOrders();
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading orders...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : noInternet
          ? _buildEmptyState(
        icon: Icons.wifi_off_rounded,
        title: "No Internet Connection",
        subtitle: "Please check your connection and try again",
        iconColor: errorColor,
        action: ElevatedButton.icon(
          onPressed: fetchOrders,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      )
          : orders.isEmpty
          ? _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: "All Clear!",
        subtitle: "There are no wrong OTP orders at this time. Everything looks good!",
        iconColor: successColor,
      )
          : RefreshIndicator(
        color: primaryColor,
        backgroundColor: cardColor,
        onRefresh: fetchOrders,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: errorColor),
                          const SizedBox(width: 6),
                          Text(
                            '${orders.length} Wrong OTP Order${orders.length != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildOrderCard(orders[index], index),
                  childCount: orders.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Don't forget to add this import at the top
