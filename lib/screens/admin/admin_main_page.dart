// =============================================================
// ADMIN - kerangka bottom navigation + dashboard
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/profil/profil_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _tab = 0;

  void _keTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = switch (_tab) {
      1 => const SegeraHadirPage(judul: 'Data', icon: Icons.dashboard_rounded),
      2 => const SegeraHadirPage(judul: 'Laporan', icon: Icons.summarize_rounded),
      3 => ProfilPage(nama: 'Admin', peran: 'Administrator', onBack: () => _keTab(0)),
      _ => _AdminDashboard(onKeTab: _keTab),
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
            NavItem(Icons.dashboard_rounded, 'Data'),
            NavItem(Icons.summarize_rounded, 'Laporan'),
            NavItem(Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final ValueChanged<int> onKeTab;

  const _AdminDashboard({required this.onKeTab});

  void _buka(BuildContext context, String judul, IconData icon) {
    bukaHalaman(context, SegeraHadirPage(judul: judul, icon: icon));
  }

  @override
  Widget build(BuildContext context) {
    const menu = [
      (Icons.person_rounded, 'Kelola Guru'),
      (Icons.groups_rounded, 'Kelola Orang Tua'),
      (Icons.school_rounded, 'Kelola Siswa'),
      (Icons.diversity_3_rounded, 'Kelola Kelas'),
      (Icons.edit_note_rounded, 'Laporan'),
      (Icons.settings_rounded, 'Pengaturan'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          SalamHeader(
            nama: 'Admin',
            peran: 'Administrator',
            tampilkanNotifikasi: false,
            onProfil: () => onKeTab(3),
          ),
          const SizedBox(height: 24),

          const SectionHeader(judul: 'Menu Utama'),
          const SizedBox(height: 12),
          MenuGrid(
            items: [
              for (final (icon, label) in menu)
                MenuCard(
                  icon: icon,
                  label: label,
                  onTap: label == 'Laporan' ? () => onKeTab(2) : () => _buka(context, label, icon),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Status sistem
          Container(
            padding: const EdgeInsets.all(14),
            decoration: kartuDecoration(color: AppColors.primaryLight.withValues(alpha: 0.6)),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.verified_user_rounded, color: AppColors.primary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistem berjalan dengan baik',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tidak ada masalah yang terdeteksi.',
                        style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
