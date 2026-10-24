// =============================================================
// TAMBAH CATATAN - guru menulis catatan untuk siswa tanggung jawabnya
// Pengirim ditentukan backend dari akun login; input dipertahankan
// bila penyimpanan gagal agar dapat diperbaiki lalu disimpan ulang.
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/guru_repository.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/admin/admin_widgets.dart';

typedef KirimCatatan = Future<ApiResponse<CatatanModel>> Function({
  required int idSiswa,
  required String isi,
  String? kategori,
  DateTime? tanggal,
  String? lampiranNama,
  String? lampiranUkuran,
});

class TambahCatatanPage extends StatefulWidget {
  final Siswa siswa;
  // Dapat diganti saat pengujian
  final KirimCatatan? kirim;

  const TambahCatatanPage({super.key, required this.siswa, this.kirim});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  // Sama dengan batas backend (CatatanPenghubung::MAKS_ISI)
  static const _maksKarakter = 500;

  final _formKey = GlobalKey<FormState>();
  final _isiController = TextEditingController();
  String _kategori = kategoriCatatan.first;
  DateTime _tanggal = DateTime.now();
  Lampiran? _lampiran;
  bool _isSaving = false;
  Map<String, String> _errorServer = {};

  @override
  void dispose() {
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (hasil != null) {
      setState(() {
        _tanggal = hasil;
        _errorServer.remove('tanggal');
      });
    }
  }

  // Sementara: simulasi memilih file (belum memakai package file_picker)
  void _pilihLampiran() {
    setState(() {
      _lampiran = _lampiran == null
          ? const Lampiran(namaFile: 'Lampiran_Catatan.jpg', ukuran: '0.8 MB')
          : null;
    });
  }

  String? _validasiIsi(String? nilai) {
    final isi = nilai?.trim() ?? '';
    if (isi.isEmpty) return 'Isi catatan wajib diisi dan tidak boleh hanya berisi spasi.';
    if (isi.length > _maksKarakter) return 'Isi catatan maksimal $_maksKarakter karakter.';
    return null;
  }

  Future<void> _simpan() async {
    setState(() => _errorServer = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final idSiswa = widget.siswa.idSiswa;
    if (idSiswa == null || idSiswa <= 0) {
      tampilkanPesan(context, 'Data siswa tidak valid. Muat ulang daftar siswa lalu coba lagi.', gagal: true);
      return;
    }

    setState(() => _isSaving = true);
    final kirim = widget.kirim ?? GuruRepository.tambahCatatan;
    final res = await kirim(
      idSiswa: idSiswa,
      isi: _isiController.text.trim(),
      kategori: _kategori,
      tanggal: _tanggal,
      lampiranNama: _lampiran?.namaFile,
      lampiranUkuran: _lampiran?.ukuran,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _errorServer = errorPerField(res);
    });

    if (res.isSuccess) {
      tampilkanPesan(context, res.message.isNotEmpty ? res.message : 'Catatan untuk ${widget.siswa.nama} berhasil disimpan');
      Navigator.of(context).pop(true);
    } else {
      tampilkanPesan(context, 'Catatan gagal disimpan. ${res.message}', gagal: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JudulAppBar(judul: 'Tambah Catatan'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Info siswa
            DetailHeader(
              leading: AppAvatar(radius: 26, perempuan: widget.siswa.perempuan),
              judul: widget.siswa.nama,
              subjudul: 'Kelas ${widget.siswa.kelas}',
            ),
            const SizedBox(height: 20),

            // Kategori
            const FormLabel('Kategori'),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: adminInputDecoration(errorText: _errorServer['kategori']),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              items: [
                for (final k in kategoriCatatan) DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (v) => setState(() {
                _kategori = v ?? _kategori;
                _errorServer.remove('kategori');
              }),
            ),
            const SizedBox(height: 16),

            // Tanggal
            const FormLabel('Tanggal'),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: adminInputDecoration(
                  errorText: _errorServer['tanggal'],
                  suffixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.textGrey),
                ),
                child: Text(
                  formatTanggal(_tanggal),
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Isi catatan
            const FormLabel('Isi Catatan', wajib: true),
            TextFormField(
              key: const Key('isi-catatan'),
              controller: _isiController,
              maxLines: 5,
              maxLength: _maksKarakter,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14),
              decoration: adminInputDecoration(
                hint: 'Tulis catatan di sini...',
                errorText: _errorServer['isi_catatan'],
              ),
              onChanged: (_) {
                if (_errorServer.containsKey('isi_catatan')) setState(() => _errorServer.remove('isi_catatan'));
              },
              validator: _validasiIsi,
            ),
            const SizedBox(height: 8),

            // Lampiran
            const FormLabel('Lampiran (opsional)'),
            _KotakLampiran(lampiran: _lampiran, onTap: _pilihLampiran),
            const SizedBox(height: 28),

            TombolUtama(
              label: _isSaving ? 'Menyimpan...' : 'Simpan Catatan',
              onPressed: _isSaving ? null : _simpan,
            ),
          ],
        ),
      ),
    );
  }
}

class _KotakLampiran extends StatelessWidget {
  final Lampiran? lampiran;
  final VoidCallback onTap;

  const _KotakLampiran({required this.lampiran, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (lampiran != null) {
      return Container(
        decoration: kartuDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lampiran!.namaFile, style: const TextStyle(fontSize: 13)),
                  Text(
                    lampiran!.ukuran,
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _GarisPutusPainter(),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 28),
                SizedBox(height: 6),
                Text(
                  'Pilih file atau foto',
                  style: TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
                SizedBox(height: 2),
                Text(
                  'Format: jpg, png, pdf (maks. 5 MB)',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Garis tepi putus-putus untuk kotak unggah
class _GarisPutusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textGrey.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double jarak = 0;
      while (jarak < metric.length) {
        canvas.drawPath(metric.extractPath(jarak, jarak + 6), paint);
        jarak += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
