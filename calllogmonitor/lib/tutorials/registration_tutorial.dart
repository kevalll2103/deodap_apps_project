import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class RegistrationTutorialData {
  static List<EnhancedTutorialStep> getRegistrationSteps() {
    return [
      EnhancedTutorialStep(
        title: "📝 Welcome to Registration!",
        description: "To use this app, you need to register your device. Enter your name, mobile number, select your SIM card, and choose your warehouse. This links your phone to the system.",
        targetAlignment: Alignment.center,
        icon: Icons.app_registration,
        color: Colors.blue,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "📱 SIM & Number Setup",
        description: "Enter your 10-digit mobile number and select which SIM card to monitor. Then tap 'Verify SIM Number' to ensure the number matches your selected SIM.",
        targetAlignment: Alignment.center,
        icon: Icons.sim_card,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🏢 Warehouse Selection",
        description: "Choose your warehouse from the dropdown menu. This determines where your call data will be organized in the system. Review privacy policy if needed.",
        targetAlignment: Alignment.center,
        icon: Icons.business,
        color: Colors.purple,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🚀 Complete Registration",
        description: "Once all fields are filled and SIM is verified, tap 'Register Device' to complete the process. You'll then access the dashboard and all app features!",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class RegistrationTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const RegistrationTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: TutorialService.registrationTutorial,
      steps: RegistrationTutorialData.getRegistrationSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}