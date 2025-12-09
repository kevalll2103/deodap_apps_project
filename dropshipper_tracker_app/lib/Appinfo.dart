import 'package:flutter/material.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Info")),
      body: const Center(child: Text("App Info Screen")),
    );
  }
}
