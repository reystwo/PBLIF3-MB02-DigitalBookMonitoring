// =============================================================
// DETAIL SISWA (GURU) - info siswa, orang tua, tambah & riwayat catatan
// Riwayat catatan dimuat per halaman, terbaru lebih dulu.
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/models/guru_models.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/guru_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';
import 'package:digital_book_connect/screens/catatan/detail_catatan_page.dart';
import 'package:digital_book_connect/screens/catatan/tambah_catatan_page.dart';

typedef MuatDetailSiswa = Future<ApiResponse<SiswaGuru>> Function(int idSiswa);
typedef MuatCatatanSiswa = Future<ApiResponse<PagedResult<CatatanModel>>> Function(int idSiswa, int page);

class DetailSiswaGuruPage extends StatefulWidget {
  final int idSiswa;
  // Dapat diganti saat pengujian
  final MuatDetailSiswa? muatDetail;
  final MuatCatatanSiswa? muatCatatan;

  const DetailSiswaGuruPage({super.key, required this.idSiswa, this.muatDetail, this.muatCatatan});

  @override
  State<DetailSiswaGuruPage> createState() => _DetailSiswaGuruPageState();
}

class _DetailSiswaGuruPageState extends State<DetailSiswaGuruPage> {
  SiswaGuru? _siswa;
  bool _loading = true;
  String? _error;

  final List<CatatanModel> _catatan = [];
  PageMeta _metaCatatan = const PageMeta();
  bool _memuatCatatan = false;
  String? _errorCatatan;

  MuatDetailSiswa get _muatDetail => widget.muatDetail ?? GuruRepository.getDetailSiswa;
  MuatCatatanSiswa get _muatCatatan =>
      widget.muatCatatan ?? (id, page) => GuruRepository.getCatatanSiswa(id, page: page);

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  Future<void> _muatSemua() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final detailFuture = _muatDetail(widget.idSiswa);
    final catatanFuture = _muatCatatan(widget.idSiswa, 1);
    final detail = await detailFuture;
    final catatan = await catatanFuture;
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (detail.isSuccess && detail.data != null) {
        _siswa = detail.data;
      } else {
        _error = detail.message;
      }
      _terapkanCatatan(catatan, ganti: true);
    });
  }

  Future<void> _muatCatatanBerikutnya() async {
    setState(() => _memuatCatatan = true);
    final res = await _muatCatatan(widget.idSiswa, _metaCatatan.currentPage + 1);
    if (!mounted) return;
    setState(() {
      _memuatCatatan = false;
      _terapkanCatatan(res, ganti: false);
    });
  }

  void _terapkanCatatan(ApiResponse<PagedResult<CatatanModel>> res, {required bool ganti}) {
    final hasil = res.data;
    if (res.isSuccess && hasil != null) {
      if (ganti) _catatan.clear();
      _catatan.addAll(hasil.items);
      _metaCatatan = hasil.meta;
      _errorCatatan = null;
    } else {
      _errorCatatan = res.message;
    }
  }

  Future<void> _tambahCatatan(SiswaGuru siswa) async {
    final tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TambahCatatanPage(siswa: siswa.toSiswa())),
    );
    if (tersimpan == true && mounted) _muatSemua();
  }

  @override
  Widget build(BuildContext context) {
    final siswa = _siswa;
    Widget body;

    if (_loading && siswa == null) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (siswa == null) {
      body = ListView(
        children: [
          PesanKosong(
            icon: Icons.cloud_off_rounded,
            judul: 'Gagal memuat data siswa',
            pesan: _error,
            labelAksi: 'Coba Lagi',
            onAksi: _muatSemua,
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _muatSemua,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            DetailHeader(
              leading: AppAvatar(radius: 26, perempuan: siswa.perempuan),
              judul: siswa.nama,
              subjudul: 'NIS ${siswa.nis}',
            ),
            const SizedBox(height: 16),
            InfoCard(
              baris: [
                InfoBaris('Jenis Kelamin', siswa.perempuan ? 'Perempuan' : 'Laki-laki'),
                InfoBaris('Kelas', siswa.tahunAjaran.isEmpty ? siswa.kelas : '${siswa.kelas} (${siswa.tahunAjaran})'),
                InfoBaris('Wali Kelas', siswa.waliKelas),
                InfoBaris('Catatan', '${siswa.jumlahCatatan} catatan penghubung'),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(judul: 'Orang Tua / Wali'),
            const SizedBox(height: 10),
            if (siswa.orangTua.isEmpty)
              Container(
                decoration: kartuDecoration(),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Belum ada orang tua/wali yang terhubung dengan siswa ini.',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              )
            else
              InfoCard(
                baris: [
                  for (final o in siswa.orangTua) InfoBaris(o.hubungan, '${o.nama}${o.noHp != null ? '\n${o.noHp}' : ''}'),
                ],
              ),
            const SizedBox(height: 20),
            TombolUtama(
              label: 'Tambah Catatan',
              icon: Icons.edit_note_rounded,
              onPressed: () => _tambahCatatan(siswa),
            ),
            const SizedBox(height: 24),
            const SectionHeader(judul: 'Riwayat Catatan'),
            const SizedBox(height: 10),
            ..._riwayat(),
          ],
        ),
      );
    }

    return Scaffold(appBar: const JudulAppBar(judul: 'Detail Siswa'), body: body);
  }

  List<Widget> _riwayat() {
    if (_errorCatatan != null && _catatan.isEmpty) {
      return [
        PesanKosong(
          icon: Icons.cloud_off_rounded,
          judul: 'Gagal memuat riwayat catatan',
          pesan: _errorCatatan,
          labelAksi: 'Coba Lagi',
          onAksi: _muatSemua,
        ),
      ];
    }

    if (_catatan.isEmpty) {
      return const [
        PesanKosong(
          icon: Icons.note_alt_outlined,
          judul: 'Belum ada catatan',
          pesan: 'Tekan "Tambah Catatan" untuk menulis catatan pertama untuk siswa ini.',
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Menampilkan ${_catatan.length} dari ${_metaCatatan.total} catatan · terbaru di atas',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
        ),
      ),
      for (final c in _catatan)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: KartuRiwayatCatatan(
            catatan: c,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailCatatanPage(catatan: Catatan.fromModel(c))),
              );
              if (mounted) _muatSemua();
            },
          ),
        ),
      if (_errorCatatan != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_errorCatatan!, style: TextStyle(fontSize: 12.5, color: Colors.red.shade700)),
        ),
      if (_metaCatatan.adaBerikutnya)
        OutlinedButton.icon(
          onPressed: _memuatCatatan ? null : _muatCatatanBerikutnya,
          icon: _memuatCatatan
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.expand_more_rounded),
          label: Text(_memuatCatatan ? 'Memuat...' : 'Muat catatan sebelumnya'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.divider),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
    ];
  }
}

/// Kartu satu catatan pada riwayat: pembuat, kategori, isi, dan waktu pembuatan.
/// Isi ditampilkan dengan widget Text sehingga selalu diperlakukan sebagai teks biasa.
class KartuRiwayatCatatan extends StatelessWidget {
  final CatatanModel catatan;
  final VoidCallback? onTap;

  const KartuRiwayatCatatan({super.key, required this.catatan, this.onTap});

  static String formatWaktu(DateTime t) =>
      '${formatTanggal(t)}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dibuat = catatan.dibuatPada ?? catatan.tanggal;
    final tanggalBerbeda = formatTanggal(dibuat) != formatTanggal(catatan.tanggal);

    return KartuMaterial(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(radius: 18, perempuan: catatan.penulisPerempuan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catatan.penulis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        Text(catatan.peranPenulis, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      catatan.kategori,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(catatan.isi, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textDark)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Dibuat ${formatWaktu(dibuat)}'
                      '${tanggalBerbeda ? ' · untuk tanggal ${formatTanggal(catatan.tanggal)}' : ''}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
