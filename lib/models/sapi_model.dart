class SapiModel {
  final int? id;
  final String namaSapi;
  final double panjangBadan;
  final double tinggiBadan; // Parameter baru untuk rumus kustom
  final double? lingkarDada; // Diubah jadi opsional agar backward compatible
  final double berat;
  final String tanggal;

  SapiModel({
    this.id,
    required this.namaSapi,
    required this.panjangBadan,
    required this.tinggiBadan,
    this.lingkarDada,
    required this.berat,
    required this.tanggal,
  });

  // Konversi dari SapiModel ke Map (untuk simpan ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_sapi': namaSapi,
      'panjang_badan': panjangBadan,
      'tinggi_badan': tinggiBadan,
      if (lingkarDada != null) 'lingkar_dada': lingkarDada,
      'berat': berat,
      'tanggal': tanggal,
    };
  }

  // Konversi dari Map SQLite ke SapiModel (untuk dibaca di UI)
  factory SapiModel.fromMap(Map<String, dynamic> map) {
    return SapiModel(
      id: map['id'] as int?,
      namaSapi: map['nama_sapi'] as String? ?? '',
      panjangBadan: (map['panjang_badan'] as num?)?.toDouble() ?? 0.0,
      tinggiBadan: (map['tinggi_badan'] as num?)?.toDouble() ?? 0.0,
      lingkarDada: (map['lingkar_dada'] as num?)?.toDouble(),
      berat: (map['berat'] as num?)?.toDouble() ?? 0.0,
      tanggal: map['tanggal'] as String? ?? '',
    );
  }

  // Helper copyWith untuk mempermudah update nilai data
  SapiModel copyWith({
    int? id,
    String? namaSapi,
    double? panjangBadan,
    double? tinggiBadan,
    double? lingkarDada,
    double? berat,
    String? tanggal,
  }) {
    return SapiModel(
      id: id ?? this.id,
      namaSapi: namaSapi ?? this.namaSapi,
      panjangBadan: panjangBadan ?? this.panjangBadan,
      tinggiBadan: tinggiBadan ?? this.tinggiBadan,
      lingkarDada: lingkarDada ?? this.lingkarDada,
      berat: berat ?? this.berat,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}