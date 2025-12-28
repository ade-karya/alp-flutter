// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:alp/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize sqflite for ffi
    sqfliteFfiInit();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // We use pump() with a duration to allow for initial timers (like AuthCubit's check)
    // to complete or move forward.
    await tester.pump(const Duration(seconds: 2));

    // Verify that the app starts.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
