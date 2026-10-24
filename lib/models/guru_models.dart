// =============================================================
// MODEL FITUR GURU - siswa tanggung jawab wali kelas
// Mengikuti format JSON endpoint /api/guru/*
// =============================================================
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/models/admin_models.dart';

int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

String _str(dynamic v) => v?.toString() ?? '';

class SiswaGuru {
  final int idSiswa;
  final String nis;
  final String nama;
  final bool perempuan;
  final String kelas;
  final String tahunAjaran;
  final int jumlahCatatan;
  // Hanya terisi pada respons detail
  final String waliKelas;
  final List<OrangTuaSiswa> orangTua;

  const SiswaGuru({
    required this.idSiswa,
    required this.nis,
    required this.nama,
    required this.perempuan,
    required this.kelas,
    this.tahunAjaran = '',
    this.jumlahCatatan = 0,
    this.waliKelas = '',
    this.orangTua = const [],
  });

  factory SiswaGuru.fromJson(Map<String, dynamic> json) => SiswaGuru(
        idSiswa: _int(json['id_siswa']),
        nis: _str(json['nis']),
        nama: _str(json['nama']),
        perempuan: json['perempuan'] is bool
            ? json['perempuan'] as bool
            : _str(json['jenis_kelamin']).toUpperCase() == 'P',
        kelas: _str(json['kelas']),
        tahunAjaran: _str(json['tahun_ajaran']),
        jumlahCatatan: _int(json['jumlah_catatan']),
        waliKelas: _str(json['wali_kelas']),
        orangTua: json['orang_tua'] is List
            ? (json['orang_tua'] as List).whereType<Map<String, dynamic>>().map(OrangTuaSiswa.fromJson).toList()
            : const [],
      );

  String get labelKelas => tahunAjaran.isEmpty ? 'Kelas $kelas' : 'Kelas $kelas ($tahunAjaran)';

  /// Bentuk ringkas yang dipakai halaman Tambah Catatan.
  Siswa toSiswa() => Siswa(idSiswa: idSiswa, nama: nama, kelas: kelas, perempuan: perempuan);
}
