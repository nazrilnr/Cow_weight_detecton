import 'dart:math';

/// Memilih rumus berdasarkan parameter [metode]:
/// - 'schoorl': Hanya membutuhkan [lingkarDada]
/// - 'winter' : Membutuhkan [lingkarDada] dan [panjangBadan]
double hitungBeratSapi({
  required double lingkarDada,
  double panjangBadan = 0,
  required String metode,
}) {
  if (lingkarDada <= 0) return 0;

  if (metode == 'schoorl') {
    // ================= RUMUS SCHOORL =================
    // BB = ((Lingkar Dada + 22)^2) / 100
    // Tidak memerlukan Panjang Badan
    return pow((lingkarDada + 22), 2) / 100;
  } 
  
    else if (metode == 'winter') {
      // ================= RUMUS WINTER =================
      // BB = (Lingkar Dada^2 * Panjang Badan) / 10840
      if (panjangBadan <= 0) return 0;
      return (lingkarDada * lingkarDada * panjangBadan) / 10840;
  }

  return 0;
}