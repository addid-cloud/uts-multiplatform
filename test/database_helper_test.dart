import 'package:flutter_test/flutter_test.dart';
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
    final note = Note(title: 'Catatan baru', content: 'Isi catatan');

    final id = await database.insert(note);
    final inserted = await database.getNotes();

    expect(inserted, hasLength(1));
    expect(inserted.single.id, id);
    expect(inserted.single.title, note.title);
    expect(inserted.single.content, note.content);

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
}
