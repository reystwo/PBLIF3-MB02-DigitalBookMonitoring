// =============================================================
// DAFTAR SISWA (GURU) - siswa di kelas yang diampu sebagai wali kelas
// Pencarian nama/NIS + pagination; data dibatasi oleh backend.
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/models/guru_models.dart';
import 'package:digital_book_connect/services/guru_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';
import 'package:digital_book_connect/screens/catatan/tambah_catatan_page.dart';
import 'package:digital_book_connect/screens/siswa/detail_siswa_page.dart';

class DaftarSiswaPage extends StatelessWidget {
  final String judul;
  // Dipakai saat halaman ini menjadi tab (kembali ke tab Beranda)
  final VoidCallback? onBack;
  // true: memilih siswa langsung membuka form Tambah Catatan
  final bool pilihUntukCatatan;
  // Dapat diganti saat pengujian
  final PageFetcher<SiswaGuru>? fetcher;

  const DaftarSiswaPage({
    super.key,
    this.judul = 'Daftar Siswa',
    this.onBack,
    this.pilihUntukCatatan = false,
    this.fetcher,
  });

  @override
  Widget build(BuildContext context) {
    return AdminListPage<SiswaGuru>(
      judul: judul,
      onBack: onBack,
      hintCari: 'Cari nama atau NIS siswa...',
      teksKosong: 'Belum ada siswa di kelas Anda',
      pesanKosong: 'Siswa akan tampil setelah Anda ditetapkan sebagai wali kelas oleh Administrator.',
      fetcher: fetcher ?? (page, search) => GuruRepository.getSiswa(page: page, search: search),
      itemBuilder: (s, onTap) => ListItemTile(
        judul: Text(s.nama),
        subjudul: 'NIS ${s.nis} · Kelas ${s.kelas}',
        keterangan: s.jumlahCatatan == 0 ? 'Belum ada catatan' : '${s.jumlahCatatan} catatan',
        perempuan: s.perempuan,
        onTap: onTap,
      ),
      onBukaDetail: (context, s) => pilihUntukCatatan
          ? Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => TambahCatatanPage(siswa: s.toSiswa())))
          : Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailSiswaGuruPage(idSiswa: s.idSiswa))),
    );
  }
}
