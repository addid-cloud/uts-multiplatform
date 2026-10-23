import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/models/note.dart';
import 'package:uts/screens/note_form_screen.dart';
import 'package:uts/theme/app_theme.dart';

void main() {
  testWidgets('saves category, color and pin selection with the note', (
    tester,
  ) async {
    Note? savedNote;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => NoteFormScreen(
                    note: Note(
                      id: 5,
                      title: 'Judul',
                      content: 'Isi catatan',
                      category: 'Kerja',
                      colorIndex: 1,
                      isPinned: true,
                    ),
                    onSave: (note) async => savedNote = note,
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Atur catatan'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Kerja'))
          .selected,
      isTrue,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kuliah'));
    await tester.tap(find.byTooltip('Langit'));
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(savedNote?.id, 5);
    expect(savedNote?.category, 'Kuliah');
    expect(savedNote?.colorIndex, 2);
    expect(savedNote?.isPinned, isTrue);
    expect(find.text('Buka'), findsOneWidget);
  });

  testWidgets('editor fits a small screen with keyboard visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(Brightness.light),
        home: const NoteFormScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('warns before discarding unsaved changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const NoteFormScreen()),
              ),
              child: const Text('Buka form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Draft');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan catatan?'), findsOneWidget);
    await tester.tap(find.text('Tetap menulis'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tinggalkan'));
    await tester.pumpAndSettle();
    expect(find.text('Buka form'), findsOneWidget);
  });

  testWidgets('requires a title and note content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoteFormScreen()));

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Isi wajib diisi'), findsOneWidget);
  });

  testWidgets('shows an error and re-enables save when saving fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NoteFormScreen(
          onSave: (_) async => throw Exception('database unavailable'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Judul');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi catatan');
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Gagal menyimpan catatan: Exception: database unavailable'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.save), findsOneWidget);
    final saveButton = find.ancestor(
      of: find.text('Simpan'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('stops saving when the database does not respond', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NoteFormScreen(onSave: (_) => Completer<void>().future),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Judul');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi catatan');
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 15));

    expect(find.textContaining('Penyimpanan terlalu lama'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('saves a valid note and returns to the previous screen', (
    tester,
  ) async {
    Note? savedNote;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NoteFormScreen(onSave: (note) async => savedNote = note),
                ),
              ),
              child: const Text('Buka form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Judul');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi catatan');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(savedNote?.title, 'Judul');
    expect(savedNote?.content, 'Isi catatan');
    expect(find.text('Buka form'), findsOneWidget);
  });
}
