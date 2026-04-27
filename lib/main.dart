import 'package:flutter/material.dart';
import 'screens/function/history_screen.dart';
import 'screens/function/hitung_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  // List halaman yang akan ditampilkan sesuai tab yang dipilih
  final List<Widget> _screens = [
    const HitungScreen(), 
    const HistoryScreen(), 
    // Catatan: Hapus kata 'const' di atas jika class HitungScreen/HistoryScreen kamu belum menggunakan const constructor
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBody: true, // 🔥 Ini wajib agar navbar benar-benar terlihat ngambang di atas konten body
        body: _screens[_selectedIndex],
        
        // --- CUSTOM FLOATING NAVBAR ---
        bottomNavigationBar: Padding(
          // Mengatur jarak dari kiri, kanan, dan bawah agar ngambang
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEFDFD), // Background navbar: EEFDFD
              borderRadius: BorderRadius.circular(30), // Membuat sisinya membulat
              boxShadow: [
                // Tambahan bayangan (shadow) halus
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent, // Transparan agar warna Container terlihat
                elevation: 0, // Hilangkan shadow bawaan BottomNavigationBar
                selectedItemColor: const Color(0xFF38D0D8), // Warna saat aktif
                unselectedItemColor: Colors.grey, // Warna saat tidak aktif
                showSelectedLabels: true,
                showUnselectedLabels: true,
                
                currentIndex: _selectedIndex, // State index saat ini
                onTap: _onItemTapped, // Fungsi ganti halaman
                
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calculate),
                    label: "Hitung",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: "History",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}