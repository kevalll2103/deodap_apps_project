import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class SecondQrcodescannerScreen extends StatefulWidget {
  const SecondQrcodescannerScreen({super.key});

  @override
  State<SecondQrcodescannerScreen> createState() => _SecondQrcodescannerScreenState();
}

class _SecondQrcodescannerScreenState extends State<SecondQrcodescannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  MobileScannerController? cameraController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  bool isFrontCamera = false;
  bool isFlashlightOn = false;
  bool isScanning = false;
  bool isInitialized = false;
  bool hasDetected = false;
  bool isProcessing = false;

  String scannedText = '';
  String lastScanned = '';
  DateTime lastScanTime = DateTime.now().subtract(const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Scanning line animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.15,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for scanning area
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeScanner() async {
    try {
      cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        useNewCameraSelector: true,
      );

      // Wait for camera initialization
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        _showSnackBar('Camera initialization failed. Please check permissions.', isError: true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!isInitialized || cameraController == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startCamera();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopCamera();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _startCamera() async {
    try {
      if (cameraController != null && mounted) {
        await cameraController!.start();
        if (!hasDetected) {
          _animationController.repeat(reverse: true);
          _pulseController.repeat(reverse: true);
        }
      }
    } catch (e) {
      debugPrint('Error starting camera: $e');
    }
  }

  Future<void> _stopCamera() async {
    try {
      if (cameraController != null) {
        await cameraController!.stop();
        _animationController.stop();
        _pulseController.stop();
      }
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pulseController.dispose();
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
    if (!isInitialized || cameraController == null || isProcessing || hasDetected) return;

    try {
      setState(() => isScanning = true);

      await cameraController!.switchCamera();
      setState(() {
        isFrontCamera = !isFrontCamera;
        // Turn off flashlight when switching to front camera
        if (isFrontCamera && isFlashlightOn) {
          isFlashlightOn = false;
        }
      });

      HapticFeedback.lightImpact();

    } catch (e) {
      debugPrint('Error switching camera: $e');
      _showSnackBar('Failed to switch camera', isError: true);
    } finally {
      setState(() => isScanning = false);
    }
  }

  Future<void> _toggleFlashlight() async {
    if (!isInitialized || cameraController == null || isFrontCamera || isProcessing || hasDetected) {
      if (isFrontCamera) {
        _showSnackBar('Flashlight not available with front camera', isError: true);
      }
      return;
    }

    try {
      await cameraController!.toggleTorch();
      setState(() {
        isFlashlightOn = !isFlashlightOn;
      });

      HapticFeedback.lightImpact();

    } catch (e) {
      debugPrint('Error toggling flashlight: $e');
      _showSnackBar('Failed to toggle flashlight', isError: true);
    }
  }

  void _refreshScan() {
    if (hasDetected || isProcessing) return;

    setState(() {
      scannedText = '';
      lastScanned = '';
      hasDetected = false;
      isProcessing = false;
      lastScanTime = DateTime.now().subtract(const Duration(seconds: 3));
    });

    // Restart animations
    if (isInitialized) {
      _animationController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }

    HapticFeedback.lightImpact();
  }

  String _validateScannedText(String text) {
    if (text.isEmpty) {
      return 'No data found';
    }

    // Clean and trim the text
    text = text.trim();

    // Handle different types of QR codes
    if (text.startsWith(RegExp(r'https?://'))) {
      // Extract useful info from URLs if needed
      try {
        Uri uri = Uri.parse(text);
        // You can extract parameters or return the full URL
        return text;
      } catch (e) {
        return text; // Return as is if URL parsing fails
      }
    }

    // For other types of data, return as is
    return text;
  }

  void _handleBarcodeDetection(BarcodeCapture barcodeCapture) {
    if (!mounted || hasDetected || isProcessing || barcodeCapture.barcodes.isEmpty) {
      return;
    }

    try {
      final now = DateTime.now();
      // Prevent duplicate scans within 1.5 seconds
      if (now.difference(lastScanTime).inMilliseconds < 1500) {
        return;
      }

      lastScanTime = now;

      final String code = barcodeCapture.barcodes.first.rawValue ?? '';
      if (code.isEmpty || code == lastScanned) return;

      // Stop animations
      _animationController.stop();
      _pulseController.stop();

      setState(() {
        isProcessing = true;
        scannedText = _validateScannedText(code);
        lastScanned = code;
      });

      // Provide strong haptic feedback for successful scan
      HapticFeedback.mediumImpact();

      // Show success animation/feedback
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            hasDetected = true;
            isProcessing = false;
          });

          // Auto-return result after showing it briefly
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted && hasDetected) {
              Navigator.pop(context, scannedText);
            }
          });
        }
      });

    } catch (e) {
      debugPrint('Error during barcode detection: $e');
      if (mounted) {
        _showSnackBar('Error processing QR code', isError: true);
        setState(() {
          isProcessing = false;
          hasDetected = false;
        });

        // Restart animations on error
        _animationController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 3 : 2),
        margin: const EdgeInsets.all(16),
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
        "BarCode Scanner",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Go Back',
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: hasDetected || isProcessing ? Colors.white54 : Colors.white,
          ),
          onPressed: hasDetected || isProcessing ? null : _refreshScan,
          tooltip: 'Refresh Scanner',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (!isInitialized) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        // Camera view with error handling
        _buildCameraView(),

        // Scanning overlay with animations
        _buildScanningOverlay(),

        // Result display
        if (scannedText.isNotEmpty) _buildResultDisplay(),

        // Control buttons
        if (!hasDetected && !isProcessing) _buildControlButtons(),

        // Processing overlay
        if (isProcessing) _buildProcessingOverlay(),

        // Success overlay
        if (hasDetected) _buildSuccessOverlay(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0B90A1),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return MobileScanner(
      controller: cameraController!,
      onDetect: _handleBarcodeDetection,
      errorBuilder: (context, error, child) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Camera Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check camera permissions\nand try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B90A1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: const Color(0xFF0B90A1),
              borderRadius: 16,
              borderLength: 32,
              borderWidth: 4,
              cutOutSize: 280 * _pulseAnimation.value,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // Scanning line
                  Positioned(
                    top: 280 * _scanAnimation.value - 1,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0B90A1),
                            const Color(0xFF0B90A1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B90A1).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Center instruction
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Point camera at QR code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultDisplay() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: hasDetected ? 140 : 180,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDetected
              ? Colors.green.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
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
                  hasDetected ? Icons.check_circle : Icons.qr_code_scanner,
                  color: hasDetected ? Colors.white : const Color(0xFF0B90A1),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  hasDetected ? 'Scan Successful!' : 'Scanned Result:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasDetected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasDetected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasDetected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                scannedText,
                style: TextStyle(
                  fontSize: 15,
                  color: hasDetected ? Colors.white : const Color(0xFF0B90A1),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDetected) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Returning result...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
        height: 90,
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
              label: 'Switch',
              onPressed: isScanning ? null : _toggleCamera,
              isLoading: isScanning,
            ),
            _buildControlButton(
              icon: isFlashlightOn ? Icons.flash_on : Icons.flash_off,
              label: 'Flash',
              onPressed: isFrontCamera ? null : _toggleFlashlight,
              isDisabled: isFrontCamera,
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
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final isEnabled = onPressed != null && !isDisabled;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF0B90A1).withOpacity(0.15)
                : Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF0B90A1).withOpacity(0.8)
                  : Colors.grey.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
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
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF0B90A1),
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Processing QR Code...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'QR Code Detected!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Returning to previous screen...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusing the same custom overlay shape from the first scanner
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
    final height = rect.height;
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