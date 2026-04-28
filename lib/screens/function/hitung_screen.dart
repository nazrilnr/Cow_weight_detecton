import 'package:flutter/material.dart';
import '../../utils/calculator.dart';
import '../../database/db_helper.dart';
import 'measurement_screen.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';


// ================= WARNA TEMA =================
const Color _colorDarkTeal = Color(0xFF1C7482);
const Color _colorLightCyan = Color(0xFFD4F9F9);
const Color _colorMediumTeal = Color(0xFF1BAAB4);
const Color _colorBrightCyan = Color(0xFF38D0D8);

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

  // 🔥 Tambahkan variabel untuk menyimpan file foto
  File? fotoDepan;
  File? fotoSamping;

  // ================= VALIDATOR =================
  String? validateText(String? value) {
    if (value == null || value.isEmpty) return "Wajib diisi";
    return null;
  }

  String? validateNumber(String? value) {
    if (value == null || value.isEmpty) return "Wajib diisi";
    if (double.tryParse(value) == null) return "Harus angka";
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
        const SnackBar(content: Text("Hitung dulu sebelum simpan")),
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
      const SnackBar(content: Text("Data tersimpan")),
    );
  }

  // ================= OPEN MEASUREMENT =================
  Future<void> openMeasurement(bool isLingkar) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      File imageFile = File(picked.path);

      // 🔥 Simpan gambar yang dipilih ke state agar UI terupdate
      setState(() {
        if (isLingkar) {
          fotoDepan = imageFile;
        } else {
          fotoSamping = imageFile;
        }
      });

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MeasurementScreen(
            image: imageFile,
            isCurveMode: isLingkar,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _colorDarkTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: _colorDarkTeal),
        title: const Text(
          "Mooasure",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomInputField(
                  label: "Nama/ID Sapi",
                  hint: "Sapi A",
                  controller: namaController,
                  validator: validateText,
                ),

                const SizedBox(height: 20),

                _CustomInputField(
                  label: "Lingkar Dada (opsional)",
                  hint: "Masukan Lingkar Dada Sapi (cm)",
                  controller: lingkarController,
                  type: TextInputType.number,
                  validator: validateNumber,
                ),
                const SizedBox(height: 12),
                
                // 🔥 Kondisi jika fotoDepan ada, tampilkan gambarnya
                fotoDepan == null
                    ? _PhotoUploadBox(
                        title: "Tambahkan Foto Tampak Depan",
                        subtitle:
                            "Pastikan untuk mengambil foto dengan\npenerangan yang jelas dan foto di ambil dalam\njarak 2 meter",
                        onTap: () => openMeasurement(true),
                      )
                    : _ImageDisplayBox(
                        image: fotoDepan!,
                        onTap: () => openMeasurement(true),
                      ),

                const SizedBox(height: 20),

                _CustomInputField(
                  label: "Panjang Sapi (opsional)",
                  hint: "Masukan Panjang Sapi (cm)",
                  controller: panjangController,
                  type: TextInputType.number,
                  validator: validateNumber,
                ),
                const SizedBox(height: 12),

                // 🔥 Kondisi jika fotoSamping ada, tampilkan gambarnya
                fotoSamping == null
                    ? _PhotoUploadBox(
                        title: "Tambahkan Foto Tampak Samping",
                        subtitle:
                            "Pastikan untuk mengambil foto dengan\npenerangan yang jelas dan foto di ambil dalam\njarak 2 meter",
                        onTap: () => openMeasurement(false),
                      )
                    : _ImageDisplayBox(
                        image: fotoSamping!,
                        onTap: () => openMeasurement(false),
                      ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: hitung,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorBrightCyan,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Hitung",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (hasil > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: _colorLightCyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ResultItemBox(
                            value: hasil.toStringAsFixed(0),
                            unit: "kg",
                            label: "Berat Badan",
                          ),
                        ),
                        Expanded(
                          child: _ResultItemBox(
                            value: lingkarController.text,
                            unit: "cm",
                            label: "Lingkar Dada",
                            alignment: CrossAxisAlignment.center,
                          ),
                        ),
                        Expanded(
                          child: _ResultItemBox(
                            value: panjangController.text,
                            unit: "cm",
                            label: "Panjang",
                            alignment: CrossAxisAlignment.end,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: simpanData,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: _colorBrightCyan, // Warna garis tepi cyan
                          width: 1.5, // Ketebalan garis
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Sudut melengkung
                        ),
                        backgroundColor: Colors.transparent, // Background transparan
                      ),
                      child: const Text(
                        "Simpan",
                        style: TextStyle(
                          color: _colorBrightCyan, // Warna text cyan
                          fontSize: 16,
                          fontWeight: FontWeight.w600, // Text sedikit tebal
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= INPUT FIELD =================
class _CustomInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType type;
  final String? Function(String?)? validator;

  const _CustomInputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.type = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _colorDarkTeal, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _colorBrightCyan, 
              fontSize: 14, 
            ),
            filled: true,
            fillColor: _colorLightCyan,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ================= FOTO UPLOAD BOX (KOSONG) =================
class _PhotoUploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoUploadBox({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: _colorLightCyan,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.camera_alt_outlined, color: _colorDarkTeal),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: _colorDarkTeal, fontWeight: FontWeight.bold)),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// 🔥 ================= FOTO TERPILIH (TERISI) =================
class _ImageDisplayBox extends StatelessWidget {
  final File image;
  final VoidCallback onTap;

  const _ImageDisplayBox({
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              width: double.infinity,
              height: 200, // Tinggi dari kotak gambarnya
              fit: BoxFit.cover,
            ),
          ),
          // Tambahkan icon 'Edit' kecil di pojok kanan atas
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= RESULT =================
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
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text("$value $unit",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: _colorDarkTeal)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}