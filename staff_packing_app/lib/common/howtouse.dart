import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFF2F2F7); // iOS-style light grey
    final Color cardBorder = Colors.grey.shade200;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ===== iOS-style curved header =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: back + title
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 32,
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CupertinoIcons.back,
                            color: Colors.grey.shade800,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'How the App Works',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 46), // to balance back button width
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Step-by-step guide for warehouse staff to use the app correctly.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ===== Body =====
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding:
                          const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How the App Works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Follow these steps for every order you process in the warehouse.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 1. Login & Warehouse Selection
                          _stepHeader(
                            icon: CupertinoIcons.person_crop_circle,
                            title: 'Login & Warehouse Selection',
                          ),
                          const SizedBox(height: 4),
                          _bullet(
                            'Enter your staff ID and password to sign in.',
                          ),
                          _bullet(
                            'Select the allocated warehouse where you are working.',
                          ),
                          _bullet(
                            'All orders and actions will be linked to this warehouse for tracking and reporting.',
                          ),
                          const SizedBox(height: 16),

                          // 2. Scan PO QR Code
                          _stepHeader(
                            icon: CupertinoIcons.qrcode_viewfinder,
                            title: 'Scan PO QR Code',
                          ),
                          const SizedBox(height: 4),
                          _bullet(
                            'When you receive a new order to process, open the app and select “Scan PO” (or the relevant option).',
                          ),
                          _bullet(
                            'Scan the QR code printed on the Purchase Order (PO).',
                          ),
                          _bullet(
                            'The app will automatically fetch the PO details linked to that QR code.',
                          ),
                          const SizedBox(height: 16),

                          // 3. Upload Packaging Images
                          _stepHeader(
                            icon: CupertinoIcons.photo_on_rectangle,
                            title: 'Upload Packaging Images',
                          ),
                          const SizedBox(height: 4),
                          _bullet(
                            'After packing the order, you must upload 2 images:',
                          ),
                          _subBullet(
                            '1st image: Product/contents after packing inside the box or polybag.',
                          ),
                          _subBullet(
                            '2nd image: Final packed shipment (outer view), with label or identification clearly visible.',
                          ),
                          _bullet(
                            'These photos are used for quality control, proof of packing, and dispute resolution.',
                          ),
                          const SizedBox(height: 16),

                          // 4. Enter Shipment Packages Count
                          _stepHeader(
                            icon: CupertinoIcons.cube_box,
                            title: 'Enter Shipment Packages Count',
                          ),
                          const SizedBox(height: 4),
                          _bullet(
                            'Enter the shipment_packages_count (total number of packages/boxes for this PO).',
                          ),
                          _bullet(
                            'This helps ensure the correct number of parcels is handed over to the courier and recorded in the system.',
                          ),
                          const SizedBox(height: 16),

                          // 5. Submit & Complete
                          _stepHeader(
                            icon: CupertinoIcons.checkmark_seal,
                            title: 'Submit & Complete',
                          ),
                          const SizedBox(height: 4),
                          _bullet(
                            'Review all details (PO, images, package count).',
                          ),
                          _bullet(
                            'Tap “Submit” to complete the process.',
                          ),
                          _bullet(
                            'The submission is stored in the system with your user ID, warehouse ID, timestamp, and images for future reference.',
                          ),
                          const SizedBox(height: 20),

                          // Purpose section
                          const Divider(height: 24),
                          const Text(
                            'Purpose',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _bullet('Ensure accurate packing for every order.'),
                          _bullet('Maintain photo proof of each shipment.'),
                          _bullet(
                              'Track which staff member packed which order and from which warehouse.'),
                          _bullet(
                              'Reduce errors, missing items, and disputes with customers and couriers.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Small helper widgets for bullets / headers =====

  static Widget _stepHeader({required IconData icon, required String title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _subBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '– ',
            style: TextStyle(fontSize: 13),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
