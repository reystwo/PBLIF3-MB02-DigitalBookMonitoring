// =============================================================
// MODEL FITUR ORANG TUA - anak (siswa) yang tertaut pada akun
// Mengikuti format JSON endpoint /api/orang-tua/anak
// =============================================================

int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

String _str(dynamic v) => v?.toString() ?? '';

class AnakOrangTua {
  final int idSiswa;
  final String nis;
  final String nama;
  // 'L' atau 'P'
  final String jenisKelamin;
  final bool perempuan;
  final String kelas;
  final String tahunAjaran;
  final String waliKelas;
  // Hubungan akun orang tua dengan anak: Ayah / Ibu / Wali
  final String hubungan;

  const AnakOrangTua({
    required this.idSiswa,
    required this.nis,
    required this.nama,
    required this.jenisKelamin,
    required this.perempuan,
    required this.kelas,
    this.tahunAjaran = '',
    this.waliKelas = '',
    this.hubungan = '',
  });

  factory AnakOrangTua.fromJson(Map<String, dynamic> json) {
    final jk = _str(json['jenis_kelamin']).toUpperCase();
    final perempuan = json['perempuan'] is bool ? json['perempuan'] as bool : jk == 'P';

    return AnakOrangTua(
      idSiswa: _int(json['id_siswa']),
      nis: _str(json['nis']),
      nama: _str(json['nama']),
      jenisKelamin: jk.isNotEmpty ? jk : (perempuan ? 'P' : 'L'),
      perempuan: perempuan,
      kelas: _str(json['kelas']),
      tahunAjaran: _str(json['tahun_ajaran']),
      waliKelas: _str(json['wali_kelas']),
      hubungan: _str(json['hubungan']),
    );
  }

  String get labelJenisKelamin => perempuan ? 'Perempuan' : 'Laki-laki';

  String get labelKelas {
    if (kelas.isEmpty) return 'Belum ada kelas';
    return tahunAjaran.isEmpty ? 'Kelas $kelas' : 'Kelas $kelas ($tahunAjaran)';
  }

  /// Nama panggilan singkat (kata pertama nama lengkap).
  String get namaDepan => nama.trim().split(RegExp(r'\s+')).first;
}
