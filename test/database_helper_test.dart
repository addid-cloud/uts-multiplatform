import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uts/db/database_helper.dart';
import 'package:uts/models/note.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('creates the notes table and supports note CRUD', () async {
    final database = DatabaseHelper.forTesting(
      databasePath: inMemoryDatabasePath,
    );
    final note = Note(
      title: 'Catatan baru',
      content: 'Isi catatan',
      category: 'Kuliah',
      colorIndex: 2,
      isPinned: true,
    );

    final id = await database.insert(note);
    final inserted = await database.getNotes();

    expect(inserted, hasLength(1));
    expect(inserted.single.id, id);
    expect(inserted.single.title, note.title);
    expect(inserted.single.content, note.content);
    expect(inserted.single.category, 'Kuliah');
    expect(inserted.single.colorIndex, 2);
    expect(inserted.single.isPinned, isTrue);

    final updated = Note(
      id: id,
      title: 'Catatan diperbarui',
      content: 'Isi diperbarui',
      createdAt: inserted.single.createdAt,
    );
    expect(await database.update(updated), 1);
    expect((await database.getNotes()).single.title, updated.title);

    expect(await database.delete(id), 1);
    expect(await database.getNotes(), isEmpty);
  });

  test('shares a single database initialization between callers', () async {
    final helper = DatabaseHelper.forTesting(
      databasePath: inMemoryDatabasePath,
    );

    final databases = await Future.wait([helper.database, helper.database]);

    expect(identical(databases[0], databases[1]), isTrue);
  });

  test('migrates existing notes without losing their content', () async {
    final folder = await Directory.systemTemp.createTemp('catatan_migration_');
    final dbPath = path.join(folder.path, 'legacy.db');
    final legacy = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT NOT NULL, created_at TEXT NOT NULL)',
        );
      },
    );
    await legacy.insert('notes', {
      'title': 'Catatan lama',
      'content': 'Tetap tersimpan',
      'created_at': '2026-01-01T10:00:00.000',
    });
    await legacy.close();
    final helper = DatabaseHelper.forTesting(databasePath: dbPath);
    try {
      final notes = await helper.getNotes();
      expect(notes.single.title, 'Catatan lama');
      expect(notes.single.content, 'Tetap tersimpan');
      expect(notes.single.category, 'Pribadi');
      expect(notes.single.colorIndex, 0);
      expect(notes.single.isPinned, isFalse);
      await helper.update(notes.single.copyWith(isPinned: true));
      await helper.insert(Note(title: 'Lebih baru', content: 'Catatan kedua'));
      for (final newest in [true, false]) {
        final sorted = await helper.getNotes(newestFirst: newest);
        expect(sorted.first.title, 'Catatan lama');
        expect(sorted.first.isPinned, isTrue);
      }
    } finally {
      await (await helper.database).close();
      await folder.delete(recursive: true);
    }
  });
}
