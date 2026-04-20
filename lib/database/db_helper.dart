import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'sapi.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_sapi TEXT,
            lingkar_dada REAL,
            panjang_badan REAL,
            berat REAL,
            tanggal TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('history', data);
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final db = await database;
    return await db.query('history', orderBy: 'id DESC');
  }
}