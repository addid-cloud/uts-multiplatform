import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/models/note.dart';
import 'package:uts/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows database loading errors and can retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          isDark: false,
          onToggleTheme: () async {},
          loadNotes: ({bool newestFirst = true}) async {
            attempts++;
            if (attempts == 1) {
              throw Exception('database unavailable');
            }
            return <Note>[];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('database unavailable'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Belum ada catatan'), findsOneWidget);
  });

  testWidgets('stops loading when the database does not respond', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          isDark: false,
          onToggleTheme: () async {},
          loadNotes: ({bool newestFirst = true}) =>
              Completer<List<Note>>().future,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 15));

    expect(find.textContaining('Waktu memuat habis'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
