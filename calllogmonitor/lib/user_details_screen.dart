import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'theme/app_theme.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  // User data
  String _userName = 'Loading...';
  String _userMobile = 'Loading...';
  String _userId = 'Loading...';
  String _userWarehouse = 'Not assigned';
  String _warehouseNumber = '';
  String _deviceNumber = 'Loading...';
  String _userSelectedSim = 'SIM 1';
  bool _isRegistered = false;
  String? _profileImagePath;
  
  // Executive data
  bool _isExecutiveLoggedIn = false;
  String _executiveName = '';
  String _executiveUsername = '';
  String _executiveWarehouse = '';
  String _executiveWarehouseId = '';

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  // Single animation controller for essential animations only
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    // Simple fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Check if executive is logged in
        _isExecutiveLoggedIn = prefs.getBool('is_executive_logged_in') ?? false;

        if (_isExecutiveLoggedIn) {
          // Load executive data
          _executiveName = prefs.getString('executive_name') ?? '';
          _executiveUsername = prefs.getString('executive_username') ?? '';
          _executiveWarehouse = prefs.getString('executive_warehouse_label') ?? '';
          _executiveWarehouseId = prefs.getString('executive_warehouse_id') ?? '';

          // Use executive data for display
          _userName = _executiveName.isNotEmpty ? _executiveName : _executiveUsername;
          _userMobile = _executiveUsername;
          _userWarehouse = _executiveWarehouse;
          _deviceNumber = _executiveUsername;
          _isRegistered = true; // Executives are always considered registered
        } else {
          // Load regular user data
          _userName = prefs.getString('user_name') ?? 'Guest';
          _userMobile = prefs.getString('mobile_number') ?? 'Not available';
          _userId = prefs.getInt('user_id')?.toString() ?? 'Not available';
          _userWarehouse = prefs.getString('warehouse_label') ?? 'Not assigned';
          _deviceNumber = _userMobile;
          _userSelectedSim = prefs.getString('selected_sim') ?? 'SIM 1';
          _isRegistered = prefs.getBool('is_registered') ?? false;
        }

        // Fetch warehouse number from SharedPreferences
        _warehouseNumber = prefs.getString('warehouse_number') ?? '';

        _profileImagePath = prefs.getString('profile_image_path');
        _isLoading = false;
      });

      // Start animations after data is loaded
      _startAnimations();
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      _startAnimations();
    }
  }

  void _startAnimations() {
    if (mounted) {
      _fadeController.forward();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', image.path);

        setState(() {
          _profileImagePath = image.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');

      setState(() {
        _profileImagePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image removed successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentBrown.withOpacity(0.9),
              AppTheme.primaryBrown.withOpacity(0.8),
              AppTheme.warmDark.withOpacity(0.7),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBrown.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Image
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImagePath != null
                        ? Image.file(
                      File(_profileImagePath!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                        : _buildDefaultAvatar(),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBrown,
                          AppTheme.accentBrown,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBrown.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () => _showImageOptions(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // User Name
            Text(
              _userName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),

            // Registration Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRegistered 
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (_isRegistered ? Colors.green : Colors.orange).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRegistered ? Icons.verified : Icons.pending,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExecutiveLoggedIn 
                        ? 'Executive Access' 
                        : (_isRegistered ? 'Verified Account' : 'Pending Verification'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.accentBrown, AppTheme.primaryBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _userName.isNotEmpty && _userName != 'Loading...'
              ? _userName[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.warmLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBrown,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppTheme.primaryBrown,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: AppTheme.primaryBrown),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text(
                  'Remove Picture',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    int index = 0,
  }) {
    // Special handling for SIM card
    if (title == 'Selected SIM') {
      return _buildSimCard(value, index);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? AppTheme.primaryBrown).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: (iconColor ?? AppTheme.primaryBrown).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Add subtle haptic feedback
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (iconColor ?? AppTheme.primaryBrown).withOpacity(0.1),
                        (iconColor ?? AppTheme.primaryBrown).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (iconColor ?? AppTheme.primaryBrown).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppTheme.primaryBrown,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Subtle arrow indicator
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimCard(String simValue, int index) {
    final isSim1 = simValue == 'SIM 1';
    final iconColor = isSim1 ? Colors.blue : Colors.green;
    final gradientColors = isSim1
        ? [Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade200]
        : [Colors.green.shade50, Colors.green.shade100, Colors.green.shade200];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: SimCardPatternPainter(iconColor.withOpacity(0.1)),
              ),
            ),
          ),
          
          // Lock icon
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock,
                size: 14,
                color: iconColor.withOpacity(0.8),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // SIM Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        iconColor.withOpacity(0.3),
                        iconColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.sim_card,
                    size: 28,
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: 20),

                // SIM Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered SIM Card',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        simValue,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: iconColor.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selected during registration',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.2),
                        iconColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 12,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Secured',
                        style: TextStyle(
                          color: iconColor.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.5,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryWarm,
        appBar: AppBar(
          title: const Text('User Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryBrown,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryWarm,
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(
            color: AppTheme.primaryBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBrown),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            _buildProfileSection(),

            const SizedBox(height: 24),

            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isExecutiveLoggedIn ? 'Executive Information' : 'Account Information',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User ID hidden for production (development only)
                  // _buildInfoCard(
                  //   icon: Icons.badge,
                  //   title: 'User ID',
                  //   value: _userId,
                  //   iconColor: Colors.blue,
                  //   index: 0,
                  // ),

                  if (_isExecutiveLoggedIn) ...[
                    _buildInfoCard(
                      icon: Icons.person,
                      title: 'Executive Name',
                      value: _executiveName.isNotEmpty ? _executiveName : 'Not available',
                      iconColor: Colors.blue,
                      index: 1,
                    ),

                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Mobile Number',
                      value: _executiveUsername,
                      iconColor: Colors.green,
                      index: 2,
                    ),

                    _buildInfoCard(
                      icon: Icons.warehouse,
                      title: 'Warehouse',
                      value: '$_executiveWarehouse (ID: $_executiveWarehouseId)',
                      iconColor: Colors.orange,
                      index: 3,
                    ),

                    if (_warehouseNumber.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.business,
                        title: 'Warehouse Number',
                        value: _warehouseNumber,
                        iconColor: Colors.blue,
                        index: 5,
                      ),

                    _buildInfoCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Role',
                      value: 'Executive',
                      iconColor: Colors.purple,
                      index: 4,
                    ),
                  ] else ...[
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Mobile Number',
                      value: _userMobile,
                      iconColor: Colors.green,
                      index: 1,
                    ),

                    _buildInfoCard(
                      icon: Icons.warehouse,
                      title: 'Warehouse',
                      value: _userWarehouse,
                      iconColor: Colors.orange,
                      index: 2,
                    ),

                    if (_warehouseNumber.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.business,
                        title: 'Warehouse Number',
                        value: _warehouseNumber,
                        iconColor: Colors.blue,
                        index: 5,
                      ),

                    _buildInfoCard(
                      icon: Icons.phone_android,
                      title: 'Device Number',
                      value: _deviceNumber,
                      iconColor: Colors.purple,
                      index: 3,
                    ),

                    _buildInfoCard(
                      icon: Icons.sim_card,
                      title: 'Selected SIM',
                      value: _userSelectedSim,
                      iconColor: _userSelectedSim == 'SIM 1' ? Colors.blue : Colors.green,
                      index: 4,
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

// Custom painter for SIM card background pattern
class SimCardPatternPainter extends CustomPainter {
  final Color color;
  
  SimCardPatternPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Draw subtle circuit-like pattern
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        final rect = Rect.fromLTWH(
          size.width * 0.7 + (i * 8.0),
          size.height * 0.2 + (j * 12.0),
          4,
          4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}