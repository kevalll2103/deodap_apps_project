import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class ClubOrderScanScreen extends StatefulWidget {
  const ClubOrderScanScreen({super.key});

  @override
  State<ClubOrderScanScreen> createState() => _ClubOrderScanScreenState();
}

class _ClubOrderScanScreenState extends State<ClubOrderScanScreen> {
  // ===== API Configuration =====
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-app';
  static const String appId = '1';
  static const String apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  // ===== iOS style colors =====
  final Color _iosBlue = const Color(0xFF007AFF);
  final Color _iosGreen = const Color(0xFF34C759);
  final Color _iosRed = const Color(0xFFFF3B30);
  final Color _iosGray = const Color(0xFF8E8E93);

  // ===== Scanner/controller =====
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    torchEnabled: false,
  );

  bool _isBusy = false;
  bool _torchOn = false;
  bool _usingFrontCam = false;

  // ===== Audio =====
  final AudioPlayer _player = AudioPlayer();

  // ===== Scan window size - perfectly centered =====
  static const double _windowSize = 280.0;
  static final BorderRadius _windowRadius = BorderRadius.circular(20);

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playOnce(String assetPath, Duration minDuration) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      await Future.delayed(minDuration);
      await _player.stop();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _fetchOrderFromQR(String qrCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    final url = Uri.parse('$baseUrl/club_orders/inward_qr_scan').replace(
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

  Future<void> _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) async {
    final Color color = success ? _iosGreen : _iosRed;
    final IconData icon = success
        ? CupertinoIcons.check_mark_circled_solid
        : CupertinoIcons.exclamationmark_triangle_fill;

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            message,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: _iosBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isBusy) return;

    final String? qr = capture.barcodes.firstOrNull?.rawValue;
    if (qr == null || qr.trim().isEmpty) return;

    setState(() => _isBusy = true);
    await _controller.stop();

    bool success = false;
    String title = 'Scan Failed';
    String message = 'Invalid or unknown QR code.';

    try {
      final result = await _fetchOrderFromQR(qr);
      final statusCode = result['http'] as int;
      final body = (result['body'] as Map<String, dynamic>?) ?? {};
      final flag = body['status_flag'];

      if (statusCode == 200 && flag == 1) {
        success = true;
        title = 'Order Scanned';
        message = 'Order found and fetched successfully.';
      } else {
        final msg = (body['status_messages'] is List && body['status_messages'].isNotEmpty)
            ? body['status_messages'][0].toString()
            : (body['message']?.toString() ?? 'Order not found or invalid QR.');
        success = false;
        title = 'Scan Failed';
        message = msg;
      }
    } catch (e) {
      success = false;
      title = 'Scan Error';
      message = 'Something went wrong: $e';
    }

    if (success) {
      await _playOnce('assets/success.mp3', const Duration(milliseconds: 900));
    } else {
      await _playOnce('assets/siren.mp3', const Duration(seconds: 3));
    }

    if (!mounted) return;

    await _showResultDialog(success: success, title: title, message: message);

    if (mounted) {
      setState(() => _isBusy = false);
      await _controller.start();
    }
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
          'Inward QR Scan',
          style: TextStyle(
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

              // iOS-style scan window border
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
                    child: Stack(
                      children: [
                        // Corner indicators (iOS style)
                        ..._buildCornerIndicators(),
                      ],
                    ),
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
                    child: Text(
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

              // Loading indicator
              if (_isBusy)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 16,
                      color: Colors.white,
                    ),
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
      // Top-left corner
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
      // Top-right corner
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
      // Bottom-left corner
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
      // Bottom-right corner
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
    // Create the full screen path
    final Path outerPath = Path()..addRect(Offset.zero & size);

    // Create the hole (scan window) path
    final RRect scanWindow = RRect.fromRectAndCorners(
      holeRect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );
    final Path holePath = Path()..addRRect(scanWindow);

    // Subtract the hole from the full screen to create transparent center
    final Path finalPath = Path.combine(PathOperation.difference, outerPath, holePath);

    // Paint the overlay with transparent center
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
