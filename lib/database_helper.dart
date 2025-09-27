import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('absences.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE absences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_name TEXT NOT NULL,
        school_email TEXT NOT NULL
      )
    ''');
  }

  Future<void> addAbsence(DateTime date) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().split('T')[0];

    await db.insert(
      'absences',
      {
        'date': dateString,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeAbsence(DateTime date) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().split('T')[0];

    await db.delete(
      'absences',
      where: 'date = ?',
      whereArgs: [dateString],
    );
  }

  Future<List<Map<String, dynamic>>> getAbsences() async {
    final db = await instance.database;
    return await db.query('absences', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getAbsencesForMonth(int year, int month) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1).toIso8601String().split('T')[0];
    final endDate = DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

    return await db.query(
      'absences',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  Future<void> saveSettings(String childName, String schoolEmail) async {
    final db = await instance.database;

    await db.delete('settings');
    await db.insert('settings', {
      'child_name': childName,
      'school_email': schoolEmail,
    });
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await instance.database;
    final result = await db.query('settings', limit: 1);

    if (result.isNotEmpty) {
      return result.first;
    }
    return {};
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
