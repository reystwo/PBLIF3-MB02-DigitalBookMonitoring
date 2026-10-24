// =============================================================
// ADMIN - kerangka bottom navigation + dashboard
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/profil/profil_page.dart';
import 'package:digital_book_connect/screens/admin/kelola_guru_page.dart';
import 'package:digital_book_connect/screens/admin/kelola_orang_tua_page.dart';
import 'package:digital_book_connect/screens/admin/kelola_siswa_page.dart';
import 'package:digital_book_connect/screens/admin/kelola_kelas_page.dart';

import 'package:digital_book_connect/services/session_manager.dart';
import 'package:digital_book_connect/services/app_repository.dart';

// Menu kelola data Admin (dipakai di Beranda dan tab Data)
const menuKelolaData = [
  (Icons.person_rounded, 'Kelola Guru'),
  (Icons.groups_rounded, 'Kelola Orang Tua'),
  (Icons.school_rounded, 'Kelola Siswa'),
  (Icons.diversity_3_rounded, 'Kelola Kelas'),
];

final Map<String, Widget Function()> halamanKelolaData = {
  'Kelola Guru': () => const KelolaGuruPage(),
  'Kelola Orang Tua': () => const KelolaOrangTuaPage(),
  'Kelola Siswa': () => const KelolaSiswaPage(),
  'Kelola Kelas': () => const KelolaKelasPage(),
};

const _keteranganMenu = {
  'Kelola Guru': 'Akun & profil guru, NIP, status akun',
  'Kelola Orang Tua': 'Akun & profil orang tua / wali murid',
  'Kelola Siswa': 'Data siswa, kelas, dan orang tua',
  'Kelola Kelas': 'Rombongan belajar & wali kelas',
};

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
      1 => AdminDataPage(onBack: () => _keTab(0)),
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
        final d = res.data!['statistik'] is Map ? res.data!['statistik'] as Map : res.data!;
        final g = d['total_guru'] ?? 0;
        final o = d['total_orang_tua'] ?? 0;
        final s = d['total_siswa'] ?? 0;
        final k = d['total_kelas'] ?? 0;
        setState(() {
          _keteranganStatus = '$g Guru · $o Orang Tua · $s Siswa · $k Kelas terdaftar.';
        });
      }
    } catch (_) {}
  }

  Future<void> _buka(BuildContext context, String judul, IconData icon) async {
    final halaman = halamanKelolaData[judul];
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => halaman?.call() ?? SegeraHadirPage(judul: judul, icon: icon)),
    );
    // Statistik diperbarui setelah kembali dari halaman kelola data
    if (mounted) _fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    const menu = [
      ...menuKelolaData,
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

// Tab "Data": pintu masuk ke empat fitur kelola data Admin
class AdminDataPage extends StatelessWidget {
  final VoidCallback? onBack;

  const AdminDataPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JudulAppBar(judul: 'Kelola Data', onBack: onBack),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ListCard(
            children: [
              for (final (icon, label) in menuKelolaData)
                // Material transparan agar efek sentuh ListTile tetap terlihat di kartu putih
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(icon, color: AppColors.primary),
                    ),
                    title: Text(
                      label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      _keteranganMenu[label] ?? '',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                    onTap: () => bukaHalaman(context, halamanKelolaData[label]!()),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
