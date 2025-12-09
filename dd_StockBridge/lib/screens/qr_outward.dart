import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QROutwardScreen extends StatelessWidget {
  const QROutwardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Outward'),
        backgroundColor: CupertinoColors.white,
        foregroundColor: CupertinoColors.activeBlue,
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.qrcode_viewfinder,
              size: 80,
              color: CupertinoColors.activeBlue,
            ),
            SizedBox(height: 16),
            Text(
              'QR Scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'QR Outward functionality will be implemented here',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}