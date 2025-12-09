import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class HomeScreenTutorialData {
  static List<EnhancedTutorialStep> getHomeScreenSteps() {
    return [
      EnhancedTutorialStep(
        title: "⚠️ Welcome to Dashboard!",
        description: "Before using the dashboard, you MUST complete the initial sync process in the Call History screen. Dashboard features won't work until this is done.",
        targetAlignment: Alignment.center,
        icon: Icons.warning,
        color: Colors.red,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "☰ Go to Call History",
        description: "Tap the menu icon (☰) in the top-left corner, then select 'Call History' from the drawer. You must complete the sync process there before using the dashboard.",
        targetAlignment: Alignment.center,
        icon: Icons.menu,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🔄 Complete Sync Process",
        description: "In Call History, tap 'Sync All Pages' and wait for 100% completion. This is mandatory for first-time users. Return here after sync is complete.",
        targetAlignment: Alignment.center,
        icon: Icons.cloud_sync,
        color: Colors.purple,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Return After Sync",
        description: "After completing the sync, return here to view your call statistics. The dashboard will then show accurate data for all your calls.",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class DrawerTutorialData {
  static List<EnhancedTutorialStep> getDrawerSteps() {
    return [
      EnhancedTutorialStep(
        title: "🗂️ Welcome to Navigation!",
        description: "This drawer contains all app features and navigation options. For first-time users, you MUST go to Call History first to complete the initial setup!",
        targetAlignment: Alignment.center,
        icon: Icons.menu_open,
        color: Colors.blue,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "⚠️ Go to Call History First!",
        description: "IMPORTANT! As a first-time user, tap 'Call History' below and complete the 'Sync All Pages' process before using any other features. This is mandatory!",
        targetAlignment: Alignment.center,
        icon: Icons.history,
        color: Colors.red,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🏠 Other Features (After Sync)",
        description: "After completing the sync in Call History, you can return to use Dashboard, User Details, and other features. They will work properly only after sync is complete.",
        targetAlignment: Alignment.center,
        icon: Icons.dashboard,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Tap Call History Now",
        description: "Close this tutorial and tap 'Call History' to begin the mandatory initial sync. You'll be guided through the process there.",
        targetAlignment: Alignment.center,
        icon: Icons.arrow_forward,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class HomeScreenTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const HomeScreenTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: TutorialService.homeScreenTutorial,
      steps: HomeScreenTutorialData.getHomeScreenSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}

class DrawerTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const DrawerTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: TutorialService.drawerTutorial,
      steps: DrawerTutorialData.getDrawerSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}