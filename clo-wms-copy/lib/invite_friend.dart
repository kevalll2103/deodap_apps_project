import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteFriendscreenEmpView extends StatefulWidget {
  const InviteFriendscreenEmpView({super.key});

  @override
  State<InviteFriendscreenEmpView> createState() => _InviteFriendscreenEmpViewState();
}

class _InviteFriendscreenEmpViewState extends State<InviteFriendscreenEmpView>
    with TickerProviderStateMixin {

  // iOS Color constants
  static const Color primaryBlue = Color(0xFF007AFF); // iOS blue
  static const Color backgroundColor = Color(0xFFF2F2F7); // iOS background
  static const Color cardColor = CupertinoColors.white;
  static const Color textColor = CupertinoColors.black;
  static const Color secondaryTextColor = CupertinoColors.systemGrey;

  // Static drive link instead of API
  final String shareLink = 'https://drive.google.com/file/d/1abc123xyz789/view?usp=sharing';

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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('Link copied to clipboard!', isSuccess: true);
  }

  void _shareLink() {
    Share.share(shareLink, subject: 'Join CustomPrint!');
  }

  void _showToast(String message, {bool isSuccess = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 100,
        child: _IOSToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showResetDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text(
            'Reset QR Code?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              decoration: TextDecoration.none,
            ),
          ),
          content: const Text(
            'Your existing QR code will no longer work. This action cannot be undone.',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: -0.1,
              decoration: TextDecoration.none,
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text(
                'Keep Current',
                style: TextStyle(
                  letterSpacing: -0.1,
                  decoration: TextDecoration.none,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text(
                'Reset QR Code',
                style: TextStyle(
                  letterSpacing: -0.1,
                  decoration: TextDecoration.none,
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

    // Simulate reset process
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isResetting = false;
    });

    _showToast('QR Code reset successfully!', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: cardColor,
        middle: const Text(
          'Invite a Friend',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            decoration: TextDecoration.none,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.share, color: primaryBlue),
              onPressed: _shareLink,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.ellipsis_circle, color: primaryBlue),
              onPressed: () => _showActionSheet(context),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // QR Code Section
                  _IOSCard(
                    child: Column(
                      children: [
                        const _SectionHeader(
                          icon: CupertinoIcons.qrcode,
                          title: 'QR-Code',
                        ),
                        const SizedBox(height: 24),

                        // QR Code Container
                        Container(
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryBlue.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/qr.png',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 200,
                                            height: 200,
                                            color: backgroundColor,
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.exclamationmark_triangle,
                                                  color: CupertinoColors.systemRed,
                                                  size: 32,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'QR not found',
                                                  style: TextStyle(
                                                    color: secondaryTextColor,
                                                    fontSize: 12,
                                                    letterSpacing: -0.1,
                                                    decoration: TextDecoration.none,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
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

                  const SizedBox(height: 24),

                  // Share Link Section - Simplified
                  _IOSCard(
                    child: Column(
                      children: [
                        const _SectionHeader(
                          icon: CupertinoIcons.share,
                          title: 'Link',
                        ),
                        const SizedBox(height: 24),

                        // Share Link Input
                        Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    shareLink,
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      letterSpacing: -0.1,
                                      decoration: TextDecoration.none,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.all(8),
                                  minSize: 0,
                                  child: const Icon(
                                    CupertinoIcons.doc_on_doc,
                                    color: cardColor,
                                    size: 16,
                                  ),
                                  onPressed: () => _copyToClipboard(shareLink),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                      // Action Buttons - Only Share and Copy (icons only)
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: const Icon(CupertinoIcons.share, size: 20, color: CupertinoColors.white),
                              onPressed: _shareLink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: const Icon(
                                CupertinoIcons.doc_on_doc,
                                size: 20,
                                color: primaryBlue,
                              ),
                              onPressed: () => _copyToClipboard(shareLink),
                            ),
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

                      void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(
          'QR Code Options',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: -0.1,
            decoration: TextDecoration.none,
          ),
        ),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: const Text(
              'Reset QR Code',
              style: TextStyle(
                color: CupertinoColors.systemRed,
                letterSpacing: -0.1,
                decoration: TextDecoration.none,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showResetDialog(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text(
            'Cancel',
            style: TextStyle(
              letterSpacing: -0.1,
              decoration: TextDecoration.none,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// iOS-style Card Widget
class _IOSCard extends StatelessWidget {
  final Widget child;

  const _IOSCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// iOS-style Section Header
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF007AFF),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: CupertinoColors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

// iOS-style Toast
class _IOSToast extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _IOSToast({
    required this.message,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSuccess ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.exclamationmark_circle_fill,
              color: CupertinoColors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
