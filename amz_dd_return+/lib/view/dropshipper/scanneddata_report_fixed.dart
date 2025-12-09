import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

class dropReport extends StatefulWidget {
  const dropReport({super.key});

  @override
  State<dropReport> createState() => _dropReportState();
}
class _dropReportState extends State<dropReport> with TickerProviderStateMixin {
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
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadSellerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sellerId = prefs.getString('seller_id') ?? '';
    });
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
        // Join multiple URLs with line breaks for better Excel formatting
        return images.map((img) => img.toString()).join('\n');
      } else if (images is String) {
        // Handle comma-separated URLs
        if (images.contains(',')) {
          return images.split(',').map((url) => url.trim()).join('\n');
        }
        return images;
      }
      return images.toString();
    } catch (e) {
      return '';
    }
  }

  Future<void> downloadScannedOrders() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Calculate the date range for the last week
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day - 7);
      DateTime endDate = now;

      // Format the dates to ISO 8601 string format
      String startDateString = startDate.toIso8601String();
      String endDateString = endDate.toIso8601String();

      // Update progress
      setState(() {
        _downloadProgress = 0.1;
      });

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
      ).timeout(Duration(seconds: 30));

      setState(() {
        _downloadProgress = 0.3;
      });

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Check API response status
        if (responseData['status'] == 'error') {
          _showErrorMessage('API Error: ${responseData['message']}');
          setState(() {
            _isDownloading = false;
          });
          return;
        }

        if (responseData['scanned_orders'] == null || responseData['scanned_orders'].isEmpty) {
          _showErrorMessage('No orders found for the last week!', isWarning: true);
          setState(() {
            _isDownloading = false;
          });
          return;
        }

        List<dynamic> orders = responseData['scanned_orders'];

        setState(() {
          _downloadProgress = 0.4;
        });

        // Create Excel workbook
        final xls.Workbook workbook = xls.Workbook();
        final xls.Worksheet sheet = workbook.worksheets[0];

        // Set sheet name
        sheet.name = 'AMZDD Return Report';

        // Create styles
        final xls.Style headerStyle = workbook.styles.add('HeaderStyle');
        headerStyle.bold = true;
        headerStyle.backColor = '#4CAF50';
        headerStyle.fontColor = '#FFFFFF';
        headerStyle.fontSize = 12;
        headerStyle.hAlign = xls.HAlignType.center;
        headerStyle.vAlign = xls.VAlignType.center;

        final xls.Style dataStyle = workbook.styles.add('DataStyle');
        dataStyle.fontSize = 11;
        dataStyle.wrapText = true;
        dataStyle.vAlign = xls.VAlignType.top;

        // Define headers (removed seller_id, seller_name, CRN)
        List<String> headers = [
          "ID", "Amazon Order ID", "Tracking ID", "OTP", "Out For Delivery Date",
          "Status", "Bad/Good", "Images", "Sticker Photo", "Unbox Photo",
          "Remarks", "Dropshipper Created At", "Deodap-Emp Updated At"
        ];

        // Set headers
        for (int i = 0; i < headers.length; i++) {
          final cell = sheet.getRangeByIndex(1, i + 1);
          cell.setText(headers[i]);
          cell.cellStyle = headerStyle;
          // Auto-fit column width
          sheet.autoFitColumn(i + 1);
        }

        setState(() {
          _downloadProgress = 0.6;
        });

        // Add data rows
        int row = 2;
        for (var order in orders) {
          try {
            // Format images with proper handling
            String images = _formatImageUrls(order['images']);
            String stickerPhoto = _formatImageUrls(order['sticker_photo']);
            String unboxPhoto = _formatImageUrls(order['unbox_photo']);

            // Set data with null safety (removed seller_id, seller_name, CRN columns)
            sheet.getRangeByIndex(row, 1).setText(order['id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 2).setText(order['amazon_order_id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 3).setText(order['return_tracking_id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 4).setText(order['otp']?.toString() ?? '');
            sheet.getRangeByIndex(row, 5).setText(order['out_for_delivery_date']?.toString() ?? '');
            sheet.getRangeByIndex(row, 6).setText(order['status']?.toString() ?? '');
            sheet.getRangeByIndex(row, 7).setText(order['bad_good_return']?.toString() ?? '');
            sheet.getRangeByIndex(row, 8).setText(images);
            sheet.getRangeByIndex(row, 9).setText(stickerPhoto);
            sheet.getRangeByIndex(row, 10).setText(unboxPhoto);
            sheet.getRangeByIndex(row, 11).setText(order['remarks']?.toString() ?? '');
            sheet.getRangeByIndex(row, 12).setText(order['created_at']?.toString() ?? '');
            sheet.getRangeByIndex(row, 13).setText(order['updated_at']?.toString() ?? '');

            // Apply data style to all cells in the row
            for (int col = 1; col <= headers.length; col++) {
              sheet.getRangeByIndex(row, col).cellStyle = dataStyle;
            }

            row++;
          } catch (e) {
            print('Error processing order: $e');
            continue;
          }
        }

        setState(() {
          _downloadProgress = 0.8;
        });

        // Auto-fit columns for better readability
        for (int i = 1; i <= headers.length; i++) {
          sheet.autoFitColumn(i);
          // Set minimum width for image columns using getRangeByIndex (updated column numbers)
          if (i >= 8 && i <= 10) {
            sheet.getRangeByIndex(1, i, row - 1, i).columnWidth = 25;
          }
        }

        // Set row height for better visibility using getRangeByIndex
        for (int i = 2; i < row; i++) {
          sheet.getRangeByIndex(i, 1, i, headers.length).rowHeight = 50;
        }

        // Get Downloads directory
        Directory? downloadsDirectory;
        if (Platform.isAndroid) {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
          if (!await downloadsDirectory.exists()) {
            downloadsDirectory = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          downloadsDirectory = await getApplicationDocumentsDirectory();
        }

        if (downloadsDirectory == null) {
          _showErrorMessage('Unable to access Downloads folder');
          setState(() {
            _isDownloading = false;
          });
          return;
        }

        // Generate filename with timestamp
        String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        String fileName = 'AMZDD_Return_Report_$timestamp.xlsx';
        String filePath = path.join(downloadsDirectory.path, fileName);

        setState(() {
          _downloadProgress = 0.9;
        });

        // Save the file
        final List<int> bytes = workbook.saveAsStream();
        await File(filePath).writeAsBytes(bytes);

        workbook.dispose();

        setState(() {
          _downloadProgress = 1.0;
        });

        // Show success dialog
        _showSuccessDialog(filePath, fileName);

      } else {
        _showErrorMessage('Failed to load data from server. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _showErrorMessage('Request timeout. Please check your internet connection.');
      } else if (e.toString().contains('SocketException')) {
        _showErrorMessage('No Internet Connection!');
      } else {
        _showErrorMessage('An error occurred: ${e.toString()}');
      }
    }

    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  void _showErrorMessage(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? Colors.orange.shade700 : Colors.red.shade700,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessDialog(String filePath, String fileName) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Download Successful!',
      desc: 'Excel file "$fileName" saved successfully in Downloads folder!',
      btnOkText: 'OK',
      btnOkOnPress: () {},
      btnCancelText: "Share File",
      btnCancelOnPress: () {
        Share.shareXFiles([XFile(filePath)], subject: 'AMZDD Return Report');
      },
      dialogBackgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.green.shade700,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      descTextStyle: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          "Generate Report",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Report Info Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "AMZDD Return Report",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Last 7 Days Data",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Download Button
                Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : downloadScannedOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDownloading ? Colors.grey[400] : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isDownloading ? Icons.hourglass_empty : Icons.download,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          _isDownloading ? "Generating..." : "Download Excel Report",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Progress Indicator
                if (_isDownloading)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 8.0,
                          percent: _downloadProgress,
                          center: Text(
                            "${(_downloadProgress * 100).toInt()}%",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          backgroundColor: Colors.grey[300]!,
                          progressColor: Colors.blue,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _getProgressText(_downloadProgress),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getProgressText(double progress) {
    if (progress < 0.2) return "Connecting to server...";
    if (progress < 0.4) return "Fetching data...";
    if (progress < 0.6) return "Processing orders...";
    if (progress < 0.8) return "Creating Excel file...";
    if (progress < 1.0) return "Saving file...";
    return "Complete!";
  }
}