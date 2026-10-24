// =============================================================
// ADMIN - KELOLA KELAS: daftar, detail, tambah, ubah, hapus
// Termasuk penentuan wali kelas (kelas.id_wali_guru).
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/admin_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';
import 'package:digital_book_connect/screens/admin/kelola_siswa_page.dart';

class KelolaKelasPage extends StatelessWidget {
  const KelolaKelasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminListPage<KelasAdmin>(
      judul: 'Kelola Kelas',
      hintCari: 'Cari nama kelas, tingkat, tahun ajaran, atau wali...',
      labelTambah: 'Tambah Kelas',
      teksKosong: 'Belum ada data kelas',
      fetcher: (page, search) => AdminRepository.getKelas(page: page, search: search),
      itemBuilder: (k, onTap) => ListItemTile(
        leading: const IkonBulat(Icons.diversity_3_rounded),
        judul: Text('Kelas ${k.namaKelas}'),
        subjudul: 'Wali kelas: ${k.waliGuru.isEmpty ? '-' : k.waliGuru}',
        keterangan: 'TA ${k.tahunAjaran} · ${k.totalSiswa} siswa',
        onTap: onTap,
      ),
      onBukaDetail: (context, k) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailKelasPage(idKelas: k.idKelas))),
      onTambah: (context) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const FormKelasPage())),
    );
  }
}

class DetailKelasPage extends StatelessWidget {
  final int idKelas;

  const DetailKelasPage({super.key, required this.idKelas});

  @override
  Widget build(BuildContext context) {
    return AdminDetailPage<KelasAdmin>(
      judul: 'Detail Kelas',
      judulHapus: 'Hapus Kelas',
      muat: () => AdminRepository.getDetailKelas(idKelas),
      hapus: (k) => AdminRepository.hapusKelas(k.idKelas),
      pesanKonfirmasiHapus: (k) => 'Hapus kelas ${k.namaKelas} (${k.tahunAjaran})? Tindakan ini tidak dapat dibatalkan.',
      bukaEdit: (context, k) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => FormKelasPage(kelas: k))),
      isi: (context, k) => [
        DetailHeader(
          leading: const IkonBulat(Icons.diversity_3_rounded, radius: 26),
          judul: 'Kelas ${k.namaKelas}',
          subjudul: 'Tahun ajaran ${k.tahunAjaran}',
        ),
        const SizedBox(height: 16),
        InfoCard(
          baris: [
            InfoBaris('Tingkat', k.tingkat),
            InfoBaris('Wali Kelas', k.nipWaliGuru.isEmpty ? k.waliGuru : '${k.waliGuru}\nNIP ${k.nipWaliGuru}'),
            InfoBaris('Jumlah Siswa', '${k.totalSiswa} siswa'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(judul: 'Daftar Siswa'),
        const SizedBox(height: 10),
        if (k.siswa.isEmpty)
          Container(
            decoration: kartuDecoration(),
            padding: const EdgeInsets.all(14),
            child: const Text(
              'Belum ada siswa di kelas ini. Tempatkan siswa melalui menu Kelola Siswa.',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          )
        else
          ListCard(
            children: [
              for (final s in k.siswa)
                ListItemTile(
                  judul: Text(s.nama),
                  subjudul: 'NIS ${s.nis}',
                  perempuan: s.perempuan,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => DetailSiswaPage(idSiswa: s.idSiswa))),
                ),
            ],
          ),
      ],
    );
  }
}

class FormKelasPage extends StatefulWidget {
  final KelasAdmin? kelas;

  const FormKelasPage({super.key, this.kelas});

  @override
  State<FormKelasPage> createState() => _FormKelasPageState();
}

class _FormKelasPageState extends State<FormKelasPage> {
  final _formKey = GlobalKey<FormState>();
  late final _namaKelas = TextEditingController(text: widget.kelas?.namaKelas);
  late final _tingkat = TextEditingController(text: widget.kelas?.tingkat);
  late final _tahunAjaran = TextEditingController(text: widget.kelas?.tahunAjaran);
  late int? _idWaliGuru = widget.kelas?.idWaliGuru;
  late String? _namaWaliGuru = widget.kelas?.waliGuru;
  bool _menyimpan = false;
  bool _sudahSubmit = false;
  Map<String, String> _errorServer = {};

  bool get _modeUbah => widget.kelas != null;

  @override
  void dispose() {
    _namaKelas.dispose();
    _tingkat.dispose();
    _tahunAjaran.dispose();
    super.dispose();
  }

  void _hapusError(String field) {
    if (_errorServer.containsKey(field)) setState(() => _errorServer.remove(field));
  }

  Future<void> _pilihWaliGuru() async {
    final guru = await pilihData<GuruAdmin>(
      context,
      judul: 'Pilih Wali Kelas',
      hintCari: 'Cari nama atau NIP guru...',
      fetcher: (search) => AdminRepository.getGuru(perPage: 20, search: search),
      judulItem: (g) => g.aktif ? g.nama : '${g.nama} (nonaktif)',
      subjudulItem: (g) => [
        'NIP ${g.nip}',
        if (g.kelasWali.isNotEmpty) 'Wali ${g.kelasWali.map((k) => k.namaKelas).join(', ')}',
      ].join(' · '),
    );
    if (guru == null) return;
    setState(() {
      _idWaliGuru = guru.idGuru;
      _namaWaliGuru = guru.nama;
      _errorServer.remove('id_wali_guru');
    });
  }

  String? _validasiTahunAjaran(String? v) {
    final wajib = validasiWajib(v, 'Tahun ajaran');
    if (wajib != null) return wajib;
    final cocok = RegExp(r'^(\d{4})/(\d{4})$').firstMatch(v!.trim());
    if (cocok == null) return 'Format tahun ajaran harus YYYY/YYYY, contoh: 2026/2027';
    if (int.parse(cocok.group(2)!) != int.parse(cocok.group(1)!) + 1) {
      return 'Tahun ajaran harus berurutan, contoh: 2026/2027';
    }
    return null;
  }

  Future<void> _simpan() async {
    setState(() {
      _errorServer = {};
      _sudahSubmit = true;
    });
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _idWaliGuru == null) return;

    setState(() => _menyimpan = true);
    final data = <String, dynamic>{
      'nama_kelas': _namaKelas.text.trim(),
      'tingkat': _tingkat.text.trim(),
      'tahun_ajaran': _tahunAjaran.text.trim(),
      'id_wali_guru': _idWaliGuru,
    };

    final res = await AdminRepository.simpanKelas(data, idKelas: widget.kelas?.idKelas);
    if (!mounted) return;
    setState(() {
      _menyimpan = false;
      _errorServer = errorPerField(res);
    });

    tampilkanPesan(context, res.message, gagal: !res.isSuccess);
    if (res.isSuccess) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final errorWali = _errorServer['id_wali_guru'] ?? (_sudahSubmit && _idWaliGuru == null ? 'Wali kelas wajib dipilih' : null);

    return Scaffold(
      appBar: JudulAppBar(judul: _modeUbah ? 'Ubah Kelas' : 'Tambah Kelas'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AdminTextField(
              label: 'Nama Kelas',
              wajib: true,
              controller: _namaKelas,
              hint: 'Contoh: 5A',
              textCapitalization: TextCapitalization.characters,
              maxLength: 50,
              errorServer: _errorServer['nama_kelas'],
              onChanged: (_) => _hapusError('nama_kelas'),
              validator: (v) => validasiWajib(v, 'Nama kelas'),
            ),
            AdminTextField(
              label: 'Tingkat',
              wajib: true,
              controller: _tingkat,
              hint: 'Contoh: 5',
              maxLength: 20,
              errorServer: _errorServer['tingkat'],
              onChanged: (_) => _hapusError('tingkat'),
              validator: (v) => validasiWajib(v, 'Tingkat'),
            ),
            AdminTextField(
              label: 'Tahun Ajaran',
              wajib: true,
              controller: _tahunAjaran,
              hint: 'Contoh: 2026/2027',
              keyboardType: TextInputType.datetime,
              errorServer: _errorServer['tahun_ajaran'],
              onChanged: (_) => _hapusError('tahun_ajaran'),
              validator: _validasiTahunAjaran,
            ),
            const FormLabel('Wali Kelas', wajib: true),
            KotakPilihan(
              nilai: _namaWaliGuru,
              hint: 'Pilih guru wali kelas',
              errorText: errorWali,
              onTap: _pilihWaliGuru,
            ),
            const SizedBox(height: 28),
            TombolUtama(
              label: _menyimpan ? 'Menyimpan...' : 'Simpan',
              onPressed: _menyimpan ? null : _simpan,
            ),
          ],
        ),
      ),
    );
  }
}
