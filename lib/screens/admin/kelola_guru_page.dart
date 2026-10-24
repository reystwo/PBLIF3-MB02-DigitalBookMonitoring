// =============================================================
// ADMIN - KELOLA GURU: daftar, detail, tambah, ubah, hapus
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/admin_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';

class KelolaGuruPage extends StatelessWidget {
  const KelolaGuruPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminListPage<GuruAdmin>(
      judul: 'Kelola Guru',
      hintCari: 'Cari nama, username, NIP, atau no. HP...',
      labelTambah: 'Tambah Guru',
      teksKosong: 'Belum ada data guru',
      fetcher: (page, search) => AdminRepository.getGuru(page: page, search: search),
      itemBuilder: (g, onTap) => ListItemTile(
        judul: _JudulDenganStatus(nama: g.nama, status: g.status),
        subjudul: 'NIP ${g.nip}',
        keterangan: g.kelasWali.isEmpty
            ? 'Belum menjadi wali kelas'
            : 'Wali kelas ${g.kelasWali.map((k) => k.namaKelas).join(', ')}',
        onTap: onTap,
      ),
      onBukaDetail: (context, g) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailGuruPage(idGuru: g.idGuru))),
      onTambah: (context) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const FormGuruPage())),
    );
  }
}

class DetailGuruPage extends StatelessWidget {
  final int idGuru;

  const DetailGuruPage({super.key, required this.idGuru});

  @override
  Widget build(BuildContext context) {
    return AdminDetailPage<GuruAdmin>(
      judul: 'Detail Guru',
      judulHapus: 'Hapus Guru',
      muat: () => AdminRepository.getDetailGuru(idGuru),
      hapus: (g) => AdminRepository.hapusGuru(g.idGuru),
      pesanKonfirmasiHapus: (g) =>
          'Hapus data guru ${g.nama}? Akun login guru ini juga akan dihapus dan tindakan ini tidak dapat dibatalkan.',
      bukaEdit: (context, g) =>
          Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => FormGuruPage(guru: g))),
      isi: (context, g) => [
        DetailHeader(
          leading: const AppAvatar(radius: 26),
          judul: g.nama,
          subjudul: '@${g.username}',
          trailing: StatusAkunChip(status: g.status),
        ),
        const SizedBox(height: 16),
        InfoCard(
          baris: [
            InfoBaris('NIP', g.nip),
            InfoBaris('Nomor HP', g.noHp ?? ''),
            InfoBaris(
              'Wali Kelas',
              g.kelasWali.isEmpty
                  ? 'Belum menjadi wali kelas'
                  : g.kelasWali.map((k) => '${k.namaKelas} (${k.tahunAjaran})').join(', '),
            ),
            InfoBaris('Catatan', '${g.jumlahCatatan} catatan penghubung'),
          ],
        ),
      ],
    );
  }
}

class FormGuruPage extends StatefulWidget {
  final GuruAdmin? guru;

  const FormGuruPage({super.key, this.guru});

  @override
  State<FormGuruPage> createState() => _FormGuruPageState();
}

class _FormGuruPageState extends State<FormGuruPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.guru?.nama);
  late final _username = TextEditingController(text: widget.guru?.username);
  late final _nip = TextEditingController(text: widget.guru?.nip);
  late final _noHp = TextEditingController(text: widget.guru?.noHp);
  final _password = TextEditingController();
  late bool _aktif = widget.guru?.aktif ?? true;
  bool _lihatSandi = false;
  bool _menyimpan = false;
  Map<String, String> _errorServer = {};

  bool get _modeUbah => widget.guru != null;

  @override
  void dispose() {
    for (final c in [_nama, _username, _nip, _noHp, _password]) {
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
      'nip': _nip.text.trim(),
      'no_hp': _noHp.text.trim(),
      if (_password.text.isNotEmpty) 'password': _password.text,
      if (_modeUbah) 'status': _aktif ? 'aktif' : 'nonaktif',
    };

    final res = await AdminRepository.simpanGuru(data, idGuru: widget.guru?.idGuru);
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
      appBar: JudulAppBar(judul: _modeUbah ? 'Ubah Guru' : 'Tambah Guru'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AdminTextField(
              label: 'Nama Lengkap',
              wajib: true,
              controller: _nama,
              hint: 'Contoh: Ibu Rina Marlina, S.Pd',
              textCapitalization: TextCapitalization.words,
              errorServer: _errorServer['nama'],
              onChanged: (_) => _hapusError('nama'),
              validator: (v) => validasiWajib(v, 'Nama'),
            ),
            AdminTextField(
              label: 'Username',
              wajib: true,
              controller: _username,
              hint: 'Contoh: guru_rina',
              helperText: 'Dipakai untuk login. Hanya huruf, angka, - dan _.',
              errorServer: _errorServer['username'],
              onChanged: (_) => _hapusError('username'),
              validator: (v) => validasiWajib(v, 'Username'),
            ),
            AdminTextField(
              label: 'NIP',
              wajib: true,
              controller: _nip,
              hint: 'Contoh: 199203142019032001',
              keyboardType: TextInputType.number,
              maxLength: 30,
              errorServer: _errorServer['nip'],
              onChanged: (_) => _hapusError('nip'),
              validator: (v) {
                final wajib = validasiWajib(v, 'NIP');
                if (wajib != null) return wajib;
                return RegExp(r'^[0-9]+$').hasMatch(v!.trim()) ? null : 'NIP hanya boleh berisi angka';
              },
            ),
            AdminTextField(
              label: 'Nomor HP',
              controller: _noHp,
              hint: 'Contoh: 081234567890',
              keyboardType: TextInputType.phone,
              errorServer: _errorServer['no_hp'],
              onChanged: (_) => _hapusError('no_hp'),
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

/// Judul baris daftar: nama + label "Nonaktif" bila akun dinonaktifkan.
class _JudulDenganStatus extends StatelessWidget {
  final String nama;
  final String status;

  const _JudulDenganStatus({required this.nama, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Text(nama, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (status != 'aktif') ...[const SizedBox(width: 6), StatusAkunChip(status: status)],
      ],
    );
  }
}
