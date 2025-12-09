import 'package:flutter/material.dart';

class Notification extends StatelessWidget {
  const Notification ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("New plan added"),
            subtitle: Text("You have a new plan assigned."),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Progress updated"),
            subtitle: Text("Your progress has been updated."),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Reminder"),
            subtitle: Text("Don't forget to check today's tasks."),
          ),
        ],
      ),
    );
  }
}
