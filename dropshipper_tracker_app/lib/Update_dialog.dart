import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'update.dart';

class SimpleUpdateDialog extends StatefulWidget {
  final String imageUrl;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String description;
  final bool isMandatory;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onLaterPressed;

  const SimpleUpdateDialog({
    Key? key,
    required this.imageUrl,
    required this.currentVersion,
    required this.latestVersion,
    this.title = 'Update Available',
    this.description = 'A new version of the app is available with exciting features and improvements.',
    this.isMandatory = true,
    this.onUpdatePressed,
    this.onLaterPressed,
  }) : super(key: key);

  @override
  State<SimpleUpdateDialog> createState() => _SimpleUpdateDialogState();
}

class _SimpleUpdateDialogState extends State<SimpleUpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isImageLoading = true;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleUpdatePressed() {
    HapticFeedback.mediumImpact();
    if (widget.onUpdatePressed != null) {
      widget.onUpdatePressed!();
    } else {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SimpleUpdateScreenView()),
      );
    }
  }

  void _handleLaterPressed() {
    HapticFeedback.lightImpact();
    if (widget.onLaterPressed != null) {
      widget.onLaterPressed!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildContent(),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.blue,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isMandatory ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isMandatory ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isMandatory ? Icons.priority_high : Icons.check_circle,
                        size: 14,
                        color: widget.isMandatory ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isMandatory ? 'Required' : 'Optional',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isMandatory ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            widget.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Version comparison
          _buildVersionComparison(),

          const SizedBox(height: 20),

          // Update image
          if (widget.imageUrl.isNotEmpty) _buildUpdateImage(),
        ],
      ),
    );
  }

  Widget _buildVersionComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Current version
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Current',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.currentVersion,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Arrow
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward,
              size: 20,
              color: Colors.blue,
            ),
          ),

          // Latest version
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Latest',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.new_releases,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.latestVersion,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateImage() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Loading indicator
            if (_isImageLoading)
              Container(
                color: Colors.grey.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),

            // Image
            Image.network(
              widget.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isImageLoading = false);
                  });
                  return child;
                }
                return const SizedBox.shrink();
              },
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isImageLoading = false;
                      _hasImageError = true;
                    });
                  }
                });
                return Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.black38,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preview not available',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Update button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handleUpdatePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                'Update Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Later button (only if not mandatory)
          if (!widget.isMandatory) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _handleLaterPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Static method to show the dialog
  static Future<void> show(
      BuildContext context, {
        required String imageUrl,
        required String currentVersion,
        required String latestVersion,
        String title = 'Update Available',
        String description = 'A new version of the app is available with exciting features and improvements.',
        bool isMandatory = true,
        VoidCallback? onUpdatePressed,
        VoidCallback? onLaterPressed,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => SimpleUpdateDialog(
        imageUrl: imageUrl,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        title: title,
        description: description,
        isMandatory: isMandatory,
        onUpdatePressed: onUpdatePressed,
        onLaterPressed: onLaterPressed,
      ),
    );
  }
}
