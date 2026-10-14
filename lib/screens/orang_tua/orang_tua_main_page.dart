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

import 'package:digital_book_connect/services/session_manager.dart';
import 'package:digital_book_connect/services/app_repository.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/siswa_model.dart';

class OrangTuaMainPage extends StatefulWidget {
  const OrangTuaMainPage({super.key});

  @override
  State<OrangTuaMainPage> createState() => _OrangTuaMainPageState();
}

class _OrangTuaMainPageState extends State<OrangTuaMainPage> {
  String _nama = 'Ibu Siti Nurhaliza';
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
        _nama = (user.namaOrangTua != null && user.namaOrangTua!.isNotEmpty)
            ? user.namaOrangTua!
            : user.nama;
      });
    }
  }

  void _keTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = switch (_tab) {
      1 => const SegeraHadirPage(judul: 'Profil Anak', icon: Icons.child_care_rounded),
      2 => RiwayatCatatanPage(judul: 'Pesan', onBack: () => _keTab(0)),
      3 => ProfilPage(nama: _nama, peran: 'Orang Tua / Wali Murid', onBack: () => _keTab(0)),
      _ => _OrangTuaDashboard(nama: _nama, onKeTab: _keTab),
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

class _OrangTuaDashboard extends StatefulWidget {
  final String nama;
  final ValueChanged<int> onKeTab;

  const _OrangTuaDashboard({required this.nama, required this.onKeTab});

  @override
  State<_OrangTuaDashboard> createState() => _OrangTuaDashboardState();
}

class _OrangTuaDashboardState extends State<_OrangTuaDashboard> {
  Siswa _anak = daftarSiswa.first;
  List<Catatan> _catatanAnak = daftarCatatan.take(3).toList();

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final res = await AppRepository.getDashboard();
      if (res.isSuccess && res.data != null && mounted) {
        final data = res.data!;
        setState(() {
          if (data['anak'] is List && (data['anak'] as List).isNotEmpty) {
            _anak = Siswa.fromModel(SiswaModel.fromJson(data['anak'][0]));
          }
          if (data['catatan_terbaru'] is List) {
            final list = (data['catatan_terbaru'] as List)
                .map((c) => Catatan.fromModel(CatatanModel.fromJson(c)))
                .toList();
            if (list.isNotEmpty) _catatanAnak = list;
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            SalamHeader(
              nama: widget.nama,
              peran: 'Orang Tua / Wali Murid',
              onNotifikasi: () => bukaHalaman(context, const NotifikasiPage()),
              onProfil: () => widget.onKeTab(3),
            ),
            const SizedBox(height: 16),

            // Kartu anak
            Material(
              color: AppColors.primaryLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onKeTab(1),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      AppAvatar(radius: 26, perempuan: _anak.perempuan, backgroundColor: Colors.white),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ananda ${_anak.nama.split(' ').last}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kelas ${_anak.kelas}',
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

            SectionHeader(judul: 'Catatan Terbaru', onLihatSemua: () => widget.onKeTab(2)),
            const SizedBox(height: 12),
            ListCard(
              children: [
                for (final c in _catatanAnak)
                  CatatanTile(
                    catatan: c,
                    onKembali: _fetchDashboard,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
