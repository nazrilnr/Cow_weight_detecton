import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

// ================= WARNA =================
const Color _colorDarkTeal = Color(0xFF1C7482);
const Color _colorBrightCyan = Color(0xFF38D0D8);

class MeasurementScreen extends StatefulWidget {
  final File image;
  final bool isCurveMode; // 🔥 true = lengkung (depan), false = garis (samping: panjang & tinggi)

  const MeasurementScreen({
    super.key,
    required this.image,
    required this.isCurveMode,
  });

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  List<Offset> kalibrasi = [];
  List<Offset> ukurPanjang = [];
  List<Offset> ukurTinggi = [];
  List<Offset> ukurLingkar = [];

  // Step: 0 = Kalibrasi, 1 = Ukur Panjang (atau Lingkar), 2 = Ukur Tinggi
  int currentStep = 0;

  double? pixelPerCm;
  double? kalibrasiCm;

  int _pointerCount = 0;
  int _rotationQuarterTurns = 0; // 🔥 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°

  final TransformationController _controller = TransformationController();
  final GlobalKey _imageKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================= ROTATE GAMBAR =================
  void rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      kalibrasi.clear();
      ukurPanjang.clear();
      ukurTinggi.clear();
      ukurLingkar.clear();
      currentStep = 0;
      pixelPerCm = null;
    });
  }

  // ================= JARAK DUA TITIK =================
  double getDistance(List<Offset> p) {
    if (p.length < 2) return 0;
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

  // ================= TAP (PRESISI TITIK GAMBAR) =================
  void handleTap(TapUpDetails details) {
    if (_pointerCount > 1) return;

    final RenderBox? box =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;

    if (box == null) return;

    final Offset localPos = box.globalToLocal(details.globalPosition);

    setState(() {
      if (currentStep == 0) {
        if (kalibrasi.length < 2) kalibrasi.add(localPos);
      } else if (widget.isCurveMode) {
        ukurLingkar.add(localPos);
      } else {
        if (currentStep == 1) {
          if (ukurPanjang.length < 2) ukurPanjang.add(localPos);
        } else if (currentStep == 2) {
          if (ukurTinggi.length < 2) ukurTinggi.add(localPos);
        }
      }
    });
  }

  // ================= UNDO =================
  void undoPoint() {
    setState(() {
      if (currentStep == 0 && kalibrasi.isNotEmpty) {
        kalibrasi.removeLast();
      } else if (widget.isCurveMode && ukurLingkar.isNotEmpty) {
        ukurLingkar.removeLast();
      } else if (currentStep == 1 && ukurPanjang.isNotEmpty) {
        ukurPanjang.removeLast();
      } else if (currentStep == 2 && ukurTinggi.isNotEmpty) {
        ukurTinggi.removeLast();
      }
    });
  }

  // ================= RESET =================
  void resetPoints() {
    setState(() {
      if (currentStep == 0) {
        kalibrasi.clear();
      } else if (widget.isCurveMode) {
        ukurLingkar.clear();
      } else if (currentStep == 1) {
        ukurPanjang.clear();
      } else if (currentStep == 2) {
        ukurTinggi.clear();
      }
    });
  }

  // ================= NEXT / LANJUT =================
  void handleNext() {
    // TAHAP 1: SELESAIKAN KALIBRASI
    if (currentStep == 0) {
      if (kalibrasi.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tandai 2 titik acuan kalibrasi terlebih dahulu")),
        );
        return;
      }

      double pixel = getDistance(kalibrasi);
      TextEditingController cmController = TextEditingController();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Masukkan Panjang Aktual Objek (cm)",
                style: TextStyle(
                  color: _colorDarkTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cmController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: _colorDarkTeal),
                decoration: InputDecoration(
                  hintText: "Contoh: 20",
                  hintStyle: TextStyle(
                    color: _colorDarkTeal.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: _colorBrightCyan.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _colorBrightCyan, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Batal",
                style: TextStyle(color: _colorBrightCyan),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                double cm = double.tryParse(cmController.text) ?? 0;
                if (cm <= 0) return;

                setState(() {
                  kalibrasiCm = cm;
                  pixelPerCm = pixel / cm;
                  currentStep = 1; // Pindah ke tahap ukur berikutnya
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorBrightCyan,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("OK"),
            )
          ],
        ),
      );
    } 
    // TAHAP 2 (JIKA MODE LENGKUNG / LINGKAR DADA)
    else if (widget.isCurveMode) {
      if (ukurLingkar.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Buat titik-titik melingkar terlebih dahulu")),
        );
        return;
      }
      double pixel = getPolylineLength(ukurLingkar);
      double cm = pixel / pixelPerCm!;
      Navigator.pop(context, cm);
    } 
    // TAHAP 2 (UKUR PANJANG BADAN)
    else if (currentStep == 1) {
      if (ukurPanjang.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tandai 2 titik panjang badan sapi")),
        );
        return;
      }

      // Berpindah ke tahap ukur tinggi badan tanpa keluar layar
      setState(() {
        currentStep = 2;
      });
    } 
    // TAHAP 3 (UKUR TINGGI BADAN & SELESAI)
    else if (currentStep == 2) {
      if (ukurTinggi.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tandai 2 titik tinggi sapi (pundak ke tanah)")),
        );
        return;
      }

      double panjangPx = getDistance(ukurPanjang);
      double tinggiPx = getDistance(ukurTinggi);

      double panjangCm = panjangPx / pixelPerCm!;
      double tinggiCm = tinggiPx / pixelPerCm!;

      // Mengembalikan Map berisi panjang dan tinggi badan
      Navigator.pop(context, <String, double>{
        'panjang': panjangCm,
        'tinggi': tinggiCm,
      });
    }
  }

  // ================= TEKS INSTRUKSI =================
  String getInstructionText() {
    if (currentStep == 0) {
      return "Langkah 1: Tandai 2 titik acuan kalibrasi pada objek";
    }
    if (widget.isCurveMode) {
      return "Langkah 2: Buat titik-titik melingkari dada sapi";
    }
    if (currentStep == 1) {
      return "Langkah 2: Tandai 2 titik PANJANG badan (bahu ke pinggul)";
    }
    return "Langkah 3: Tandai 2 titik TINGGI badan (pundak tegak ke kaki)";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    double? panjangCmPreview;
    double? tinggiCmPreview;
    double? lingkarCmPreview;

    if (pixelPerCm != null) {
      if (widget.isCurveMode && ukurLingkar.length >= 2) {
        lingkarCmPreview = getPolylineLength(ukurLingkar) / pixelPerCm!;
      }
      if (ukurPanjang.length >= 2) {
        panjangCmPreview = getDistance(ukurPanjang) / pixelPerCm!;
      }
      if (ukurTinggi.length >= 2) {
        tinggiCmPreview = getDistance(ukurTinggi) / pixelPerCm!;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _colorDarkTeal,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            children: [
              SizedBox(width: 16),
              Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
              Text(
                "Kembali",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 24),
            tooltip: "Putar Gambar",
            onPressed: rotateImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 💡 BANNER INSTRUKSI DINAMIS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(
              color: currentStep == 0
                  ? Colors.amber.shade50
                  : _colorBrightCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: currentStep == 0
                    ? Colors.amber.shade400
                    : _colorBrightCyan,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentStep == 0 ? Icons.straighten : Icons.ads_click,
                  color: currentStep == 0 ? Colors.amber.shade900 : _colorDarkTeal,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    getInstructionText(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: currentStep == 0
                          ? Colors.amber.shade900
                          : _colorDarkTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: InteractiveViewer(
                  transformationController: _controller,
                  maxScale: 5,
                  minScale: 1,
                  child: Listener(
                    onPointerDown: (_) => setState(() => _pointerCount++),
                    onPointerUp: (_) => setState(() => _pointerCount = max(0, _pointerCount - 1)),
                    onPointerCancel: (_) => setState(() => _pointerCount = max(0, _pointerCount - 1)),
                    child: GestureDetector(
                      onTapUp: handleTap,
                      child: Stack(
                        key: _imageKey,
                        clipBehavior: Clip.none,
                        children: [
                          RotatedBox(
                            quarterTurns: _rotationQuarterTurns,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                widget.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // 🔴 KALIBRASI (Hanya tampil saat Step 0 / proses kalibrasi)
                          if (currentStep == 0 && kalibrasi.length >= 2)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LinePainter(kalibrasi, Colors.red),
                              ),
                            ),

                          // 🔵 UKUR PANJANG
                          if (ukurPanjang.length >= 2)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LinePainter(ukurPanjang, Colors.blue),
                              ),
                            ),

                          // 🟢 UKUR TINGGI
                          if (ukurTinggi.length >= 2)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LinePainter(ukurTinggi, Colors.green),
                              ),
                            ),

                          // 🔵 UKUR LINGKAR
                          if (ukurLingkar.length >= 2)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LinePainter(ukurLingkar, Colors.blue),
                              ),
                            ),

                          // Titik Kalibrasi (Hanya tampil saat Step 0)
                          if (currentStep == 0)
                            ...kalibrasi.asMap().entries.map(
                                (e) => titik(e.value, Colors.red, e.key, 0)),

                          // Titik Panjang (Biru)
                          ...ukurPanjang.asMap().entries.map(
                              (e) => titik(e.value, Colors.blue, e.key, 1)),

                          // Titik Tinggi (Hijau)
                          ...ukurTinggi.asMap().entries.map(
                              (e) => titik(e.value, Colors.green, e.key, 2)),

                          // Titik Lingkar (Biru)
                          ...ukurLingkar.asMap().entries.map(
                              (e) => titik(e.value, Colors.blue, e.key, 3)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 📏 PREVIEW HASIL UKUR
          if (currentStep > 0 && kalibrasiCm != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      "Acuan Kalibrasi: ${kalibrasiCm!.toStringAsFixed(0)} cm",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.isCurveMode)
                    Text(
                      lingkarCmPreview == null
                          ? "Lingkar Dada: -"
                          : "Lingkar Dada: ${lingkarCmPreview.toStringAsFixed(2)} cm",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _colorDarkTeal,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          panjangCmPreview == null
                              ? "PB: -"
                              : "PB: ${panjangCmPreview.toStringAsFixed(1)} cm",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          tinggiCmPreview == null
                              ? "TB: -"
                              : "TB: ${tinggiCmPreview.toStringAsFixed(1)} cm",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // 🔘 BUTTONS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: resetPoints,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _colorBrightCyan, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Reset",
                      style: TextStyle(color: _colorBrightCyan, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: undoPoint,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _colorBrightCyan, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Undo",
                      style: TextStyle(color: _colorBrightCyan, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorBrightCyan,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      currentStep == 0
                          ? "Lanjut"
                          : currentStep == 1 && !widget.isCurveMode
                              ? "Lanjut TB"
                              : "Selesai",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TITIK =================
  Widget titik(Offset p, Color color, int index, int type) {
    const double pointSize = 12.0;

    return Positioned(
      left: p.dx - (pointSize / 2),
      top: p.dy - (pointSize / 2),
      child: GestureDetector(
        onPanUpdate: (details) {
          double scale = _controller.value.getMaxScaleOnAxis();

          setState(() {
            Offset delta = details.delta / scale;
            if (type == 0) {
              kalibrasi[index] += delta;
            } else if (type == 1) {
              ukurPanjang[index] += delta;
            } else if (type == 2) {
              ukurTinggi[index] += delta;
            } else if (type == 3) {
              ukurLingkar[index] += delta;
            }
          });
        },
        child: Container(
          width: pointSize,
          height: pointSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
              )
            ],
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
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}