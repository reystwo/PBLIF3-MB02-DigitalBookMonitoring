// =============================================================
// DATA DUMMY - dipakai sementara sampai backend tersedia
// =============================================================

import 'package:digital_book_connect/models/siswa_model.dart';
import 'package:digital_book_connect/models/catatan_model.dart';

class Siswa {
  final int? idSiswa;
  final String nama;
  final String kelas;
  final bool perempuan;

  const Siswa({
    this.idSiswa,
    required this.nama,
    required this.kelas,
    this.perempuan = false,
  });

  factory Siswa.fromModel(SiswaModel model) {
    return Siswa(
      idSiswa: model.idSiswa,
      nama: model.nama,
      kelas: model.kelas,
      perempuan: model.perempuan,
    );
  }

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa.fromModel(SiswaModel.fromJson(json));
  }

  SiswaModel toModel() {
    return SiswaModel(
      idSiswa: idSiswa ?? 0,
      nis: '',
      nama: nama,
      jenisKelamin: perempuan ? 'P' : 'L',
      perempuan: perempuan,
      idKelas: 0,
      kelas: kelas,
    );
  }

  Map<String, dynamic> toJson() => toModel().toJson();
}

class Lampiran {
  final String namaFile;
  final String ukuran;

  const Lampiran({required this.namaFile, required this.ukuran});

  factory Lampiran.fromJson(Map<String, dynamic> json) {
    return Lampiran(
      namaFile: json['nama_file']?.toString() ?? json['namaFile']?.toString() ?? '',
      ukuran: json['ukuran']?.toString() ?? '1.0 MB',
    );
  }
}

class Catatan {
  final int? idCatatan;
  final int? parentId;
  final int? idPengirim;
  final String penulis;
  final String peranPenulis; // contoh: "Guru Kelas 7A" / "Orang Tua"
  final bool penulisPerempuan;
  final Siswa siswa;
  final String kategori;
  final DateTime tanggal;
  final String isi;
  final Lampiran? lampiran;
  final int jumlahBalasan;
  final List<Catatan> balasan;

  const Catatan({
    this.idCatatan,
    this.parentId,
    this.idPengirim,
    required this.penulis,
    required this.peranPenulis,
    required this.siswa,
    required this.kategori,
    required this.tanggal,
    required this.isi,
    this.penulisPerempuan = false,
    this.lampiran,
    this.jumlahBalasan = 0,
    this.balasan = const [],
  });

  factory Catatan.fromModel(CatatanModel model) {
    final daftarBalasan = model.balasan.map(Catatan.fromModel).toList();
    return Catatan(
      idCatatan: model.idCatatan,
      parentId: model.parentId,
      idPengirim: model.idPengirim,
      penulis: model.penulis,
      peranPenulis: model.peranPenulis,
      penulisPerempuan: model.penulisPerempuan,
      siswa: Siswa.fromModel(model.siswa),
      kategori: model.kategori,
      tanggal: model.tanggal,
      isi: model.isi,
      lampiran: model.lampiran != null
          ? Lampiran(
              namaFile: model.lampiran!.namaFile,
              ukuran: model.lampiran!.ukuran,
            )
          : null,
      jumlahBalasan: model.jumlahBalasan > daftarBalasan.length
          ? model.jumlahBalasan
          : daftarBalasan.length,
      balasan: daftarBalasan,
    );
  }

  Catatan copyWith({
    int? jumlahBalasan,
    List<Catatan>? balasan,
  }) {
    return Catatan(
      idCatatan: idCatatan,
      parentId: parentId,
      idPengirim: idPengirim,
      penulis: penulis,
      peranPenulis: peranPenulis,
      penulisPerempuan: penulisPerempuan,
      siswa: siswa,
      kategori: kategori,
      tanggal: tanggal,
      isi: isi,
      lampiran: lampiran,
      jumlahBalasan: jumlahBalasan ?? this.jumlahBalasan,
      balasan: balasan ?? this.balasan,
    );
  }

  factory Catatan.fromJson(Map<String, dynamic> json) {
    return Catatan.fromModel(CatatanModel.fromJson(json));
  }
}

class Aktivitas {
  final int? idCatatan;
  final String nama;
  final String keterangan;
  final String waktu;
  final bool perempuan;

  const Aktivitas({
    this.idCatatan,
    required this.nama,
    required this.keterangan,
    required this.waktu,
    this.perempuan = false,
  });

  factory Aktivitas.fromModel(AktivitasModel model) {
    return Aktivitas(
      idCatatan: model.idCatatan,
      nama: model.nama,
      keterangan: model.keterangan,
      waktu: model.waktu,
      perempuan: model.perempuan,
    );
  }

  factory Aktivitas.fromJson(Map<String, dynamic> json) {
    return Aktivitas.fromModel(AktivitasModel.fromJson(json));
  }
}

const List<String> daftarKelas = ['7A', '7B'];

const List<String> kategoriCatatan = [
  'Akademik',
  'Perilaku',
  'Kesehatan',
  'Kegiatan',
  'Lainnya',
];

const List<Siswa> daftarSiswa = [
  Siswa(nama: 'Ahmad Rizki', kelas: '7A'),
  Siswa(nama: 'Aisyah Putri', kelas: '7A', perempuan: true),
  Siswa(nama: 'Budi Santoso', kelas: '7A'),
  Siswa(nama: 'Citra Lestari', kelas: '7B', perempuan: true),
  Siswa(nama: 'Dani Pratama', kelas: '7B'),
  Siswa(nama: 'Fajar Ramadhan', kelas: '7B'),
  Siswa(nama: 'Siti Aisyah', kelas: '7A', perempuan: true),
];

final List<Catatan> daftarCatatan = [
  Catatan(
    penulis: 'Bapak Ahmad',
    peranPenulis: 'Guru Kelas 7A',
    siswa: daftarSiswa[0],
    kategori: 'Akademik',
    tanggal: DateTime(2025, 9, 12),
    isi: 'Ananda Rizki menunjukkan peningkatan pada mata pelajaran Matematika. '
        'Namun, perlu lebih fokus dalam mengerjakan tugas rumah. Tetap semangat!',
    lampiran: const Lampiran(namaFile: 'Foto_Tugas_Matematika.jpg', ukuran: '1.2 MB'),
  ),
  Catatan(
    penulis: 'Ibu Siti',
    peranPenulis: 'Orang Tua',
    penulisPerempuan: true,
    siswa: daftarSiswa[0],
    kategori: 'Lainnya',
    tanggal: DateTime(2025, 9, 10),
    isi: 'Terima kasih atas informasinya, Pak. Kami akan mendampingi Rizki '
        'belajar di rumah.',
  ),
  Catatan(
    penulis: 'Bapak Ahmad',
    peranPenulis: 'Guru Kelas 7A',
    siswa: daftarSiswa[6],
    kategori: 'Perilaku',
    tanggal: DateTime(2025, 9, 8),
    isi: 'Siti aktif bertanya di kelas dan membantu teman-temannya. Pertahankan!',
  ),
];

const List<Aktivitas> aktivitasTerbaru = [
  Aktivitas(
    nama: 'Siti Aisyah',
    keterangan: 'Menerima catatan baru dari guru',
    waktu: 'Hari ini, 08:24',
    perempuan: true,
  ),
  Aktivitas(
    nama: 'Ahmad Rizki',
    keterangan: 'Orang tua telah membalas pesan',
    waktu: 'Kemarin, 16:45',
  ),
];

// Format tanggal sederhana: 12 Sep 2025
const _namaBulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatTanggal(DateTime t) => '${t.day} ${_namaBulan[t.month - 1]} ${t.year}';
