import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glances_client_advanced/app.dart';

/// Guards the first-run flow end to end.
///
/// With no saved server, the app must render the Home screen's first-run hint
/// ("Glances shows you nothing until it reaches a Glances server…") with an
/// "Open settings" button instead of hanging on a loading view. This is a
/// regression test for the previous gate-in-`MaterialApp.builder` bug.
///
/// Note: bounded [WidgetTester.pump] calls are used instead of
/// [WidgetTester.pumpAndSettle] because the Home loading view animates
/// indefinitely while the (empty) server state is resolved, which would make
/// `pumpAndSettle` time out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Start with no saved server -> first-run state.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the first-run hint when no server is saved',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlancesApp()));
    await tester.pump(); // resolve the settings provider
    await tester.pump(const Duration(milliseconds: 300)); // settle animations

    // The hint text and the "Open settings" entry point are shown.
    expect(
      find.textContaining('Glances shows you nothing until it reaches a '
          'Glances server'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Open settings'), findsOneWidget);

    // The bottom navigation shell is still rendered (the app is navigable).
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('"Open settings" navigates to the Settings screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlancesApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(FilledButton, 'Open settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // route transition

    // The Settings screen (with its Server section) is now visible.
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Server address'), findsOneWidget);
  });
}
