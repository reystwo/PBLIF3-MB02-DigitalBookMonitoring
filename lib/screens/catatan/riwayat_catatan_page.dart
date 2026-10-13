// =============================================================
// RIWAYAT CATATAN - daftar seluruh catatan
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/catatan/detail_catatan_page.dart';

class RiwayatCatatanPage extends StatefulWidget {
  final String judul;
  final VoidCallback? onBack;

  const RiwayatCatatanPage({super.key, this.judul = 'Riwayat Catatan', this.onBack});

  @override
  State<RiwayatCatatanPage> createState() => _RiwayatCatatanPageState();
}

class _RiwayatCatatanPageState extends State<RiwayatCatatanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JudulAppBar(judul: widget.judul, onBack: widget.onBack),
      body: daftarCatatan.isEmpty
          ? const Center(
              child: Text('Belum ada catatan', style: TextStyle(color: AppColors.textGrey)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ListCard(
                  children: [
                    for (final c in daftarCatatan) CatatanTile(catatan: c, tampilkanSiswa: true),
                  ],
                ),
              ],
            ),
    );
  }
}

// Baris catatan, dipakai juga di dashboard orang tua
class CatatanTile extends StatelessWidget {
  final Catatan catatan;
  final bool tampilkanSiswa;

  const CatatanTile({super.key, required this.catatan, this.tampilkanSiswa = false});

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
      onTap: () => bukaHalaman(context, DetailCatatanPage(catatan: catatan)),
    );
  }
}
