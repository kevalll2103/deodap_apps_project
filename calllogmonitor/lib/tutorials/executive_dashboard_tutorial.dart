import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class ExecutiveDashboardTutorialData {
  static List<EnhancedTutorialStep> getExecutiveDashboardSteps() {
    return [
      EnhancedTutorialStep(
        title: "👋 Welcome to Executive Dashboard!",
        description: "This is your executive dashboard where you can view all your leads organized by source and status. Get insights into your sales pipeline at a glance.",
        targetAlignment: Alignment.center,
        icon: Icons.dashboard,
        color: Colors.blue,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "📊 Leads Summary",
        description: "The top section shows your total leads count. This gives you a quick overview of your overall lead volume across all sources.",
        targetAlignment: Alignment.topCenter,
        icon: Icons.analytics,
        color: Colors.green,
        animationType: TutorialAnimationType.slideFromTop,
      ),
      
      EnhancedTutorialStep(
        title: "🏢 Leads by Source",
        description: "Below you'll see leads organized by source (like DeoDapApp, Website, etc.). Each source shows status buttons with lead counts. Tap any status button to view filtered leads.",
        targetAlignment: Alignment.center,
        icon: Icons.business,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🎯 Status Buttons",
        description: "Each colorful button represents a lead status (New, Converted, On Hold, etc.). The number shows how many leads are in that status. Tap to view detailed leads.",
        targetAlignment: Alignment.bottomCenter,
        icon: Icons.touch_app,
        color: Colors.purple,
        animationType: TutorialAnimationType.slideFromBottom,
      ),
      
      EnhancedTutorialStep(
        title: "🔄 Refresh Data",
        description: "Use the refresh button in the top-right corner to get the latest lead data. You can also pull down to refresh the entire dashboard.",
        targetAlignment: Alignment.topRight,
        icon: Icons.refresh,
        color: Colors.teal,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Ready to Explore!",
        description: "You're all set! Tap on any status button to view and manage your leads. Use the menu to access other features like lead details and call history.",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class ExecutiveDashboardTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const ExecutiveDashboardTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: 'executive_dashboard',
      steps: ExecutiveDashboardTutorialData.getExecutiveDashboardSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}