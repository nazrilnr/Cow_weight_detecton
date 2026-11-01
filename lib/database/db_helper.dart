import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sapi_model.dart';

class DBHelper {
  static const String _dataKey = 'sapi_list';
  static const String _lastIdKey = 'sapi_last_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _readAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_dataKey);

    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _writeAll(List<Map<String, dynamic>> items) async {
    final prefs = await _prefs;
    await prefs.setString(_dataKey, jsonEncode(items));
  }

  // Simpan data menggunakan SapiModel
  Future<void> insertSapi(SapiModel sapi) async {
    final prefs = await _prefs;
    final items = await _readAll();

    final nextId = (prefs.getInt(_lastIdKey) ?? 0) + 1;
    final map = sapi.toMap();
    map['id'] = nextId;
    items.add(map);

    await prefs.setInt(_lastIdKey, nextId);
    await _writeAll(items);
  }

  // Ambil data dalam bentuk List<SapiModel>
  Future<List<SapiModel>> getSapiList() async {
    final items = await _readAll();
    items.sort(_sortByIdDesc);
    return items.map((map) => SapiModel.fromMap(map)).toList();
  }

  // Hapus data berdasarkan ID
  Future<int> deleteSapi(int id) async {
    final items = await _readAll();
    final before = items.length;
    items.removeWhere((item) => item['id'] == id);
    await _writeAll(items);
    return before - items.length;
  }

  // -------------------------------------------------------------
  // ⚠️ METHOD LAMA (Dibiarkan ada agar tidak error jika dipanggil)
  // -------------------------------------------------------------
  Future<void> insertData(Map<String, dynamic> data) async {
    final items = await _readAll();

    if (data['id'] == null) {
      final prefs = await _prefs;
      final nextId = (prefs.getInt(_lastIdKey) ?? 0) + 1;
      data['id'] = nextId;
      await prefs.setInt(_lastIdKey, nextId);
    }

    items.add(data);
    await _writeAll(items);
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final items = await _readAll();
    items.sort(_sortByIdDesc);
    return items;
  }

  int _sortByIdDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final idA = (a['id'] as num?)?.toInt() ?? 0;
    final idB = (b['id'] as num?)?.toInt() ?? 0;
    return idB.compareTo(idA);
  }
}
