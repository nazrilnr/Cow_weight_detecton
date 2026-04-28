import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ================= WARNA TEMA =================
const Color _colorDarkTeal = Color(0xFF1C7482);
const Color _colorLightCyan = Color(0xFFD4F9F9);
const Color _colorMediumTeal = Color(0xFF1BAAB4);
const Color _colorBrightCyan = Color(0xFF38D0D8);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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

  // ================= FORMAT ANGKA & TANGGAL =================
  String formatNumber(dynamic value) {
    return double.parse(value.toString()).toStringAsFixed(0);
  }

  String formatDate(String dateString) {
    try {
      DateTime dt = DateTime.parse(dateString);
      List<String> months = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (e) {
      return dateString;
    }
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
      
      // Jika tidak ada yang dipilih lagi, otomatis keluar dari mode select
      if (selectedIds.isEmpty) {
        isSelecting = false;
      }
    });
  }

  void selectAll() {
    setState(() {
      selectedIds = filteredData.map((e) => e['id'] as int).toSet();
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
            pw.Text("Riwayat Sapi", style: pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ["Nama", "Lingkar", "Panjang", "Berat"],
              data: exportList.map((item) {
                return [
                  item['nama_sapi'],
                  "${formatNumber(item['lingkar_dada'])} cm",
                  "${formatNumber(item['panjang_badan'])} cm",
                  "${formatNumber(item['berat'])} kg",
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

  // ================= UI MAIN =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _colorDarkTeal,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isSelecting ? "${selectedIds.length} dipilih" : "Riwayat",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isSelecting)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: clearSelection,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            child: TextField(
              controller: searchController,
              onChanged: search,
              style: const TextStyle(color: _colorDarkTeal),
              decoration: InputDecoration(
                hintText: "Cari Sapi",
                hintStyle: TextStyle(
                  color: _colorMediumTeal.withOpacity(0.7),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: _colorMediumTeal),
                filled: true,
                fillColor: _colorLightCyan,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔘 TOMBOL PILIH
          if (!isSelecting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => isSelecting = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorBrightCyan,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      "Pilih",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // 📋 LIST DATA
          Expanded(
            child: filteredData.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada data",
                      style: TextStyle(color: _colorMediumTeal),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final id = item['id'];
                      final isSelected = selectedIds.contains(id);
                      final tanggalStr = item['tanggal'] ?? "";

                      const String dummyAkurasi = "95";
                      const String dummyJenis = "Limosin"; 

                      return GestureDetector(
                        onTap: isSelecting ? () => toggleSelect(id) : null,
                        onLongPress: () {
                          if (!isSelecting) {
                            setState(() {
                              isSelecting = true;
                              selectedIds.add(id); // Otomatis memilih card yang ditekan
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          color: Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Checkbox saat mode Pilih
                              if (isSelecting)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10, right: 12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: _colorBrightCyan,
                                      side: const BorderSide(color: _colorMediumTeal),
                                      onChanged: (_) => toggleSelect(id),
                                    ),
                                  ),
                                ),

                              // Konten Riwayat
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Nama & Tanggal
                                    Text(
                                      item['nama_sapi'],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tanggalStr.isNotEmpty ? formatDate(tanggalStr) : "-",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Box Hijau Muda (Data Grid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _colorLightCyan,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(color: _colorBrightCyan, width: 2)
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _ResultItemBox(
                                                  value: formatNumber(item['berat']),
                                                  unit: "kg",
                                                  label: "Berat Badan",
                                                  alignment: CrossAxisAlignment.start,
                                                ),
                                              ),
                                              Expanded(
                                                child: _ResultItemBox(
                                                  value: formatNumber(item['lingkar_dada']),
                                                  unit: "cm",
                                                  label: "Lingkar Dada",
                                                  alignment: CrossAxisAlignment.center,
                                                ),
                                              ),
                                              Expanded(
                                                child: _ResultItemBox(
                                                  value: formatNumber(item['panjang_badan']),
                                                  unit: "cm",
                                                  label: "Panjang",
                                                  alignment: CrossAxisAlignment.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Expanded(
                                                child: _ResultItemBox(
                                                  value: dummyAkurasi,
                                                  unit: "%",
                                                  label: "Akurasi",
                                                  alignment: CrossAxisAlignment.start,
                                                ),
                                              ),
                                              Expanded(
                                                child: _ResultItemBox(
                                                  value: dummyJenis,
                                                  unit: "",
                                                  label: "Jenis Sapi",
                                                  alignment: CrossAxisAlignment.center,
                                                ),
                                              ),
                                              Expanded(child: SizedBox()),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      // ================= TOMBOL BAWAH (DIPINDAH KE SINI AGAR TIDAK KETUMPUK) =================
      bottomNavigationBar: isSelecting
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.05),
                  //     blurRadius: 10,
                  //     offset: const Offset(0, -5),
                  //   )
                  // ],
                ),
                child: Row(
                  children: [
                    // Tombol Pilih Semua
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: selectAll,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _colorDarkTeal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.select_all, color: _colorDarkTeal, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Pilih Semua",
                                  style: TextStyle(
                                    color: _colorDarkTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Tombol Export PDF
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: exportData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colorBrightCyan,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Export PDF",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ================= KOMPONEN UI TAMBAHAN =================

class _ResultItemBox extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final CrossAxisAlignment alignment;

  const _ResultItemBox({
    required this.value,
    required this.unit,
    required this.label,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    TextAlign textAlign = TextAlign.left;
    if (alignment == CrossAxisAlignment.center) {
      textAlign = TextAlign.center;
    } else if (alignment == CrossAxisAlignment.end) {
      textAlign = TextAlign.right;
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        RichText(
          textAlign: textAlign,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: _colorDarkTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: " $unit",
                  style: const TextStyle(
                    color: _colorDarkTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: textAlign,
          style: const TextStyle(
            color: _colorMediumTeal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}