// =============================================================
// BUKU PENGHUBUNG DIGITAL - Entry Point
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/screens/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

// Kumpulan warna agar mudah diubah dari satu tempat
class AppColors {
  static const Color primary = Color(0xFF2F6B4F); // hijau tua (judul & tombol)
  static const Color primaryLight = Color(0xFFE4EFE7); // hijau muda (lingkaran ikon)
  static const Color accent = Color(0xFF8FC1A0); // hijau daun pada logo
  static const Color background = Color(0xFFF7F9F7); // latar belakang
  static const Color textDark = Color(0xFF26332C);
  static const Color textGrey = Color(0xFF5E6B64);
  static const Color divider = Color(0xFFDDE5DF);
  static const Color blob = Color(0x262F6B4F); // hijau transparan 15%
  static const Color blobSoft = Color(0x142F6B4F); // hijau transparan 8%
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buku Penghubung Digital',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const HomePage(),
    );
  }
}