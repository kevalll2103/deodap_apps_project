import 'dart:convert';
import 'dart:io';
import 'package:amz/view/employee/second_scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ScanAnotherTrackingid extends StatefulWidget {
  const ScanAnotherTrackingid({super.key});

  @override
  State<ScanAnotherTrackingid> createState() => _ScanAnotherTrackingidState();
}

class _ScanAnotherTrackingidState extends State<ScanAnotherTrackingid> {
  final TextEditingController orderIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String orderId = ''; // Define it at the class level
  Map<String, dynamic>? orderData; // API response store karne ke liye variable

  // Three options: 'right', 'wrong', 'not_claim'
  String selectedOption = 'right'; // Default is 'right'

  File? capturedImage; // Store captured image
  final ImagePicker _picker = ImagePicker();

  void findOrderID() async {
    FocusScope.of(context).unfocus(); // Hide keyboard

    if (orderIdController.text.isEmpty) {
      return;
    }

    setState(() {
      orderData = null; // Clear previous data
      orderId = '';  // Clear previous ID
      selectedOption = 'right'; // Reset to default
      capturedImage = null; // Clear previous image
    });

    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black12.withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context)!.insert(overlayEntry);

    try {
      final response = await http.post(
        Uri.parse('https://customprint.deodap.com/api_amzDD_return/get_sallerdata_by_trackingID.php'),
        body: {'tracking_id': orderIdController.text},
      );

      overlayEntry.remove(); // Remove loader

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("API Response: $data");

        if (data['status'] == 'success') {
          setState(() {
            orderData = data['data'][0];
            orderId = orderData!['id'].toString(); // Update orderId
          });

          print("✅ Matched Order ID: $orderId"); // Debugging
        } else {
          setState(() {
            orderData = null;
            orderId = ''; // Clear ID if not found
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This tracking ID process is completed',
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error, please try again later!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade900,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      overlayEntry.remove(); // Remove loader
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No Internet Connection!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        capturedImage = File(image.path);
      });
    }
  }

  Future<void> submitScanOrder() async {
    FocusScope.of(context).requestFocus(FocusNode());

    String enteredTrackingId = orderIdController.text.trim();

    if (enteredTrackingId.isEmpty) {
      print("❌ Please enter Tracking ID!");
      return;
    }

    if (orderId.isEmpty) {  // Check if orderId is missing
      print("❌ Order ID not found! API cannot be called.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order ID is missing! Fetch it first."),
          backgroundColor: Colors.red.shade900,
        ),
      );
      return;
    }

    // Check if image is required (Wrong OTP or Not a Claim)
    if ((selectedOption == 'wrong' || selectedOption == 'not_claim') && capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please capture an image for verification!"),
          backgroundColor: Colors.red.shade900,
        ),
      );
      return;
    }

    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black12.withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    var url = Uri.parse("https://customprint.deodap.com/api_amzDD_return/emp_scanorder.php");
    var request = http.MultipartRequest("POST", url);
    print("✅ Sending API Data:");
    print("Order ID: $orderId");
    print("Return Tracking ID: $enteredTrackingId");
    print("Selected Option: $selectedOption");

    request.fields['id'] = orderId;
    request.fields['return_tracking_id'] = enteredTrackingId;

    // Send appropriate values based on selected option
    if (selectedOption == 'right') {
      request.fields['otp_status'] = 'right';
      request.fields['is_not_a_claim'] = 'false';
      request.fields['status'] = 'completed';
    } else if (selectedOption == 'wrong') {
      request.fields['otp_status'] = 'wrong';
      request.fields['is_not_a_claim'] = 'false';
      request.fields['status'] = 'wrongotp';
    } else if (selectedOption == 'not_claim') {
      request.fields['otp_status'] = 'right'; // Keep it right for not_claim
      request.fields['is_not_a_claim'] = 'true';
      request.fields['status'] = 'notaclaim';
    }


    // Add image if captured
    if (capturedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'images[]', // ✅ This matches what PHP expects
        capturedImage!.path,
      ));
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      overlayEntry.remove();

      if (jsonResponse['success'] == true) {
        print("✅ Order Scan Successfully");
        setState(() {
          orderIdController.clear();
          orderData = null;
          orderId = ''; // Clear ID
          selectedOption = 'right'; // Reset to default
          capturedImage = null; // Clear image
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Scan Successfully', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print("❌ Update Failed: ${jsonResponse['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? "Failed to update!")),
        );
      }
    } catch (e) {
      overlayEntry.remove();
      print("❌ API Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Internet Connection..! '),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildOrderDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF718096),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A365D), Color(0xFF2C5AA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Scan Tracking ID',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Scanner Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 32,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Scanner',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A365D),
                              ),
                            ),
                            Text(
                              'Scan or manually enter tracking ID',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final scannedOrderId = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SecondScanner()),
                              );
                              if (scannedOrderId != null) {
                                orderIdController.text = scannedOrderId.toString();
                                findOrderID(); // Automatically find after scanning
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                            label: Text(
                              'Scan QR Code',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A365D),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Manual Entry Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Manual Entry',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A365D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: orderIdController,
                      focusNode: _focusNode,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2D3748),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter Tracking ID manually',
                        hintStyle: GoogleFonts.poppins(color: const Color(0xFF718096), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        prefixIcon: Icon(Icons.track_changes_rounded, color: const Color(0xFF718096)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: findOrderID,
                      icon: const Icon(Icons.search_rounded, color: Colors.white),
                      label: Text(
                        'Find Order',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Order Details Section
            if (orderData != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.hourglass_bottom,
                            color: Colors.orange.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Found',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A365D),
                                ),
                              ),
                              Text(
                                'Pending status - Ready to process',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildOrderDetailRow('Seller Name', orderData!['seller_name']),
                          _buildOrderDetailRow('Order ID', orderData!['amazon_order_id']),
                          _buildOrderDetailRow('Tracking ID', orderData!['return_tracking_id']),
                          _buildOrderDetailRow('OTP', orderData!['otp']),
                          _buildOrderDetailRow('Created', orderData!['created_at']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This tracking ID is currently in 'Pending' status. Please select an option below to update the status.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Options Selection Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A365D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.checklist_rounded,
                            color: const Color(0xFF1A365D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Select Processing Option',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A365D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Right OTP Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOption = 'right';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: selectedOption == 'right' ? Colors.green.shade50 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == 'right' ? Colors.green : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedOption == 'right' ? Colors.green : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: selectedOption == 'right' ? Colors.white : Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Correct OTP - Complete Order",
                              style: GoogleFonts.poppins(
                                color: selectedOption == 'right' ? Colors.green.shade700 : const Color(0xFF2D3748),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Wrong OTP Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOption = 'wrong';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: selectedOption == 'wrong' ? Colors.red.shade50 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == 'wrong' ? Colors.red : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedOption == 'wrong' ? Colors.red : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.cancel_rounded,
                                color: selectedOption == 'wrong' ? Colors.white : Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Wrong OTP - Requires Image",
                              style: GoogleFonts.poppins(
                                color: selectedOption == 'wrong' ? Colors.red.shade700 : const Color(0xFF2D3748),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Not a Claim Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOption = 'not_claim';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedOption == 'not_claim' ? Colors.orange.shade50 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == 'not_claim' ? Colors.orange : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedOption == 'not_claim' ? Colors.orange : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_rounded,
                                color: selectedOption == 'not_claim' ? Colors.white : Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Not a Claim - Requires Image",
                              style: GoogleFonts.poppins(
                                color: selectedOption == 'not_claim' ? Colors.orange.shade700 : const Color(0xFF2D3748),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Capture Section (only show when wrong OTP or not a claim)
              if (selectedOption == 'wrong' || selectedOption == 'not_claim') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Image Verification Required',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A365D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (capturedImage != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              capturedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: captureImage,
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                          label: Text(
                            capturedImage != null ? "Retake Image" : "Capture Image",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: submitScanOrder,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    'Process Order',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ] else ...[
              // Empty state when no order is found
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 64,
                      color: const Color(0xFF718096),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Order Found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan a QR code or enter a tracking ID to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}