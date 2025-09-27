import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'absences.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE absences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<bool> insertAbsence(DateTime date) async {
    try {
      final db = await database;
      await db.insert(
        'absences',
        {
          'date': date.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return true;
    } catch (e) {
      print('Błąd podczas dodawania nieobecności: \$e');
      return false;
    }
  }

  Future<List<DateTime>> getAbsences() async {
    try {
      final db = await database;
      final result = await db.query('absences', orderBy: 'date DESC');
      return result.map((row) => DateTime.parse(row['date'] as String)).toList();
    } catch (e) {
      print('Błąd podczas pobierania nieobecności: \$e');
      return [];
    }
  }

  Future<bool> deleteAbsence(DateTime date) async {
    try {
      final db = await database;
      final result = await db.delete(
        'absences',
        where: 'date = ?',
        whereArgs: [date.toIso8601String()],
      );
      return result > 0;
    } catch (e) {
      print('Błąd podczas usuwania nieobecności: \$e');
      return false;
    }
  }

  Future<List<DateTime>> getAbsencesForMonth(int year, int month) async {
    final absences = await getAbsences();
    return absences.where((date) => date.year == year && date.month == month).toList();
  }

  Future<int> getAbsenceCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM absences');
      return result.first['count'] as int;
    } catch (e) {
      print('Błąd podczas liczenia nieobecności: \$e');
      return 0;
    }
  }
}