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
}

class Lampiran {
  final String namaFile;
  final String ukuran;

  const Lampiran({required this.namaFile, required this.ukuran});
}

class Catatan {
  final int? idCatatan;
  final String penulis;
  final String peranPenulis; // contoh: "Guru Kelas 5A" / "Orang Tua"
  final bool penulisPerempuan;
  final Siswa siswa;
  final String kategori;
  final DateTime tanggal;
  final String isi;
  final Lampiran? lampiran;

  const Catatan({
    this.idCatatan,
    required this.penulis,
    required this.peranPenulis,
    required this.siswa,
    required this.kategori,
    required this.tanggal,
    required this.isi,
    this.penulisPerempuan = false,
    this.lampiran,
  });

  factory Catatan.fromModel(CatatanModel model) {
    return Catatan(
      idCatatan: model.idCatatan,
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
    );
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
}

const List<String> daftarKelas = ['5A', '5B'];

const List<String> kategoriCatatan = [
  'Akademik',
  'Perilaku',
  'Kesehatan',
  'Kegiatan',
  'Lainnya',
];

const List<Siswa> daftarSiswa = [
  Siswa(nama: 'Ahmad Rizki', kelas: '5A'),
  Siswa(nama: 'Aisyah Putri', kelas: '5A', perempuan: true),
  Siswa(nama: 'Budi Santoso', kelas: '5A'),
  Siswa(nama: 'Citra Lestari', kelas: '5B', perempuan: true),
  Siswa(nama: 'Dani Pratama', kelas: '5B'),
  Siswa(nama: 'Fajar Ramadhan', kelas: '5B'),
  Siswa(nama: 'Siti Aisyah', kelas: '5A', perempuan: true),
];

final List<Catatan> daftarCatatan = [
  Catatan(
    penulis: 'Bapak Ahmad',
    peranPenulis: 'Guru Kelas 5A',
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
    peranPenulis: 'Guru Kelas 5A',
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
