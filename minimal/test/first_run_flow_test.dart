import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glances_client/app.dart';
import 'package:glances_client/ui/components/server_connect_dialog.dart';

/// Guards the first-run flow end to end.
///
/// With no saved server, the app must render the non-dismissible
/// [ServerConnectDialog] (not hang on a loading view). This is a regression
/// test for the bug where the first-run gate was installed in
/// `MaterialApp.builder`, which replaced the Navigator and caused
/// `showDialog` to fail, leaving the app stuck on the loading view forever.
///
/// Note: bounded [WidgetTester.pump] calls are used instead of
/// [WidgetTester.pumpAndSettle] because the loading view behind the dialog
/// animates indefinitely, which would make `pumpAndSettle` time out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Start with no saved server -> first-run state.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the first-run connect dialog when no server is saved',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlancesApp()));
    await tester.pump(); // resolve the config provider, schedule the dialog
    await tester.pump(const Duration(milliseconds: 100)); // post-frame -> showDialog
    await tester.pump(const Duration(milliseconds: 300)); // dialog entrance

    // The dialog is shown and the shell is still gated behind it.
    expect(find.byType(ServerConnectDialog), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('connect dialog saves the server and proceeds past the gate',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlancesApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ServerConnectDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'glances.example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump(); // start async save
    await tester.pump(const Duration(milliseconds: 100)); // persist + close dialog
    await tester.pump(const Duration(milliseconds: 300)); // dialog exit animation

    // Dialog closed and the shell (bottom navigation) is rendered.
    expect(find.byType(ServerConnectDialog), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    // The normalized URL was persisted.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('glances_server_base_url'),
      'http://glances.example.com',
    );
  });

  testWidgets('connect dialog shows an error for invalid input',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlancesApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Still on the dialog, an error message is shown, and nothing was saved.
    expect(find.byType(ServerConnectDialog), findsOneWidget);
    expect(find.text('Enter a server address'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
