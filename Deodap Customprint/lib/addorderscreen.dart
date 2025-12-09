import 'package:Deodap_Customprint/qrcodscanner_screen.dart';
import 'package:Deodap_Customprint/showfullscreenimage_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // kept for some helpers & 3P packages
import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ImageData {
  final Uint8List bytes;
  final String fileName;

  ImageData({required this.bytes, required this.fileName});
}

class Addorderscreen extends StatefulWidget {
  const Addorderscreen({super.key});

  @override
  State<Addorderscreen> createState() => _AddorderscreenState();
}

class _AddorderscreenState extends State<Addorderscreen>
    with TickerProviderStateMixin {
  String userId = '';
  ImageData? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNodeOrderName = FocusNode();

  final TextEditingController orderIdController = TextEditingController();
  final TextEditingController orderNameController = TextEditingController();

  bool _isLoading = false;
  bool _isCameraLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoCloseTimer;

  OverlayEntry? _toast; // Cupertino-style toast

  // THEME: Cupertino colors
  static const _brand = Color(0xFF0B90A1);
  static const _bg = CupertinoColors.systemGroupedBackground;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeAnimations();
    _setupTextControllerListeners();
  }

  void _initializeAnimations() {
    _pulseController =
        AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _pulseAnimation =
        Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);

    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  void _setupTextControllerListeners() {
    orderIdController.addListener(() => setState(() {}));
    orderNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _focusNode.dispose();
    _focusNodeOrderName.dispose();
    orderIdController.dispose();
    orderNameController.dispose();
    _autoCloseTimer?.cancel();
    _removeToast();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) {
        _showErrorDialog('User ID Error', 'User ID not found. Please login again.');
      }
    } catch (_) {
      _showErrorDialog('Storage Error', 'Failed to load user data. Please restart the app.');
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  // ---------- Camera ----------
  Future<void> _captureImage() async {
    setState(() => _isCameraLoading = true);
    _showToast('Opening camera…', isLoading: true);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        final image = File(pickedFile.path);
        final bytes = await image.readAsBytes();

        if (bytes.length > 10 * 1024 * 1024) {
          throw Exception('Image too large. Please capture ≤ 10MB.');
        }

        if (mounted) {
          setState(() {
            _selectedImage = ImageData(bytes: bytes, fileName: path.basename(image.path));
          });
          _showToast('Image captured ✅');
        }
      } else {
        _showToast('Cancelled');
      }
    } catch (e) {
      String msg = 'Failed to capture image';
      final s = e.toString().toLowerCase();
      if (s.contains('permission') || s.contains('denied')) {
        msg = 'Camera permission denied. Enable it in Settings.';
      } else if (s.contains('no_available_camera')) {
        msg = 'No camera available on this device.';
      } else if (s.contains('image too large')) {
        msg = 'Image too large. Please capture ≤ 10MB.';
      }
      _showToast(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isCameraLoading = false);
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
    _showToast('Image removed');
  }

  void _clearName() {
    orderNameController.clear();
    _focusNodeOrderName.unfocus();
  }

  void _clearID() {
    orderIdController.clear();
    _focusNode.unfocus();
  }

  void _clearAllFields() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear All Fields'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('Are you sure you want to clear all fields and the image?'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                orderIdController.clear();
                orderNameController.clear();
                _selectedImage = null;
                _focusNode.unfocus();
                _focusNodeOrderName.unfocus();
              });
              _showToast('Cleared ✨');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // ---------- Upload ----------
  Future<void> _addProduct() async {
    FocusScope.of(context).unfocus();

    try {
      final orderId = orderIdController.text.trim();
      final orderName = orderNameController.text.trim();

      if (orderId.isEmpty) {
        _showErrorDialog('Validation Error', 'Please enter Order ID.');
        return;
      }
      if (_selectedImage == null) {
        _showErrorDialog('Validation Error', 'Please capture an image.');
        return;
      }
      if (userId.isEmpty) {
        _showErrorDialog('Authentication Error', 'User ID not found. Please login again.');
        return;
      }
      if (!await _checkConnectivity()) {
        _showErrorDialog('Connection Error', 'No internet connection.');
        return;
      }

      setState(() => _isLoading = true);
      final overlay = _showSimpleLoadingOverlay();

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://customprint.deodap.com/api_customprint/add_new_order_mail.php'),
        );

        request.headers.addAll({
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        });

        request.fields['product_unique_id'] = orderId;
        request.fields['product_name'] = orderName.isEmpty ? 'N/A' : orderName;
        request.fields['user_id'] = userId;
        request.fields['image_count'] = '1';

        String contentType = 'image/jpeg';
        final lower = _selectedImage!.fileName.toLowerCase();
        if (lower.endsWith('.png')) contentType = 'image/png';

        request.files.add(http.MultipartFile.fromBytes(
          'product_image',
          _selectedImage!.bytes,
          filename: _selectedImage!.fileName,
          contentType: MediaType.parse(contentType),
        ));

        final response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Upload timeout. Check your connection and retry.'),
        );

        if (overlay.mounted) overlay.remove();

        if (response.statusCode == 200) {
          final body = await response.stream.bytesToString();

          try {
            final Map<String, dynamic> data = json.decode(body);
            if (data.containsKey('error')) {
              final err = (data['error'] ?? 'Unknown error').toString();
              if (err.toLowerCase().contains('already exists') ||
                  err.toLowerCase().contains('duplicate')) {
                _showProductExistsDialog(orderId);
                return;
              } else {
                throw Exception(err);
              }
            }
            if (data.containsKey('message')) {
              final msg = (data['message'] ?? '').toString().toLowerCase();
              if (msg.contains('already exists') || msg.contains('duplicate')) {
                _showProductExistsDialog(orderId);
                return;
              }
            }
            _showAutoCloseSuccessDialog();
          } catch (_) {
            final s = body.toLowerCase();
            if (s.contains('already exists') || s.contains('duplicate')) {
              _showProductExistsDialog(orderId);
              return;
            }
            _showAutoCloseSuccessDialog();
          }
        } else if (response.statusCode == 400) {
          throw Exception('Bad request. Please check your data and try again.');
        } else if (response.statusCode == 401) {
          throw Exception('Authentication failed. Please login again.');
        } else if (response.statusCode == 403) {
          throw Exception('Access denied. Please contact support.');
        } else if (response.statusCode == 404) {
          throw Exception('Server endpoint not found. Please contact support.');
        } else if (response.statusCode == 413) {
          throw Exception('File too large. Please select a smaller image.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Upload failed with status code: ${response.statusCode}');
        }
      } catch (e) {
        if (overlay.mounted) overlay.remove();
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Upload failed. Please try again.';
      final s = e.toString();
      if (s.contains('timeout')) {
        msg = 'Upload timeout. Check internet and retry.';
      } else if (s.contains('SocketException')) {
        msg = 'Network error. Check your internet.';
      } else if (s.contains('HandshakeException')) {
        msg = 'SSL connection error. Try again.';
      } else if (s.toLowerCase().contains('already exists')) {
        _showProductExistsDialog(orderIdController.text.trim());
        return;
      } else if (s.contains('Exception: ')) {
        msg = s.replaceAll('Exception: ', '');
      }
      _showErrorDialog('Upload Failed', msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- Overlays / Dialogs ----------
  OverlayEntry _showSimpleLoadingOverlay() {
    final entry = OverlayEntry(
      builder: (_) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CupertinoActivityIndicator(radius: 16),
                SizedBox(height: 12),
                Text('Uploading Image…', style: TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                SizedBox(height: 4),
                Text(
                  'Please wait, this will only take a moment',
                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  void _showAutoCloseSuccessDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Success 🎉', style: TextStyle(decoration: TextDecoration.none)),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Order uploaded successfully! You’ll receive a confirmation email shortly.\n\nAuto closing in 3 seconds…',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              _autoCloseTimer?.cancel();
              Navigator.pop(ctx);
              _resetForNewOrder();
            },
            child: const Text('Add Another Order', style: TextStyle(decoration: TextDecoration.none)),
          ),
        ],
      ),
    );

    _autoCloseTimer = Timer(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        _resetForNewOrder();
      }
    });
  }

  void _resetForNewOrder() {
    setState(() {
      orderIdController.clear();
      orderNameController.clear();
      _selectedImage = null;
      _focusNode.unfocus();
      _focusNodeOrderName.unfocus();
    });
    _showToast('Ready for next order 🚀');
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title, style: const TextStyle(decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: const TextStyle(decoration: TextDecoration.none)),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  void _showProductExistsDialog(String orderId) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Order ID Already Exists', style: TextStyle(decoration: TextDecoration.none)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'The Order ID "$orderId" already exists in the system.\n\nUse a different Order ID or check if this order was already uploaded.',
            style: const TextStyle(decoration: TextDecoration.none),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              _focusNode.requestFocus();
              orderIdController.selection =
                  TextSelection(baseOffset: 0, extentOffset: orderIdController.text.length);
            },
            child: const Text('Edit Order ID', style: TextStyle(decoration: TextDecoration.none)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              orderIdController.clear();
              _focusNode.requestFocus();
            },
            child: const Text('Clear & Retry', style: TextStyle(decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  // ---------- Cupertino Toast ----------
  void _showToast(String message, {bool isError = false, bool isLoading = false}) {
    _removeToast();

    _toast = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 32,
        child: CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (isError
                  ? CupertinoColors.systemRed
                  : isLoading
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.label)
                  .withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: CupertinoActivityIndicator(),
                  ),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_toast!);

    Future.delayed(Duration(milliseconds: isLoading ? 900 : 2000), _removeToast);
  }

  void _removeToast() {
    _toast?.remove();
    _toast = null;
  }

  // ---------- Share ----------
  void _shareProductData() async {
    FocusScope.of(context).unfocus();

    final String orderId = orderIdController.text.trim();
    final String orderName = orderNameController.text.trim();

    if (_selectedImage != null && orderId.isNotEmpty) {
      try {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/shared_${_selectedImage!.fileName}');
        await tempFile.writeAsBytes(_selectedImage!.bytes);

        String textToShare = 'Order ID: $orderId';
        if (orderName.isNotEmpty) textToShare += '\nName: $orderName';

        await Share.shareXFiles([XFile(tempFile.path)], text: textToShare);
      } catch (_) {
        _showToast('Failed to share. Please try again.', isError: true);
      }
    } else {
      _showToast('Please add an image and Order ID to share.', isError: true);
    }
  }

  // ---------- Widgets ----------
  Widget _sectionHeader(String title, {bool required = false, bool captured = false}) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            )),
        if (required)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _chip('Required', CupertinoColors.systemRed),
          ),
        if (captured)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _chip('✓ Captured', CupertinoColors.activeGreen),
          ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
      BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.9),
            decoration: TextDecoration.none,
          )),
    );
  }

  Widget _cupertinoField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      placeholder: placeholder,
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, decoration: TextDecoration.none),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
      cursorColor: _brand,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
      ),
      suffix: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 6.0), child: suffix),
    );
  }

  Widget _buildCameraPrompt() {
    return GestureDetector(
      onTap: _isCameraLoading ? null : _captureImage,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        padding: const EdgeInsets.all(4),
        color: _isCameraLoading ? CupertinoColors.systemGrey : _brand,
        strokeWidth: 2.5,
        dashPattern: const [10, 6],
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            height: 300,
            width: double.infinity,
            child: Center(
              child: _isCameraLoading
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CupertinoActivityIndicator(radius: 14),
                  SizedBox(height: 12),
                  Text('Opening Camera…',
                      style: TextStyle(
                          color: _brand, fontWeight: FontWeight.w700, fontSize: 16, decoration: TextDecoration.none)),
                ],
              )
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _brand.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(56),
                          border: Border.all(color: _brand.withOpacity(0.25), width: 2),
                        ),
                        child: const Icon(CupertinoIcons.camera_fill, size: 46, color: _brand),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Tap to Capture Image',
                      style: TextStyle(
                          color: _brand, fontWeight: FontWeight.w800, fontSize: 20, decoration: TextDecoration.none)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: CupertinoColors.activeGreen.withOpacity(0.3)),
                    ),
                    child: const Text('One perfect shot is all you need ✨',
                        style: TextStyle(
                            color: CupertinoColors.activeGreen, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(CupertinoIcons.camera, color: _brand, size: 18),
                const SizedBox(width: 8),
                const Text('Captured Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                const Spacer(),
                _chip('✓ Ready', CupertinoColors.activeGreen),
              ],
            ),
          ),

          // Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => ShowfullscreenimageScreen(
                          imageBytes: _selectedImage!.bytes,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImage!.bytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),

                // Actions
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _roundIconButton(
                        icon: CupertinoIcons.camera_fill,
                        color: _brand,
                        onTap: _captureImage,
                      ),
                      const SizedBox(width: 8),
                      _roundIconButton(
                        icon: CupertinoIcons.xmark,
                        color: CupertinoColors.destructiveRed,
                        onTap: _removeImage,
                      ),
                    ],
                  ),
                ),

                // Hint
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Tap to view full screen 👁️',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 11, decoration: TextDecoration.none)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // TRUE Cupertino-style circular icon button (no underline ever)
  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: CupertinoColors.white, size: 18),
        ),
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 8),
            decoration:
            BoxDecoration(color: CupertinoColors.activeBlue, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: CupertinoColors.activeBlue, decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Order', style: TextStyle(decoration: TextDecoration.none)),
        backgroundColor: CupertinoColors.systemGrey6.withOpacity(0.9),
        previousPageTitle: 'Back',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _clearAllFields,
              child: const Icon(CupertinoIcons.refresh_thick, size: 22),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _shareProductData,
              child: const Icon(CupertinoIcons.share, size: 22),
            ),
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: DefaultTextStyle.merge( // <- removes any accidental underlines globally
          style: const TextStyle(decoration: TextDecoration.none),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
                      ),
                      child: Row(
                        children: const [
                          Icon(CupertinoIcons.info, color: _brand, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complete all required fields to upload your order',
                              style: TextStyle(
                                  color: _brand, fontWeight: FontWeight.w600, fontSize: 14, decoration: TextDecoration.none),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                // Image Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Product Image',
                            required: true, captured: _selectedImage != null),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _selectedImage == null
                              ? _buildCameraPrompt()
                              : _buildImagePreview(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Order ID
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Order ID', required: true),
                        const SizedBox(height: 8),
                        _cupertinoField(
                          controller: orderIdController,
                          focusNode: _focusNode,
                          placeholder: 'Enter order id',
                          suffix: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (orderIdController.text.isNotEmpty)
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  onPressed: _clearID,
                                  child: const Icon(CupertinoIcons.clear_circled_solid,
                                      color: CupertinoColors.systemGrey, size: 20),
                                ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                onPressed: () async {
                                  _focusNode.unfocus();
                                  _focusNodeOrderName.unfocus();
                                  try {
                                    final scanned = await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (_) => QrcodscannerScreen()),
                                    );
                                    if (scanned != null && scanned != 'No order ID available') {
                                      orderIdController.text = scanned;
                                      _showToast('QR scanned ✅');
                                    }
                                  } catch (_) {
                                    _showToast('Failed to scan QR.', isError: true);
                                  }
                                },
                                child: const Icon(CupertinoIcons.qrcode_viewfinder,
                                    color: _brand, size: 24),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Order Name
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Order Name'),
                        const SizedBox(height: 8),
                        _cupertinoField(
                          controller: orderNameController,
                          focusNode: _focusNodeOrderName,
                          placeholder: 'Enter order name (optional)',
                          suffix: orderNameController.text.isNotEmpty
                              ? CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            onPressed: _clearName,
                            child: const Icon(CupertinoIcons.clear_circled_solid,
                                color: CupertinoColors.systemGrey, size: 20),
                          )
                              : const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(CupertinoIcons.pencil,
                                color: CupertinoColors.systemGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Upload Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: CupertinoButton.filled(
                        onPressed: _isLoading ? null : _addProduct,
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CupertinoActivityIndicator(),
                            SizedBox(width: 12),
                            Text('Uploading Image…',
                                style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                          ],
                        )
                            : const Text('🚀 Upload Order',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
                      ),
                    ),
                  ),
                ),

                // Tips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: CupertinoColors.systemBlue.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [
                            Icon(CupertinoIcons.lightbulb, color: CupertinoColors.activeBlue, size: 18),
                            SizedBox(width: 8),
                            Text('Quick Tips',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.activeBlue,
                                    decoration: TextDecoration.none)),
                          ]),
                          const SizedBox(height: 8),
                          _tip('📸 One perfect image is all you need'),
                          _tip('🔄 Retake anytime for better quality'),
                          _tip('📱 Use QR scanner for quick Order ID input'),
                          _tip('⚡ Fast single image upload'),
                          _tip('🔄 Auto-clear after successful upload'),
                          _tip('📧 Email confirmation sent after upload'),
                        ],
                      ),
                    ),
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
