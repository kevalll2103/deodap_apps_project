import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, CircleAvatar; // only for Colors.transparent
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

// ===== Your screens (keep these imports as in your project) =====
import 'package:Deodap_Customprint/aboutapp_screen.dart';
import 'package:Deodap_Customprint/addorderscreen.dart';
import 'package:Deodap_Customprint/contactscreen.dart';
import 'package:Deodap_Customprint/recyclebin_screen.dart';
import 'package:Deodap_Customprint/getreport_screen.dart' as report;
import 'package:Deodap_Customprint/getreport_screen.dart';
import 'package:Deodap_Customprint/homefullscreenimage.dart';
import 'package:Deodap_Customprint/invitefrd_screen.dart';
import 'package:Deodap_Customprint/one_orderupdatescreen.dart';
import 'package:Deodap_Customprint/second_qrcodescanner_screen.dart' show SecondQrcodescannerScreen;
import 'package:Deodap_Customprint/showallrecord.dart';
import 'package:Deodap_Customprint/splashscreen.dart';
import 'package:Deodap_Customprint/setting_screen.dart';
// ===== Brand color (replaces all previous accents) =====
const kBrand = Color(0xFF007E9B);

class HomescreenCupertinoIOS extends StatefulWidget {
  const HomescreenCupertinoIOS({super.key});

  @override
  State<HomescreenCupertinoIOS> createState() => _HomescreenCupertinoIOSState();
}

class _HomescreenCupertinoIOSState extends State<HomescreenCupertinoIOS> with TickerProviderStateMixin {
  // Controllers & Focus
  final TextEditingController _orderIdController = TextEditingController();
  final FocusNode _orderIdFocusNode = FocusNode();

  // App State
  static const String _appVersion = "1.0.0";
  static const String _keyLogin = 'isLoggedIn';

  String _sellerName = 'N/A';
  String _userEmail = 'N/A';
  String _userId = 'N/A';
  bool _isLoading = false;
  bool _isFetchingProduct = false;
  Map<String, dynamic>? _sellerData;
  String? _errorMessage;
  Map<String, dynamic>? _productData;

  // Animations (subtle)
  late AnimationController _welcomeController;
  late Animation<double> _welcomeOpacity;

  // Overlay for "Processing…"
  OverlayEntry? _overlayEntry;

  // Drawer state
  bool _isDrawerOpen = false;
  final double _drawerWidth = 300;

  @override
  void initState() {
    super.initState();
    _initAnim();
    _initializeApp();
  }

  void _initAnim() {
    _welcomeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _welcomeOpacity = CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut);
    _welcomeController.forward();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _orderIdFocusNode.dispose();
    _welcomeController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  // =========================
  // Initialization
  // =========================
  Future<void> _initializeApp() async {
    try {
      await _loadUserDetails();
      await _fetchOrders();
    } catch (e) {
      _showCupertinoError('Initialization Error', 'Failed to initialize app: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _sellerName = prefs.getString('fullname') ?? 'N/A';
        _userEmail = prefs.getString('email') ?? 'N/A';
        _userId = prefs.getString('user_id') ?? 'N/A';
      });
    } catch (e) {
      _showCupertinoError('User Details Error', 'Failed to load user details: $e');
    }
  }

  // =========================
  // Network
  // =========================
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => _errorMessage = "No Internet Connection");
        return;
      }

      const url = "https://customprint.deodap.com/api_customprint/count_product.php";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _sellerData = data['data']);
        } else {
          setState(() => _errorMessage = data['message'] ?? 'Failed to fetch orders');
        }
      } else {
        setState(() => _errorMessage = 'Server error: ${response.statusCode}');
      }
    } on SocketException {
      setState(() => _errorMessage = "No Internet Connection");
    } on TimeoutException {
      setState(() => _errorMessage = "Request Timeout");
    } catch (e) {
      setState(() => _errorMessage = "Failed to fetch orders: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _findProduct() async {
    if (!mounted) return;

    final productUniqueId = _orderIdController.text.trim();
    if (productUniqueId.isEmpty) {
      _showCupertinoInfo('Empty Field', 'Please enter an order ID');
      return;
    }

    setState(() {
      _isFetchingProduct = true;
      _productData = null;
    });
    _unfocusAll();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _showCupertinoError('Connection Error', 'No internet connection');
        return;
      }

      const url = 'https://customprint.deodap.com/api_customprint/count_product.php';
      final response = await http
          .post(Uri.parse(url), body: {'product_unique_id': productUniqueId})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() => _productData = responseData['data']);
        } else {
          _showCupertinoInfo('Not Found', responseData['message'] ?? 'Order ID not found');
        }
      } else {
        _showCupertinoError('Server Error', 'Failed to fetch order details');
      }
    } on SocketException {
      _showCupertinoError('Connection Error', 'No internet connection');
    } on TimeoutException {
      _showCupertinoError('Timeout', 'Server took too long to respond');
    } catch (e) {
      _showCupertinoError('Find Product Error', 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isFetchingProduct = false);
    }
  }

  Future<void> _moveToRecycleBin() async {
    if (!mounted || _productData == null) return;
    _showLoadingOverlay();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final orderId = _productData!['product_id'];

      if (userId != null && orderId != null) {
        await _moveOrderToRecycleBin(orderId, userId);
        _clearProductData();
        _showCupertinoSuccess('Success', 'Order moved to recycle bin');
      } else {
        _showCupertinoError('Error', 'User or order info not found');
      }
    } catch (e) {
      _showCupertinoError('Move Error', 'Failed to move: $e');
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> _moveOrderToRecycleBin(String orderId, String userId) async {
    const url = 'https://customprint.deodap.com/api_customprint/move_to_recyclebin.php';

    final response = await http
        .post(Uri.parse(url), body: {'product_id': orderId, 'user_id': userId})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to move order to recycle bin');
    }

    final responseData = json.decode(response.body);
    if (responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Failed to move order');
    }
  }

  Future<void> _deleteProduct() async {
    if (!mounted || _productData == null) return;

    _showLoadingOverlay();
    try {
      final productId = _productData!['product_id'];
      final url = 'https://customprint.deodap.com/delete_one_order_by_ID.php?id=$productId';

      final response = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != null) {
          _clearProductData();
          _showCupertinoSuccess('Deleted', 'Product deleted successfully');
        } else {
          _showCupertinoError('Error', jsonResponse['message'] ?? 'Order ID does not exist');
        }
      } else {
        _showCupertinoError('Server Error', 'Failed to delete product');
      }
    } on SocketException {
      _showCupertinoError('Connection Error', 'No internet connection');
    } on TimeoutException {
      _showCupertinoError('Timeout', 'Server took too long to respond');
    } catch (e) {
      _showCupertinoError('Delete Error', 'Failed: $e');
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> _performLogout() async {
    _showLoadingOverlay();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final shared = await SharedPreferences.getInstance();
      await shared.setBool(_keyLogin, false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => Splashscreen()),
        );
      }
    } catch (e) {
      _showCupertinoError('Logout Error', 'Failed: $e');
    } finally {
      _hideLoadingOverlay();
    }
  }

  // =========================
  // Utilities & Overlays
  // =========================
  void _unfocusAll() {
    FocusScope.of(context).unfocus();
    _orderIdFocusNode.unfocus();
  }

  void _clearProductData() {
    setState(() {
      _productData = null;
      _orderIdController.clear();
    });
  }

  void _showLoadingOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(child: Container(color: CupertinoColors.black.withOpacity(0.35))),
          Center(
            child: CupertinoPopupSurface(
              isSurfacePainted: true,
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(height: 6),
                    CupertinoActivityIndicator(radius: 12),
                    SizedBox(height: 10),
                    Text('Processing…', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // =========================
  // Cupertino Dialogs
  // =========================
  Future<void> _showCupertinoError(String title, String message) async {
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message, style: GoogleFonts.poppins(fontSize: 13, decoration: TextDecoration.none)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCupertinoSuccess(String title, String message) async {
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message, style: GoogleFonts.poppins(fontSize: 13, decoration: TextDecoration.none)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCupertinoInfo(String title, String message) async {
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message, style: GoogleFonts.poppins(fontSize: 13, decoration: TextDecoration.none)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderActions() async {
    if (!mounted) return;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Order Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _moveToRecycleBin();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.trash, size: 18),
                const SizedBox(width: 8),
                Text('Move to Bin', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct();
            },
            isDestructiveAction: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.delete_simple, size: 18),
                const SizedBox(width: 8),
                Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Are you sure you want to logout?', style: GoogleFonts.poppins(fontSize: 13, decoration: TextDecoration.none)),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: GoogleFonts.poppins(decoration: TextDecoration.none)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout();
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // Navigation helper
  // =========================
  void _navigateTo(Widget page) {
    _unfocusAll();
    _clearProductData();
    Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
  }

  // ============================================================
  // Custom Left "Cupertino Drawer"
  // ============================================================
  Widget _cupertinoDrawer() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SafeArea(
        child: Container(
          width: _drawerWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border(
              right: BorderSide(color: CupertinoColors.separator, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              _drawerHeader(),        // smaller header
              Expanded(child: _drawerItems()), // flat list, no rounded corners
              _drawerVersion(),
            ],
          ),
        ),
      ),
    );
  }

  // Smaller profile details header
  Widget _drawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      color: kBrand, // solid brand color
      child: Row(
        children: [
          Container(
            width: 56, // smaller
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CupertinoColors.white, width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: CupertinoColors.white,
              backgroundImage: AssetImage('assets/images/user_image.jpeg'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text("ID: $_userId",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      )),
                ),
                const SizedBox(height: 4),
                Text("Deodap Custom Printing",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: CupertinoColors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Flat list (no corners, no borders on tiles)
  Widget _drawerItems() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _drawerTile(CupertinoIcons.trash, "Recycle Bin", kBrand, () {
          _toggleDrawer(false);
          _navigateTo(const RecyclebinscreenView());
        }, emphasize: true),

        _divider(),
        _drawerTile(CupertinoIcons.house, "Home", kBrand, () => _toggleDrawer(false)),
        _drawerTile(CupertinoIcons.cube_box, "All Orders", kBrand, () {
          _toggleDrawer(false);
          _navigateTo(const ShowAllRecordCupertino());
        }),
        _drawerTile(CupertinoIcons.doc_text, "Get Report", kBrand, () {
          _toggleDrawer(false);
          _navigateTo(CustomprintReportPage());
        }),
        _drawerTile(CupertinoIcons.info, "Settings", kBrand, () {
          _toggleDrawer(false);
          _navigateTo(setting());
        }),

        _divider(),
        _drawerTile(CupertinoIcons.square_arrow_right, "Logout", CupertinoColors.systemRed, () {
          _toggleDrawer(false);
          _confirmLogout();
        }, danger: true),
      ],
    );
  }

  Widget _drawerTile(
      IconData icon,
      String title,
      Color tint,
      VoidCallback onTap, {
        bool emphasize = false,
        bool danger = false,
      }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (danger ? CupertinoColors.systemRed : tint).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: danger ? CupertinoColors.systemRed : tint, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: danger ? CupertinoColors.systemRed : CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const Icon(CupertinoIcons.forward, size: 16, color: CupertinoColors.systemGrey),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 0.6, color: CupertinoColors.separator);

  Widget _drawerVersion() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.separator),
        ),
        child: Center(
          child: Text(
            'Version: $_appVersion',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDrawer(bool open) {
    setState(() => _isDrawerOpen = open);
  }

  // =========================
  // UI Pieces (compact iOS)
  // =========================

  // White background welcome card (as requested)
  Widget _welcomeCard() {
    return FadeTransition(
      opacity: _welcomeOpacity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CupertinoColors.separator),
          boxShadow: [
            BoxShadow(
              color: kBrand.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: GoogleFonts.poppins(color: CupertinoColors.label, decoration: TextDecoration.none),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back! 👋",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel,
                          decoration: TextDecoration.none,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      _sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kBrand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.person, color: kBrand, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tint,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: CupertinoColors.secondaryLabel,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCounts() {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(fontSize: 12, color: CupertinoColors.systemRed, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _fetchOrders,
                  child: const Icon(CupertinoIcons.refresh, size: 18),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile(
              title: "Total Orders",
              value: _sellerData != null ? "${_sellerData!['total_products'] ?? '0'}" : "0",
              icon: CupertinoIcons.cube_box,
              tint: kBrand,
            ),
            const SizedBox(width: 10),
            _statTile(
              title: "Quick Report",
              value: "CSV",
              icon: CupertinoIcons.doc_text,
              tint: CupertinoColors.activeGreen,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.separator),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Generate Report", style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                    const SizedBox(height: 2),
                    Text("Download comprehensive order reports", style: GoogleFonts.poppins(fontSize: 12, color: CupertinoColors.secondaryLabel, decoration: TextDecoration.none)),
                  ],
                ),
              ),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () async {
                  _unfocusAll();
                  await Navigator.push(context, CupertinoPageRoute(builder: (_) => CustomprintReportPage()));
                  _clearProductData();
                },
                child: Text('Get Report', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(CupertinoIcons.search, color: kBrand, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Search Order", style: GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                Text("Find and manage your orders", style: GoogleFonts.poppins(fontSize: 12, color: CupertinoColors.secondaryLabel, decoration: TextDecoration.none)),
              ],
            )
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.separator),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoTextField(
                    controller: _orderIdController,
                    focusNode: _orderIdFocusNode,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    placeholder: 'Enter Order ID',
                    placeholderStyle: GoogleFonts.poppins(color: CupertinoColors.placeholderText, fontSize: 14, decoration: TextDecoration.none),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: CupertinoColors.label, decoration: TextDecoration.none),
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minSize: 36,
                  color: kBrand,
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(CupertinoIcons.qrcode_viewfinder, color: CupertinoColors.white, size: 18),
                  onPressed: () async {
                    _unfocusAll();
                    _clearProductData();
                    final scannedOrderId = await Navigator.push(context, CupertinoPageRoute(builder: (_) => SecondQrcodescannerScreen()));
                    if (scannedOrderId != null && scannedOrderId != 'No order ID available') {
                      _orderIdController.text = scannedOrderId;
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: CupertinoButton.filled(
              onPressed: _isFetchingProduct ? null : _findProduct,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _isFetchingProduct
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 10),
                  Text('Searching…', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.search, size: 18),
                  const SizedBox(width: 6),
                  Text('Find Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color tint) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: CupertinoColors.secondaryLabel, fontWeight: FontWeight.w500, decoration: TextDecoration.none)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.poppins(fontSize: 14, color: CupertinoColors.label, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _productImage() {
    final String? url = _productData?['product_image'];
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          _unfocusAll();
          if (url != null) {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => HomeFullScreenImage(imageUrl: url)));
          }
        },
        child: url != null
            ? Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(color: CupertinoColors.systemGrey6, child: const Center(child: CupertinoActivityIndicator()));
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: CupertinoColors.systemGrey6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_square, size: 20, color: CupertinoColors.systemGrey),
                Text('Error', style: GoogleFonts.poppins(fontSize: 10, color: CupertinoColors.systemGrey2, decoration: TextDecoration.none)),
              ],
            ),
          ),
        )
            : Container(
          color: CupertinoColors.systemGrey6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.photo_on_rectangle, size: 20, color: CupertinoColors.systemGrey),
              Text('No Image', style: GoogleFonts.poppins(fontSize: 10, color: CupertinoColors.systemGrey2, decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard() {
    if (_productData == null || _productData!.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/sammy-line-searching.gif', height: 90, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text("No Order Selected", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: CupertinoColors.secondaryLabel, decoration: TextDecoration.none)),
          const SizedBox(height: 4),
          Text("Search for an order ID to view details", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: CupertinoColors.systemGrey, decoration: TextDecoration.none)),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrand.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: kBrand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "#${_productData!['product_id'] ?? 'N/A'}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: CupertinoColors.white, fontSize: 11.5, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order Found! ✅", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: CupertinoColors.activeGreen, decoration: TextDecoration.none)),
                      const SizedBox(height: 2),
                      Text(
                        "${_productData!['product_unique_id'] ?? 'N/A'}",
                        style: GoogleFonts.poppins(fontSize: 13.5, color: CupertinoColors.label, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
                _productImage(),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _detailRow(CupertinoIcons.person, "Customer", "${_productData!['fullname'] ?? 'N/A'}", kBrand),
                const SizedBox(height: 8),
                _detailRow(CupertinoIcons.phone, "Mobile", "${_productData!['mobilenumber'] ?? 'N/A'}", kBrand),
                const SizedBox(height: 8),
                _detailRow(CupertinoIcons.time, "Created", "${_productData!['created_at'] ?? 'N/A'}", kBrand),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        onPressed: _navigateToEdit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.pencil, size: 18),
                            const SizedBox(width: 6),
                            Text('Edit Order', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: CupertinoColors.systemRed,
                        onPressed: _showOrderActions,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.ellipsis, size: 18, color: CupertinoColors.white),
                            const SizedBox(width: 6),
                            Text('Actions', style: GoogleFonts.poppins(color: CupertinoColors.white, fontSize: 13.5, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    _unfocusAll();
    _orderIdController.clear();
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => OrderUpdatescreenView(
          productUniqueId: _productData!['product_unique_id'] ?? '',
          productImage: _productData!['product_image'] ?? '',
          productName: _productData!['product_name'] ?? '',
          createdAt: _productData!['created_at'] ?? '',
          Id: _productData!['product_id']?.toString() ?? '',
        ),
      ),
    );
    setState(() => _productData = null);
  }

  Widget _footer() {
    return Center(
      child: Text(
        'Version: $_appVersion • ID: $_userId',
        style: GoogleFonts.poppins(fontSize: 11.5, color: CupertinoColors.secondaryLabel, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text("Deodap Custom Printing", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _toggleDrawer(true),
          child: const Icon(CupertinoIcons.line_horizontal_3, size: 22),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            _unfocusAll();
            await Navigator.push(context, CupertinoPageRoute(builder: (_) => Addorderscreen()));
            await _fetchOrders();
            _clearProductData();
          },
          child: const Icon(CupertinoIcons.add_circled, size: 24),
        ),
        backgroundColor: CupertinoColors.systemGrey6,
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Content
            CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _fetchOrders),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _welcomeCard(),
                      const SizedBox(height: 14),
                      _orderCounts(),
                      const SizedBox(height: 14),
                      _searchCard(),
                      const SizedBox(height: 14),
                      _productCard(),
                      const SizedBox(height: 16),
                      _footer(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),

            // Loading veil
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.black.withOpacity(0.1),
                  child: const Center(child: CupertinoActivityIndicator()),
                ),
              ),

            // Drawer backdrop
            if (_isDrawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _toggleDrawer(false),
                  child: Container(color: CupertinoColors.black.withOpacity(0.25)),
                ),
              ),

            // Drawer panel (animated)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              left: _isDrawerOpen ? 0 : -_drawerWidth,
              child: _cupertinoDrawer(),
            ),
          ],
        ),
      ),
    );
  }
}
