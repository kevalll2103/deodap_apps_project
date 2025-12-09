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

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> with TickerProviderStateMixin {
  // Color constants - matching the design system
  static const Color primaryColor = Color(0xFF1565C0); // This is Colors.blue[800]

  static const Color secondaryColor = Colors.blueAccent;
  static const Color accentColor = Colors.blue;
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    // Start pulse animation for download button
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatImageUrls(dynamic images) {
    try {
      if (images == null) return '';

      if (images is List) {
        return images
            .map((img) => img.toString().trim())
            .where((url) => url.isNotEmpty)
            .join(',');
      } else if (images is String) {
        return images
            .split(',')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .join(',');
      }

      return images.toString().trim();
    } catch (e) {
      return '';
    }
  }

  Future<void> downloadScannedOrders() async {
    // Button press animation
    _scaleController.forward().then((_) => _scaleController.reverse());

    // Stop pulse animation when downloading
    _pulseController.stop();

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

      // Update the URL to include the date range
      final url = 'https://customprint.deodap.com/api_amzDD_return/report_emp.php?start_date=$startDateString&end_date=$endDateString';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App/1.0',
        },
      ).timeout(const Duration(seconds: 30));

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
        headerStyle.backColor = '#2196F3';
        headerStyle.fontColor = '#FFFFFF';
        headerStyle.fontSize = 12;
        headerStyle.hAlign = xls.HAlignType.center;
        headerStyle.vAlign = xls.VAlignType.center;

        final xls.Style dataStyle = workbook.styles.add('DataStyle');
        dataStyle.fontSize = 11;
        dataStyle.wrapText = true;
        dataStyle.vAlign = xls.VAlignType.top;

        // Define headers
        List<String> headers = [
          "ID", "Seller ID", "Seller Name", "CRN", "Amazon Order ID", "Tracking ID",
          "OTP", "Out For Delivery Date", "Status", "Bad/Good", "Images",
          "Sticker Photo", "Unbox Photo", "Remarks", "Dropshipper Created At",
          "Deodap-Emp Updated At"
        ];

        // Set headers
        for (int i = 0; i < headers.length; i++) {
          final cell = sheet.getRangeByIndex(1, i + 1);
          cell.setText(headers[i]);
          cell.cellStyle = headerStyle;
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

            // Set data with null safety
            sheet.getRangeByIndex(row, 1).setText(order['id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 2).setText(order['seller_id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 3).setText(order['seller_name']?.toString() ?? '');
            sheet.getRangeByIndex(row, 4).setText(order['crn']?.toString() ?? '');
            sheet.getRangeByIndex(row, 5).setText(order['amazon_order_id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 6).setText(order['return_tracking_id']?.toString() ?? '');
            sheet.getRangeByIndex(row, 7).setText(order['otp']?.toString() ?? '');
            sheet.getRangeByIndex(row, 8).setText(order['out_for_delivery_date']?.toString() ?? '');
            sheet.getRangeByIndex(row, 9).setText(order['status']?.toString() ?? '');
            sheet.getRangeByIndex(row, 10).setText(order['bad_good_return']?.toString() ?? '');
            sheet.getRangeByIndex(row, 11).setText(images);
            sheet.getRangeByIndex(row, 12).setText(stickerPhoto);
            sheet.getRangeByIndex(row, 13).setText(unboxPhoto);
            sheet.getRangeByIndex(row, 14).setText(order['remarks']?.toString() ?? '');
            sheet.getRangeByIndex(row, 15).setText(order['created_at']?.toString() ?? '');
            sheet.getRangeByIndex(row, 16).setText(order['updated_at']?.toString() ?? '');

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
          // Set minimum width for image columns
          if (i >= 11 && i <= 13) {
            sheet.getRangeByIndex(1, i, row - 1, i).columnWidth = 25;
          }
        }

        // Set row height for better visibility
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

    // Restart pulse animation when not downloading
    if (!_isDownloading) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _showErrorMessage(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: cardColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: cardColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? warningColor : errorColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
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
      dialogBackgroundColor: cardColor,
      titleTextStyle: GoogleFonts.poppins(
        color: successColor,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      descTextStyle: GoogleFonts.poppins(
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: cardColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: cardColor.withOpacity(0.1),
            shape: const CircleBorder(),
          ),
        ),
        title: Text(
          "Generate Report",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cardColor,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isDownloading)
            IconButton(
              onPressed: downloadScannedOrders,
              icon: const Icon(Icons.refresh, color: cardColor),
              tooltip: 'Refresh Report',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Report Info Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.1),
                                secondaryColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            size: 48,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "AMZDD Return Report",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.1),
                                secondaryColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Last 7 Days Data",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoItem(Icons.calendar_today, "Period", "Weekly"),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            _buildInfoItem(Icons.file_download, "Format", "Excel"),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            _buildInfoItem(Icons.share, "Share", "Enabled"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Download Button
                  AnimatedBuilder(
                    animation: Listenable.merge([_buttonScaleAnimation, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScaleAnimation.value * (_isDownloading ? 1.0 : _pulseAnimation.value),
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDownloading
                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                  : [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _isDownloading
                                    ? Colors.grey.withOpacity(0.3)
                                    : primaryColor.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isDownloading ? null : downloadScannedOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isDownloading
                                      ? Icons.hourglass_empty
                                      : Icons.download_rounded,
                                  color: cardColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isDownloading ? "Generating Report..." : "Download Excel Report",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: cardColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Progress Indicator
                  if (_isDownloading)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 80.0,
                            lineWidth: 10.0,
                            percent: _downloadProgress,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${(_downloadProgress * 100).toInt()}%",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  "Progress",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.grey.shade200,
                            progressColor: primaryColor,
                            circularStrokeCap: CircularStrokeCap.round,
                            animation: true,
                            animationDuration: 300,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.1),
                                  secondaryColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getProgressText(_downloadProgress),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Features List
                  if (!_isDownloading)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Report Features",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFeatureItem(Icons.table_chart, "Comprehensive Excel Format", "Well-structured data with proper formatting"),
                          _buildFeatureItem(Icons.image, "Image URLs Included", "All product images and photos included"),
                          _buildFeatureItem(Icons.share, "Easy Sharing Options", "Share reports instantly with team members"),
                          _buildFeatureItem(Icons.security, "Secure Data Export", "Protected data handling and encryption"),
                          _buildFeatureItem(Icons.schedule, "Weekly Reports", "Automated 7-day data collection"),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressText(double progress) {
    if (progress < 0.2) return "🔗 Connecting to server...";
    if (progress < 0.4) return "📥 Fetching order data...";
    if (progress < 0.6) return "⚙️ Processing orders...";
    if (progress < 0.8) return "📊 Creating Excel file...";
    if (progress < 1.0) return "💾 Saving to device...";
    return "✅ Report generated successfully!";
  }
}