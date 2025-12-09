import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class PermissionsTutorialData {
  static List<EnhancedTutorialStep> getPermissionsSteps() {
    return [
      EnhancedTutorialStep(
        title: "🔐 Welcome to Permissions!",
        description: "This app needs several permissions to monitor and sync your call logs. We need access to call logs, phone state, contacts, and notifications to function properly.",
        targetAlignment: Alignment.center,
        icon: Icons.security,
        color: Colors.blue,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "📞 Essential Permissions",
        description: "Call logs: To read your call history\nPhone state: To identify which SIM was used\nContacts: To show contact names\nNotifications: For sync status updates",
        targetAlignment: Alignment.center,
        icon: Icons.call,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🔋 Battery Settings",
        description: "To ensure reliable background syncing, please disable battery optimization for this app when prompted. This prevents the system from stopping the sync process.",
        targetAlignment: Alignment.center,
        icon: Icons.battery_saver,
        color: Colors.red,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Grant All Permissions",
        description: "Tap 'Grant All Permissions' below to allow access to call logs, contacts, and phone state. After that, tap 'Battery Settings' to ensure uninterrupted syncing.",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.teal,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class PermissionsTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const PermissionsTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: TutorialService.permissionsTutorial,
      steps: PermissionsTutorialData.getPermissionsSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}