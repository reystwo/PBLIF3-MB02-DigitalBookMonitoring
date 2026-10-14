class SiswaModel {
  final int idSiswa;
  final String nis;
  final String nama;
  final String jenisKelamin;
  final bool perempuan;
  final int idKelas;
  final String kelas;
  final List<dynamic> orangTua;

  const SiswaModel({
    required this.idSiswa,
    required this.nis,
    required this.nama,
    required this.jenisKelamin,
    required this.perempuan,
    required this.idKelas,
    required this.kelas,
    this.orangTua = const [],
  });

  factory SiswaModel.fromJson(Map<String, dynamic> json) {
    final jk = json['jenis_kelamin']?.toString() ?? 'L';
    final isPerempuan = json['perempuan'] is bool
        ? json['perempuan']
        : (jk.toUpperCase() == 'P');

    return SiswaModel(
      idSiswa: json['id_siswa'] is int
          ? json['id_siswa']
          : int.tryParse(json['id_siswa']?.toString() ?? '0') ?? 0,
      nis: json['nis']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      jenisKelamin: jk,
      perempuan: isPerempuan,
      idKelas: json['id_kelas'] is int
          ? json['id_kelas']
          : int.tryParse(json['id_kelas']?.toString() ?? '0') ?? 0,
      kelas: json['kelas']?.toString() ?? '',
      orangTua: json['orang_tua'] is List ? json['orang_tua'] : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_siswa': idSiswa,
      'nis': nis,
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
      'perempuan': perempuan,
      'id_kelas': idKelas,
      'kelas': kelas,
      'orang_tua': orangTua,
    };
  }
}

class KelasModel {
  final int idKelas;
  final String namaKelas;
  final String tingkat;
  final String tahunAjaran;
  final String waliGuru;
  final int totalSiswa;

  const KelasModel({
    required this.idKelas,
    required this.namaKelas,
    required this.tingkat,
    required this.tahunAjaran,
    required this.waliGuru,
    required this.totalSiswa,
  });

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      idKelas: json['id_kelas'] is int
          ? json['id_kelas']
          : int.tryParse(json['id_kelas']?.toString() ?? '0') ?? 0,
      namaKelas: json['nama_kelas']?.toString() ?? '',
      tingkat: json['tingkat']?.toString() ?? '',
      tahunAjaran: json['tahun_ajaran']?.toString() ?? '',
      waliGuru: json['wali_guru']?.toString() ?? '',
      totalSiswa: json['total_siswa'] is int
          ? json['total_siswa']
          : int.tryParse(json['total_siswa']?.toString() ?? '0') ?? 0,
    );
  }
}
