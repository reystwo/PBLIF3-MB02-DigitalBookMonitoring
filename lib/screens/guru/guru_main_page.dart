// =============================================================
// GURU - kerangka bottom navigation + dashboard
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/siswa/daftar_siswa_page.dart';
import 'package:digital_book_connect/screens/catatan/riwayat_catatan_page.dart';
import 'package:digital_book_connect/screens/notifikasi/notifikasi_page.dart';
import 'package:digital_book_connect/screens/profil/profil_page.dart';

class GuruMainPage extends StatefulWidget {
  const GuruMainPage({super.key});

  @override
  State<GuruMainPage> createState() => _GuruMainPageState();
}

class _GuruMainPageState extends State<GuruMainPage> {
  static const _nama = 'Bapak Ahmad';
  int _tab = 0;

  void _keTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = switch (_tab) {
      1 => DaftarSiswaPage(onBack: () => _keTab(0)),
      2 => RiwayatCatatanPage(onBack: () => _keTab(0)),
      3 => ProfilPage(nama: _nama, peran: 'Guru', onBack: () => _keTab(0)),
      _ => _GuruDashboard(onKeTab: _keTab),
    };
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _keTab(0);
      },
      child: Scaffold(
        body: halaman,
        bottomNavigationBar: AppBottomNav(
          currentIndex: _tab,
          onTap: _keTab,
          items: const [
            NavItem(Icons.home_rounded, 'Beranda'),
            NavItem(Icons.groups_rounded, 'Siswa'),
            NavItem(Icons.edit_note_rounded, 'Catatan'),
            NavItem(Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _GuruDashboard extends StatelessWidget {
  final ValueChanged<int> onKeTab;

  const _GuruDashboard({required this.onKeTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          SalamHeader(
            nama: 'Selamat Datang,\nBapak Ahmad',
            peran: 'Guru',
            onNotifikasi: () => bukaHalaman(context, const NotifikasiPage()),
            onProfil: () => onKeTab(3),
          ),
          const SizedBox(height: 16),

          // Kartu kelas yang diampu
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onKeTab(1),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 28),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelas 5A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text('SDN 01 Batam', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader(judul: 'Menu Utama'),
          const SizedBox(height: 12),
          MenuGrid(
            items: [
              MenuCard(icon: Icons.groups_rounded, label: 'Daftar Siswa', onTap: () => onKeTab(1)),
              MenuCard(
                icon: Icons.edit_note_rounded,
                label: 'Tambah Catatan',
                onTap: () => bukaHalaman(context, const DaftarSiswaPage(judul: 'Pilih Siswa')),
              ),
              MenuCard(icon: Icons.history_rounded, label: 'Riwayat Catatan', onTap: () => onKeTab(2)),
              MenuCard(
                icon: Icons.notifications_rounded,
                label: 'Notifikasi',
                onTap: () => bukaHalaman(context, const NotifikasiPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SectionHeader(
            judul: 'Aktivitas Terbaru',
            onLihatSemua: () => bukaHalaman(context, const NotifikasiPage()),
          ),
          const SizedBox(height: 12),
          ListCard(
            children: [
              for (final a in aktivitasTerbaru)
                ListItemTile(
                  judul: Text(a.nama),
                  subjudul: a.keterangan,
                  keterangan: a.waktu,
                  perempuan: a.perempuan,
                  onTap: () => onKeTab(2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
