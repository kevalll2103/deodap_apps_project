import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:math' as math;

class UpdateScreenView extends StatefulWidget {
  final Map<String, dynamic>? updateData;

  const UpdateScreenView({
    super.key,
    this.updateData,
  });

  @override
  State<UpdateScreenView> createState() => _UpdateScreenViewState();
}

class _UpdateScreenViewState extends State<UpdateScreenView>
    with TickerProviderStateMixin {

  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _buttonController;
  late AnimationController _rocketController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _rocketBounceAnimation;
  late Animation<double> _rocketRotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  // State variables
  String shareLink = '';
  bool isLoading = true;
  bool hasError = false;
  bool isUpdating = false;
  String currentVersion = '';
  String latestVersion = '';
  String updateTitle = '';
  String updateDescription = '';
  String releaseNotes = '';
  bool isMandatory = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initVersion();
  }

  void _setupAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Rocket animation controller
    _rocketController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Shimmer animation controller
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Fade animation with custom curve
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Slide animation with bounce
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    // Scale animation with spring effect
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Button scale animation
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    // Rocket bounce with sine wave
    _rocketBounceAnimation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _rocketController,
      curve: Curves.easeInOut,
    ));

    // Rocket rotation animation
    _rocketRotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rocketController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
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

    // Start repeating animations
    _rocketController.repeat(reverse: true);
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat(reverse: true);
  }

  Future<void> _initVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;

      if (widget.updateData != null) {
        _processUpdateData(widget.updateData!);
      } else {
        await _fetchUpdateStatus();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _processUpdateData(Map<String, dynamic> data) {
    setState(() {
      shareLink = data['apk_url'] ?? data['download_url'] ?? '';
      latestVersion = data['latest_version'] ?? 'Unknown';
      updateTitle = data['update_title'] ?? 'Update Available';
      updateDescription = data['update_description'] ?? 'A new version is available with improvements and bug fixes.';
      releaseNotes = data['release_notes'] ?? '';
      isMandatory = data['is_mandatory'] ?? true;
      isLoading = false;
      hasError = false;
    });

    _mainController.forward();
  }

  Future<void> _fetchUpdateStatus() async {
    try {
      final response = await http.post(
        Uri.parse('https://customprint.deodap.com/api_amzDD_return/checkupdate.php'),
        body: {
          'version': currentVersion,
          'role': 'admin',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            shareLink = data['apk_url'] ?? data['download_url'] ?? '';
            latestVersion = data['latest_version'] ?? 'Unknown';
            isLoading = false;
            hasError = false;
          });

          _mainController.forward();
        } else {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _launchUpdateLink() async {
    if (shareLink.isEmpty) return;

    setState(() {
      isUpdating = true;
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final url = Uri.parse(shareLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar("Could not launch update link");
      }
    } catch (e) {
      _showErrorSnackBar("Error opening update link: $e");
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _exitApp() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Exit App',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isMandatory
              ? 'This update is required to continue using the app. Do you want to exit?'
              : 'Are you sure you want to exit the app?',
          style: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _buttonController.dispose();
    _rocketController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildAnimatedBackground(),
            SafeArea(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    } else if (hasError) {
      return _buildErrorState();
    } else {
      return _buildUpdateContent();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Checking for updates...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Failed to load update information",
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              _fetchUpdateStatus();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateContent() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Enhanced Rocket Animation
                  _buildRocketAnimation(),

                  const SizedBox(height: 32),

                  // Enhanced Title with Shimmer Effect
                  _buildShimmerTitle(),

                  const SizedBox(height: 32),

                  // Enhanced Content Card
                  _buildContentCard(),

                  const SizedBox(height: 40),

                  // Enhanced Update Button
                  _buildUpdateButton(),

                  const SizedBox(height: 20),

                  // Enhanced Action Button
                  _buildActionButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRocketAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rocketController, _pulseController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _rocketBounceAnimation.value),
          child: Transform.rotate(
            angle: _rocketRotateAnimation.value,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600.withOpacity(0.3),
                      Colors.purple.shade600.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse effect
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.blue.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Rocket Image
                    Image.asset(
                      'assets/images/rocket_image.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerTitle() {
    return AnimatedBuilder(
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
            updateTitle.isNotEmpty ? updateTitle : '🚀 New Version Available! 🚀',
            style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dear user,",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            updateDescription.isNotEmpty
                ? updateDescription
                : "We are thrilled to inform you that a brand-new version of our application has been released! This update brings exciting new features and enhancements.",
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "✨ What's New?",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          if (releaseNotes.isNotEmpty) ...[
            ...releaseNotes.split('\n').map((note) =>
            note.trim().isNotEmpty ? _buildFeatureItem(note.trim()) : const SizedBox.shrink()
            ).toList(),
          ] else ...[
            _buildFeatureItem("Enjoy a smoother and faster experience"),
            _buildFeatureItem("Explore fresh functionalities to ease your tasks"),
            _buildFeatureItem("Improved stability and bug fixes"),
            _buildFeatureItem("Enhanced security and performance"),
          ],
          const SizedBox(height: 24),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800.withOpacity(0.3),
            Colors.purple.shade800.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Version",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentVersion,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.blue),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Latest Version",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latestVersion,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade700,
                  Colors.blue.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (shareLink.isNotEmpty && !isUpdating)
                  ? () {
                _buttonController.forward().then((_) {
                  _buttonController.reverse();
                });
                _launchUpdateLink();
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: isUpdating
                  ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Update Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return TextButton.icon(
      onPressed: isMandatory ? _exitApp : () => Navigator.pop(context),
      icon: Icon(
        isMandatory ? Icons.exit_to_app_rounded : Icons.schedule_rounded,
        color: Colors.black54,
        size: 20,
      ),
      label: Text(
        isMandatory ? 'Exit App' : 'Maybe Later',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final particleCount = 20;
    final random = math.Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = math.sin(animationValue * 2 * math.pi + i) * 10;

      canvas.drawCircle(
        Offset(x, y + offset),
        random.nextDouble() * 3 + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}