import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/models/note.dart';
import 'package:uts/screens/home_screen.dart';
import 'package:uts/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('combines category and pinned filters on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(Brightness.dark),
        home: HomeScreen(
          isDark: true,
          onToggleTheme: () async {},
          loadNotes: ({bool newestFirst = true}) async => [
            Note(
              id: 1,
              title: 'Kuliah biasa',
              content: 'Tugas',
              category: 'Kuliah',
            ),
            Note(
              id: 2,
              title: 'Kuliah penting',
              content: 'Ujian',
              category: 'Kuliah',
              isPinned: true,
            ),
            Note(
              id: 3,
              title: 'Ide penting',
              content: 'Proyek',
              category: 'Ide',
              isPinned: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Kuliah'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kuliah'));
    await tester.pumpAndSettle();
    expect(find.text('2 catatan'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Disematkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Disematkan'));
    await tester.pumpAndSettle();
    expect(find.text('1 catatan'), findsOneWidget);
    expect(find.text('Kuliah penting'), findsOneWidget);
    expect(find.text('Kuliah biasa'), findsNothing);
    expect(find.text('Ide penting'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searches content and restores notes after clearing search', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          isDark: false,
          onToggleTheme: () async {},
          loadNotes: ({bool newestFirst = true}) async => [
            Note(
              id: 1,
              title: 'Rencana akhir pekan',
              content: 'Pergi ke taman',
            ),
            Note(id: 2, title: 'Ide proyek', content: 'Aplikasi resep masakan'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'RESEP');
    await tester.pumpAndSettle();
    expect(find.text('Ide proyek'), findsOneWidget);
    expect(find.text('Rencana akhir pekan'), findsNothing);
    await tester.enterText(find.byType(TextField), 'tidak cocok');
    await tester.pumpAndSettle();
    expect(find.text('Catatan tidak ditemukan'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('Rencana akhir pekan'), findsOneWidget);
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tampilan grid'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.pumpAndSettle();
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
