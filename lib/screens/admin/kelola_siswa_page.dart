// =============================================================
// ADMIN - KELOLA SISWA: daftar, detail, tambah, ubah, hapus
// Termasuk penempatan kelas dan relasi orang tua (siswa_orang_tua).
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/admin_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';

class KelolaSiswaPage extends StatelessWidget {
  const KelolaSiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminListPage<SiswaAdmin>(
      judul: 'Kelola Siswa',
      hintCari: 'Cari nama atau NIS siswa...',
      labelTambah: 'Tambah Siswa',
      teksKosong: 'Belum ada data siswa',
      fetcher: (page, search) => AdminRepository.getSiswa(page: page, search: search),
      itemBuilder: (s, onTap) => ListItemTile(
        judul: Text(s.nama),
        subjudul: 'NIS ${s.nis} · Kelas ${s.kelas}',
        keterangan: s.orangTua.isEmpty
            ? 'Belum ada data orang tua'
            : 'Orang tua: ${s.orangTua.map((o) => o.nama).join(', ')}',
        perempuan: s.perempuan,
        onTap: onTap,
      ),
      onBukaDetail: (context, s) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailSiswaPage(idSiswa: s.idSiswa))),
      onTambah: (context) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const FormSiswaPage())),
    );
  }
}

class DetailSiswaPage extends StatelessWidget {
  final int idSiswa;

  const DetailSiswaPage({super.key, required this.idSiswa});

  @override
  Widget build(BuildContext context) {
    return AdminDetailPage<SiswaAdmin>(
      judul: 'Detail Siswa',
      judulHapus: 'Hapus Siswa',
      muat: () => AdminRepository.getDetailSiswa(idSiswa),
      hapus: (s) => AdminRepository.hapusSiswa(s.idSiswa),
      pesanKonfirmasiHapus: (s) =>
          'Hapus data siswa ${s.nama}? Hubungan dengan orang tua akan dilepas (akun orang tua tetap ada). Tindakan ini tidak dapat dibatalkan.',
      bukaEdit: (context, s) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => FormSiswaPage(siswa: s))),
      isi: (context, s) => [
        DetailHeader(
          leading: AppAvatar(radius: 26, perempuan: s.perempuan),
          judul: s.nama,
          subjudul: 'NIS ${s.nis}',
        ),
        const SizedBox(height: 16),
        InfoCard(
          baris: [
            InfoBaris('Jenis Kelamin', s.perempuan ? 'Perempuan' : 'Laki-laki'),
            InfoBaris('Kelas', s.tahunAjaran.isEmpty ? s.kelas : '${s.kelas} (${s.tahunAjaran})'),
            InfoBaris('Wali Kelas', s.waliKelas),
            InfoBaris('Catatan', '${s.jumlahCatatan} catatan penghubung'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(judul: 'Orang Tua / Wali'),
        const SizedBox(height: 10),
        if (s.orangTua.isEmpty)
          Container(
            decoration: kartuDecoration(),
            padding: const EdgeInsets.all(14),
            child: const Text(
              'Belum ada orang tua yang terhubung. Tekan "Ubah Data" untuk menambahkan.',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          )
        else
          InfoCard(baris: [for (final o in s.orangTua) InfoBaris(o.hubungan, '${o.nama}${o.noHp != null ? '\n${o.noHp}' : ''}')]),
      ],
    );
  }
}

class FormSiswaPage extends StatefulWidget {
  final SiswaAdmin? siswa;

  const FormSiswaPage({super.key, this.siswa});

  @override
  State<FormSiswaPage> createState() => _FormSiswaPageState();
}

class _FormSiswaPageState extends State<FormSiswaPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nis = TextEditingController(text: widget.siswa?.nis);
  late final _nama = TextEditingController(text: widget.siswa?.nama);
  late String? _jenisKelamin = widget.siswa?.jenisKelamin;
  late int? _idKelas = widget.siswa?.idKelas;
  late String? _labelKelas = widget.siswa == null
      ? null
      : (widget.siswa!.tahunAjaran.isEmpty
          ? 'Kelas ${widget.siswa!.kelas}'
          : 'Kelas ${widget.siswa!.kelas} (${widget.siswa!.tahunAjaran})');
  late final List<OrangTuaSiswa> _orangTua = [...?widget.siswa?.orangTua];
  bool _menyimpan = false;
  bool _sudahSubmit = false;
  Map<String, String> _errorServer = {};

  bool get _modeUbah => widget.siswa != null;

  @override
  void dispose() {
    _nis.dispose();
    _nama.dispose();
    super.dispose();
  }

  void _hapusError(String field) {
    if (_errorServer.containsKey(field)) setState(() => _errorServer.remove(field));
  }

  String? get _errorOrangTua {
    for (final e in _errorServer.entries) {
      if (e.key.startsWith('orang_tua')) return e.value;
    }
    return null;
  }

  Future<void> _pilihKelas() async {
    final kelas = await pilihData<KelasAdmin>(
      context,
      judul: 'Pilih Kelas',
      hintCari: 'Cari nama kelas atau tahun ajaran...',
      fetcher: (search) => AdminRepository.getKelas(perPage: 20, search: search),
      judulItem: (k) => 'Kelas ${k.namaKelas} (${k.tahunAjaran})',
      subjudulItem: (k) => 'Wali: ${k.waliGuru} · ${k.totalSiswa} siswa',
    );
    if (kelas == null) return;
    setState(() {
      _idKelas = kelas.idKelas;
      _labelKelas = 'Kelas ${kelas.namaKelas} (${kelas.tahunAjaran})';
      _errorServer.remove('id_kelas');
    });
  }

  Future<void> _tambahOrangTua() async {
    final ortu = await pilihData<OrangTuaAdmin>(
      context,
      judul: 'Pilih Orang Tua',
      hintCari: 'Cari nama, username, atau no. HP...',
      fetcher: (search) => AdminRepository.getOrangTua(perPage: 20, search: search),
      judulItem: (o) => o.nama,
      subjudulItem: (o) => [o.noHp ?? '@${o.username}', if (o.anak.isNotEmpty) 'Anak: ${o.anak.map((a) => a.nama).join(', ')}'].join(' · '),
    );
    if (ortu == null || !mounted) return;
    if (_orangTua.any((o) => o.idOrangTua == ortu.idOrangTua)) {
      tampilkanPesan(context, '${ortu.nama} sudah ada di daftar orang tua.', gagal: true);
      return;
    }
    setState(() {
      _orangTua.add(OrangTuaSiswa(idOrangTua: ortu.idOrangTua, nama: ortu.nama, noHp: ortu.noHp, hubungan: 'Wali'));
      _errorServer.removeWhere((k, _) => k.startsWith('orang_tua'));
    });
  }

  Future<void> _simpan() async {
    setState(() {
      _errorServer = {};
      _sudahSubmit = true;
    });
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _jenisKelamin == null || _idKelas == null) return;

    setState(() => _menyimpan = true);
    final data = <String, dynamic>{
      'nis': _nis.text.trim(),
      'nama': _nama.text.trim(),
      'jenis_kelamin': _jenisKelamin,
      'id_kelas': _idKelas,
      'orang_tua': _orangTua.map((o) => o.toRequest()).toList(),
    };

    final res = await AdminRepository.simpanSiswa(data, idSiswa: widget.siswa?.idSiswa);
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
    final errorJk = _errorServer['jenis_kelamin'] ?? (_sudahSubmit && _jenisKelamin == null ? 'Jenis kelamin wajib dipilih' : null);
    final errorKelas = _errorServer['id_kelas'] ?? (_sudahSubmit && _idKelas == null ? 'Kelas wajib dipilih' : null);

    return Scaffold(
      appBar: JudulAppBar(judul: _modeUbah ? 'Ubah Siswa' : 'Tambah Siswa'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AdminTextField(
              label: 'NIS',
              wajib: true,
              controller: _nis,
              hint: 'Contoh: 1008',
              maxLength: 30,
              errorServer: _errorServer['nis'],
              onChanged: (_) => _hapusError('nis'),
              validator: (v) => validasiWajib(v, 'NIS'),
            ),
            AdminTextField(
              label: 'Nama Siswa',
              wajib: true,
              controller: _nama,
              hint: 'Contoh: Ahmad Rizki',
              textCapitalization: TextCapitalization.words,
              errorServer: _errorServer['nama'],
              onChanged: (_) => _hapusError('nama'),
              validator: (v) => validasiWajib(v, 'Nama siswa'),
            ),

            const FormLabel('Jenis Kelamin', wajib: true),
            Wrap(
              spacing: 8,
              children: [
                for (final (kode, label) in const [('L', 'Laki-laki'), ('P', 'Perempuan')])
                  ChoiceChip(
                    label: Text(label),
                    selected: _jenisKelamin == kode,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _jenisKelamin == kode ? Colors.white : AppColors.textGrey,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(color: _jenisKelamin == kode ? AppColors.primary : AppColors.divider),
                    ),
                    onSelected: (_) => setState(() {
                      _jenisKelamin = kode;
                      _errorServer.remove('jenis_kelamin');
                    }),
                  ),
              ],
            ),
            if (errorJk != null) _TeksError(errorJk),
            const SizedBox(height: 16),

            const FormLabel('Kelas', wajib: true),
            KotakPilihan(nilai: _labelKelas, hint: 'Pilih kelas', errorText: errorKelas, onTap: _pilihKelas),
            const SizedBox(height: 20),

            Row(
              children: [
                const Expanded(child: FormLabel('Orang Tua / Wali')),
                TextButton.icon(
                  onPressed: _tambahOrangTua,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Tambah'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            if (_orangTua.isEmpty)
              Container(
                decoration: kartuDecoration(),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Belum ada orang tua yang dihubungkan.',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              )
            else
              ListCard(
                children: [
                  for (var i = 0; i < _orangTua.length; i++) _barisOrangTua(i),
                ],
              ),
            if (_errorOrangTua != null) _TeksError(_errorOrangTua!),
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

  Widget _barisOrangTua(int i) {
    final o = _orangTua[i];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (o.noHp != null)
                  Text(o.noHp!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: daftarHubungan.contains(o.hubungan) ? o.hubungan : null,
            hint: const Text('Hubungan'),
            underline: const SizedBox.shrink(),
            items: [for (final h in daftarHubungan) DropdownMenuItem(value: h, child: Text(h))],
            onChanged: (h) => setState(() => _orangTua[i] = o.copyWith(hubungan: h)),
          ),
          IconButton(
            tooltip: 'Lepas hubungan',
            onPressed: () => setState(() => _orangTua.removeAt(i)),
            icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _TeksError extends StatelessWidget {
  final String teks;

  const _TeksError(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Text(teks, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
    );
  }
}
