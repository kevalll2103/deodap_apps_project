import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SecondScanner extends StatefulWidget {
  const SecondScanner({super.key});

  @override
  State<SecondScanner> createState() => _SecondScannerState();
}

class _SecondScannerState extends State<SecondScanner>
    with SingleTickerProviderStateMixin {
  String scannedText = ''; // This will store the scanned QR/barcode text
  String lastScanned = ''; // This will store the last scanned text to avoid duplicates

  final MobileScannerController cameraController = MobileScannerController(
    facing: CameraFacing.back,
  );

  bool isFlashlightOn = false; // Track the state of the flashlight

  late final AudioPlayer _audioPlayer;

  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanLineAnimation =
        CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    cameraController.dispose();
    _scanLineController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Toggle the camera (front/back)
  void _toggleCamera() {
    cameraController.switchCamera();
  }

  // Refresh the scanned text
  void _refreshScan() {
    setState(() {
      scannedText = '';
      lastScanned = '';
    });
  }

  // Toggle the flashlight
  void _toggleFlashlight() {
    setState(() {
      isFlashlightOn = !isFlashlightOn;
      cameraController.toggleTorch();
    });
  }

  // Function to validate the scanned text
  String _validateScannedText(String text) {
    // Check if the scanned text is empty or is a URL
    if (text.isEmpty || text.startsWith(RegExp(r'https?://'))) {
      return 'No order ID available';
    } else {
      return text;
    }
  }

  Future<void> _playSiren() async {
    try {
      // ensure fresh play
      await _audioPlayer.stop();
      // Asset path relative to the `assets/` folder defined in pubspec
      await _audioPlayer.play(AssetSource('mp3/siren.mp3'));
    } catch (e) {
      debugPrint('Error playing siren: $e');
    }
  }

  void _handleDetection(BarcodeCapture barcodeCapture) async {
    if (barcodeCapture.barcodes.isEmpty) return;

    final String code = barcodeCapture.barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    // avoid duplicate processing
    if (code == lastScanned) return;

    final validated = _validateScannedText(code);

    setState(() {
      scannedText = validated;
      lastScanned = code;
    });

    if (validated != 'No order ID available') {
      await _playSiren();
      if (!mounted) return;
      Navigator.pop(context, validated); // Return scanned text
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        elevation: 0.0,
        title: const Text(
          "Barcode Scanner",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back without sending data
          },
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshScan,
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // Scanner with a defined scan window
          LayoutBuilder(
            builder: (context, constraints) {
              final double boxWidth = constraints.maxWidth * 0.7;
              final double boxHeight = constraints.maxWidth * 0.28;

              final Rect scanWindow = Rect.fromCenter(
                center: Offset(
                  constraints.maxWidth / 2,
                  constraints.maxHeight / 2.3,
                ),
                width: boxWidth,
                height: boxHeight,
              );

              return MobileScanner(
                controller: cameraController,
                scanWindow: scanWindow,
                onDetect: _handleDetection,
              );
            },
          ),

          // Overlay with transparent scan area + animated line + hints
          LayoutBuilder(
            builder: (context, constraints) {
              final double boxWidth = constraints.maxWidth * 0.7;
              final double boxHeight = constraints.maxWidth * 0.28;

              final double left = (constraints.maxWidth - boxWidth) / 2;
              final double top = (constraints.maxHeight / 2.3) - (boxHeight / 2);

              return Stack(
                children: [
                  // Dark overlay
                  Container(
                    color: Colors.black.withOpacity(0.45),
                  ),

                  // Clear scan box border
                  Positioned(
                    left: left,
                    top: top,
                    width: boxWidth,
                    height: boxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),

                  // Rounded corner accents
                  Positioned(
                    left: left - 2,
                    top: top - 2,
                    child: _corner(Alignment.topLeft),
                  ),
                  Positioned(
                    right: left - 2,
                    top: top - 2,
                    child: _corner(Alignment.topRight),
                  ),
                  Positioned(
                    left: left - 2,
                    bottom: constraints.maxHeight - (top + boxHeight) - 2,
                    child: _corner(Alignment.bottomLeft),
                  ),
                  Positioned(
                    right: left - 2,
                    bottom: constraints.maxHeight - (top + boxHeight) - 2,
                    child: _corner(Alignment.bottomRight),
                  ),

                  // Animated scanning line
                  Positioned(
                    left: left + 6,
                    right: left + 6,
                    top: top + 6,
                    height: boxHeight - 12,
                    child: AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        final double dy =
                            (_scanLineAnimation.value) * (boxHeight - 24);
                        return Stack(
                          children: [
                            Positioned(
                              top: dy,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.lightGreenAccent.withOpacity(0),
                                      Colors.lightGreenAccent.withOpacity(0.9),
                                      Colors.lightGreenAccent.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Guide text above
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top - 40,
                    child: const Center(
                      child: Text(
                        'Align the barcode within the box',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Display scanned text at bottom (if any)
          if (scannedText.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 90,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  scannedText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Bottom control bar with flashlight and camera toggle
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              height: 60,
              color: Colors.blue[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: _toggleCamera,
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFlashlight,
                    icon: Icon(
                      isFlashlightOn ? Icons.flash_on : Icons.flash_off_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to draw white corner accents
  Widget _corner(Alignment alignment) {
    const double size = 20;
    return Transform.rotate(
      angle: alignment == Alignment.topLeft
          ? 0
          : alignment == Alignment.topRight
              ? math.pi / 2
              : alignment == Alignment.bottomRight
                  ? math.pi
                  : -math.pi / 2,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white, width: 3),
            left: BorderSide(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
