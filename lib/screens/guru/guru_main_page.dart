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

import 'package:digital_book_connect/services/session_manager.dart';
import 'package:digital_book_connect/services/app_repository.dart';

class GuruMainPage extends StatefulWidget {
  const GuruMainPage({super.key});

  @override
  State<GuruMainPage> createState() => _GuruMainPageState();
}

class _GuruMainPageState extends State<GuruMainPage> {
  String _nama = 'Bapak Ahmad';
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
        _nama = (user.namaGuru != null && user.namaGuru!.isNotEmpty)
            ? user.namaGuru!
            : user.nama;
      });
    }
  }

  void _keTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = switch (_tab) {
      1 => DaftarSiswaPage(onBack: () => _keTab(0)),
      2 => RiwayatCatatanPage(onBack: () => _keTab(0)),
      3 => ProfilPage(nama: _nama, peran: 'Guru', onBack: () => _keTab(0)),
      _ => _GuruDashboard(nama: _nama, onKeTab: _keTab),
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

class _GuruDashboard extends StatefulWidget {
  final String nama;
  final ValueChanged<int> onKeTab;

  const _GuruDashboard({required this.nama, required this.onKeTab});

  @override
  State<_GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<_GuruDashboard> {
  String _kelasNama = 'Kelas 5A';
  final _sekolah = 'SDN 01 Batam';
  List<Aktivitas> _listAktivitas = aktivitasTerbaru;

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
          final kelasWali = data['kelas_wali'];
          _kelasNama = kelasWali is Map && kelasWali['nama_kelas'] != null
              ? 'Kelas ${kelasWali['nama_kelas']}'
              : 'Belum menjadi wali kelas';
          if (data['catatan_terbaru'] is List) {
            _listAktivitas = (data['catatan_terbaru'] as List)
                .whereType<Map<String, dynamic>>()
                .map(_aktivitasDariCatatan)
                .toList();
          }
        });
      }
    } catch (_) {}
  }

  // Ringkasan catatan dari /dashboard (catatan_terbaru) untuk daftar aktivitas
  Aktivitas _aktivitasDariCatatan(Map<String, dynamic> c) {
    final tanggal = DateTime.tryParse(c['tanggal']?.toString() ?? '');
    return Aktivitas(
      idCatatan: int.tryParse(c['id_catatan']?.toString() ?? ''),
      nama: c['nama_siswa']?.toString() ?? 'Siswa',
      keterangan: '${c['kategori'] ?? 'Umum'} · oleh ${c['penulis'] ?? '-'}',
      waktu: tanggal != null ? formatTanggal(tanggal) : '',
    );
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
              nama: 'Selamat Datang,\n${widget.nama}',
              peran: 'Guru',
              onNotifikasi: () => bukaHalaman(context, const NotifikasiPage()),
              onProfil: () => widget.onKeTab(3),
            ),
            const SizedBox(height: 16),

            // Kartu kelas yang diampu
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onKeTab(1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _kelasNama,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(_sekolah, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
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
                MenuCard(icon: Icons.groups_rounded, label: 'Daftar Siswa', onTap: () => widget.onKeTab(1)),
                MenuCard(
                  icon: Icons.edit_note_rounded,
                  label: 'Tambah Catatan',
                  onTap: () =>
                      bukaHalaman(context, const DaftarSiswaPage(judul: 'Pilih Siswa', pilihUntukCatatan: true)),
                ),
                MenuCard(icon: Icons.history_rounded, label: 'Riwayat Catatan', onTap: () => widget.onKeTab(2)),
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
            if (_listAktivitas.isEmpty)
              Container(
                decoration: kartuDecoration(),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Belum ada aktivitas catatan.',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              )
            else
              ListCard(
                children: [
                  for (final a in _listAktivitas)
                    ListItemTile(
                      judul: Text(a.nama),
                      subjudul: a.keterangan,
                      keterangan: a.waktu,
                      perempuan: a.perempuan,
                      onTap: () => widget.onKeTab(2),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
