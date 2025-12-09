import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Keep if you actually use it for compression before upload/display
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:share_plus/share_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
// For Android MediaStore access (add dependency if not already present)
// import 'package:permission_handler/permission_handler.dart'; // For requesting storage permissions if needed
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // Alternative for saving to gallery/downloads

class DropReport extends StatefulWidget { // Changed class name to follow Dart conventions (UpperCamelCase)
  const DropReport({super.key});

  @override
  State<DropReport> createState() => _DropReportState(); // Changed state class name
}

class _DropReportState extends State<DropReport> with TickerProviderStateMixin {
  String sellerId = '';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSellerId();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000), // const added
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5), // const added
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadSellerId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        sellerId = prefs.getString('seller_id') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatImageUrls(dynamic images) {
    try {
      if (images == null) return '';

      if (images is List) {
        return images
            .map((img) => img.toString().trim())
            .where((img) => img.isNotEmpty) // Filter out empty strings
            .join('\n');
      } else if (images is String) {
        if (images.contains(',')) {
          return images
              .split(',')
              .map((url) => url.trim())
              .where((url) => url.isNotEmpty) // Filter out empty strings
              .join('\n');
        }
        return images.trim();
      }
      return images.toString().trim();
    } catch (e) {
      print('Error formatting image URL: $e'); // Log the error
      return '';
    }
  }

  Future<String?> _getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        // More robust way: getExternalStorageDirectory() provides app-specific external storage.
        // For public "Downloads" folder, MediaStore API is better for Android 10+
        // However, for simplicity and broader compatibility if not using MediaStore:
        directory = await getExternalStorageDirectory(); // App's external files dir
        // Or try common public downloads directory (might need permissions / might not be reliable)
        // String? downloadsPath = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
        // if (downloadsPath != null) {
        //   directory = Directory(downloadsPath);
        //   if (!await directory.exists()) {
        //     await directory.create(recursive: true);
        //   }
        // }
        // Fallback to a common, though less reliable path if getExternalStorageDirectory is null
        if (directory == null) {
          final commonDownloadsDir = Directory('/storage/emulated/0/Download');
          if (await commonDownloadsDir.exists()) {
            directory = commonDownloadsDir;
          } else {
            // As a last resort, use application support directory (less user accessible)
            directory = await getApplicationSupportDirectory();
          }
        }

      }
    } catch (err) {
      print("Cannot get download path: $err");
    }
    return directory?.path;
  }


  Future<void> downloadScannedOrders() async {
    if (mounted) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });
    }

    try {
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day - 7);
      DateTime endDate = now;
      String startDateString = startDate.toIso8601String();
      String endDateString = endDate.toIso8601String();

      if (mounted) setState(() => _downloadProgress = 0.1);

      if (sellerId.isEmpty) {
        _showErrorMessage('Seller ID not loaded. Please try again.');
        if (mounted) setState(() => _isDownloading = false);
        return;
      }

      final url = 'https://customprint.deodap.com'
          '/api_amzDD_return/report_dropshipper.php'
          '?start_date=$startDateString'
          '&end_date=$endDateString'
          '&seller_id=$sellerId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App/1.0',
        },
      ).timeout(const Duration(seconds: 60)); // Increased timeout slightly

      if (mounted) setState(() => _downloadProgress = 0.3);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData['status'] == 'error') {
          _showErrorMessage('API Error: ${responseData['message']}');
          if (mounted) setState(() => _isDownloading = false);
          return;
        }

        if (responseData['scanned_orders'] == null ||
            (responseData['scanned_orders'] as List).isEmpty) {
          _showErrorMessage('No orders found for the last week!', isWarning: true);
          if (mounted) setState(() => _isDownloading = false);
          return;
        }

        List<dynamic> orders = responseData['scanned_orders'];
        if (mounted) setState(() => _downloadProgress = 0.4);

        final xls.Workbook workbook = xls.Workbook();
        final xls.Worksheet sheet = workbook.worksheets[0];
        sheet.name = 'AMZDD Return Report';

        final xls.Style headerStyle = workbook.styles.add('HeaderStyle');
        headerStyle.bold = true;
        headerStyle.backColorRgb = const Color(0xFF4CAF50); // Using Color object
        headerStyle.fontColorRgb = const Color(0xFFFFFFFF); // Using Color object
        headerStyle.fontSize = 12;
        headerStyle.hAlign = xls.HAlignType.center;
        headerStyle.vAlign = xls.VAlignType.center;

        final xls.Style dataStyle = workbook.styles.add('DataStyle');
        dataStyle.fontSize = 11;
        dataStyle.wrapText = true;
        dataStyle.vAlign = xls.VAlignType.top;

        List<String> headers = [
          "ID", "Amazon Order ID", "Tracking ID", "OTP", "Out For Delivery Date",
          "Status", "Bad/Good", "Images", "Sticker Photo", "Unbox Photo",
          "Remarks", "Dropshipper Created At", "Deodap-Emp Updated At"
        ];

        for (int i = 0; i < headers.length; i++) {
          final cell = sheet.getRangeByIndex(1, i + 1);
          cell.setText(headers[i]);
          cell.cellStyle = headerStyle;
        }
        // It's often better to autoFitColumns after all data is added.

        if (mounted) setState(() => _downloadProgress = 0.6);

        int rowIndex = 2; // Renamed for clarity
        for (var order in orders) {
          try {
            String images = _formatImageUrls(order['images']);
            String stickerPhoto = _formatImageUrls(order['sticker_photo']);
            String unboxPhoto = _formatImageUrls(order['unbox_photo']);

            sheet.getRangeByIndex(rowIndex, 1).setText(order['id']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 2).setText(order['amazon_order_id']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 3).setText(order['return_tracking_id']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 4).setText(order['otp']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 5).setText(order['out_for_delivery_date']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 6).setText(order['status']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 7).setText(order['bad_good_return']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 8).setText(images);
            sheet.getRangeByIndex(rowIndex, 9).setText(stickerPhoto);
            sheet.getRangeByIndex(rowIndex, 10).setText(unboxPhoto);
            sheet.getRangeByIndex(rowIndex, 11).setText(order['remarks']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 12).setText(order['created_at']?.toString() ?? '');
            sheet.getRangeByIndex(rowIndex, 13).setText(order['updated_at']?.toString() ?? '');

            for (int col = 1; col <= headers.length; col++) {
              sheet.getRangeByIndex(rowIndex, col).cellStyle = dataStyle;
            }
            rowIndex++;
          } catch (e) {
            print('Error processing order row: $e for order: $order'); // More context in error
            continue;
          }
        }

        if (mounted) setState(() => _downloadProgress = 0.8);

        for (int i = 1; i <= headers.length; i++) {
          sheet.autoFitColumn(i);
          if (i >= 8 && i <= 10) { // Image columns
            // Get the current autofitted width, ensure it's at least 25
            var currentWidth = sheet.getRangeByIndex(1, i).columnWidth;
            sheet.getRangeByIndex(1, i, rowIndex -1 , i).columnWidth = currentWidth < 25.0 ? 25.0 : currentWidth;

            // Alternative: fixed width if autofit is not desired for these
            // sheet.getRangeByIndex(1, i, rowIndex - 1, i).columnWidth = 25;
          }
        }

        for (int i = 2; i < rowIndex; i++) { // Corrected loop condition
          sheet.getRangeByIndex(i, 1, i, headers.length).rowHeight = 50;
        }

        String? downloadDirPath = await _getDownloadPath();
        if (downloadDirPath == null) {
          _showErrorMessage('Unable to determine downloads directory.');
          if (mounted) setState(() => _isDownloading = false);
          return;
        }

        String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        String fileName = 'AMZDD_Return_Report_$timestamp.xlsx';
        String filePath = path.join(downloadDirPath, fileName);

        if (mounted) setState(() => _downloadProgress = 0.9);

        final List<int> bytes = workbook.saveAsStream();
        File excelFile = File(filePath);
        await excelFile.writeAsBytes(bytes, flush: true); // Added flush

        workbook.dispose();

        if (mounted) setState(() => _downloadProgress = 1.0);

        _showSuccessDialog(filePath, fileName);

      } else {
        _showErrorMessage('Failed to load data. Status: ${response.statusCode}. Body: ${response.body}'); // Added response body for debugging
      }
    } catch (e, s) { // Added stacktrace
      print('Download error: $e\nStacktrace: $s'); // Log stacktrace
      if (e.toString().contains('TimeoutException')) {
        _showErrorMessage('Request timeout. Please check your internet connection and try again.');
      } else if (e is SocketException) { // More specific check for SocketException
        _showErrorMessage('No Internet Connection or server unreachable.');
      } else {
        _showErrorMessage('An error occurred: ${e.toString()}');
      }
    } finally { // Ensure state is reset
      if (mounted) {
        setState(() {
          _isDownloading = false;
          // Optionally reset progress after a short delay or when dialog is dismissed
          // _downloadProgress = 0.0;
        });
      }
    }
  }

  void _showErrorMessage(String message, {bool isWarning = false}) {
    if (!mounted) return; // Don't show if widget is disposed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline, // Changed icons
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle( // const added
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? Colors.orange.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4), // Slightly longer for errors
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16), // Added margin
      ),
    );
  }

  void _showSuccessDialog(String filePath, String fileName) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Download Successful!',
      desc: 'Excel file "$fileName" saved to:\n$filePath', // Show full path
      btnOkText: 'OK',
      btnOkOnPress: () {
        if (mounted) setState(() => _downloadProgress = 0.0); // Reset progress on OK
      },
      btnCancelText: "Share File",
      btnCancelColor: Colors.blue[800], // Custom color for share
      btnCancelOnPress: () {
        Share.shareXFiles([XFile(filePath)], subject: 'AMZDD Return Report');
        if (mounted) setState(() => _downloadProgress = 0.0); // Reset progress on Share
      },
      dialogBackgroundColor: Colors.white,
      titleTextStyle: TextStyle( // const removed as color is not const
        color: Colors.green.shade700,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      descTextStyle: TextStyle( // const removed
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
      onDismissCallback: (type) { // Reset progress if dialog is dismissed otherwise
        if (mounted) setState(() => _downloadProgress = 0.0);
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800], // Consider using Theme.of(context).primaryColor
        elevation: 0,
        title: Text(
          "Generate Report",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // const added
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // const added
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24), // const added
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // To make button full width easily
              children: [
                Container(
                  padding: const EdgeInsets.all(24), // const added
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [ // Subtle shadow
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.blue[800], //Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "AMZDD Return Report",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Data from the Last 7 Days", // Slightly rephrased
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox( // Using SizedBox for consistent height
                  height: 50, // Standard button height
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _isDownloading ? Icons.hourglass_empty_rounded : Icons.download_for_offline_rounded, // Changed icons
                      color: Colors.white,
                      // size: 24, // Icon size is often handled by ButtonStyle
                    ),
                    label: Text(
                      _isDownloading ? "Generating..." : "Download Excel Report",
                      style: GoogleFonts.poppins(
                        fontSize: 16, // Adjusted for better fit
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _isDownloading ? null : downloadScannedOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDownloading ? Colors.grey[400] : Colors.blue[800], //Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Consistent border radius
                      ),
                      elevation: _isDownloading ? 0 : 4,
                      textStyle: GoogleFonts.poppins( // Ensure font is applied
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30), // Adjusted spacing

                // Progress Indicator
                if (_isDownloading)
                  AnimatedOpacity( // Use AnimatedOpacity for smoother appearance
                    opacity: _isDownloading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        CircularPercentIndicator(
                          radius: 50.0, // Slightly smaller
                          lineWidth: 10.0, // Slightly thicker
                          percent: _downloadProgress,
                          center: Text(
                            "${(_downloadProgress * 100).toInt()}%",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800], //Theme.of(context).primaryColor,
                            ),
                          ),
                          backgroundColor: Colors.grey[300]!,
                          progressColor: Colors.blue[800], //Theme.of(context).primaryColor,
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true, // Enable animation
                          animationDuration: 300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getProgressText(_downloadProgress),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700], // Darker grey for better contrast
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(), // Pushes content to center if not enough content, or above if too much
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Ensure you have a stable internet connection.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getProgressText(double progress) {
    if (progress <= 0.0) return "Starting download..."; // Added initial state
    if (progress < 0.2) return "Connecting to server...";
    if (progress < 0.4) return "Fetching data...";
    if (progress < 0.6) return "Processing orders...";
    if (progress < 0.8) return "Creating Excel file...";
    if (progress < 1.0) return "Saving file...";
    return "Download complete!";
  }
}
