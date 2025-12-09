import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

class SimpleUpdateScreenView extends StatefulWidget {
  final Map<String, dynamic>? updateData;

  const SimpleUpdateScreenView({
    super.key,
    this.updateData,
  });

  @override
  State<SimpleUpdateScreenView> createState() => _SimpleUpdateScreenViewState();
}

class _SimpleUpdateScreenViewState extends State<SimpleUpdateScreenView>
    with SingleTickerProviderStateMixin {

  // Single animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _setupAnimation();
    _initVersion();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
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
      updateDescription = data['update_description'] ??
          'A new version is available with improvements and bug fixes.';
      releaseNotes = data['release_notes'] ?? '';
      isMandatory = data['is_mandatory'] ?? true;
      isLoading = false;
      hasError = false;
    });

    _animationController.forward();
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
            updateTitle = data['update_title'] ?? 'Update Available';
            updateDescription = data['update_description'] ??
                'A new version is available with improvements and bug fixes.';
            releaseNotes = data['release_notes'] ?? '';
            isMandatory = data['is_mandatory'] ?? true;
            isLoading = false;
            hasError = false;
          });

          _animationController.forward();
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
        backgroundColor: Colors.red,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Exit App'),
          ],
        ),
        content: Text(
          isMandatory
              ? 'This update is required to continue using the app. Do you want to exit?'
              : 'Are you sure you want to exit the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !isMandatory
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 24),
          Text(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Failed to load update information",
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _fetchUpdateStatus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Update Icon
              _buildUpdateIcon(),

              const SizedBox(height: 32),

              // Title
              _buildTitle(),

              const SizedBox(height: 32),

              // Content Card
              _buildContentCard(),

              const SizedBox(height: 32),

              // Update Button
              _buildUpdateButton(),

              const SizedBox(height: 16),

              // Action Button
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: const Icon(
        Icons.system_update_rounded,
        size: 80,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      updateTitle.isNotEmpty ? updateTitle : '🚀 New Version Available! 🚀',
      style: const TextStyle(
        fontSize: 24,
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            "Dear user,",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            updateDescription.isNotEmpty
                ? updateDescription
                : "We are excited to inform you that a new version of our application is available! "
                "This update includes exciting new features and important improvements.",
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "✨ What's New?",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (releaseNotes.isNotEmpty) ...[
            ...releaseNotes.split('\n')
                .where((note) => note.trim().isNotEmpty)
                .map((note) => _buildFeatureItem(note.trim()))
                .toList(),
          ] else ...[
            _buildFeatureItem("Improved performance and stability"),
            _buildFeatureItem("New features and enhancements"),
            _buildFeatureItem("Bug fixes and security updates"),
            _buildFeatureItem("Better user experience"),
          ],
          const SizedBox(height: 20),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Current Version",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                currentVersion,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Latest Version",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                latestVersion,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: (shareLink.isNotEmpty && !isUpdating) ? _launchUpdateLink : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        icon: isUpdating
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.download_rounded),
        label: Text(
          isUpdating ? "Updating..." : "Update Now",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return TextButton.icon(
      onPressed: isMandatory ? _exitApp : () => Navigator.pop(context),
      icon: Icon(
        isMandatory ? Icons.exit_to_app : Icons.schedule,
        color: Colors.black54,
        size: 18,
      ),
      label: Text(
        isMandatory ? 'Exit App' : 'Maybe Later',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
