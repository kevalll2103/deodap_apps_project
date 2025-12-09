import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amz/view/dropshipper/loginscreen_dropshipper_view.dart';
import 'package:amz/view/employee/loginscreen_employee_view.dart';

class AccountTypescreenView extends StatefulWidget {
  const AccountTypescreenView({super.key});

  @override
  State<AccountTypescreenView> createState() => _AccountTypescreenViewState();
}

class _AccountTypescreenViewState extends State<AccountTypescreenView>
    with TickerProviderStateMixin {
  int? _selectedAccountType;
  bool _isAnimating = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _selectAccountType(int accountType) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedAccountType = accountType;
      _isAnimating = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (accountType == 0) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreenDropshipperView(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreenAdminView(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }

        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _selectedAccountType = null;
              _isAnimating = false;
            });
          }
        });
      }
    });
  }

  Widget _buildAccountTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required int accountType,
    required bool isSelected,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => _selectAccountType(accountType),
        onTapDown: (_) {
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.1),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? primaryColor.withOpacity(0.25)
                    : Colors.black.withOpacity(0.08),
                blurRadius: isSelected ? 25 : 15,
                offset: const Offset(0, 10),
                spreadRadius: isSelected ? 3 : 1,
              ),
              if (isSelected)
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: 5,
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with simplified styling
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [primaryColor, secondaryColor]
                        : [
                      primaryColor.withOpacity(0.15),
                      secondaryColor.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                      : [],
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: isSelected ? Colors.white : primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : const Color(0xFF2D3748),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Selection indicator
              Container(
                height: 6,
                width: isSelected ? 80 : 0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Check mark for selected state
              Opacity(
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              // Add profile functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Deodap International',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFF667eea).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Enhanced header
                    _buildHeaderSection(),

                    const SizedBox(height: 45),

                    // Account type cards
                    _buildAccountTypeCard(
                      title: "Dropshipper",
                      subtitle: "Manage your dropshipping business\nand track orders efficiently",
                      icon: Icons.storefront_rounded,
                      primaryColor: const Color(0xFF3B82F6),
                      secondaryColor: const Color(0xFF1D4ED8),
                      accountType: 0,
                      isSelected: _selectedAccountType == 0,
                    ),

                    const SizedBox(height: 24),

                    _buildAccountTypeCard(
                      title: "Employee",
                      subtitle: "Access staff dashboard and\nmanage daily operations",
                      icon: Icons.admin_panel_settings_rounded,
                      primaryColor: const Color(0xFF10B981),
                      secondaryColor: const Color(0xFF059669),
                      accountType: 1,
                      isSelected: _selectedAccountType == 1,
                    ),

                    const SizedBox(height: 35),

                    // Enhanced footer
                    _buildFooterSection(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Enhanced welcome text with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'Welcome Back!',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Enhanced subtitle with glassmorphism
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            "Choose your account type to continue",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Need Help?",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Select 'Dropshipper' if you manage products and orders.\nSelect 'Employee' if you're part of the operations team.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Company website link
          GestureDetector(
            onTap: () {
              // You can add URL launcher functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visit: https://deodap.in/'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'deodap.in',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}