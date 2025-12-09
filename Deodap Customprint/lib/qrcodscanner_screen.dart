import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class QrcodscannerScreen extends StatefulWidget {
  const QrcodscannerScreen({super.key});

  @override
  State<QrcodscannerScreen> createState() => _QrcodscannerScreenState();
}

class _QrcodscannerScreenState extends State<QrcodscannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  MobileScannerController? cameraController;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool isFrontCamera = false;
  bool isFlashlightOn = false;
  bool isScanning = false;
  bool isInitialized = false;
  bool hasDetected = false;

  String scannedText = '';
  String lastScanned = '';
  DateTime lastScanTime = DateTime.now().subtract(const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  Future<void> _initializeScanner() async {
    try {
      cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      // Wait a bit for camera to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to initialize camera. Please check permissions.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!isInitialized || cameraController == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startScanner();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopScanner();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _startScanner() async {
    try {
      if (cameraController != null && mounted) {
        await cameraController!.start();
      }
    } catch (e) {
      debugPrint('Error starting scanner: $e');
    }
  }

  Future<void> _stopScanner() async {
    try {
      if (cameraController != null) {
        await cameraController!.stop();
      }
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    try {
      await cameraController?.dispose();
      cameraController = null;
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (!isInitialized || cameraController == null || isScanning) return;

    try {
      await cameraController!.switchCamera();
      setState(() {
        isFrontCamera = !isFrontCamera;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error switching camera: $e');
      _showErrorSnackBar('Failed to switch camera');
    }
  }

  Future<void> _toggleFlashlight() async {
    if (!isInitialized || cameraController == null || isFrontCamera) return;

    try {
      await cameraController!.toggleTorch();
      setState(() {
        isFlashlightOn = !isFlashlightOn;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error toggling flashlight: $e');
      _showErrorSnackBar('Failed to toggle flashlight');
    }
  }

  void _refreshScan() {
    if (hasDetected) return;

    setState(() {
      scannedText = '';
      lastScanned = '';
      hasDetected = false;
      lastScanTime = DateTime.now().subtract(const Duration(seconds: 3));
    });

    HapticFeedback.lightImpact();
  }

  String _validateAndProcessScannedText(String text) {
    if (text.isEmpty) {
      return 'No data found';
    }

    // Clean the text
    text = text.trim();

    // If it's a URL, extract relevant parts or return as is
    if (text.startsWith(RegExp(r'https?://'))) {
      // You can process URLs here if needed
      return text;
    }

    // Return the scanned text as is
    return text;
  }

  void _handleBarcodeDetection(BarcodeCapture barcodeCapture) {
    if (!mounted || hasDetected || isScanning || barcodeCapture.barcodes.isEmpty) {
      return;
    }

    try {
      final now = DateTime.now();
      if (now.difference(lastScanTime).inMilliseconds < 1000) {
        return; // Prevent rapid duplicate scans
      }

      lastScanTime = now;

      final String code = barcodeCapture.barcodes.first.rawValue ?? '';
      if (code.isEmpty || code == lastScanned) return;

      setState(() {
        isScanning = true;
        hasDetected = true;
        scannedText = _validateAndProcessScannedText(code);
        lastScanned = code;
      });

      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Auto-close after successful scan
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && hasDetected) {
          Navigator.pop(context, scannedText);
        }
      });

    } catch (e) {
      debugPrint('Error during barcode detection: $e');
      if (mounted) {
        _showErrorSnackBar('Error processing QR code');
        setState(() {
          isScanning = false;
          hasDetected = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0B90A1),
      centerTitle: true,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text(
        "QR Code Scanner",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: hasDetected ? null : _refreshScan,
          tooltip: 'Refresh Scanner',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (!isInitialized || cameraController == null) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        // Camera view
        _buildCameraView(),

        // Scanning overlay
        _buildScanningOverlay(),

        // Scanned result display
        if (scannedText.isNotEmpty) _buildResultDisplay(),

        // Control buttons
        if (!hasDetected) _buildControlButtons(),

        // Loading overlay when processing
        if (isScanning) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF0B90A1),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Initializing Camera...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return ClipRect(
      child: MobileScanner(
        controller: cameraController!,
        onDetect: _handleBarcodeDetection,
        errorBuilder: (context, error, child) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check camera permissions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: const Color(0xFF0B90A1),
          borderRadius: 12,
          borderLength: 30,
          borderWidth: 4,
          cutOutSize: 250,
        ),
      ),
      child: AnimatedBuilder(
        animation: _scanAnimation,
        builder: (context, child) {
          return Container(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Positioned(
                    top: _scanAnimation.value * 200,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0B90A1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: hasDetected ? 120 : 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: const Color(0xFF0B90A1),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Scanned Result:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                scannedText,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF0B90A1),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasDetected) ...[
              const SizedBox(height: 12),
              Text(
                'Returning result...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: isFrontCamera ? Icons.camera_rear : Icons.camera_front,
              label: 'Camera',
              onPressed: _toggleCamera,
            ),
            _buildControlButton(
              icon: isFlashlightOn ? Icons.flash_on : Icons.flash_off,
              label: 'Flash',
              onPressed: isFrontCamera ? null : _toggleFlashlight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF0B90A1).withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF0B90A1)
                  : Colors.grey,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey,
              size: 24,
            ),
            iconSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0B90A1),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Processing QR Code...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path outerPath = Path()..addRect(rect);
    Path innerPath = Path();

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    innerPath.addRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
    );

    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final borderOffset = borderWidth / 2;
    final borderRadius2 = borderRadius + borderOffset;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutWidth,
      height: cutOutHeight,
    );

    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(0),
    );
    final innerRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius2),
    );

    final outerPath = Path()..addRRect(outerRRect);
    final innerPath = Path()..addRRect(innerRRect);

    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      Paint()
        ..color = overlayColor
        ..style = PaintingStyle.fill,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw corner borders
    final left = cutOutRect.left;
    final top = cutOutRect.top;
    final right = cutOutRect.right;
    final bottom = cutOutRect.bottom;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderRadius2 + borderLength)
        ..lineTo(left, top + borderRadius2)
        ..arcToPoint(Offset(left + borderRadius2, top),
            radius: Radius.circular(borderRadius2), clockwise: false)
        ..lineTo(left + borderRadius2 + borderLength, top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength - borderRadius2, top)
        ..lineTo(right - borderRadius2, top)
        ..arcToPoint(Offset(right, top + borderRadius2),
            radius: Radius.circular(borderRadius2), clockwise: false)
        ..lineTo(right, top + borderRadius2 + borderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - borderRadius2 - borderLength)
        ..lineTo(left, bottom - borderRadius2)
        ..arcToPoint(Offset(left + borderRadius2, bottom),
            radius: Radius.circular(borderRadius2), clockwise: false)
        ..lineTo(left + borderRadius2 + borderLength, bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength - borderRadius2, bottom)
        ..lineTo(right - borderRadius2, bottom)
        ..arcToPoint(Offset(right, bottom - borderRadius2),
            radius: Radius.circular(borderRadius2), clockwise: false)
        ..lineTo(right, bottom - borderRadius2 - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}