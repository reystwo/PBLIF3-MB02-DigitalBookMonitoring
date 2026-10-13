// =============================================================
// DAFTAR SISWA - cari & filter siswa per kelas
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/catatan/tambah_catatan_page.dart';

class DaftarSiswaPage extends StatefulWidget {
  final String judul;
  // Dipakai saat halaman ini menjadi tab (kembali ke tab Beranda)
  final VoidCallback? onBack;

  const DaftarSiswaPage({super.key, this.judul = 'Daftar Siswa', this.onBack});

  @override
  State<DaftarSiswaPage> createState() => _DaftarSiswaPageState();
}

class _DaftarSiswaPageState extends State<DaftarSiswaPage> {
  String? _kelasDipilih; // null = semua kelas
  String _kataKunci = '';

  List<Siswa> get _hasil {
    return daftarSiswa.where((s) {
      final cocokKelas = _kelasDipilih == null || s.kelas == _kelasDipilih;
      final cocokNama = s.nama.toLowerCase().contains(_kataKunci.toLowerCase());
      return cocokKelas && cocokNama;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;
    return Scaffold(
      appBar: JudulAppBar(judul: widget.judul, onBack: widget.onBack),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Kolom pencarian
          TextField(
            onChanged: (v) => setState(() => _kataKunci = v),
            decoration: InputDecoration(
              hintText: 'Cari nama siswa...',
              hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filter kelas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Semua Kelas', null),
                for (final k in daftarKelas) _chip('Kelas $k', k),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (hasil.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Siswa tidak ditemukan', style: TextStyle(color: AppColors.textGrey)),
              ),
            )
          else
            ListCard(
              children: [
                for (final s in hasil)
                  ListItemTile(
                    judul: Text(s.nama),
                    subjudul: 'Kelas ${s.kelas}',
                    perempuan: s.perempuan,
                    onTap: () => bukaHalaman(context, TambahCatatanPage(siswa: s)),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? kelas) {
    final aktif = _kelasDipilih == kelas;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: aktif,
        showCheckmark: false,
        onSelected: (_) => setState(() => _kelasDipilih = kelas),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: aktif ? Colors.white : AppColors.textGrey,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: aktif ? AppColors.primary : AppColors.divider),
        ),
      ),
    );
  }
}
