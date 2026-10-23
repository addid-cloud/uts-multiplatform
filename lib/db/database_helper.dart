import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

/// Pengelola database SQLite lokal (data terstruktur: catatan).
class DatabaseHelper {
  DatabaseHelper._({String? databasePath}) : _databasePath = databasePath;

  DatabaseHelper.forTesting({required String databasePath})
    : _databasePath = databasePath;

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'catatan.db';
  static const _databaseVersion = 1;
  final String? _databasePath;
  Future<Database>? _database;

  Future<Database> get database async {
    final pendingDatabase = _database ??= _init();
    try {
      return await pendingDatabase;
    } catch (_) {
      if (identical(_database, pendingDatabase)) {
        _database = null;
      }
      rethrow;
    }
  }

  Future<Database> _init() async {
    final path = _databasePath ?? join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Note>> getNotes({bool newestFirst = true}) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      orderBy: 'created_at ${newestFirst ? 'DESC' : 'ASC'}',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<int> insert(Note n) async =>
      (await database).insert('notes', n.toMap()..remove('id'));

  Future<int> update(Note n) async => (await database).update(
    'notes',
    n.toMap(),
    where: 'id = ?',
    whereArgs: [n.id],
  );

  Future<int> delete(int id) async =>
      (await database).delete('notes', where: 'id = ?', whereArgs: [id]);
}
