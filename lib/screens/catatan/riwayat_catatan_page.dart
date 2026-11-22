import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/catatan/detail_catatan_page.dart';
import 'package:digital_book_connect/services/app_repository.dart';

class RiwayatCatatanPage extends StatefulWidget {
  final String judul;
  final VoidCallback? onBack;

  const RiwayatCatatanPage({super.key, this.judul = 'Riwayat Catatan', this.onBack});

  @override
  State<RiwayatCatatanPage> createState() => _RiwayatCatatanPageState();
}

class _RiwayatCatatanPageState extends State<RiwayatCatatanPage> {
  // Hanya data dari server: daftar kosong berarti memang belum ada catatan
  List<Catatan> _listCatatan = const [];
  bool _memuat = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCatatan();
  }

  Future<void> _fetchCatatan() async {
    final res = await AppRepository.getCatatan();
    if (!mounted) return;
    setState(() {
      _memuat = false;
      if (res.isSuccess) {
        _error = null;
        _listCatatan = (res.data ?? const []).map((m) => Catatan.fromModel(m)).toList();
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_memuat) {
      return Scaffold(
        appBar: JudulAppBar(judul: widget.judul, onBack: widget.onBack),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: JudulAppBar(judul: widget.judul, onBack: widget.onBack),
      body: RefreshIndicator(
        onRefresh: _fetchCatatan,
        child: _listCatatan.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                    child: Text(
                      _error == null ? 'Belum ada catatan' : 'Gagal memuat catatan.\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  ListCard(
                    children: [
                      for (final c in _listCatatan)
                        CatatanTile(
                          catatan: c,
                          tampilkanSiswa: true,
                          onKembali: _fetchCatatan,
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// Baris catatan, dipakai juga di dashboard orang tua
class CatatanTile extends StatelessWidget {
  final Catatan catatan;
  final bool tampilkanSiswa;
  final VoidCallback? onKembali;

  const CatatanTile({
    super.key,
    required this.catatan,
    this.tampilkanSiswa = false,
    this.onKembali,
  });

  @override
  Widget build(BuildContext context) {
    final peranSingkat = catatan.peranPenulis.startsWith('Guru') ? 'Guru' : catatan.peranPenulis;
    final awalan = peranSingkat == 'Guru' ? 'Catatan' : 'Membalas';
    return ListItemTile(
      perempuan: catatan.penulisPerempuan,
      judul: Text.rich(
        TextSpan(
          text: catatan.penulis,
          children: [
            TextSpan(
              text: ' ($peranSingkat)',
              style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
      subjudul: tampilkanSiswa
          ? '${catatan.siswa.nama} · ${catatan.isi}'
          : '$awalan: ${catatan.isi}',
      keterangan: formatTanggal(catatan.tanggal),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailCatatanPage(catatan: catatan)),
        );
        onKembali?.call();
      },
    );
  }
}
