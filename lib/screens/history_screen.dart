import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> data = [];

  void loadData() async {
    DBHelper dbHelper = DBHelper();
    final result = await dbHelper.getData();

    setState(() {
      data = result;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("History")),
      body: data.isEmpty
          ? Center(child: Text("Belum ada data"))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(data[index]['nama_sapi']),
                  subtitle: Text(
                    "Berat: ${data[index]['berat'].toStringAsFixed(2)} kg",
                  ),
                );
              },
            ),
    );
  }
}