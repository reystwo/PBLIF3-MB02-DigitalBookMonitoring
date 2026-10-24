import 'package:digital_book_connect/models/siswa_model.dart';

class LampiranModel {
  final String namaFile;
  final String ukuran;

  const LampiranModel({
    required this.namaFile,
    required this.ukuran,
  });

  factory LampiranModel.fromJson(Map<String, dynamic> json) {
    return LampiranModel(
      namaFile: json['nama_file']?.toString() ?? json['namaFile']?.toString() ?? '',
      ukuran: json['ukuran']?.toString() ?? '1.0 MB',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_file': namaFile,
      'ukuran': ukuran,
    };
  }
}

class CatatanModel {
  final int idCatatan;
  final int idSiswa;
  final int idPengirim;
  final int idPenerima;
  final String penulis;
  final String peranPenulis;
  final bool penulisPerempuan;
  final String kategori;
  final String isi;
  final DateTime tanggal;
  final String tanggalLabel;
  final String statusDibaca;
  final SiswaModel siswa;
  final LampiranModel? lampiran;
  // Waktu catatan disimpan di server (created_at); null pada data lama/dummy
  final DateTime? dibuatPada;

  const CatatanModel({
    required this.idCatatan,
    required this.idSiswa,
    required this.idPengirim,
    required this.idPenerima,
    required this.penulis,
    required this.peranPenulis,
    this.penulisPerempuan = false,
    required this.kategori,
    required this.isi,
    required this.tanggal,
    required this.tanggalLabel,
    this.statusDibaca = 'belum_dibaca',
    required this.siswa,
    this.lampiran,
    this.dibuatPada,
  });

  factory CatatanModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['tanggal']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final siswaJson = json['siswa'] is Map<String, dynamic>
        ? json['siswa'] as Map<String, dynamic>
        : <String, dynamic>{
            'id_siswa': json['id_siswa'],
            'nama': 'Siswa',
            'kelas': '',
          };

    LampiranModel? lampiranParsed;
    if (json['lampiran'] is Map<String, dynamic>) {
      lampiranParsed = LampiranModel.fromJson(json['lampiran']);
    } else if (json['lampiran_nama'] != null && json['lampiran_nama'].toString().isNotEmpty) {
      lampiranParsed = LampiranModel(
        namaFile: json['lampiran_nama'].toString(),
        ukuran: json['lampiran_ukuran']?.toString() ?? '1.0 MB',
      );
    }

    return CatatanModel(
      idCatatan: json['id_catatan'] is int
          ? json['id_catatan']
          : int.tryParse(json['id_catatan']?.toString() ?? '0') ?? 0,
      idSiswa: json['id_siswa'] is int
          ? json['id_siswa']
          : int.tryParse(json['id_siswa']?.toString() ?? '0') ?? 0,
      idPengirim: json['id_pengirim'] is int
          ? json['id_pengirim']
          : int.tryParse(json['id_pengirim']?.toString() ?? '0') ?? 0,
      idPenerima: json['id_penerima'] is int
          ? json['id_penerima']
          : int.tryParse(json['id_penerima']?.toString() ?? '0') ?? 0,
      penulis: json['penulis']?.toString() ?? 'Pengguna',
      peranPenulis: json['peran_penulis']?.toString() ?? 'Pengguna',
      penulisPerempuan: json['penulis_perempuan'] == true,
      kategori: json['kategori']?.toString() ?? 'Umum',
      isi: json['isi']?.toString() ?? json['isi_catatan']?.toString() ?? '',
      tanggal: parsedDate,
      tanggalLabel: json['tanggal_label']?.toString() ??
          '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}',
      statusDibaca: json['status_dibaca']?.toString() ?? 'belum_dibaca',
      siswa: SiswaModel.fromJson(siswaJson),
      lampiran: lampiranParsed,
      dibuatPada: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class AktivitasModel {
  final int idCatatan;
  final int idSiswa;
  final String nama;
  final String keterangan;
  final String waktu;
  final bool perempuan;
  final String statusDibaca;

  const AktivitasModel({
    required this.idCatatan,
    required this.idSiswa,
    required this.nama,
    required this.keterangan,
    required this.waktu,
    this.perempuan = false,
    this.statusDibaca = 'belum_dibaca',
  });

  factory AktivitasModel.fromJson(Map<String, dynamic> json) {
    return AktivitasModel(
      idCatatan: json['id_catatan'] is int
          ? json['id_catatan']
          : int.tryParse(json['id_catatan']?.toString() ?? '0') ?? 0,
      idSiswa: json['id_siswa'] is int
          ? json['id_siswa']
          : int.tryParse(json['id_siswa']?.toString() ?? '0') ?? 0,
      nama: json['nama']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      waktu: json['waktu']?.toString() ?? '',
      perempuan: json['perempuan'] == true,
      statusDibaca: json['status_dibaca']?.toString() ?? 'belum_dibaca',
    );
  }
}
