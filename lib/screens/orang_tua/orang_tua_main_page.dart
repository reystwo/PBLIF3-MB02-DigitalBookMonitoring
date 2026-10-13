// =============================================================
// ORANG TUA / WALI - kerangka bottom navigation + dashboard
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/catatan/riwayat_catatan_page.dart';
import 'package:digital_book_connect/screens/notifikasi/notifikasi_page.dart';
import 'package:digital_book_connect/screens/profil/profil_page.dart';

class OrangTuaMainPage extends StatefulWidget {
  const OrangTuaMainPage({super.key});

  @override
  State<OrangTuaMainPage> createState() => _OrangTuaMainPageState();
}

class _OrangTuaMainPageState extends State<OrangTuaMainPage> {
  static const _nama = 'Ibu Siti Nurhaliza';
  int _tab = 0;

  void _keTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = switch (_tab) {
      1 => const SegeraHadirPage(judul: 'Profil Anak', icon: Icons.child_care_rounded),
      2 => RiwayatCatatanPage(judul: 'Pesan', onBack: () => _keTab(0)),
      3 => ProfilPage(nama: _nama, peran: 'Orang Tua / Wali Murid', onBack: () => _keTab(0)),
      _ => _OrangTuaDashboard(onKeTab: _keTab),
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
            NavItem(Icons.groups_rounded, 'Anak'),
            NavItem(Icons.chat_rounded, 'Pesan'),
            NavItem(Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _OrangTuaDashboard extends StatelessWidget {
  final ValueChanged<int> onKeTab;

  const _OrangTuaDashboard({required this.onKeTab});

  @override
  Widget build(BuildContext context) {
    final anak = daftarSiswa.first;
    final catatanAnak = daftarCatatan.where((c) => c.siswa == anak).take(3).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          SalamHeader(
            nama: 'Ibu Siti Nurhaliza',
            peran: 'Orang Tua / Wali Murid',
            onNotifikasi: () => bukaHalaman(context, const NotifikasiPage()),
            onProfil: () => onKeTab(3),
          ),
          const SizedBox(height: 16),

          // Kartu anak
          Material(
            color: AppColors.primaryLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onKeTab(1),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const AppAvatar(radius: 26, backgroundColor: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ananda ${anak.nama.split(' ').last}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kelas ${anak.kelas}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textDark),
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
              MenuCard(
                icon: Icons.assignment_rounded,
                label: 'Catatan Guru',
                onTap: () => bukaHalaman(context, const RiwayatCatatanPage(judul: 'Catatan Guru')),
              ),
              MenuCard(
                icon: Icons.insights_rounded,
                label: 'Perkembangan Anak',
                onTap: () => bukaHalaman(
                  context,
                  const SegeraHadirPage(judul: 'Perkembangan Anak', icon: Icons.insights_rounded),
                ),
              ),
              MenuCard(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal & Kegiatan',
                onTap: () => bukaHalaman(
                  context,
                  const SegeraHadirPage(judul: 'Jadwal & Kegiatan', icon: Icons.calendar_month_rounded),
                ),
              ),
              MenuCard(
                icon: Icons.notifications_rounded,
                label: 'Notifikasi',
                onTap: () => bukaHalaman(context, const NotifikasiPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SectionHeader(judul: 'Catatan Terbaru', onLihatSemua: () => onKeTab(2)),
          const SizedBox(height: 12),
          ListCard(children: [for (final c in catatanAnak) CatatanTile(catatan: c)]),
        ],
      ),
    );
  }
}
