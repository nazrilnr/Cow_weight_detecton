import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

// ================= WARNA =================
const Color _colorDarkTeal = Color(0xFF1C7482);
const Color _colorBrightCyan = Color(0xFF38D0D8);

class MeasurementScreen extends StatefulWidget {
  final File image;
  final bool isCurveMode; // 🔥 true = lengkung, false = garis

  const MeasurementScreen({
    super.key,
    required this.image,
    required this.isCurveMode,
  });

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

  // ================= GARIS LURUS =================
  double getDistance(List<Offset> p) {
    return sqrt(pow(p[0].dx - p[1].dx, 2) + pow(p[0].dy - p[1].dy, 2));
  }

  // ================= GARIS LENGKUNG =================
  double getPolylineLength(List<Offset> pts) {
    double total = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += sqrt(
        pow(pts[i].dx - pts[i + 1].dx, 2) +
            pow(pts[i].dy - pts[i + 1].dy, 2),
      );
    }
    return total;
  }

  // ================= CONVERT =================
  Offset toImageSpace(Offset localPosition) {
    final Matrix4 inverse = Matrix4.inverted(_controller.value);
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
        if (widget.isCurveMode) {
          ukur.add(corrected); // 🔥 MULTI TITIK
        } else {
          if (ukur.length < 2) ukur.add(corrected); // 🔥 GARIS LURUS
        }
      }
    });
  }

  // ================= UNDO =================
  void undoPoint() {
    setState(() {
      if (isKalibrasi && kalibrasi.isNotEmpty) {
        kalibrasi.removeLast();
      } else if (!isKalibrasi && ukur.isNotEmpty) {
        ukur.removeLast();
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
          title: const Text("Kalibrasi"),
          content: TextField(
            controller: cmController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: "Masukkan panjang (cm)"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
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
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      if (ukur.length < 2) return;

      double pixel = widget.isCurveMode
          ? getPolylineLength(ukur)
          : getDistance(ukur);

      double cm = pixel / pixelPerCm!;

      Navigator.pop(context, cm);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    double? cmPreview;

    if (!isKalibrasi && pixelPerCm != null && ukur.length >= 2) {
      double pixel = widget.isCurveMode
          ? getPolylineLength(ukur)
          : getDistance(ukur);

      cmPreview = pixel / pixelPerCm!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isKalibrasi
            ? "Kalibrasi"
            : widget.isCurveMode
                ? "Ukur Lingkar Dada"
                : "Ukur Panjang"),
        backgroundColor: _colorDarkTeal,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _controller,
              maxScale: 5,
              minScale: 1,
              child: GestureDetector(
                onTapDown: handleTap,
                child: Stack(
                  key: _imageKey,
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: Image.file(widget.image)),

                    // 🔴 KALIBRASI
                    if (kalibrasi.length >= 2)
                      CustomPaint(
                        painter: LinePainter(kalibrasi, Colors.red),
                        size: Size.infinite,
                      ),

                    // 🔵 UKUR
                    if (ukur.length >= 2)
                      CustomPaint(
                        painter: LinePainter(ukur, Colors.blue),
                        size: Size.infinite,
                      ),

                    // 🔴 TITIK
                    ...kalibrasi.asMap().entries.map(
                        (e) => titik(e.value, Colors.red, e.key, true)),

                    // 🔵 TITIK
                    ...ukur.asMap().entries.map(
                        (e) => titik(e.value, Colors.blue, e.key, false)),
                  ],
                ),
              ),
            ),
          ),

          // 🔥 PREVIEW
          if (!isKalibrasi)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                cmPreview == null
                    ? "Panjang: -"
                    : "Panjang: ${cmPreview.toStringAsFixed(2)} cm",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

          // 🔘 BUTTON
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: resetPoints,
                  child: const Text("Reset"),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: undoPoint,
                  child: const Text("Undo"),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: handleNext,
                  child: Text(isKalibrasi ? "Next" : "Selesai"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TITIK =================
  Widget titik(Offset p, Color color, int index, bool isKalib) {
    return Positioned(
      left: p.dx - 10,
      top: p.dy - 10,
      child: GestureDetector(
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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

// ================= LINE =================
class LinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  LinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}