// root_tabs.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';        // the updated Home below (acts as Home tab)
import 'qr_inward.dart'; // your existing scanner (no app bar required here)
import 'profile_screen.dart';      // updated ProfileScreen supports showAppBar=false

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});
  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // iOS-styled bottom tab scaffold
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.qrcode_viewfinder),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      tabBuilder: (ctx, i) {
        switch (i) {
          case 0:
            return CupertinoTabView(builder: (_) => const HomeScreen()); // Has AppBar + Drawer
          case 1:
          // Scanner tab without any extra AppBar/Drawer
            return CupertinoTabView(builder: (_) => const ClubOrderScanScreen(warehouseId: 0, warehouseLabel: '',));
          case 2:
          default:
          // Profile without AppBar/Drawer
            return CupertinoTabView(
              builder: (_) => const ProfileScreen(showAppBar: false),
            );
        }
      },
    );
  }
}
