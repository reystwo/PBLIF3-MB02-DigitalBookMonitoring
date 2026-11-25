// =============================================================
// ORANG TUA / WALI - kerangka bottom navigation + dashboard
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/catatan/riwayat_catatan_page.dart';
import 'package:digital_book_connect/screens/notifikasi/notifikasi_page.dart';
import 'package:digital_book_connect/screens/orang_tua/profil_anak_page.dart';
import 'package:digital_book_connect/screens/profil/profil_page.dart';

import 'package:digital_book_connect/services/session_manager.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/app_repository.dart';
import 'package:digital_book_connect/services/orang_tua_repository.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/orang_tua_models.dart';

typedef MuatDashboard = Future<ApiResponse<Map<String, dynamic>>> Function();

class OrangTuaMainPage extends StatefulWidget {
  // Dapat diganti saat pengujian
  final MuatAnak? muatAnak;
  final MuatDashboard? muatDashboard;

  const OrangTuaMainPage({super.key, this.muatAnak, this.muatDashboard});

  @override
  State<OrangTuaMainPage> createState() => _OrangTuaMainPageState();
}

class _OrangTuaMainPageState extends State<OrangTuaMainPage> {
  String _nama = 'Bapak/Ibu';
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
      1 => ProfilAnakPage(onBack: () => _keTab(0), muat: widget.muatAnak),
      2 => RiwayatCatatanPage(judul: 'Pesan', onBack: () => _keTab(0)),
      3 => ProfilPage(nama: _nama, peran: 'Orang Tua / Wali Murid', onBack: () => _keTab(0)),
      _ => _OrangTuaDashboard(
          nama: _nama,
          onKeTab: _keTab,
          muatAnak: widget.muatAnak,
          muatDashboard: widget.muatDashboard,
        ),
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
  final MuatAnak? muatAnak;
  final MuatDashboard? muatDashboard;

  const _OrangTuaDashboard({
    required this.nama,
    required this.onKeTab,
    this.muatAnak,
    this.muatDashboard,
  });

  @override
  State<_OrangTuaDashboard> createState() => _OrangTuaDashboardState();
}

class _OrangTuaDashboardState extends State<_OrangTuaDashboard> {
  // Anak dari server (endpoint /api/orang-tua/anak), bukan data dummy
  List<AnakOrangTua> _anak = const [];
  bool _memuatAnak = true;
  String? _errorAnak;
  // Hanya catatan dari server (bukan data dummy)
  List<Catatan> _catatanAnak = const [];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    final muatAnak = widget.muatAnak ?? OrangTuaRepository.getAnak;
    final muatDashboard = widget.muatDashboard ?? AppRepository.getDashboard;

    final (anakRes, dashboardRes) = await (muatAnak(), muatDashboard()).wait;
    if (!mounted) return;

    setState(() {
      _memuatAnak = false;

      final anak = anakRes.data;
      if (anakRes.isSuccess && anak != null) {
        _anak = anak;
        _errorAnak = null;
      } else {
        _anak = const [];
        _errorAnak = anakRes.message;
      }

      final data = dashboardRes.data;
      if (dashboardRes.isSuccess && data != null && data['catatan_terbaru'] is List) {
        _catatanAnak = (data['catatan_terbaru'] as List)
            .whereType<Map<String, dynamic>>()
            .map((c) => Catatan.fromModel(CatatanModel.fromJson(c)))
            .toList();
      }
    });
  }

  Future<void> _ulangiMuat() {
    setState(() {
      _memuatAnak = true;
      _errorAnak = null;
    });
    return _fetchDashboard();
  }

  // Kartu ringkasan anak: memuat / gagal / belum ada / 1 anak / beberapa anak
  Widget _kartuAnak() {
    Widget leading;
    String judul;
    String subjudul;
    VoidCallback onTap = () => widget.onKeTab(1);

    if (_memuatAnak) {
      leading = const CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
        ),
      );
      judul = 'Memuat data anak...';
      subjudul = 'Mohon tunggu sebentar';
    } else if (_errorAnak != null) {
      leading = const CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        child: Icon(Icons.cloud_off_rounded, color: AppColors.primary),
      );
      judul = 'Gagal memuat data anak';
      subjudul = 'Ketuk untuk mencoba lagi';
      onTap = _ulangiMuat;
    } else if (_anak.isEmpty) {
      leading = const CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        child: Icon(Icons.child_care_rounded, color: AppColors.primary),
      );
      judul = 'Belum ada anak terhubung';
      subjudul = 'Hubungi Administrator sekolah';
    } else if (_anak.length == 1) {
      final anak = _anak.first;
      leading = AppAvatar(radius: 26, perempuan: anak.perempuan, backgroundColor: Colors.white);
      judul = 'Ananda ${anak.namaDepan}';
      subjudul = anak.kelas.isEmpty ? 'Belum ada kelas' : 'Kelas ${anak.kelas}';
    } else {
      leading = const CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        child: Icon(Icons.groups_rounded, color: AppColors.primary),
      );
      judul = '${_anak.length} Anak Terhubung';
      subjudul = _anak.map((a) => a.namaDepan).join(', ');
    }

    return Material(
      key: const Key('kartu-anak-dashboard'),
      color: AppColors.primaryLight.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subjudul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              nama: widget.nama,
              peran: 'Orang Tua / Wali Murid',
              onNotifikasi: () => bukaHalaman(context, const NotifikasiPage()),
              onProfil: () => widget.onKeTab(3),
            ),
            const SizedBox(height: 16),

            // Kartu anak
            _kartuAnak(),
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
            if (_catatanAnak.isEmpty)
              Container(
                decoration: kartuDecoration(),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Belum ada catatan',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              )
            else
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
