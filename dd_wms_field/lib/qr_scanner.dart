// lib/qr_scanner.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class ClubOrderScanScreen extends StatefulWidget {
  final int warehouseId;
  final String warehouseLabel;

  const ClubOrderScanScreen({
    super.key,
    required this.warehouseId,
    required this.warehouseLabel,
  });

  @override
  State<ClubOrderScanScreen> createState() => _ClubOrderScanScreenState();
}

class _ClubOrderScanScreenState extends State<ClubOrderScanScreen> {
  // ===== API Configuration =====
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-field-app';
  static const String appId = '1';
  static const String apiKey = 'd5e61e52-fd9d-4ac9-a953-fde5fe5f6e5e';

  // ===== iOS style colors =====
  final Color _iosBlue = const Color(0xFF007E9B);
  final Color _iosGreen = const Color(0xFF34C759);
  final Color _iosRed = const Color(0xFFFF3B30);

  // ===== Scanner/controller =====
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    torchEnabled: false,
  );

  // Audio
  final AudioPlayer _player = AudioPlayer();

  bool _isBusy = false;
  bool _torchOn = false;
  bool _usingFrontCam = false;

  // ===== Scan window size - perfectly centered =====
  static const double _windowSize = 280.0;
  static final BorderRadius _windowRadius = BorderRadius.circular(20);

  String get _scanKey => 'scan_count_${widget.warehouseId}';

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchOrderFromQR(String qrCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    final url = Uri.parse('$baseUrl/club_orders/pickup_qr_scan').replace(
      queryParameters: {
        'app_id': appId,
        'api_key': apiKey,
        'token': token,
        'qr': qrCode,
      },
    );

    final res = await http.get(url, headers: {'Accept': 'application/json'});

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      json = {};
    }

    return {
      'http': res.statusCode,
      'body': json,
    };
  }

  // ======= SOUND HELPERS =======
  Future<void> _playFor(Duration d, String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      await Future.delayed(d);
      await _player.stop();
    } catch (_) {}
  }

  // ======= UI POPUPS =======

  /// SUCCESS: 1s toast (no buttons) + success.mp3 for 1s
  Future<void> _showSuccessToast(String title, String message) async {
    // Fire sound (no await necessary)
    unawaited(_playFor(const Duration(seconds: 1), 'audio/success.mp3'));

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 90),
          child: _CupertinoToast(
            color: _iosGreen,
            icon: CupertinoIcons.check_mark_circled_solid,
            title: title,
            message: message,
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // auto dismiss
    }
  }

  /// FAILURE: alert.mp3 for 2s + dialog with OK (stays until OK)
  Future<void> _showFailureDialog(String title, String message) async {
    // Start sound; don't block UI
    unawaited(_playFor(const Duration(seconds: 2), 'audio/alert.mp3'));

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: _iosRed, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // NEW: increment per-warehouse scanned count
  Future<void> _incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_scanKey) ?? 0;
    await prefs.setInt(_scanKey, current + 1);
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isBusy) return;

    final String? qr = capture.barcodes.firstOrNull?.rawValue;
    if (qr == null || qr.trim().isEmpty) return;

    setState(() => _isBusy = true);
    await _controller.stop();

    bool success = false;
    String message = 'Invalid or unknown QR code.';

    try {
      final result = await _fetchOrderFromQR(qr);
      final statusCode = result['http'] as int;
      final body = (result['body'] as Map<String, dynamic>?) ?? {};
      final flag = body['status_flag'];

      if (statusCode == 200 && flag == 1) {
        success = true;
        message = 'Order found and fetched successfully.';
        await _incrementScanCount();
      } else {
        message = (body['status_messages'] is List && body['status_messages'].isNotEmpty)
            ? body['status_messages'][0].toString()
            : (body['message']?.toString() ?? message);
      }
    } catch (e) {
      success = false;
      message = 'Something went wrong: $e';
    }

    if (!mounted) return;

    if (success) {
      await _showSuccessToast('Scan Success', message);
    } else {
      await _showFailureDialog('Scan Failed', message);
    }

    if (!mounted) return;
    setState(() => _isBusy = false);
    await _controller.start();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _switchCamera() async {
    await _controller.switchCamera();
    setState(() => _usingFrontCam = !_usingFrontCam);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.back,
            color: _iosBlue,
            size: 28,
          ),
        ),
        title: Text(
          'Pickup QR – ${widget.warehouseLabel}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: _toggleTorch,
            child: Icon(
              _torchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
              color: _torchOn ? Colors.amber : _iosBlue,
              size: 24,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: _switchCamera,
            child: Icon(
              CupertinoIcons.camera_rotate_fill,
              color: _iosBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          // Perfect center positioning for scan window
          final Rect windowRect = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: _windowSize,
            height: _windowSize,
          );

          return Stack(
            children: [
              // Fullscreen camera view
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _handleDetect,
                ),
              ),

              // Transparent background overlay with center hole
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TransparentOverlayPainter(
                      holeRect: windowRect,
                      radius: _windowRadius,
                      overlayColor: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // iOS-style scan window border + corners
              Positioned(
                left: (size.width - _windowSize) / 2,
                top: (size.height - _windowSize) / 2,
                child: IgnorePointer(
                  child: Container(
                    width: _windowSize,
                    height: _windowSize,
                    decoration: BoxDecoration(
                      borderRadius: _windowRadius,
                      border: Border.all(
                        color: _iosBlue.withOpacity(0.9),
                        width: 3,
                      ),
                    ),
                    child: Stack(children: _buildCornerIndicators()),
                  ),
                ),
              ),

              // iOS-style instruction text
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Align QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // Loading overlay
              if (_isBusy)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // iOS-style corner indicators
  List<Widget> _buildCornerIndicators() {
    const double cornerSize = 25.0;
    const double cornerThickness = 4.0;
    final Color cornerColor = _iosBlue.withOpacity(0.8);

    return [
      // Top-right
      Positioned(
        top: 15,
        right: 15,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cornerColor, width: cornerThickness),
              right: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // Top-left
      Positioned(
        top: 15,
        left: 15,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cornerColor, width: cornerThickness),
              left: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 15,
        right: 15,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cornerColor, width: cornerThickness),
              right: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 15,
        left: 15,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cornerColor, width: cornerThickness),
              left: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
    ];
  }
}

// ===== Custom painter for transparent overlay with center hole =====
class _TransparentOverlayPainter extends CustomPainter {
  _TransparentOverlayPainter({
    required this.holeRect,
    required this.radius,
    required this.overlayColor,
  });

  final Rect holeRect;
  final BorderRadius radius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Path outerPath = Path()..addRect(Offset.zero & size);

    final RRect scanWindow = RRect.fromRectAndCorners(
      holeRect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );
    final Path holePath = Path()..addRRect(scanWindow);

    final Path finalPath =
    Path.combine(PathOperation.difference, outerPath, holePath);

    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TransparentOverlayPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.radius != radius ||
        oldDelegate.overlayColor != overlayColor;
  }
}

// ===== Extension for safe list access =====
extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : this[0];
}
// ===== Small Cupertino-style toast widget (used for 1s success popup) =====
class _CupertinoToast extends StatelessWidget {
  const _CupertinoToast({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
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
}
