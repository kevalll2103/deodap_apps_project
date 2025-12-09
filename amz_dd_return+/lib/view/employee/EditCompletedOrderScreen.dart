import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:amz/view/employee/second_scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';

class EditCompletedOrderScreen extends StatefulWidget {
  const EditCompletedOrderScreen({super.key});

  @override
  State<EditCompletedOrderScreen> createState() => _EditCompletedOrderScreenState();
}

class _EditCompletedOrderScreenState extends State<EditCompletedOrderScreen> {
  // Controllers
  final TextEditingController orderIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State variables
  Map<String, dynamic>? orderData;
  String orderId = '';
  String returnCondition = 'good'; // Default condition
  List<Uint8List> stickerPhotos = [];
  List<Uint8List> unboxPhotos = [];
  bool isUploading = false;
  double uploadProgress = 0.0;

  // Constants
  static const _apiBaseUrl = 'https://customprint.deodap.com/api_amzDD_return';
  static const _primaryColor = Color(0xFF0172B2);
  static const _secondaryColor = Color(0xFF001645);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (orderData != null) {
      orderId = orderData!['id'].toString();
    }
  }

  @override
  void dispose() {
    orderIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Optimized image capture with compression
  Future<void> _getImage(String type) async {
    if (type == 'sticker' && stickerPhotos.length >= 3) {
      _showErrorSnackbar('You can upload a maximum of 3 sticker photos.');
      return;
    } else if (type == 'unbox' && unboxPhotos.length >= 3) {
      _showErrorSnackbar('You can upload a maximum of 3 unbox photos.');
      return;
    }

    // Show loading indicator
    _showImageProcessingDialog();

    try {
      final pickedFile = await _picker.pickImage(

        source: ImageSource.camera,
        imageQuality: 95,     // Reduce quality to 60%
        maxWidth: 1200,       // Limit width
        maxHeight: 1200,      // Limit height
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();

        // Further compress if still too large
        Uint8List finalImageBytes = imageBytes;
        if (imageBytes.length > 500000) { // If larger than 500KB
          finalImageBytes = await _compressImage(imageBytes);
        }

        Navigator.pop(context); // Remove loading dialog

        setState(() {
          if (type == 'sticker') {
            stickerPhotos.add(finalImageBytes);
          } else {
            unboxPhotos.add(finalImageBytes);
          }
        });

        _showSuccessSnackbar('Image captured successfully (${(finalImageBytes.length / 1024).toStringAsFixed(1)}KB)');
      } else {
        Navigator.pop(context); // Remove loading dialog
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog
      _showErrorSnackbar('Failed to capture image. Please try again.');
    }
  }

  // Advanced image compression
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 800,
        targetHeight: 800,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      print('Compression error: $e');
    }

    return imageBytes; // Return original if compression fails
  }

  void _showImageProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Processing image...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Optimizing for faster upload',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> findOrderID() async {
    FocusScope.of(context).unfocus();

    if (orderIdController.text.isEmpty) {
      return;
    }

    setState(() {
      orderData = null;
      orderId = '';
    });

    final overlayEntry = _createLoaderOverlay();
    Overlay.of(context).insert(overlayEntry);

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/get_completed_order.php'),
        body: {'tracking_id': orderIdController.text},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );

      overlayEntry.remove();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _handleFindOrderResponse(data);
      } else {
        _showErrorSnackbar('Server error, please try again later!');
      }
    } catch (e) {
      overlayEntry.remove();
      if (e.toString().contains('timeout')) {
        _showErrorSnackbar('Request timeout. Please check your connection.');
      } else {
        _showErrorSnackbar('No Internet Connection!');
      }
    }
  }

  void _handleFindOrderResponse(Map<String, dynamic> data) {
    if (data['status'] == 'success') {
      setState(() {
        orderData = data['data'][0];
        orderId = orderData!['id'].toString();
      });
    } else if (data['message'] == 'No pending orders found for this tracking ID') {
      setState(() {
        orderData = null;
        orderId = '';
      });
      _showInfoSnackbar('This tracking ID process is completed');
    } else {
      setState(() {
        orderData = null;
        orderId = '';
      });
      _showErrorSnackbar('Tracking ID not found!');
    }
  }

  Future<void> submitScanOrder() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (orderIdController.text.isEmpty) {
      _showErrorSnackbar('Please enter Tracking ID!');
      return;
    }

    if (orderId.isEmpty) {
      _showErrorSnackbar('Order ID not found! Fetch it first.');
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    // Show progress dialog
    _showUploadProgressDialog();

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$_apiBaseUrl/updated_order.php"),
      );

      request.fields['id'] = orderId;
      request.fields['return_tracking_id'] = orderIdController.text;
      request.fields['bad_good_return'] = returnCondition;

      int totalFiles = stickerPhotos.length + unboxPhotos.length;
      int processedFiles = 0;

      // Add sticker photos
      for (int i = 0; i < stickerPhotos.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'sticker_photos[]',
            stickerPhotos[i],
            filename: "sticker_photo_$i.jpg",
          ),
        );
        processedFiles++;
        setState(() {
          uploadProgress = (processedFiles / totalFiles) * 0.5; // 50% for preparation
        });
      }

      // Add unbox photos
      for (int i = 0; i < unboxPhotos.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'unbox_photos[]',
            unboxPhotos[i],
            filename: "unbox_photo_$i.jpg",
          ),
        );
        processedFiles++;
        setState(() {
          uploadProgress = (processedFiles / totalFiles) * 0.5; // 50% for preparation
        });
      }

      setState(() {
        uploadProgress = 0.7; // 70% - starting upload
      });

      var response = await request.send().timeout(
        const Duration(seconds: 60), // Increased timeout for upload
        onTimeout: () => throw Exception('Upload timeout'),
      );

      setState(() {
        uploadProgress = 0.9; // 90% - processing response
      });

      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      Navigator.pop(context); // Remove progress dialog

      setState(() {
        isUploading = false;
        uploadProgress = 1.0;
      });

      if (jsonResponse['success'] == true) {
        _handleSuccessfulSubmission();
      } else {
        _showErrorSnackbar(jsonResponse['message'] ?? "Failed to update!");
      }
    } catch (e) {
      Navigator.pop(context); // Remove progress dialog
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });

      if (e.toString().contains('timeout')) {
        _showErrorSnackbar('Upload timeout. Please try again with smaller images.');
      } else {
        _showErrorSnackbar('Upload failed. Check your internet connection.');
      }
    }
  }

  void _showUploadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Uploading images...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stickerPhotos.length + unboxPhotos.length} photos to upload',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${(uploadProgress * 100).toInt()}% complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSuccessfulSubmission() {
    setState(() {
      orderIdController.clear();
      stickerPhotos.clear();
      unboxPhotos.clear();
      returnCondition = 'good'; // Reset to default condition
      orderData = null;
      orderId = '';
      isUploading = false;
      uploadProgress = 0.0;
    });

    _showSuccessSnackbar('Order Scan Successfully');
  }

  OverlayEntry _createLoaderOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black12.withOpacity(0.8),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 2),
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
          'Edit Completed Order',
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
            _buildQuickScannerSection(),
            const SizedBox(height: 20),
            _buildManualEntrySection(),
            const SizedBox(height: 20),
            if (orderData != null) _buildOrderDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScannerSection() {
    return Container(
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
                      'Scan completed order tracking ID',
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
              onPressed: () async {
                final scannedOrderId = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondScanner()),
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
        ],
      ),
    );
  }

  Widget _buildManualEntrySection() {
    return Container(
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
    );
  }

  Widget _buildOrderDetailsSection() {
    return Column(
      children: [
        _buildOrderInfoCard(),
        const SizedBox(height: 20),
        _buildInstructionCard(),
        const SizedBox(height: 20),
        _buildReturnTypeSelector(),
        const SizedBox(height: 20),
        _buildPhotoUploadSection(),
        const SizedBox(height: 30),
        _buildScanButton(),
      ],
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
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
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed Order Found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A365D),
                      ),
                    ),
                    Text(
                      'Ready for update processing',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green.shade700,
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
        ],
      ),
    );
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

  Widget _buildInstructionCard() {
    return Container(
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
              "This tracking ID is currently in 'Completed' status. Select return condition and upload photos to update the order.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTypeSelector() {
    return Container(
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
                  Icons.category_rounded,
                  color: const Color(0xFF1A365D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Return Condition',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A365D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildReturnConditionButton("Good", 'good', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildReturnConditionButton("Bad", 'bad', Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildReturnConditionButton("Used", 'used', Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnConditionButton(String label, String condition, Color color) {
    bool isSelected = returnCondition == condition;
    return GestureDetector(
      onTap: () {
        setState(() {
          returnCondition = condition;
          stickerPhotos.clear(); // Clear previous photos when changing condition
          unboxPhotos.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getConditionIcon(condition),
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConditionIcon(String condition) {
    switch (condition) {
      case 'good':
        return Icons.thumb_up_rounded;
      case 'bad':
        return Icons.thumb_down_rounded;
      case 'used':
        return Icons.history_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Widget _buildPhotoUploadSection() {
    return Container(
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
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.purple.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Photo Upload',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A365D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Sticker Photos Section
          _buildPhotoSection('Sticker Photos', 'sticker', stickerPhotos, Colors.blue),
          const SizedBox(height: 20),
          
          // Unbox Photos Section
          _buildPhotoSection('Unbox Photos', 'unbox', unboxPhotos, Colors.green),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String title, String type, List<Uint8List> photos, Color color) {
    bool isMaxReached = photos.length >= 3;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title (max 3)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            if (photos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${photos.length}/3",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: isMaxReached ? [] : [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: isMaxReached ? null : () => _getImage(type),
            icon: Icon(
              isMaxReached ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
              color: Colors.white,
            ),
            label: Text(
              isMaxReached ? "Maximum Reached" : "Capture Photo",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isMaxReached ? Colors.grey.shade400 : color,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          photos[index],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (type == 'sticker') {
                                stickerPhotos.removeAt(index);
                              } else {
                                unboxPhotos.removeAt(index);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isUploading ? [] : [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isUploading ? null : submitScanOrder,
        icon: Icon(
          isUploading ? Icons.hourglass_empty_rounded : Icons.cloud_upload_rounded,
          color: Colors.white,
        ),
        label: Text(
          isUploading ? "Uploading..." : "Update Order",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isUploading ? Colors.grey.shade400 : Colors.green.shade600,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}