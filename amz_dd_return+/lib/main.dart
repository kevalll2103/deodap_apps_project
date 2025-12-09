 import 'package:flutter/material.dart';
 import 'package:get/get.dart';
 import 'package:amz/view/splashscreen_view.dart';


 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   // Ensure SharedPreferences etc. load properly
   runApp(const MyApp());
}

class MyApp extends StatelessWidget {
   const MyApp({super.key});


   @override
   Widget build(BuildContext context) {
     return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AMZ Deodap Dropshipper Return+',
      theme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: const SplashscreenView(),
    );
  }
}

