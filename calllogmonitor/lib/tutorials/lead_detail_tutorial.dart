import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../services/enhanced_tutorial_service.dart';
import '../theme/app_theme.dart';

class LeadDetailTutorialData {
  static List<EnhancedTutorialStep> getLeadDetailSteps() {
    return [
      EnhancedTutorialStep(
        title: "📋 Lead Details Overview",
        description: "Welcome to the complete lead details screen! Here you can see all information about this lead including client details, call history, items, and more.",
        targetAlignment: Alignment.center,
        icon: Icons.assignment,
        color: Colors.blue,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "ℹ️ Lead Information",
        description: "The first section shows lead details like lead number, warehouse, sales person, source, status, total amount, date, and any reminders set for this lead.",
        targetAlignment: Alignment.topCenter,
        icon: Icons.info,
        color: Colors.green,
        animationType: TutorialAnimationType.slideFromTop,
      ),
      
      EnhancedTutorialStep(
        title: "👤 Client Information",
        description: "This section displays client details including name, mobile number, address, city, state, and pincode. You can directly call, SMS, or WhatsApp the client from here.",
        targetAlignment: Alignment.center,
        icon: Icons.person,
        color: Colors.orange,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "📞 Call Summary & History",
        description: "View call statistics and detailed call history in the tabbed section. Switch between 'Items' and 'Calls' tabs to see purchased items or call logs with this client.",
        targetAlignment: Alignment.center,
        icon: Icons.phone,
        color: Colors.purple,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🛒 Items & Purchases",
        description: "The Items tab shows all products in this lead with SKU, weight, rate, quantity, and total amount. This helps you understand what the client is interested in buying.",
        targetAlignment: Alignment.bottomCenter,
        icon: Icons.shopping_cart,
        color: Colors.teal,
        animationType: TutorialAnimationType.slideFromBottom,
      ),
      
      EnhancedTutorialStep(
        title: "✏️ Update Lead Status",
        description: "Use the edit button in the top-right corner to update the lead status. You can change status, add comments, and set reminders to keep track of lead progress.",
        targetAlignment: Alignment.topRight,
        icon: Icons.edit,
        color: Colors.indigo,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "🔄 Refresh & Actions",
        description: "Use the refresh button to get latest data. Take actions like calling, messaging, or updating status to move the lead forward in your sales pipeline.",
        targetAlignment: Alignment.topCenter,
        icon: Icons.refresh,
        color: Colors.brown,
        animationType: TutorialAnimationType.fadeIn,
      ),
      
      EnhancedTutorialStep(
        title: "✅ Master Lead Management!",
        description: "You now know how to view complete lead details, contact clients, and update lead status. Use these tools to effectively manage your sales pipeline!",
        targetAlignment: Alignment.center,
        icon: Icons.check_circle,
        color: Colors.green,
        animationType: TutorialAnimationType.fadeIn,
      ),
    ];
  }
}

class LeadDetailTutorialWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTutorialCompleted;

  const LeadDetailTutorialWidget({
    Key? key,
    required this.child,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedTutorialWidget(
      child: child,
      tutorialKey: 'lead_detail',
      steps: LeadDetailTutorialData.getLeadDetailSteps(),
      onTutorialCompleted: onTutorialCompleted,
      backgroundColor: Colors.black.withOpacity(0.7),
    );
  }
}