import 'package:Deodap_STrack/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deodap STracking App',
      home: Splashscreen(),
      // Directly set the home screen without routes
    );
  }
}
