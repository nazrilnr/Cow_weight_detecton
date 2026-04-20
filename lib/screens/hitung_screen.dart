import 'package:flutter/material.dart';
import '../utils/calculator.dart';
import '../database/db_helper.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class HitungScreen extends StatefulWidget {
  @override
  _HitungScreenState createState() => _HitungScreenState();
}

class _HitungScreenState extends State<HitungScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController lingkarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();

  double hasil = 0;

  File? _imageLingkar;
  File? _imagePanjang;

  // 🔴 KALIBRASI
  List<Offset> _kalibrasiLingkar = [];
  List<Offset> _kalibrasiPanjang = [];

  // 🔵 UKUR
  List<Offset> _ukurLingkar = [];
  List<Offset> _ukurPanjang = [];

  double? pixelPerCmLingkar;
  double? pixelPerCmPanjang;

  bool isKalibrasiLingkar = true;
  bool isKalibrasiPanjang = true;

  // ================= RESET =================
  void resetLingkar() {
    _kalibrasiLingkar.clear();
    _ukurLingkar.clear();
    pixelPerCmLingkar = null;
    isKalibrasiLingkar = true;
  }

  void resetPanjang() {
    _kalibrasiPanjang.clear();
    _ukurPanjang.clear();
    pixelPerCmPanjang = null;
    isKalibrasiPanjang = true;
  }

  // ================= HITUNG =================
  void hitung() {
    double lingkar = double.tryParse(lingkarController.text) ?? 0;
    double panjang = double.tryParse(panjangController.text) ?? 0;

    if (lingkar <= 0 || panjang <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Isi data dulu")));
      return;
    }

    setState(() {
      hasil = hitungBeratSapi(lingkar, panjang);
    });
  }

  // ================= SIMPAN =================
  void simpanData() async {
    DBHelper db = DBHelper();

    await db.insertData({
      'nama_sapi': namaController.text,
      'lingkar_dada': double.tryParse(lingkarController.text) ?? 0,
      'panjang_badan': double.tryParse(panjangController.text) ?? 0,
      'berat': hasil,
      'tanggal': DateTime.now().toString(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Data tersimpan")));
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage(ImageSource source, String target) async {
    final picked = await ImagePicker().pickImage(source: source);

    if (picked != null) {
      setState(() {
        if (target == "lingkar") {
          _imageLingkar = File(picked.path);
          resetLingkar(); // 🔥 RESET
        } else {
          _imagePanjang = File(picked.path);
          resetPanjang(); // 🔥 RESET
        }
      });
    }
  }

  void showSource(String target) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text("Kamera"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera, target);
            },
          ),
          ListTile(
            title: Text("Galeri"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery, target);
            },
          ),
        ],
      ),
    );
  }

  // ================= KALIBRASI =================
  void inputKalibrasi(double pixel, bool isLingkar) {
    TextEditingController cmController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Kalibrasi"),
        content: TextField(
          controller: cmController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Panjang (cm)"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              double cm = double.tryParse(cmController.text) ?? 0;
              if (cm <= 0) return;

              setState(() {
                if (isLingkar) {
                  pixelPerCmLingkar = pixel / cm;
                  isKalibrasiLingkar = false;
                } else {
                  pixelPerCmPanjang = pixel / cm;
                  isKalibrasiPanjang = false;
                }
              });

              Navigator.pop(context);
            },
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  void prosesLingkar() {
    if (isKalibrasiLingkar && _kalibrasiLingkar.length == 2) {
      inputKalibrasi(_getDistance(_kalibrasiLingkar), true);
    } else if (!isKalibrasiLingkar && _ukurLingkar.length == 2) {
      double cm = _getDistance(_ukurLingkar) / pixelPerCmLingkar!;
      lingkarController.text = cm.toStringAsFixed(2);
    }
  }

  void prosesPanjang() {
    if (isKalibrasiPanjang && _kalibrasiPanjang.length == 2) {
      inputKalibrasi(_getDistance(_kalibrasiPanjang), false);
    } else if (!isKalibrasiPanjang && _ukurPanjang.length == 2) {
      double cm = _getDistance(_ukurPanjang) / pixelPerCmPanjang!;
      panjangController.text = cm.toStringAsFixed(2);
    }
  }

  double _getDistance(List<Offset> p) {
    return sqrt(pow(p[0].dx - p[1].dx, 2) +
        pow(p[0].dy - p[1].dy, 2));
  }

  Widget buildImageLingkar() {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          if (isKalibrasiLingkar) {
            if (_kalibrasiLingkar.length < 2) {
              _kalibrasiLingkar.add(details.localPosition);
            }
          } else {
            if (_ukurLingkar.length < 2) {
              _ukurLingkar.add(details.localPosition);
            }
          }
        });

        Future.delayed(Duration(milliseconds: 500), () {
          prosesLingkar();
        });
      },
      child: Stack(
        children: [
          Image.file(_imageLingkar!, height: 200),
          ..._kalibrasiLingkar.map((p) => titik(p, Colors.red)),
          ..._ukurLingkar.map((p) => titik(p, Colors.blue)),
        ],
      ),
    );
  }

  Widget buildImagePanjang() {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          if (isKalibrasiPanjang) {
            if (_kalibrasiPanjang.length < 2) {
              _kalibrasiPanjang.add(details.localPosition);
            }
          } else {
            if (_ukurPanjang.length < 2) {
              _ukurPanjang.add(details.localPosition);
            }
          }
        });

        Future.delayed(Duration(milliseconds: 500), () {
          prosesPanjang();
        });
      },
      child: Stack(
        children: [
          Image.file(_imagePanjang!, height: 200),
          ..._kalibrasiPanjang.map((p) => titik(p, Colors.red)),
          ..._ukurPanjang.map((p) => titik(p, Colors.blue)),
        ],
      ),
    );
  }

  Widget titik(Offset p, Color color) {
    return Positioned(
      left: p.dx - 6,
      top: p.dy - 6,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hitung Sapi")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(labelText: "Nama Sapi"),
            ),

            SizedBox(height: 10),

            TextField(
              controller: lingkarController,
              decoration: InputDecoration(
                labelText: "Lingkar Dada",
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () => showSource("lingkar"),
                ),
              ),
            ),

            if (_imageLingkar != null) buildImageLingkar(),

            SizedBox(height: 20),

            TextField(
              controller: panjangController,
              decoration: InputDecoration(
                labelText: "Panjang Badan",
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () => showSource("panjang"),
                ),
              ),
            ),

            if (_imagePanjang != null) buildImagePanjang(),

            SizedBox(height: 20),

            ElevatedButton(onPressed: hitung, child: Text("Hitung")),

            SizedBox(height: 10),

            Text("Berat: ${hasil.toStringAsFixed(2)} kg"),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: simpanData,
              child: Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}