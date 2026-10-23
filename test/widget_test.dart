import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/models/note.dart';
import 'package:uts/screens/note_form_screen.dart';

void main() {
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
