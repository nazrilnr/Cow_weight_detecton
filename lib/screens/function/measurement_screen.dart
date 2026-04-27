import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

// ================= WARNA TEMA =================
const Color _colorDarkTeal = Color(0xFF1C7482);
const Color _colorBrightCyan = Color(0xFF38D0D8);
const Color _colorMediumTeal = Color(0xFF1BAAB4);

class MeasurementScreen extends StatefulWidget {
  final File image;

  const MeasurementScreen({super.key, required this.image});

  @override
  _MeasurementScreenState createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  List<Offset> kalibrasi = [];
  List<Offset> ukur = [];

  bool isKalibrasi = true;
  double? pixelPerCm;

  final TransformationController _controller = TransformationController();
  final GlobalKey _imageKey = GlobalKey();

  // ================= DISTANCE =================
  double getDistance(List<Offset> p) {
    return sqrt(pow(p[0].dx - p[1].dx, 2) + pow(p[0].dy - p[1].dy, 2));
  }

  // ================= CONVERT COORD =================
  Offset toImageSpace(Offset localPosition) {
    final Matrix4 matrix = _controller.value;
    final Matrix4 inverse = Matrix4.inverted(matrix);

    return MatrixUtils.transformPoint(inverse, localPosition);
  }

  // ================= TAP =================
  void handleTap(TapDownDetails details) {
    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;

    final local = box.globalToLocal(details.globalPosition);
    final corrected = toImageSpace(local);

    setState(() {
      if (isKalibrasi) {
        if (kalibrasi.length < 2) kalibrasi.add(corrected);
      } else {
        if (ukur.length < 2) ukur.add(corrected);
      }
    });
  }

  // ================= RESET =================
  void resetPoints() {
    setState(() {
      if (isKalibrasi) {
        kalibrasi.clear();
      } else {
        ukur.clear();
      }
    });
  }

  // ================= NEXT =================
  void handleNext() {
    if (isKalibrasi) {
      if (kalibrasi.length < 2) return;

      double pixel = getDistance(kalibrasi);

      TextEditingController cmController = TextEditingController();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Kalibrasi",
            style: TextStyle(
              color: _colorDarkTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: cmController,
            keyboardType: TextInputType.number,
            cursorColor: _colorDarkTeal,
            decoration: const InputDecoration(
              labelText: "Masukkan Panjang Aktual (cm)",
              labelStyle: TextStyle(color: _colorMediumTeal),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _colorBrightCyan),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Batal",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                double cm = double.tryParse(cmController.text) ?? 0;
                if (cm <= 0) return;

                setState(() {
                  pixelPerCm = pixel / cm;
                  isKalibrasi = false;
                  kalibrasi.clear();
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorBrightCyan,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      );
    } else {
      if (ukur.length < 2) return;

      double pixel = getDistance(ukur);
      double cm = pixel / pixelPerCm!;

      Navigator.pop(context, cm);
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
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isKalibrasi ? "Kalibrasi Foto" : "Ukur Sapi",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🖼️ AREA GAMBAR
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5), // Background abu-abu muda agar foto lebih menonjol
              width: double.infinity,
              child: InteractiveViewer(
                transformationController: _controller,
                maxScale: 5,
                minScale: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: handleTap,
                  child: Stack(
                    key: _imageKey,
                    clipBehavior: Clip.none,
                    children: [
                      Center(child: Image.file(widget.image)),

                      // 🔴 GARIS KALIBRASI
                      if (kalibrasi.length == 2)
                        CustomPaint(
                          painter: LinePainter(kalibrasi, Colors.red),
                          size: Size.infinite,
                        ),

                      // 🔵 GARIS UKUR
                      if (ukur.length == 2)
                        CustomPaint(
                          painter: LinePainter(ukur, Colors.blue),
                          size: Size.infinite,
                        ),

                      // 🔴 TITIK DRAG KALIBRASI
                      ...kalibrasi.asMap().entries.map(
                          (e) => titik(e.value, Colors.red, e.key, true)),

                      // 🔵 TITIK DRAG UKUR
                      ...ukur.asMap().entries.map(
                          (e) => titik(e.value, Colors.blue, e.key, false)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🎛️ PANEL KONTROL BAWAH
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ℹ️ INSTRUKSI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isKalibrasi ? Icons.straighten : Icons.photo_size_select_large,
                        color: isKalibrasi ? Colors.red : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isKalibrasi
                            ? "Tap 2 titik MERAH (bisa digeser)"
                            : "Tap 2 titik BIRU (bisa digeser)",
                        style: const TextStyle(
                          color: _colorDarkTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🔘 TOMBOL AKSI
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: resetPoints,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _colorDarkTeal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Reset",
                              style: TextStyle(
                                color: _colorDarkTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorBrightCyan,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isKalibrasi ? "Next" : "Selesai",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DRAG TITIK =================
  Widget titik(Offset p, Color color, int index, bool isKalib) {
    return Positioned(
      left: p.dx - 15, // Disesuaikan sedikit hitbox-nya agar lebih mudah ditarik
      top: p.dy - 15,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          final RenderBox box =
              _imageKey.currentContext!.findRenderObject() as RenderBox;

          final local = box.globalToLocal(details.globalPosition);
          final corrected = toImageSpace(local);

          setState(() {
            if (isKalib) {
              kalibrasi[index] = corrected;
            } else {
              ukur[index] = corrected;
            }
          });
        },
        child: Container(
          width: 30, // Area sentuh diperbesar sedikit
          height: 30,
          alignment: Alignment.center,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= LINE PAINTER =================
class LinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  LinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8) // Sedikit transparan agar tidak menutupi fitur sapi
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(points[0], points[1], paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}