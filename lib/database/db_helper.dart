import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sapi_model.dart';

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

  //  Simpan data menggunakan SapiModel
  Future<void> insertSapi(SapiModel sapi) async {
    final db = await database;
    await db.insert('history', sapi.toMap());
  }

  //  Ambil data dalam bentuk List<SapiModel>
  Future<List<SapiModel>> getSapiList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history', orderBy: 'id DESC');
    return maps.map((map) => SapiModel.fromMap(map)).toList();
  }

  //  Hapus data berdasarkan ID (BARU)
  Future<int> deleteSapi(int id) async {
    final db = await database;
    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -------------------------------------------------------------
  // ⚠️ METHOD LAMA (Dibiarkan ada agar tidak error jika dipanggil)
  // -------------------------------------------------------------
  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('history', data);
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final db = await database;
    return await db.query('history', orderBy: 'id DESC');
  }
}