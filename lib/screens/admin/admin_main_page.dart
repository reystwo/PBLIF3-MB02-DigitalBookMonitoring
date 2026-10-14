// =============================================================
// ADMIN - kerangka bottom navigation + dashboard
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/profil/profil_page.dart';

import 'package:digital_book_connect/services/session_manager.dart';
import 'package:digital_book_connect/services/app_repository.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  String _nama = 'Admin';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SessionManager.getUser();
    if (user != null && mounted) {
      setState(() {
        _nama = user.nama.isNotEmpty ? user.nama : 'Admin';
      });
    }
  }

  void _keTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = switch (_tab) {
      1 => const SegeraHadirPage(judul: 'Data', icon: Icons.dashboard_rounded),
      2 => const SegeraHadirPage(judul: 'Laporan', icon: Icons.summarize_rounded),
      3 => ProfilPage(nama: _nama, peran: 'Administrator', onBack: () => _keTab(0)),
      _ => _AdminDashboard(nama: _nama, onKeTab: _keTab),
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

class _AdminDashboard extends StatefulWidget {
  final String nama;
  final ValueChanged<int> onKeTab;

  const _AdminDashboard({required this.nama, required this.onKeTab});

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  String _keteranganStatus = 'Tidak ada masalah yang terdeteksi.';

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final res = await AppRepository.getDashboard();
      if (res.isSuccess && res.data != null && mounted) {
        final d = res.data!;
        final u = d['total_user'] ?? 0;
        final s = d['total_siswa'] ?? 0;
        final g = d['total_guru'] ?? 0;
        setState(() {
          _keteranganStatus = '$u Akun Pengguna · $g Guru · $s Siswa terdaftar.';
        });
      }
    } catch (_) {}
  }

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
      child: RefreshIndicator(
        onRefresh: _fetchDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            SalamHeader(
              nama: widget.nama,
              peran: 'Administrator',
              tampilkanNotifikasi: false,
              onProfil: () => widget.onKeTab(3),
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
                    onTap: label == 'Laporan'
                        ? () => widget.onKeTab(2)
                        : () => _buka(context, label, icon),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Status sistem
            Container(
              padding: const EdgeInsets.all(14),
              decoration: kartuDecoration(color: AppColors.primaryLight.withValues(alpha: 0.6)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.verified_user_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sistem berjalan dengan baik',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _keteranganStatus,
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
