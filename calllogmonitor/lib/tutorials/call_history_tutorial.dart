import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class CallHistoryTutorialData {
  static List<EnhancedTutorialStep> getCallHistorySteps() {
    return [
      EnhancedTutorialStep(
        title: "🚀 Welcome to Call History!",
        description: "You MUST complete the initial sync process here before using other features. This screen shows all your call logs that need to be uploaded to the server.",
        targetAlignment: Alignment.center,
        icon: Icons.priority_high,
        color: Colors.red,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "⚠️ Tap 'Sync All Pages'",
        description: "THIS IS REQUIRED! Tap the purple 'Sync All Pages' button in the top-right corner to upload all your call history. You must complete this before using other app features.",
        targetAlignment: Alignment.center,
        icon: Icons.cloud_sync,
        color: Colors.red,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "⏳ Wait for Completion",
        description: "After tapping 'Sync All Pages', wait for the sync to finish. The progress bar at the bottom will show status. Do NOT leave this screen until sync reaches 100%.",
        targetAlignment: Alignment.center,
        icon: Icons.hourglass_bottom,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Ready to Proceed!",
        description: "Once sync is complete, you can access all app features. In the future, your calls will be automatically synced in the background every 2 minutes.",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class CallHistoryTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const CallHistoryTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: TutorialService.callHistoryTutorial,
      steps: CallHistoryTutorialData.getCallHistorySteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
      showSkipButton: false, // Don't allow skipping the mandatory sync tutorial
    );
  }
}