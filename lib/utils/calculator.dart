import 'dart:math';

/// Menghitung estimasi Lingkar Dada (LD) menggunakan rumus keliling elips Ramanujan
/// [a] = setengah diameter horizontal dada[cite: 2]
/// [b] = setengah diameter vertikal dada[cite: 2]
double hitungLingkarDadaElips(double a, double b) {
  if (a <= 0 || b <= 0) return 0.0;

  double term1 = 3 * (a + b);
  double term2 = sqrt((3 * a + b) * (a + 3 * b));
  
  return pi * (term1 - term2);
}

/// Menghitung Berat Badan (BB) sapi menggunakan persamaan regresi[cite: 1]
/// [lingkarDada] = LD (cm)[cite: 1]
/// [panjangBadan] = PB (cm)[cite: 1, 2]
/// [tinggiBadan]  = TB (cm)[cite: 1, 2]
double hitungBeratSapi({
  required double lingkarDada,
  required double panjangBadan,
  required double tinggiBadan,
}) {
  // Validasi input tidak boleh bernilai nol atau negatif
  if (lingkarDada <= 0 || panjangBadan <= 0 || tinggiBadan <= 0) {
    return 0.0;
  }

  // Persamaan regresi: BB = -782.0699 + 6.5562(LD) + 3.8259(PB) - 3.5292(TB)[cite: 1]
  double berat = -782.0699 +
      (6.5562 * lingkarDada) +
      (3.8259 * panjangBadan) -
      (3.5292 * tinggiBadan);

  // Mencegah hasil negatif jika input pengukuran terlalu kecil
  return berat > 0 ? double.parse(berat.toStringAsFixed(2)) : 0.0;
}