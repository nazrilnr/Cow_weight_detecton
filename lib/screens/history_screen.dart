import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];

  bool isSelecting = false;
  Set<int> selectedIds = {};

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= LOAD =================
  void loadData() async {
    final db = DBHelper();
    final result = await db.getData();

    setState(() {
      data = result;
      filteredData = result;
    });
  }

  // ================= FORMAT ANGKA =================
  String format(dynamic value) {
    return double.parse(value.toString()).toStringAsFixed(2);
  }

  // ================= SEARCH =================
  void search(String keyword) {
    final results = data.where((item) {
      return item['nama_sapi']
          .toLowerCase()
          .contains(keyword.toLowerCase());
    }).toList();

    setState(() {
      filteredData = results;
    });
  }

  // ================= SELECT =================
  void toggleSelect(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void selectAll() {
    setState(() {
      selectedIds =
          filteredData.map((e) => e['id'] as int).toSet();
    });
  }

  void clearSelection() {
    setState(() {
      selectedIds.clear();
      isSelecting = false;
    });
  }

  // ================= EXPORT PDF =================
  Future<void> exportData() async {
    final exportList =
        data.where((e) => selectedIds.contains(e['id'])).toList();

    if (exportList.isEmpty) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("History Sapi",
                style: pw.TextStyle(fontSize: 20)),

            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              headers: ["Nama", "Lingkar", "Panjang", "Berat"],
              data: exportList.map((item) {
                return [
                  item['nama_sapi'],
                  "${format(item['lingkar_dada'])} cm",
                  "${format(item['panjang_badan'])} cm",
                  "${format(item['berat'])} kg",
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSelecting
            ? Text("${selectedIds.length} dipilih")
            : Text("History"),
        actions: [
          if (!isSelecting)
            IconButton(
              icon: Icon(Icons.checklist),
              onPressed: () {
                setState(() => isSelecting = true);
              },
            ),

          if (isSelecting)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: clearSelection,
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: search,
              decoration: InputDecoration(
                hintText: "Cari nama sapi...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 📋 LIST
          Expanded(
            child: filteredData.isEmpty
                ? Center(child: Text("Tidak ada data"))
                : ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final id = item['id'];

                      return Card(
                        margin: EdgeInsets.all(10),
                        child: ListTile(
                          leading: isSelecting
                              ? Checkbox(
                                  value:
                                      selectedIds.contains(id),
                                  onChanged: (_) =>
                                      toggleSelect(id),
                                )
                              : null,
                          title: Text(item['nama_sapi']),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Lingkar: ${format(item['lingkar_dada'])} cm"),
                              Text(
                                  "Panjang: ${format(item['panjang_badan'])} cm"),
                              Text(
                                  "Berat: ${format(item['berat'])} kg"),
                            ],
                          ),
                          onTap: isSelecting
                              ? () => toggleSelect(id)
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          // 🔘 ACTION BUTTON
          if (isSelecting)
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectAll,
                      icon: Icon(Icons.select_all),
                      label: Text("Pilih Semua"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: exportData,
                      icon: Icon(Icons.picture_as_pdf),
                      label: Text("Export PDF"),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}