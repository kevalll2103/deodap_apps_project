import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dropshipper_plan_progress_tracker/login.dart';

void main() {
  testWidgets('Login page shows username and password fields', (WidgetTester tester) async {
    // Build LoginPage
    await tester.pumpWidget(const MaterialApp(home: Login()));

    // Check if Username field exists
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Check if Login button exists
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
