import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tutorial_service.dart';
import '../theme/app_theme.dart';

/// Enhanced tutorial animation types
enum TutorialAnimationType {
  slideFromTop,
  slideFromBottom,
  slideFromLeft,
  slideFromRight,
  fadeIn,
  scaleIn,
  bounceIn,
  celebration,
}

/// Enhanced tutorial step with additional styling and animation options
class EnhancedTutorialStep extends TutorialStep {
  final IconData icon;
  final Color color;
  final TutorialAnimationType animationType;
  final Widget? targetWidget;

  EnhancedTutorialStep({
    required String title,
    required String description,
    required Alignment targetAlignment,
    required this.icon,
    required this.color,
    required this.animationType,
    this.targetWidget,
    EdgeInsets targetPadding = const EdgeInsets.all(8),
    VoidCallback? onStepCompleted,
  }) : super(
          title: title,
          description: description,
          targetAlignment: targetAlignment,
          targetPadding: targetPadding,
          targetWidget: targetWidget,
          onStepCompleted: onStepCompleted,
        );
}

/// Enhanced tutorial manager widget with animations and improved UI
class EnhancedTutorialManager extends StatefulWidget {
  final String tutorialKey;
  final List<EnhancedTutorialStep> steps;
  final VoidCallback? onTutorialCompleted;
  final VoidCallback? onTutorialSkipped;
  final bool showSkipButton;
  final bool showPreviousButton;
  final Color? backgroundColor;

  const EnhancedTutorialManager({
    Key? key,
    required this.tutorialKey,
    required this.steps,
    this.onTutorialCompleted,
    this.onTutorialSkipped,
    this.showSkipButton = true,
    this.showPreviousButton = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<EnhancedTutorialManager> createState() => _EnhancedTutorialManagerState();
}

class _EnhancedTutorialManagerState extends State<EnhancedTutorialManager>
    with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _stepController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  late Animation<double> _stepAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStepAnimation();
  }

  void _initializeAnimations() {
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _stepAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stepController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (_currentStepIndex + 1) / widget.steps.length,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startStepAnimation() {
    _stepController.forward();
    _updateProgress();
  }

  void _updateProgress() {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: (_currentStepIndex + 1) / widget.steps.length,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStepIndex < widget.steps.length - 1) {
      _stepController.reverse().then((_) {
        setState(() {
          _currentStepIndex++;
        });
        _startStepAnimation();
      });
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStepIndex > 0) {
      _stepController.reverse().then((_) {
        setState(() {
          _currentStepIndex--;
        });
        _startStepAnimation();
      });
    }
  }

  void _skipTutorial() {
    HapticFeedback.mediumImpact();
    TutorialService.markTutorialCompleted(widget.tutorialKey);
    widget.onTutorialSkipped?.call();
  }

  void _completeTutorial() {
    HapticFeedback.heavyImpact();
    TutorialService.markTutorialCompleted(widget.tutorialKey);
    widget.onTutorialCompleted?.call();
  }

  @override
  void dispose() {
    _stepController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.steps[_currentStepIndex];
    
    return Material(
      color: widget.backgroundColor ?? Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          // Highlighted target widget if provided
          if (currentStep.targetWidget != null)
            Align(
              alignment: currentStep.targetAlignment,
              child: Container(
                padding: currentStep.targetPadding,
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
                child: currentStep.targetWidget,
              ),
            ),
          
          // Animated tutorial card
          AnimatedBuilder(
            animation: _stepAnimation,
            builder: (context, child) {
              return _buildAnimatedTutorialCard(currentStep);
            },
          ),
          
          // Progress indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: widget.showSkipButton ? 100 : 16,
            child: _buildProgressIndicator(),
          ),
          
          // Skip button
          if (widget.showSkipButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildSkipButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTutorialCard(EnhancedTutorialStep step) {
    Widget card = _buildTutorialCard(step);
    
    switch (step.animationType) {
      case TutorialAnimationType.slideFromTop:
        return Transform.translate(
          offset: Offset(0, -100 * (1 - _stepAnimation.value)),
          child: card,
        );
      case TutorialAnimationType.slideFromBottom:
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _stepAnimation.value)),
          child: card,
        );
      case TutorialAnimationType.slideFromLeft:
        return Transform.translate(
          offset: Offset(-100 * (1 - _stepAnimation.value), 0),
          child: card,
        );
      case TutorialAnimationType.slideFromRight:
        return Transform.translate(
          offset: Offset(100 * (1 - _stepAnimation.value), 0),
          child: card,
        );
      case TutorialAnimationType.scaleIn:
        return Transform.scale(
          scale: _stepAnimation.value,
          child: card,
        );
      case TutorialAnimationType.bounceIn:
        return Transform.scale(
          scale: _stepAnimation.value,
          child: Transform.rotate(
            angle: (1 - _stepAnimation.value) * 0.1,
            child: card,
          ),
        );
      case TutorialAnimationType.celebration:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _stepAnimation.value * _pulseAnimation.value,
              child: card,
            );
          },
        );
      case TutorialAnimationType.fadeIn:
      default:
        return Opacity(
          opacity: _stepAnimation.value,
          child: card,
        );
    }
  }

  Widget _buildTutorialCard(EnhancedTutorialStep step) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400 || screenSize.height < 600;
    final isTablet = screenSize.width > 600;
    
    return SafeArea(
      child: Align(
        alignment: step.targetAlignment,
        child: Container(
          width: isTablet ? 500 : null,
          margin: EdgeInsets.all(isSmallScreen ? 16 : 20),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.8,
            maxWidth: screenSize.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
                // Icon with animated background
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final iconSize = isSmallScreen ? 60.0 : 80.0;
                    final iconInnerSize = isSmallScreen ? 30.0 : 40.0;
                    
                    return Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            step.color.withOpacity(0.2),
                            step.color.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: step.color.withOpacity(0.3),
                            blurRadius: 15 * _pulseAnimation.value,
                            spreadRadius: 2 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                      child: Icon(
                        step.icon,
                        size: iconInnerSize,
                        color: step.color,
                      ),
                    );
                  },
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Title
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: step.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                // Description
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 24),
                
                // Navigation buttons
                isSmallScreen 
                  ? Column(
                      children: [
                        if (_currentStepIndex > 0 && widget.showPreviousButton)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _buildNavButton(
                              icon: Icons.arrow_back,
                              label: 'Previous',
                              onTap: _previousStep,
                              color: Colors.grey,
                              isFullWidth: true,
                            ),
                          ),
                        
                        Text(
                          '${_currentStepIndex + 1} of ${widget.steps.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        SizedBox(
                          width: double.infinity,
                          child: _buildNavButton(
                            icon: _currentStepIndex == widget.steps.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                            label: _currentStepIndex == widget.steps.length - 1
                                ? 'Finish'
                                : 'Next',
                            onTap: _nextStep,
                            color: step.color,
                            isFullWidth: true,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStepIndex > 0 && widget.showPreviousButton)
                          _buildNavButton(
                            icon: Icons.arrow_back,
                            label: 'Previous',
                            onTap: _previousStep,
                            color: Colors.grey,
                          )
                        else
                          const SizedBox(width: 100),
                        
                        Text(
                          '${_currentStepIndex + 1} of ${widget.steps.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        _buildNavButton(
                          icon: _currentStepIndex == widget.steps.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                          label: _currentStepIndex == widget.steps.length - 1
                              ? 'Finish'
                              : 'Next',
                          onTap: _nextStep,
                          color: step.color,
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isFullWidth ? 24 : 16, 
          vertical: isFullWidth ? 12 : 8
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isFullWidth ? 12 : 20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: isFullWidth ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.steps[_currentStepIndex].color,
              ),
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              'Tutorial Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _skipTutorial,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Base widget for all tutorial screens
class EnhancedTutorialWidget extends StatefulWidget {
  final Widget child;
  final String tutorialKey;
  final List<EnhancedTutorialStep> steps;
  final VoidCallback? onTutorialCompleted;
  final bool showSkipButton;
  final bool showPreviousButton;
  final Color? backgroundColor;

  const EnhancedTutorialWidget({
    Key? key,
    required this.child,
    required this.tutorialKey,
    required this.steps,
    this.onTutorialCompleted,
    this.showSkipButton = true,
    this.showPreviousButton = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<EnhancedTutorialWidget> createState() => _EnhancedTutorialWidgetState();
}

class _EnhancedTutorialWidgetState extends State<EnhancedTutorialWidget>
    with TickerProviderStateMixin {
  bool _showTutorial = false;
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkTutorial();
  }

  void _initializeAnimations() {
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOutCubic,
    ));
  }

  Future<void> _checkTutorial() async {
    final shouldShow = !(await TutorialService.isTutorialCompleted(widget.tutorialKey));
    if (shouldShow && mounted) {
      setState(() {
        _showTutorial = true;
      });
      _overlayController.forward();
    }
  }

  void _onTutorialCompleted() async {
    await _overlayController.reverse();
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
      widget.onTutorialCompleted?.call();
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showTutorial)
          AnimatedBuilder(
            animation: _overlayAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _overlayAnimation.value,
                child: EnhancedTutorialManager(
                  tutorialKey: widget.tutorialKey,
                  steps: widget.steps,
                  onTutorialCompleted: _onTutorialCompleted,
                  onTutorialSkipped: _onTutorialCompleted,
                  showSkipButton: widget.showSkipButton,
                  showPreviousButton: widget.showPreviousButton,
                  backgroundColor: widget.backgroundColor,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Welcome tutorial for first-time users with improved UI
class WelcomeTutorialScreen extends StatelessWidget {
  final VoidCallback onCompleted;
  final VoidCallback? onSkipped;
  final String appName;
  final String? logoAssetPath;
  final IconData? logoIcon;
  final Color? logoColor;
  final List<String> setupSteps;

  const WelcomeTutorialScreen({
    Key? key, 
    required this.onCompleted,
    this.onSkipped,
    this.appName = 'Deodap Call Monitor',
    this.logoAssetPath,
    this.logoIcon = Icons.phone,
    this.logoColor = Colors.blue,
    this.setupSteps = const [
      'Grant permissions',
      'Register your device',
      'Complete initial sync',
      'Explore the dashboard',
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400 || screenSize.height < 600;
    final isTablet = screenSize.width > 600;
    
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Center(
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
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
                  // App logo or icon
                  _buildLogo(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Welcome title
                  Text(
                    '🎉 Welcome to $appName!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Welcome description
                  _buildDescription(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  
                  // Action buttons
                  isSmallScreen
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                TutorialService.markFirstAppLaunchCompleted();
                                if (onSkipped != null) {
                                  onSkipped!();
                                } else {
                                  onCompleted();
                                }
                              },
                              child: const Text(
                                'Skip Setup',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                TutorialService.markFirstAppLaunchCompleted();
                                onCompleted();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: logoColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Start Setup',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              TutorialService.markFirstAppLaunchCompleted();
                              if (onSkipped != null) {
                                onSkipped!();
                              } else {
                                onCompleted();
                              }
                            },
                            child: const Text(
                              'Skip Setup',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              TutorialService.markFirstAppLaunchCompleted();
                              onCompleted();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: logoColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Start Setup',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    final logoSize = isSmallScreen ? 60.0 : 80.0;
    final iconSize = isSmallScreen ? 30.0 : 40.0;
    
    if (logoAssetPath != null) {
      return Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
        child: Image.asset(
          logoAssetPath!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo(isSmallScreen);
          },
        ),
      );
    } else {
      return _buildDefaultLogo(isSmallScreen);
    }
  }

  Widget _buildDefaultLogo(bool isSmallScreen) {
    final logoSize = isSmallScreen ? 60.0 : 80.0;
    final iconSize = isSmallScreen ? 30.0 : 40.0;
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            logoColor ?? Colors.blue, 
            (logoColor ?? Colors.blue).withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        logoIcon ?? Icons.phone,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }

  Widget _buildDescription(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'This app monitors and syncs your call logs automatically. We\'ll guide you through a quick setup process:',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.black54,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: setupSteps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            final stepSize = isSmallScreen ? 20.0 : 24.0;
            final fontSize = isSmallScreen ? 10.0 : 12.0;
            final textSize = isSmallScreen ? 13.0 : 15.0;
            
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 4),
              child: Row(
                children: [
                  Container(
                    width: stepSize,
                    height: stepSize,
                    decoration: BoxDecoration(
                      color: logoColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: logoColor ?? Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: logoColor ?? Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: textSize,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}