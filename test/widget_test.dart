import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_app/main.dart';
import 'package:provider/provider.dart';

import 'package:farmer_app/providers/auth_provider.dart';
import 'package:farmer_app/providers/farmer_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => FarmerProvider()),
        ],
        child: const AgriAdvisorApp(),
      ),
    );

    expect(find.byType(AgriAdvisorApp), findsOneWidget);

    // Advance through startup work, then dispose the tree so animation timers
    // are cancelled before the test finishes.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
