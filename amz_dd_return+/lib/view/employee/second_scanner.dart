import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SecondScanner extends StatefulWidget {
  const SecondScanner({super.key});

  @override
  State<SecondScanner> createState() => _SecondScannerState();
}

class _SecondScannerState extends State<SecondScanner> {

  bool isFrontCamera = false; // Track whether the front camera is in use
  // Toggle the camera (front/back)
  void _toggleCamera() {
    cameraController.switchCamera(); // Switch between front and back camera
    setState(() {
      isFrontCamera = !isFrontCamera; // Update the camera state
    });
  }



  String scannedText = ''; // This will store the scanned QR code text
  String lastScanned = ''; // This will store the last scanned QR code to avoid duplicates
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashlightOn = false; // Track the state of the flashlight

  // Function to refresh the scanned text
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
      cameraController.toggleTorch(); // Toggle the flashlight on/off
    });
  }




  // Function to validate the scanned text
  String _validateScannedText(String text) {
    // Check if the scanned text is empty or is a URL
    if (text.isEmpty || text.startsWith(RegExp(r'https?://'))) {
      return 'No order ID available'; // Return message for empty text or URL
    } else {
      return text; // Otherwise, return the scanned text
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        elevation: 0.0,
        title: Text(
          "Barcode Scanner",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back without sending data if nothing is scanned
          },
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshScan,
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // Full screen camera view
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture barcodeCapture) {
              final String code = barcodeCapture.barcodes.first.rawValue ?? '';
              if (code != lastScanned) {
                setState(() {
                  scannedText = _validateScannedText(code);
                  lastScanned = code;

                  // If the scanned text is valid, pop the scanner screen and return the order ID
                  if (scannedText != 'No order ID available') {
                    Navigator.pop(context, scannedText); // Return the scanned text
                  }
                });
              }
            },
          ),

          // Display scanned text below the scanner
          if (scannedText.isNotEmpty)
            Positioned(
              left: 70,
              right: 70,
              bottom: 70,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        scannedText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
              height: 55,
              color: Colors.blue[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: _toggleCamera,
                    icon: Icon(
                      isFrontCamera
                          ? Icons.cameraswitch_outlined // Front camera icon
                          : Icons.cameraswitch, // Back camera icon
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFlashlight,
                    icon: Icon(
                      isFlashlightOn ? Icons.flash_on : Icons.flash_off_outlined,
                      color: Colors.white,
                      size: 35,
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
}
