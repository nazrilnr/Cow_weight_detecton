import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class MeasurementScreen extends StatefulWidget {
  final File image;

  MeasurementScreen({required this.image});

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
    return sqrt(pow(p[0].dx - p[1].dx, 2) +
        pow(p[0].dy - p[1].dy, 2));
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
                  pixelPerCm = pixel / cm;
                  isKalibrasi = false;
                  kalibrasi.clear();
                });

                Navigator.pop(context);
              },
              child: Text("OK"),
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
      appBar: AppBar(
        title: Text(isKalibrasi ? "Kalibrasi" : "Ukur Sapi"),
      ),
      body: Column(
        children: [
          Expanded(
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

                    // 🔴 TITIK DRAG
                    ...kalibrasi.asMap().entries.map((e) =>
                        titik(e.value, Colors.red, e.key, true)),

                    // 🔵 TITIK DRAG
                    ...ukur.asMap().entries.map((e) =>
                        titik(e.value, Colors.blue, e.key, false)),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              isKalibrasi
                  ? "Tap 2 titik MERAH (bisa digeser)"
                  : "Tap 2 titik BIRU (bisa digeser)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: resetPoints,
                  child: Text("Reset"),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: handleNext,
                  child:
                      Text(isKalibrasi ? "Next" : "Selesai"),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),
        ],
      ),
    );
  }

  // ================= DRAG TITIK =================
  Widget titik(
      Offset p, Color color, int index, bool isKalib) {
    return Positioned(
      left: p.dx - 10,
      top: p.dy - 10,
      child: GestureDetector(
        onPanUpdate: (details) {
          final RenderBox box =
              _imageKey.currentContext!.findRenderObject()
                  as RenderBox;

          final local =
              box.globalToLocal(details.globalPosition);

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
            border:
                Border.all(color: Colors.white, width: 2),
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
      ..strokeWidth = 3;

    canvas.drawLine(points[0], points[1], paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}