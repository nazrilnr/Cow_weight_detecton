import 'package:flutter/material.dart';
import '../../utils/calculator.dart';
import '../../database/db_helper.dart';
import '../../models/sapi_model.dart';
import 'measurement_screen.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ================= WARNA TEMA =================
const Color _colorDarkTeal = Color(0xFF1C7482);
const Color _colorLightCyan = Color(0xFFD4F9F9);
const Color _colorBrightCyan = Color(0xFF38D0D8);

class HitungScreen extends StatefulWidget {
  const HitungScreen({super.key});

  @override
  State<HitungScreen> createState() => _HitungScreenState();
}

class _HitungScreenState extends State<HitungScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController lingkarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();
  final TextEditingController tinggiController = TextEditingController(); // 🔥 Controller Baru

  double hasil = 0;

  File? fotoDepan;
  File? fotoSamping;

  @override
  void dispose() {
    namaController.dispose();
    lingkarController.dispose();
    panjangController.dispose();
    tinggiController.dispose();
    super.dispose();
  }

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

  // ================= HITUNG (RUMUS BARU) =================
  void hitung() {
    if (!_formKey.currentState!.validate()) return;

    double lingkar = double.parse(lingkarController.text);
    double panjang = double.parse(panjangController.text);
    double tinggi = double.parse(tinggiController.text);

    setState(() {
      hasil = hitungBeratSapi(
        lingkarDada: lingkar,
        panjangBadan: panjang,
        tinggiBadan: tinggi,
      );
    });
  }

  // ================= SIMPAN (SAPI MODEL) =================
  void simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    if (hasil == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hitung dulu sebelum simpan")),
      );
      return;
    }

    final sapiBaru = SapiModel(
      namaSapi: namaController.text,
      lingkarDada: double.parse(lingkarController.text),
      panjangBadan: double.parse(panjangController.text),
      tinggiBadan: double.parse(tinggiController.text), // 🔥 Simpan tinggi badan
      berat: hasil,
      tanggal: DateTime.now().toIso8601String(),
    );

    DBHelper db = DBHelper();
    await db.insertSapi(sapiBaru);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: _colorDarkTeal,
                size: 56,
              ),
              SizedBox(height: 12),
              Text(
                "Berhasil Disimpan",
                style: TextStyle(
                  color: _colorDarkTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            "Data pengukuran sapi telah berhasil tersimpan ke dalam riwayat.",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorBrightCyan,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= OPEN MEASUREMENT =================
  Future<void> openMeasurement(bool isLingkar) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (picked != null) {
      File imageFile = File(picked.path);

      setState(() {
        if (isLingkar) {
          fotoDepan = imageFile;
        } else {
          fotoSamping = imageFile;
        }
      });

      // Navigator mengarah ke screen pengukuran
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MeasurementScreen(
            image: imageFile,
            isCurveMode: isLingkar,
          ),
        ),
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          if (isLingkar) {
            // Jika hasil lingkar dada berupa double tunggal
            if (result is double) {
              lingkarController.text = result.toStringAsFixed(2);
            }
          } else {
            // Jika hasil samping mengembalikan Map { 'panjang': double, 'tinggi': double }
            if (result is Map<String, double>) {
              if (result['panjang'] != null) {
                panjangController.text = result['panjang']!.toStringAsFixed(2);
              }
              if (result['tinggi'] != null) {
                tinggiController.text = result['tinggi']!.toStringAsFixed(2);
              }
            } else if (result is double) {
              // Fallback jika measurement screen lama masih return 1 nilai panjang
              panjangController.text = result.toStringAsFixed(2);
            }
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
        iconTheme: const IconThemeData(color: Colors.white),
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

                // ================= FORM PANJANG & TINGGI (FOTO SAMPING) =================
                Row(
                  children: [
                    Expanded(
                      child: _CustomInputField(
                        label: "Panjang Sapi",
                        hint: "Panjang (cm)",
                        controller: panjangController,
                        type: TextInputType.number,
                        validator: validateNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CustomInputField(
                        label: "Tinggi Sapi",
                        hint: "Tinggi (cm)",
                        controller: tinggiController,
                        type: TextInputType.number,
                        validator: validateNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                fotoSamping == null
                    ? _PhotoUploadBox(
                        title: "Tambahkan Foto Tampak Samping",
                        subtitle:
                            "Ukur panjang & tinggi sapi sekaligus dalam\nsatu foto tampak samping (jarak 2 meter)",
                        onTap: () => openMeasurement(false),
                      )
                    : _ImageDisplayBox(
                        image: fotoSamping!,
                        onTap: () => openMeasurement(false),
                      ),

                const SizedBox(height: 20),

                // ================= FORM LINGKAR DADA (FOTO DEPAN) =================
                _CustomInputField(
                  label: "Lingkar Dada",
                  hint: "Masukan Lingkar Dada Sapi (cm)",
                  controller: lingkarController,
                  type: TextInputType.number,
                  validator: validateNumber,
                ),
                const SizedBox(height: 12),

                fotoDepan == null
                    ? _PhotoUploadBox(
                        title: "Tambahkan Foto Tampak Depan",
                        subtitle:
                            "Pastikan untuk mengambil foto dengan\npenerangan jelas dan jarak 2 meter",
                        onTap: () => openMeasurement(true),
                      )
                    : _ImageDisplayBox(
                        image: fotoDepan!,
                        onTap: () => openMeasurement(true),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (hasil > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: _colorLightCyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ResultItemBox(
                                value: hasil.toStringAsFixed(2),
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
                          ],
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        Row(
                          children: [
                            Expanded(
                              child: _ResultItemBox(
                                value: panjangController.text,
                                unit: "cm",
                                label: "Panjang Badan",
                              ),
                            ),
                            Expanded(
                              child: _ResultItemBox(
                                value: tinggiController.text,
                                unit: "cm",
                                label: "Tinggi Badan",
                                alignment: CrossAxisAlignment.center,
                              ),
                            ),
                          ],
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
                          color: _colorBrightCyan,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: const Text(
                        "Simpan",
                        style: TextStyle(
                          color: _colorBrightCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
        Text(
          label,
          style: const TextStyle(
            color: _colorDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
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

// ================= FOTO UPLOAD BOX =================
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: _colorLightCyan,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.camera_alt_outlined, color: _colorDarkTeal),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: _colorDarkTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= FOTO TERPILIH =================
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
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
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
        Text(
          "$value $unit",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _colorDarkTeal,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}