// =============================================================
// PROFIL ANAK (ORANG TUA) - anak yang ditautkan Admin pada akun
// Data dari server; mendukung 0, 1, atau lebih dari 1 anak.
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/models/orang_tua_models.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/orang_tua_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';

typedef MuatAnak = Future<ApiResponse<List<AnakOrangTua>>> Function();

class ProfilAnakPage extends StatefulWidget {
  // Dipakai saat halaman ini menjadi tab (kembali ke tab Beranda)
  final VoidCallback? onBack;
  // Dapat diganti saat pengujian
  final MuatAnak? muat;

  const ProfilAnakPage({super.key, this.onBack, this.muat});

  @override
  State<ProfilAnakPage> createState() => _ProfilAnakPageState();
}

class _ProfilAnakPageState extends State<ProfilAnakPage> {
  List<AnakOrangTua> _anak = const [];
  bool _loading = true;
  String? _error;

  MuatAnak get _muatAnak => widget.muat ?? OrangTuaRepository.getAnak;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _muatAnak();
    if (!mounted) return;

    final data = res.data;
    final berhasil = res.isSuccess && data != null;
    setState(() {
      _loading = false;
      if (berhasil) {
        _anak = data;
      } else if (_anak.isEmpty) {
        _error = res.message;
      }
    });

    // Muat ulang gagal tetapi data lama masih ada: tetap tampilkan data + beri tahu pengguna
    if (!berhasil && _anak.isNotEmpty) {
      tampilkanPesan(context, 'Gagal memperbarui data: ${res.message}', gagal: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JudulAppBar(judul: 'Profil Anak', onBack: widget.onBack),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: _isi(),
        ),
      ),
    );
  }

  List<Widget> _isi() {
    if (_loading && _anak.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ];
    }

    if (_error != null) {
      return [
        PesanKosong(
          icon: Icons.cloud_off_rounded,
          judul: 'Gagal memuat data anak',
          pesan: _error,
          labelAksi: 'Coba Lagi',
          onAksi: _muat,
        ),
      ];
    }

    if (_anak.isEmpty) {
      return const [
        PesanKosong(
          icon: Icons.child_care_rounded,
          judul: 'Belum ada anak terhubung',
          pesan: 'Data anak akan tampil setelah Administrator sekolah menautkan siswa ke akun Anda. '
              'Silakan hubungi pihak sekolah.',
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          _anak.length == 1 ? '1 anak terhubung dengan akun Anda' : '${_anak.length} anak terhubung dengan akun Anda',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
        ),
      ),
      for (var i = 0; i < _anak.length; i++) ...[
        if (i > 0) const SizedBox(height: 20),
        _KartuAnak(key: Key('kartu-anak-${_anak[i].idSiswa}'), anak: _anak[i]),
      ],
    ];
  }
}

class _KartuAnak extends StatelessWidget {
  final AnakOrangTua anak;

  const _KartuAnak({super.key, required this.anak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailHeader(
          leading: AppAvatar(radius: 28, perempuan: anak.perempuan),
          judul: anak.nama,
          subjudul: anak.labelKelas,
        ),
        const SizedBox(height: 8),
        InfoCard(
          baris: [
            InfoBaris('NIS', anak.nis),
            InfoBaris('Jenis Kelamin', anak.labelJenisKelamin),
            InfoBaris('Kelas', anak.kelas),
            InfoBaris('Tahun Ajaran', anak.tahunAjaran),
            InfoBaris('Wali Kelas', anak.waliKelas),
            InfoBaris('Hubungan Anda', anak.hubungan),
          ],
        ),
      ],
    );
  }
}
