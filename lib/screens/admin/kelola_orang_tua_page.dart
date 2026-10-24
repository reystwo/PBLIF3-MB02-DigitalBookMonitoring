// =============================================================
// ADMIN - KELOLA ORANG TUA / WALI: daftar, detail, tambah, ubah, hapus
// Hubungan dengan anak (siswa_orang_tua) diatur dari Kelola Siswa.
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/admin_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';
import 'package:digital_book_connect/screens/admin/kelola_siswa_page.dart';

class KelolaOrangTuaPage extends StatelessWidget {
  const KelolaOrangTuaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminListPage<OrangTuaAdmin>(
      judul: 'Kelola Orang Tua',
      hintCari: 'Cari nama, username, no. HP, atau nama anak...',
      labelTambah: 'Tambah Orang Tua',
      teksKosong: 'Belum ada data orang tua',
      fetcher: (page, search) => AdminRepository.getOrangTua(page: page, search: search),
      itemBuilder: (o, onTap) => ListItemTile(
        judul: Row(
          children: [
            Flexible(child: Text(o.nama, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (!o.aktif) ...[const SizedBox(width: 6), StatusAkunChip(status: o.status)],
          ],
        ),
        subjudul: o.anak.isEmpty
            ? 'Belum terhubung dengan siswa'
            : 'Anak: ${o.anak.map((a) => '${a.nama} (${a.kelas})').join(', ')}',
        keterangan: o.noHp ?? '@${o.username}',
        perempuan: true,
        onTap: onTap,
      ),
      onBukaDetail: (context, o) => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => DetailOrangTuaPage(idOrangTua: o.idOrangTua))),
      onTambah: (context) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const FormOrangTuaPage())),
    );
  }
}

class DetailOrangTuaPage extends StatelessWidget {
  final int idOrangTua;

  const DetailOrangTuaPage({super.key, required this.idOrangTua});

  @override
  Widget build(BuildContext context) {
    return AdminDetailPage<OrangTuaAdmin>(
      judul: 'Detail Orang Tua',
      judulHapus: 'Hapus Orang Tua',
      muat: () => AdminRepository.getDetailOrangTua(idOrangTua),
      hapus: (o) => AdminRepository.hapusOrangTua(o.idOrangTua),
      pesanKonfirmasiHapus: (o) =>
          'Hapus data orang tua ${o.nama}? Akun login orang tua ini juga akan dihapus dan tindakan ini tidak dapat dibatalkan.',
      bukaEdit: (context, o) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => FormOrangTuaPage(orangTua: o))),
      isi: (context, o) => [
        DetailHeader(
          leading: const AppAvatar(radius: 26, perempuan: true),
          judul: o.nama,
          subjudul: '@${o.username}',
          trailing: StatusAkunChip(status: o.status),
        ),
        const SizedBox(height: 16),
        InfoCard(
          baris: [
            InfoBaris('Nomor HP', o.noHp ?? ''),
            InfoBaris('Alamat', o.alamat ?? ''),
            InfoBaris('Catatan', '${o.jumlahCatatan} catatan penghubung'),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(judul: 'Anak / Siswa'),
        const SizedBox(height: 10),
        if (o.anak.isEmpty)
          Container(
            decoration: kartuDecoration(),
            padding: const EdgeInsets.all(14),
            child: const Text(
              'Belum terhubung dengan siswa. Hubungkan melalui menu Kelola Siswa pada data siswa yang bersangkutan.',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          )
        else
          ListCard(
            children: [
              for (final a in o.anak)
                ListItemTile(
                  judul: Text(a.nama),
                  subjudul: 'NIS ${a.nis} · Kelas ${a.kelas}',
                  keterangan: 'Hubungan: ${a.hubungan}',
                  perempuan: a.perempuan,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => DetailSiswaPage(idSiswa: a.idSiswa))),
                ),
            ],
          ),
      ],
    );
  }
}

class FormOrangTuaPage extends StatefulWidget {
  final OrangTuaAdmin? orangTua;

  const FormOrangTuaPage({super.key, this.orangTua});

  @override
  State<FormOrangTuaPage> createState() => _FormOrangTuaPageState();
}

class _FormOrangTuaPageState extends State<FormOrangTuaPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.orangTua?.nama);
  late final _username = TextEditingController(text: widget.orangTua?.username);
  late final _noHp = TextEditingController(text: widget.orangTua?.noHp);
  late final _alamat = TextEditingController(text: widget.orangTua?.alamat);
  final _password = TextEditingController();
  late bool _aktif = widget.orangTua?.aktif ?? true;
  bool _lihatSandi = false;
  bool _menyimpan = false;
  Map<String, String> _errorServer = {};

  bool get _modeUbah => widget.orangTua != null;

  @override
  void dispose() {
    for (final c in [_nama, _username, _noHp, _alamat, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hapusError(String field) {
    if (_errorServer.containsKey(field)) setState(() => _errorServer.remove(field));
  }

  Future<void> _simpan() async {
    setState(() => _errorServer = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _menyimpan = true);
    final data = <String, dynamic>{
      'nama': _nama.text.trim(),
      'username': _username.text.trim(),
      'no_hp': _noHp.text.trim(),
      'alamat': _alamat.text.trim(),
      if (_password.text.isNotEmpty) 'password': _password.text,
      if (_modeUbah) 'status': _aktif ? 'aktif' : 'nonaktif',
    };

    final res = await AdminRepository.simpanOrangTua(data, idOrangTua: widget.orangTua?.idOrangTua);
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
    return Scaffold(
      appBar: JudulAppBar(judul: _modeUbah ? 'Ubah Orang Tua' : 'Tambah Orang Tua'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AdminTextField(
              label: 'Nama Lengkap',
              wajib: true,
              controller: _nama,
              hint: 'Contoh: Ibu Siti Nurhaliza',
              textCapitalization: TextCapitalization.words,
              errorServer: _errorServer['nama'],
              onChanged: (_) => _hapusError('nama'),
              validator: (v) => validasiWajib(v, 'Nama'),
            ),
            AdminTextField(
              label: 'Username',
              wajib: true,
              controller: _username,
              hint: 'Contoh: ortu_siti',
              helperText: 'Dipakai untuk login. Hanya huruf, angka, - dan _.',
              errorServer: _errorServer['username'],
              onChanged: (_) => _hapusError('username'),
              validator: (v) => validasiWajib(v, 'Username'),
            ),
            AdminTextField(
              label: 'Nomor HP',
              controller: _noHp,
              hint: 'Contoh: 081298765432',
              keyboardType: TextInputType.phone,
              errorServer: _errorServer['no_hp'],
              onChanged: (_) => _hapusError('no_hp'),
            ),
            AdminTextField(
              label: 'Alamat',
              controller: _alamat,
              hint: 'Contoh: Jl. Melati No. 12, Batam Centre',
              maxLines: 3,
              maxLength: 255,
              errorServer: _errorServer['alamat'],
              onChanged: (_) => _hapusError('alamat'),
            ),
            AdminTextField(
              label: _modeUbah ? 'Kata Sandi Baru' : 'Kata Sandi',
              wajib: !_modeUbah,
              controller: _password,
              obscureText: !_lihatSandi,
              hint: 'Minimal 8 karakter',
              helperText: _modeUbah ? 'Kosongkan jika kata sandi tidak diubah.' : null,
              errorServer: _errorServer['password'],
              onChanged: (_) => _hapusError('password'),
              suffixIcon: IconButton(
                tooltip: _lihatSandi ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                icon: Icon(
                  _lihatSandi ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return _modeUbah ? null : 'Kata sandi wajib diisi';
                return v!.length < 8 ? 'Kata sandi minimal 8 karakter' : null;
              },
            ),
            if (_modeUbah) ...[
              SaklarStatusAkun(aktif: _aktif, onChanged: (v) => setState(() => _aktif = v)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
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
