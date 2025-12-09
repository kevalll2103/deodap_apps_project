import 'package:flutter/material.dart';
import 'package:amz/view/employee/homescreen_employee_view.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class InviteFriendscreenDropshipperView extends StatefulWidget {
  const InviteFriendscreenDropshipperView({super.key});

  @override
  State<InviteFriendscreenDropshipperView> createState() => _InviteFriendscreenEmpViewState();
}

class _InviteFriendscreenEmpViewState extends State<InviteFriendscreenDropshipperView>
    with TickerProviderStateMixin {
  // Color constants - matching the design system
  static const Color primaryColor = Color(0xFF1565C0); // Same as Colors.blue[800]

  static const Color secondaryColor = Colors.blueAccent;
  static const Color accentColor = Colors.blue;
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;

  String? imageUrl;
  String? shareLink;
  bool isLoading = true;
  bool isResetting = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://customprint.deodap.com/invite_friend.php'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-App/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            imageUrl = data['screen']['image_url'];
            shareLink = data['screen']['link'];
            isLoading = false;
          });
        } else {
          _showErrorMessage('Failed to load data');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        _showErrorMessage('Server error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Network error: Unable to connect');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: cardColor, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Link copied to clipboard!',
              style: TextStyle(color: cardColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareLink() {
    if (shareLink != null) {
      Share.share(shareLink!, subject: 'Join CustomPrint!');
    } else {
      _showErrorMessage('Share link not available');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: cardColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: cardColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: warningColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Reset QR Code?',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your existing QR code will no longer work. This action cannot be undone.',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Keep Current',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Reset QR Code',
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _resetQRCode();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetQRCode() async {
    setState(() {
      isResetting = true;
    });

    // Show loading overlay
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Resetting...',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    try {
      await Future.delayed(const Duration(seconds: 2));
      await fetchData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: cardColor, size: 20),
              SizedBox(width: 12),
              Text(
                'QR Code reset successfully!',
                style: TextStyle(color: cardColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      _showErrorMessage('Failed to reset QR code');
    } finally {
      overlayEntry.remove();
      setState(() {
        isResetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Invite a Friend",
          style: TextStyle(
            color: cardColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: cardColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: cardColor),
            onPressed: _shareLink,
            tooltip: 'Share Link',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: cardColor),
            color: Colors.grey[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'Reset QR Code') {
                _showConfirmationDialog(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Reset QR Code',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: cardColor, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Reset QR Code',
                        style: TextStyle(
                          color: cardColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // QR Code Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Your QR Code",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 3,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // QR Code Container
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: isLoading
                            ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading QR Code...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageUrl != null
                                        ? Image.network(
                                      imageUrl!,
                                      width: 220,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 220,
                                          height: 220,
                                          color: backgroundColor,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 220,
                                          height: 220,
                                          color: backgroundColor,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error, color: errorColor, size: 40),
                                              SizedBox(height: 8),
                                              Text('Failed to load QR'),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                        : Container(
                                      width: 220,
                                      height: 220,
                                      color: backgroundColor,
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_2, color: Colors.grey, size: 40),
                                          SizedBox(height: 8),
                                          Text('QR Code not available'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Share Link Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.share,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Share Link",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 3,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Share Link Input
                      Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: shareLink ?? 'Loading share link...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 20.0,
                            ),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.copy, color: cardColor, size: 20),
                                onPressed: shareLink != null
                                    ? () => _copyToClipboard(shareLink!)
                                    : null,
                                tooltip: 'Copy Link',
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: shareLink != null ? _shareLink : null,
                              icon: const Icon(Icons.share, size: 20),
                              label: const Text('Share Link'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: cardColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: shareLink != null
                                  ? () => _copyToClipboard(shareLink!)
                                  : null,
                              icon: const Icon(Icons.copy, size: 20),
                              label: const Text('Copy'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Privacy Notice',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "This QR code is private and unique to you. Share it only with trusted contacts who need access to your CustomPrint application.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}