# Mooasure 🐄

**Mooasure** adalah aplikasi mobile sederhana untuk **mengestimasi berat badan sapi tanpa timbangan**. Caranya: ambil foto sapi, ukur beberapa bagian tubuhnya langsung di layar, lalu aplikasi akan menghitung perkiraan beratnya secara otomatis.

Aplikasi ini dibuat menggunakan Flutter dan cocok dipakai oleh peternak maupun peneliti yang ingin memantau berat sapi dengan cara yang praktis.

---

## 🔍 Tentang Aplikasi

Menimbang sapi secara langsung bisa merepotkan, apalagi jika sapi berukuran besar atau jumlahnya banyak. Mooasure menawarkan alternatif dengan memanfaatkan **foto + pengukuran digital**:

1. Pengguna mengambil atau memilih foto sapi dari galeri.
2. Pengguna menandai titik-titik ukur pada foto (dengan bantuan kalibrasi agar hasilnya sesuai dalam satuan cm).
3. Aplikasi mengubah jarak antar titik menjadi centimeter, lalu menghitung berat sapi memakai rumus regresi.
4. Hasil pengukuran bisa disimpan dan dilihat kembali di riwayat.

> 💡 **Catatan:** Hasil yang ditampilkan adalah *estimasi*, bukan timbangan resmi. Akurasi sangat bergantung pada kualitas foto, jarak pengambilan, dan ketelitian saat menandai titik.

---

## ✨ Fitur-Fitur

### 1. Hitung Berat Sapi
- Form pengukuran: **nama/ID sapi**, **poel**, **lingkar dada**, **panjang badan**, dan **tinggi badan**.
- Tombol **Hitung** untuk mengolah data menjadi estimasi berat (kg).
- Tombol **Simpan** untuk menyimpan hasil ke riwayat.

### 2. Pengukuran dari Foto
- Pilih foto dari galeri untuk dua mode pengukuran:
  - **Foto tampak depan** → mengukur **lingkar dada** dengan titik-titik yang membentuk garis melingkar.
  - **Foto tampak samping** → mengukur **panjang badan** dan **tinggi badan** sekaligus dalam satu foto.
- **Kalibrasi**: tandai 2 titik acuan pada objek yang diketahui ukurannya (misalnya penggaris 20 cm), lalu masukkan panjang aslinya.
- Kontrol pengukuran:
  - **Zoom in/out** dengan pinch, **geser** foto, dan **putar** foto.
  - **Undo** untuk membatalkan titik terakhir.
  - **Reset** untuk mengulang titik pada langkah saat ini.
  - Titik bisa **digeser** kembali agar lebih presisi.
- Preview hasil pengukuran langsung muncul di layar sebelum disimpan.

### 3. Riwayat Pengukuran
- Daftar semua hasil pengukuran yang sudah disimpan (tersimpan di perangkat).
- **Pencarian** berdasarkan nama/ID sapi.
- **Hapus satu data** lewat tombol hapus pada item, atau **hapus banyak data** dengan mode pilih (centang item → Hapus).
- **Export PDF** untuk data yang dipilih, lalu bisa dicetak atau dibagikan.

### 4. Tampilan
- Navigasi bawah mengambang dengan dua tab: **Hitung** dan **History**.
- Tema warna biru/tocha yang bersih dan mudah dibaca.

---

## 📋 Cara Menggunakan

### A. Mengukur dan Menghitung Berat

1. Buka aplikasi → pilih tab **Hitung**.
2. Isi **Nama/ID Sapi** dan pilih **Poel** (opsional, sesuai kandang).
3. Ukur lewat foto, atau isi angka manual jika ukuran sudah diketahui:
   - **Lingkar Dada (cm)**: ketuk kotak **Tambahkan Foto Tampak Depan** → pilih foto → tandai 2 titik kalibrasi → masukkan panjang acuan (cm) → buat titik-titik mengikuti bentuk dada → **Selesai**.
   - **Panjang & Tinggi (cm)**: ketuk kotak **Tambahkan Foto Tampak Samping** → pilih foto → kalibrasi → tandai 2 titik panjang (bahu → pinggul) → **Lanjut TB** → tandai 2 titik tinggi (pundak → kaki) → **Selesai**.
   - Atau ketik langsung angka lingkar, panjang, dan tinggi pada kolom yang tersedia.
4. Tekan tombol **Hitung**.
5. Jika hasil muncul, tekan **Simpan** untuk menyimpannya ke riwayat.

### B. Melihat & Mengelola Riwayat

1. Pilih tab **History**.
2. Gunakan kolom **Cari Sapi** untuk mencari berdasarkan nama.
3. Untuk menghapus:
   - Satu data → ketuk ikon tempat sampah pada data tersebut → konfirmasi **Hapus**.
   - Beberapa data → ketuk **Pilih** (atau tahan lama salah satu data) → centang data → **Hapus**.
4. Untuk membuat laporan: ketuk **Pilih** → centang data yang ingin dicetak → **Export** → pilih opsi cetak/simpan PDF.

---

## 🧮 Rumus Perhitungan

Berat badan dihitung dengan persamaan regresi:

```
BB = -706,9511 + 3,4147 × LD + 3,1140 × PB - 0,7059 × TB
```

Keterangan:
- **BB** = Berat Badan (kg)
- **LD** = Lingkar Dada (cm)
- **PB** = Panjang Badan (cm)
- **TB** = Tinggi Badan (cm)

Jika semua ukuran valid (lebih dari 0), hasil dibulatkan menjadi 2 angka desimal. Jika ada ukuran kosong atau hasil negatif, berat ditampilkan `0`.

---

## 🚀 Cara Menjalankan Proyek

Pastikan **Flutter SDK** sudah terpasang (proyek ini menggunakan Dart SDK `^3.11.5`).

```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan di emulator/perangkat yang tersedia
flutter run
```

Untuk membuat file rilis:

```bash
flutter build apk      # Android
flutter build ios      # iOS (Butuh macOS & Xcode)
```

---

## 🧰 Teknologi yang Dipakai

| Paket | Fungsi |
| --- | --- |
| `image_picker` | Mengambil/milih foto dari galeri |
| `shared_preferences` | Menyimpan data riwayat di perangkat |
| `pdf` & `printing` | Membuat dan mencetak laporan PDF |
| `path` & `path_provider` | Mengelola path penyimpanan lokal |
| `flutter_launcher_icons` | Ikon aplikasi |

---

## ✅ Tips Pengambilan Foto

- Ambil foto dengan **penerangan yang cukup** dan sapi terlihat jelas.
- Usahakan jarak kamera sekitar **2 meter** dari sapi.
- Sediakan objek acuan dengan ukuran yang diketahui (misalnya penggaris atau tongkat 20 cm) di dekat sapi untuk kalibrasi.
- Posisikan kamera sejajar dengan bagian yang diukur agar tidak terjadi distorsi.
- Periksa kembali titik-titik yang sudah ditandai sebelum menekan **Selesai**.

---

## 📁 Struktur Singkat

```
lib/
├── main.dart                     # Entry point & navigasi tab
├── screens/
│   └── function/
│       ├── hitung_screen.dart    # Form hitung & simpan
│       ├── measurement_screen.dart # Pengukuran dari foto
│       └── history_screen.dart   # Riwayat, hapus, export PDF
├── database/db_helper.dart       # Penyimpanan lokal (SharedPreferences)
├── models/sapi_model.dart        # Model data sapi
└── utils/calculator.dart         # Rumus lingkar & berat sapi
```

---

Dibuat sebagai aplikasi Flutter untuk kebutuhan pencatatan dan estimasi berat sapi. 🐄
