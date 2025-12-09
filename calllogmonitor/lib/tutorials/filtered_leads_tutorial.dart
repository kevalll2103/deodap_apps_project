import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class FilteredLeadsTutorialData {
  static List<EnhancedTutorialStep> getFilteredLeadsSteps() {
    return [
      EnhancedTutorialStep(
        title: "🎯 Filtered Leads View",
        description: "Welcome to the filtered leads screen! Here you can see all leads for a specific source and status combination. This helps you focus on leads that need attention.",
        targetAlignment: Alignment.center,
        icon: Icons.filter_list,
        color: Colors.blue,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "📋 Filter Information",
        description: "The top card shows which source and status you're viewing, along with the total count of leads. This helps you stay oriented about what data you're seeing.",
        targetAlignment: Alignment.topCenter,
        icon: Icons.info,
        color: Colors.green,
        animationType: TutorialAnimationType.slideFromTop,
      ),
      
      EnhancedTutorialStep(
        title: "👤 Lead Cards",
        description: "Each card represents one lead with customer name, phone number, date, and total amount. All the key information is displayed at a glance for quick decision making.",
        targetAlignment: Alignment.center,
        icon: Icons.person,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "📞 Quick Actions",
        description: "At the bottom of each lead card, you'll find action buttons: Copy phone number, Send SMS, Open WhatsApp, and Make a call. These help you contact customers quickly.",
        targetAlignment: Alignment.bottomCenter,
        icon: Icons.touch_app,
        color: Colors.purple,
        animationType: TutorialAnimationType.slideFromBottom,
      ),
      
      EnhancedTutorialStep(
        title: "👆 Tap for Details",
        description: "Tap anywhere on a lead card to view complete lead details including client information, call history, items, and more. You can also update the lead status from there.",
        targetAlignment: Alignment.center,
        icon: Icons.touch_app,
        color: Colors.teal,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🔄 Refresh & Navigate",
        description: "Use the refresh button to get latest data, or pull down to refresh. Use the back button to return to the dashboard and explore other lead categories.",
        targetAlignment: Alignment.topRight,
        icon: Icons.refresh,
        color: Colors.indigo,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Start Managing Leads!",
        description: "You're ready to manage your leads! Tap on any lead to view details, use quick actions to contact customers, and keep your pipeline moving forward.",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class FilteredLeadsTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const FilteredLeadsTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: 'filtered_leads',
      steps: FilteredLeadsTutorialData.getFilteredLeadsSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}