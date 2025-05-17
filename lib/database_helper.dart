import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fortune.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL,
  password TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  type TEXT NOT NULL,
  result TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id)
)
''');
  }

  Future<int> createUser(String username, String password) async {
    final db = await instance.database;
    return await db.insert('users', {'username': username, 'password': password});
  }

  Future<bool> authenticateUser(String username, String password) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return results.isNotEmpty;
  }

  Future<int> addHistory(int userId, String type, String result) async {
    final db = await instance.database;
    return await db.insert('history', {
      'user_id': userId,
      'type': type,
      'result': result,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(int userId) async {
    final db = await instance.database;
    return await db.query(
      'history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC', // Добавляем сортировку по убыванию
    );
  }

  Future<int> getUserId(String username) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (results.isNotEmpty) {
      return results.first['id'] as int;
    }
    return -1;
  }

  Future<void> deleteHistoryItem(int id) async {
    final db = await instance.database;
    await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
