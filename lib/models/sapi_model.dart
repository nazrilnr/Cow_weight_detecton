class SapiModel {
  final int? id;
  final String namaSapi;
  final double lingkarDada;
  final double panjangBadan;
  final double berat;
  final String tanggal;

  SapiModel({
    this.id,
    required this.namaSapi,
    required this.lingkarDada,
    required this.panjangBadan,
    required this.berat,
    required this.tanggal,
  });

  // Konversi dari SapiModel ke Map (untuk simpan ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_sapi': namaSapi,
      'lingkar_dada': lingkarDada,
      'panjang_badan': panjangBadan,
      'berat': berat,
      'tanggal': tanggal,
    };
  }

  // Konversi dari Map SQLite ke SapiModel (untuk dibaca di UI)
  factory SapiModel.fromMap(Map<String, dynamic> map) {
    return SapiModel(
      id: map['id'] as int?,
      namaSapi: map['nama_sapi'] ?? '',
      lingkarDada: (map['lingkar_dada'] as num?)?.toDouble() ?? 0.0,
      panjangBadan: (map['panjang_badan'] as num?)?.toDouble() ?? 0.0,
      berat: (map['berat'] as num?)?.toDouble() ?? 0.0,
      tanggal: map['tanggal'] ?? '',
    );
  }
}