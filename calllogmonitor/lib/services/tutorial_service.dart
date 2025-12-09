import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialPrefix = 'tutorial_completed_';
  
  // Tutorial keys for different features (updated for enhanced tutorials)
  static const String homeScreenTutorial = 'home_screen';
  static const String callHistoryTutorial = 'call_history';
  static const String registrationTutorial = 'registration';
  static const String permissionsTutorial = 'permissions';
  static const String drawerTutorial = 'drawer';
  static const String firstAppLaunch = 'first_app_launch';
  
  // Tutorial completion tracking
  static const String initialSyncCompleted = 'initial_sync_completed';
  static const String allTutorialsCompleted = 'all_tutorials_completed';

  // Check if tutorial has been completed
  static Future<bool> isTutorialCompleted(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_tutorialPrefix$tutorialKey') ?? false;
  }

  // Mark tutorial as completed
  static Future<void> markTutorialCompleted(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_tutorialPrefix$tutorialKey', true);
  }

  // Reset all tutorials (for testing)
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_tutorialPrefix));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }

  // Check if this is the first app launch
  static Future<bool> isFirstAppLaunch() async {
    return !(await isTutorialCompleted(firstAppLaunch));
  }

  // Mark first app launch as completed
  static Future<void> markFirstAppLaunchCompleted() async {
    await markTutorialCompleted(firstAppLaunch);
  }

  // Check if initial sync has been completed
  static Future<bool> isInitialSyncCompleted() async {
    return await isTutorialCompleted(initialSyncCompleted);
  }

  // Mark initial sync as completed
  static Future<void> markInitialSyncCompleted() async {
    await markTutorialCompleted(initialSyncCompleted);
  }

  // Check if all tutorials have been completed
  static Future<bool> areAllTutorialsCompleted() async {
    final tutorials = [
      permissionsTutorial,
      registrationTutorial,
      callHistoryTutorial,
      homeScreenTutorial,
      drawerTutorial,
    ];
    
    for (String tutorial in tutorials) {
      if (!(await isTutorialCompleted(tutorial))) {
        return false;
      }
    }
    return true;
  }

  // Get tutorial completion status for all tutorials
  static Future<Map<String, bool>> getTutorialCompletionStatus() async {
    final tutorials = [
      permissionsTutorial,
      registrationTutorial,
      callHistoryTutorial,
      homeScreenTutorial,
      drawerTutorial,
    ];
    
    Map<String, bool> status = {};
    for (String tutorial in tutorials) {
      status[tutorial] = await isTutorialCompleted(tutorial);
    }
    status[firstAppLaunch] = await isTutorialCompleted(firstAppLaunch);
    status[initialSyncCompleted] = await isTutorialCompleted(initialSyncCompleted);
    
    return status;
  }

  // Get next tutorial to show based on app state
  static Future<String?> getNextTutorial() async {
    // Check tutorials in order of priority
    if (!(await isTutorialCompleted(permissionsTutorial))) {
      return permissionsTutorial;
    }
    if (!(await isTutorialCompleted(registrationTutorial))) {
      return registrationTutorial;
    }
    if (!(await isTutorialCompleted(callHistoryTutorial))) {
      return callHistoryTutorial;
    }
    if (!(await isTutorialCompleted(homeScreenTutorial))) {
      return homeScreenTutorial;
    }
    if (!(await isTutorialCompleted(drawerTutorial))) {
      return drawerTutorial;
    }
    
    return null; // All tutorials completed
  }

  // Reset specific tutorial (useful for testing)
  static Future<void> resetTutorial(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_tutorialPrefix$tutorialKey');
  }
}

// Tutorial overlay widget
class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool showSkip;
  final Alignment targetAlignment;
  final EdgeInsets targetPadding;

  const TutorialOverlay({
    Key? key,
    required this.child,
    required this.title,
    required this.description,
    required this.onNext,
    this.onSkip,
    this.showSkip = true,
    this.targetAlignment = Alignment.center,
    this.targetPadding = const EdgeInsets.all(8),
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value * 0.8,
              child: Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
              ),
            );
          },
        ),
        
        // Highlighted target widget
        Align(
          alignment: widget.targetAlignment,
          child: Container(
            padding: widget.targetPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
        
        // Tutorial instruction card
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tutorial icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (widget.showSkip && widget.onSkip != null)
                            TextButton(
                              onPressed: widget.onSkip,
                              child: const Text(
                                'Skip Tutorial',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: widget.onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Got it!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Tutorial step data class
class TutorialStep {
  final String title;
  final String description;
  final Widget? targetWidget;
  final Alignment targetAlignment;
  final EdgeInsets targetPadding;
  final VoidCallback? onStepCompleted;

  TutorialStep({
    required this.title,
    required this.description,
    this.targetWidget,
    this.targetAlignment = Alignment.center,
    this.targetPadding = const EdgeInsets.all(8),
    this.onStepCompleted,
  });
}

// Tutorial manager widget
class TutorialManager extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onTutorialCompleted;
  final VoidCallback? onTutorialSkipped;
  final String tutorialKey;

  const TutorialManager({
    Key? key,
    required this.steps,
    required this.onTutorialCompleted,
    required this.tutorialKey,
    this.onTutorialSkipped,
  }) : super(key: key);

  @override
  State<TutorialManager> createState() => _TutorialManagerState();
}

class _TutorialManagerState extends State<TutorialManager> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      widget.steps[_currentStep - 1].onStepCompleted?.call();
    } else {
      _completeTutorial();
    }
  }

  void _skipTutorial() {
    TutorialService.markTutorialCompleted(widget.tutorialKey);
    widget.onTutorialSkipped?.call();
    widget.onTutorialCompleted();
  }

  void _completeTutorial() {
    TutorialService.markTutorialCompleted(widget.tutorialKey);
    widget.steps.last.onStepCompleted?.call();
    widget.onTutorialCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    
    return TutorialOverlay(
      title: step.title,
      description: step.description,
      targetAlignment: step.targetAlignment,
      targetPadding: step.targetPadding,
      onNext: _nextStep,
      onSkip: widget.onTutorialSkipped != null ? _skipTutorial : null,
      showSkip: widget.onTutorialSkipped != null,
      child: step.targetWidget ?? const SizedBox.shrink(),
    );
  }
}

// Welcome tutorial for first-time users with enhanced UI matching call_history_tutorial
class WelcomeTutorial extends StatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback? onSkipped;

  const WelcomeTutorial({
    Key? key, 
    required this.onCompleted,
    this.onSkipped,
  }) : super(key: key);

  @override
  State<WelcomeTutorial> createState() => _WelcomeTutorialState();
}

class _WelcomeTutorialState extends State<WelcomeTutorial> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true, period: const Duration(milliseconds: 1500));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400 || screenSize.height < 600;
    final isTablet = screenSize.width > 600;
    
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: isTablet ? 500 : null,
                    margin: EdgeInsets.all(isSmallScreen ? 16 : 32),
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                    constraints: BoxConstraints(
                      maxHeight: screenSize.height * 0.9,
                      maxWidth: screenSize.width * 0.95,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App logo or icon with animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              final logoSize = isSmallScreen ? 80.0 : 100.0;
                              final iconSize = isSmallScreen ? 40.0 : 50.0;
                              
                              return Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF8B6F47), // AppTheme.primaryBrown
                                      Color(0xFFA0845C), // AppTheme.accentBrown
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF8B6F47).withOpacity(0.3),
                                      blurRadius: 15 * _pulseAnimation.value,
                                      spreadRadius: 2 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.phone_in_talk,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 28),
                      
                          // Welcome title with enhanced styling
                          Text(
                            '🎉 Welcome to Deodap Call Monitor!',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3C2E26), // AppTheme.textPrimary
                              height: 1.2,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                      
                          // Welcome description with enhanced styling
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16, 
                              vertical: isSmallScreen ? 16 : 20
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFCF7EF).withOpacity(0.5), // AppTheme.primaryWarm
                              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                              border: Border.all(
                                color: Color(0xFFE8D5C4), // AppTheme.warmDark
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'This app monitors and syncs your call logs automatically. We\'ll guide you through a quick setup process:',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Color(0xFF6B5139), // AppTheme.textSecondary
                                    height: 1.5,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                            
                                // Setup steps with enhanced styling
                                _buildSetupStep(1, 'Grant permissions', Icons.security, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                _buildSetupStep(2, 'Register your device', Icons.app_registration, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                _buildSetupStep(3, 'Complete initial sync', Icons.sync, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                _buildSetupStep(4, 'Explore the dashboard', Icons.dashboard, isSmallScreen),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                      
                          // Action buttons with enhanced styling
                          Flex(
                            direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
                            mainAxisAlignment: isSmallScreen ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
                            children: [
                              // Skip button
                              Container(
                                width: isSmallScreen ? double.infinity : null,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    TutorialService.markFirstAppLaunchCompleted();
                                    if (widget.onSkipped != null) {
                                      widget.onSkipped!();
                                    } else {
                                      widget.onCompleted();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Color(0xFF8B6F47).withOpacity(0.7), // AppTheme.primaryBrown
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 24 : 20,
                                      vertical: isSmallScreen ? 14 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 12),
                                    ),
                                  ),
                                  child: Text(
                                    'Skip Setup',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(
                                width: isSmallScreen ? 0 : 16,
                                height: isSmallScreen ? 12 : 0,
                              ),
                              
                              // Start button
                              Container(
                                width: isSmallScreen ? double.infinity : null,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF8B6F47).withOpacity(0.2), // AppTheme.primaryBrown
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    TutorialService.markFirstAppLaunchCompleted();
                                    widget.onCompleted();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF8B6F47), // AppTheme.primaryBrown
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 24 : 32,
                                      vertical: isSmallScreen ? 16 : 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Start Setup',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildSetupStep(int number, String text, IconData icon, bool isSmallScreen) {
    final stepSize = isSmallScreen ? 24.0 : 28.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;
    final textSize = isSmallScreen ? 14.0 : 15.0;
    
    return Row(
      children: [
        Container(
          width: stepSize,
          height: stepSize,
          decoration: BoxDecoration(
            color: Color(0xFF8B6F47).withOpacity(0.1), // AppTheme.primaryBrown
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(0xFF8B6F47), // AppTheme.primaryBrown
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Color(0xFF8B6F47), // AppTheme.primaryBrown
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Icon(
          icon,
          size: iconSize,
          color: Color(0xFF8B6F47), // AppTheme.primaryBrown
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: textSize,
              color: Color(0xFF3C2E26), // AppTheme.textPrimary
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Tutorial progress indicator widget
class TutorialProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? activeColor;
  final Color? inactiveColor;

  const TutorialProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCurrent
                ? (activeColor ?? Colors.blue)
                : (inactiveColor ?? Colors.grey.shade300),
            border: isCurrent
                ? Border.all(
                    color: activeColor ?? Colors.blue,
                    width: 2,
                  )
                : null,
          ),
        );
      }),
    );
  }
}