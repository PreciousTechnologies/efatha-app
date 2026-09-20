// Efatha Church App smoke test.
//
// Splash shows branding, waits ~3s, then routes to Welcome when no session
// exists (Supabase unconfigured in tests, Django storage empty -> fallback).
// Fixed-duration pumps are used instead of pumpAndSettle because Splash runs
// repeating (never-settling) ambient animations until it navigates away.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:efatha_app/main.dart';

void main() {
  testWidgets('Efatha Church App smoke test', (WidgetTester tester) async {
    // Mock local storage so auth checks resolve (empty = logged out).
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const EfathaChurchApp());

    // Verify that splash screen shows
    expect(find.text('EFATHA'), findsOneWidget);
    expect(find.text('Church Community'), findsOneWidget);

    // Let splash finish (3s delay) + navigation fade + welcome intro.
    await tester.pump(const Duration(seconds: 4));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Welcome screen offers both entry points.
    expect(find.text("I'm New Here"), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);
  });
}
