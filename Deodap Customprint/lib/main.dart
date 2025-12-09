import 'package:Deodap_Customprint/splashscreen.dart' show Splashscreen;
import 'package:flutter/material.dart';
import 'themes/app_theme.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deodap Customprint app',
      theme: appTheme,
      home: Splashscreen(),
      // Directly set the home screen without routes
    );
  }
}
