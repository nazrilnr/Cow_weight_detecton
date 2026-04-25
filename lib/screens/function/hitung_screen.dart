import 'package:flutter/material.dart';
import '../../utils/calculator.dart';
import '../../database/db_helper.dart';
import 'measurement_screen.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HitungScreen extends StatefulWidget {
  const HitungScreen({super.key});

  @override
  _HitungScreenState createState() => _HitungScreenState();
}

class _HitungScreenState extends State<HitungScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController lingkarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();

  double hasil = 0;

  // ================= VALIDATOR =================
  String? validateText(String? value) {
    if (value == null || value.isEmpty) {
      return "Wajib diisi";
    }
    return null;
  }

  String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Wajib diisi";
    }
    if (double.tryParse(value) == null) {
      return "Harus angka";
    }
    return null;
  }

  // ================= HITUNG =================
  void hitung() {
    if (!_formKey.currentState!.validate()) return;

    double lingkar = double.parse(lingkarController.text);
    double panjang = double.parse(panjangController.text);

    setState(() {
      hasil = hitungBeratSapi(lingkar, panjang);
    });
  }

  // ================= SIMPAN =================
  void simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    if (hasil == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hitung dulu sebelum simpan")),
      );
      return;
    }

    DBHelper db = DBHelper();

    await db.insertData({
      'nama_sapi': namaController.text,
      'lingkar_dada': double.parse(lingkarController.text),
      'panjang_badan': double.parse(panjangController.text),
      'berat': hasil,
      'tanggal': DateTime.now().toString(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data tersimpan")),
    );
  }

  // ================= OPEN MEASUREMENT =================
  Future<void> openMeasurement(bool isLingkar) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MeasurementScreen(
            image: File(picked.path),
          ),
        ),
      );

      if (result != null) {
        setState(() {
          if (isLingkar) {
            lingkarController.text =
                (result as double).toStringAsFixed(2);
          } else {
            panjangController.text =
                (result as double).toStringAsFixed(2);
          }
        });
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hitung Sapi")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey, // 🔥 PENTING
          child: Column(
            children: [
              // 🐄 Nama
              TextFormField(
                controller: namaController,
                validator: validateText,
                decoration: InputDecoration(
                  labelText: "Nama Sapi",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 16),

              // 📏 Lingkar
              TextFormField(
                controller: lingkarController,
                keyboardType: TextInputType.number,
                validator: validateNumber,
                decoration: InputDecoration(
                  labelText: "Lingkar Dada (cm)",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.camera_alt),
                    onPressed: () => openMeasurement(true),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 📏 Panjang
              TextFormField(
                controller: panjangController,
                keyboardType: TextInputType.number,
                validator: validateNumber,
                decoration: InputDecoration(
                  labelText: "Panjang Badan (cm)",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.camera_alt),
                    onPressed: () => openMeasurement(false),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // 🔘 HITUNG
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hitung,
                  child: Text("Hitung"),
                ),
              ),

              SizedBox(height: 16),

              // 📊 HASIL
              Text(
                "Berat: ${hasil.toStringAsFixed(2)} kg",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // 💾 SIMPAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: simpanData,
                  child: Text("Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}