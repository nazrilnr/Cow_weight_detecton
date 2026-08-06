double hitungBeratSapi(double lingkarDada, double panjangBadan) {
  if (lingkarDada <= 0 || panjangBadan <= 0) {
    return 0;
  }

  double berat = (lingkarDada * lingkarDada * panjangBadan) / 10840;
  return berat;
}