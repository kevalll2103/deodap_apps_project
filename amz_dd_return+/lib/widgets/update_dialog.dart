import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amz/view/updatescreen_view.dart';
import 'dart:math' as math;

class UpdateDialog extends StatefulWidget {
  final String imageUrl;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String description;
  final bool isMandatory;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onLaterPressed;

  const UpdateDialog({
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
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _rotationController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  bool _isImageLoading = true;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Main animation controller for dialog entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Pulse animation for update button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Shimmer animation for loading states
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Particle animation for background effects
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Rotation animation for icon
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Glow animation for borders
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Scale animation with elastic effect
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Slide animation from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    // Pulse animation with smooth curves
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat(reverse: true);
    _particleController.repeat();
    _rotationController.repeat();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
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
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const UpdateScreenView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
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
        return Stack(
          children: [
            // Animated background overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // Main dialog
            Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(24),
                      child: _buildDialogContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
          // Glow effect
          BoxShadow(
            color: Colors.blue.withOpacity(0.3 * _glowAnimation.value),
            blurRadius: 30 * _glowAnimation.value,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF8FAFC),
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated particles background
              _buildParticlesBackground(),

              // Main content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildContent(),
                  _buildActions(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticlesBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: DialogParticlesPainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.purple.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          // Animated icon container
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.purple.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.1, // Subtle rotation
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 20),

          // Title and badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with shimmer effect
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Colors.black87,
                            Colors.blue,
                            Colors.black87,
                          ],
                          stops: [
                            (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Status badge with glow
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isMandatory
                              ? [Colors.red.withOpacity(0.3), Colors.orange.withOpacity(0.3)]
                              : [Colors.green.withOpacity(0.3), Colors.teal.withOpacity(0.3)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isMandatory ? Colors.red : Colors.green)
                                .withOpacity(0.4 * _glowAnimation.value),
                            blurRadius: 10 * _glowAnimation.value,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isMandatory ? Icons.priority_high_rounded : Icons.check_circle_rounded,
                            color: widget.isMandatory ? Colors.red : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isMandatory ? 'Required' : 'Optional',
                            style: GoogleFonts.poppins(
                              color: widget.isMandatory ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            widget.description,
            style: GoogleFonts.poppins(
              color: Colors.black54,
              fontSize: 16,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // Enhanced Version Information
          _buildVersionInfo(),

          const SizedBox(height: 24),

          // Update Image with enhanced effects
          _buildUpdateImage(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.blue.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                      Icons.phone_android_rounded,
                      color: Colors.black54,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Current Version',
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.currentVersion,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Arrow with pulse animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_pulseAnimation.value - 1.0) * 0.2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              );
            },
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
                      'Latest Version',
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.new_releases_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.latestVersion,
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
    if (widget.imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Shimmer loading effect
            if (_isImageLoading)
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey.withOpacity(0.1),
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.1),
                        ],
                        stops: [
                          (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                          _shimmerAnimation.value.clamp(0.0, 1.0),
                          (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Actual image with enhanced loading
            Image.network(
              "${widget.imageUrl}?ts=${DateTime.now().millisecondsSinceEpoch}",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isImageLoading = false);
                    }
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
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          size: 48,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preview not available',
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Overlay gradient for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Enhanced Update Button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF1D4ED8),
                        Color(0xFF1E40AF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleUpdatePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.download_for_offline_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Update Now',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Later Button (only if not mandatory)
          if (!widget.isMandatory) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _handleLaterPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(
                Icons.schedule_rounded,
                color: Colors.black54,
                size: 20,
              ),
              label: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Static method to show the update dialog with enhanced transitions
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
    return showGeneralDialog(
      context: context,
      barrierDismissible: !isMandatory,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => UpdateDialog(
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

// Custom painter for animated particles in the dialog background
class DialogParticlesPainter extends CustomPainter {
  final double animationValue;

  DialogParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final particleCount = 15;
    final random = math.Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = math.sin(animationValue * 2 * math.pi + i) * 5;
      final opacity = (math.sin(animationValue * 2 * math.pi + i * 0.5) + 1) * 0.1;

      paint.color = Colors.blue.withOpacity(opacity * 2);

      canvas.drawCircle(
        Offset(x, y + offset),
        random.nextDouble() * 2 + 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}