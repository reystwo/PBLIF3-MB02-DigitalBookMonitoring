// =============================================================
// MODEL KELOLA DATA ADMIN - Guru, Orang Tua, Siswa, Kelas
// Mengikuti format JSON endpoint /api/admin/*
// =============================================================

int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

String _str(dynamic v) => v?.toString() ?? '';

String? _strAtauNull(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

List<Map<String, dynamic>> _daftar(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

/// Info halaman dari respons ber-pagination.
class PageMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PageMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 10,
    this.total = 0,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    final lastPage = _int(json['last_page']);
    return PageMeta(
      currentPage: _int(json['current_page']) < 1 ? 1 : _int(json['current_page']),
      lastPage: lastPage < 1 ? 1 : lastPage,
      perPage: _int(json['per_page']),
      total: _int(json['total']),
    );
  }

  bool get adaSebelumnya => currentPage > 1;
  bool get adaBerikutnya => currentPage < lastPage;
}

class PagedResult<T> {
  final List<T> items;
  final PageMeta meta;

  const PagedResult({required this.items, required this.meta});
}

String labelStatusAkun(String status) => status == 'aktif' ? 'Aktif' : 'Nonaktif';

// ---------------------- GURU ----------------------

class KelasRingkas {
  final int idKelas;
  final String namaKelas;
  final String tahunAjaran;

  const KelasRingkas({required this.idKelas, required this.namaKelas, required this.tahunAjaran});

  factory KelasRingkas.fromJson(Map<String, dynamic> json) => KelasRingkas(
        idKelas: _int(json['id_kelas']),
        namaKelas: _str(json['nama_kelas']),
        tahunAjaran: _str(json['tahun_ajaran']),
      );
}

class GuruAdmin {
  final int idGuru;
  final int idUser;
  final String nama;
  final String username;
  final String status;
  final String nip;
  final String? noHp;
  final List<KelasRingkas> kelasWali;
  final int jumlahCatatan;

  const GuruAdmin({
    required this.idGuru,
    required this.idUser,
    required this.nama,
    required this.username,
    required this.status,
    required this.nip,
    this.noHp,
    this.kelasWali = const [],
    this.jumlahCatatan = 0,
  });

  bool get aktif => status == 'aktif';

  factory GuruAdmin.fromJson(Map<String, dynamic> json) => GuruAdmin(
        idGuru: _int(json['id_guru']),
        idUser: _int(json['id_user']),
        nama: _str(json['nama']),
        username: _str(json['username']),
        status: _str(json['status']).isEmpty ? 'aktif' : _str(json['status']),
        nip: _str(json['nip']),
        noHp: _strAtauNull(json['no_hp']),
        kelasWali: _daftar(json['kelas_wali']).map(KelasRingkas.fromJson).toList(),
        jumlahCatatan: _int(json['jumlah_catatan']),
      );
}

// ---------------------- ORANG TUA ----------------------

class AnakRingkas {
  final int idSiswa;
  final String nis;
  final String nama;
  final String kelas;
  final bool perempuan;
  final String hubungan;

  const AnakRingkas({
    required this.idSiswa,
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.perempuan,
    required this.hubungan,
  });

  factory AnakRingkas.fromJson(Map<String, dynamic> json) => AnakRingkas(
        idSiswa: _int(json['id_siswa']),
        nis: _str(json['nis']),
        nama: _str(json['nama']),
        kelas: _str(json['kelas']),
        perempuan: json['perempuan'] == true,
        hubungan: _str(json['hubungan']).isEmpty ? 'Wali' : _str(json['hubungan']),
      );
}

class OrangTuaAdmin {
  final int idOrangTua;
  final int idUser;
  final String nama;
  final String username;
  final String status;
  final String? noHp;
  final String? alamat;
  final List<AnakRingkas> anak;
  final int jumlahCatatan;

  const OrangTuaAdmin({
    required this.idOrangTua,
    required this.idUser,
    required this.nama,
    required this.username,
    required this.status,
    this.noHp,
    this.alamat,
    this.anak = const [],
    this.jumlahCatatan = 0,
  });

  bool get aktif => status == 'aktif';

  factory OrangTuaAdmin.fromJson(Map<String, dynamic> json) => OrangTuaAdmin(
        idOrangTua: _int(json['id_orang_tua']),
        idUser: _int(json['id_user']),
        nama: _str(json['nama']),
        username: _str(json['username']),
        status: _str(json['status']).isEmpty ? 'aktif' : _str(json['status']),
        noHp: _strAtauNull(json['no_hp']),
        alamat: _strAtauNull(json['alamat']),
        anak: _daftar(json['anak']).map(AnakRingkas.fromJson).toList(),
        jumlahCatatan: _int(json['jumlah_catatan']),
      );
}

// ---------------------- SISWA ----------------------

/// Nilai hubungan siswa-orang tua yang diterima backend.
const daftarHubungan = ['Ayah', 'Ibu', 'Wali'];

class OrangTuaSiswa {
  final int idOrangTua;
  final String nama;
  final String? noHp;
  final String hubungan;

  const OrangTuaSiswa({
    required this.idOrangTua,
    required this.nama,
    this.noHp,
    required this.hubungan,
  });

  factory OrangTuaSiswa.fromJson(Map<String, dynamic> json) => OrangTuaSiswa(
        idOrangTua: _int(json['id_orang_tua']),
        nama: _str(json['nama']),
        noHp: _strAtauNull(json['no_hp']),
        hubungan: _str(json['hubungan']).isEmpty ? 'Wali' : _str(json['hubungan']),
      );

  OrangTuaSiswa copyWith({String? hubungan}) => OrangTuaSiswa(
        idOrangTua: idOrangTua,
        nama: nama,
        noHp: noHp,
        hubungan: hubungan ?? this.hubungan,
      );

  Map<String, dynamic> toRequest() => {'id_orang_tua': idOrangTua, 'hubungan': hubungan};
}

class SiswaAdmin {
  final int idSiswa;
  final String nis;
  final String nama;
  final String jenisKelamin;
  final bool perempuan;
  final int idKelas;
  final String kelas;
  final String tahunAjaran;
  final List<OrangTuaSiswa> orangTua;
  final String waliKelas;
  final int jumlahCatatan;

  const SiswaAdmin({
    required this.idSiswa,
    required this.nis,
    required this.nama,
    required this.jenisKelamin,
    required this.perempuan,
    required this.idKelas,
    required this.kelas,
    this.tahunAjaran = '',
    this.orangTua = const [],
    this.waliKelas = '',
    this.jumlahCatatan = 0,
  });

  factory SiswaAdmin.fromJson(Map<String, dynamic> json) {
    final jk = _str(json['jenis_kelamin']).isEmpty ? 'L' : _str(json['jenis_kelamin']);
    return SiswaAdmin(
      idSiswa: _int(json['id_siswa']),
      nis: _str(json['nis']),
      nama: _str(json['nama']),
      jenisKelamin: jk,
      perempuan: json['perempuan'] is bool ? json['perempuan'] as bool : jk == 'P',
      idKelas: _int(json['id_kelas']),
      kelas: _str(json['kelas']),
      tahunAjaran: _str(json['tahun_ajaran']),
      orangTua: _daftar(json['orang_tua']).map(OrangTuaSiswa.fromJson).toList(),
      waliKelas: _str(json['wali_kelas']),
      jumlahCatatan: _int(json['jumlah_catatan']),
    );
  }
}

// ---------------------- KELAS ----------------------

class SiswaRingkas {
  final int idSiswa;
  final String nis;
  final String nama;
  final bool perempuan;

  const SiswaRingkas({required this.idSiswa, required this.nis, required this.nama, required this.perempuan});

  factory SiswaRingkas.fromJson(Map<String, dynamic> json) => SiswaRingkas(
        idSiswa: _int(json['id_siswa']),
        nis: _str(json['nis']),
        nama: _str(json['nama']),
        perempuan: json['perempuan'] == true,
      );
}

class KelasAdmin {
  final int idKelas;
  final String namaKelas;
  final String tingkat;
  final String tahunAjaran;
  final int idWaliGuru;
  final String waliGuru;
  final String nipWaliGuru;
  final int totalSiswa;
  final List<SiswaRingkas> siswa;

  const KelasAdmin({
    required this.idKelas,
    required this.namaKelas,
    required this.tingkat,
    required this.tahunAjaran,
    required this.idWaliGuru,
    required this.waliGuru,
    this.nipWaliGuru = '',
    this.totalSiswa = 0,
    this.siswa = const [],
  });

  factory KelasAdmin.fromJson(Map<String, dynamic> json) => KelasAdmin(
        idKelas: _int(json['id_kelas']),
        namaKelas: _str(json['nama_kelas']),
        tingkat: _str(json['tingkat']),
        tahunAjaran: _str(json['tahun_ajaran']),
        idWaliGuru: _int(json['id_wali_guru']),
        waliGuru: _str(json['wali_guru']),
        nipWaliGuru: _str(json['nip_wali_guru']),
        totalSiswa: _int(json['total_siswa']),
        siswa: _daftar(json['siswa']).map(SiswaRingkas.fromJson).toList(),
      );
}
