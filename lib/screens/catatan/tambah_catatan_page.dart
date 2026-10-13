// =============================================================
// TAMBAH CATATAN - guru menulis catatan untuk seorang siswa
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';

class TambahCatatanPage extends StatefulWidget {
  final Siswa siswa;

  const TambahCatatanPage({super.key, required this.siswa});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  static const _maksKarakter = 500;

  final _formKey = GlobalKey<FormState>();
  final _isiController = TextEditingController();
  String _kategori = kategoriCatatan.first;
  DateTime _tanggal = DateTime.now();
  Lampiran? _lampiran;

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
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  // Sementara: simulasi memilih file (belum memakai package file_picker)
  void _pilihLampiran() {
    setState(() {
      _lampiran = _lampiran == null
          ? const Lampiran(namaFile: 'Lampiran_Catatan.jpg', ukuran: '0.8 MB')
          : null;
    });
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    daftarCatatan.insert(
      0,
      Catatan(
        penulis: 'Bapak Ahmad',
        peranPenulis: 'Guru Kelas 5A',
        siswa: widget.siswa,
        kategori: _kategori,
        tanggal: _tanggal,
        isi: _isiController.text.trim(),
        lampiran: _lampiran,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Catatan untuk ${widget.siswa.nama} berhasil disimpan'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).pop();
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
            Container(
              decoration: kartuDecoration(),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AppAvatar(radius: 26, perempuan: widget.siswa.perempuan),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.siswa.nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelas ${widget.siswa.kelas}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kategori
            const _Label('Kategori'),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: _inputDecoration(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              items: [
                for (final k in kategoriCatatan) DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (v) => setState(() => _kategori = v ?? _kategori),
            ),
            const SizedBox(height: 16),

            // Tanggal
            const _Label('Tanggal'),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: _inputDecoration().copyWith(
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
            const _Label('Catatan'),
            TextFormField(
              controller: _isiController,
              maxLines: 5,
              maxLength: _maksKarakter,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration().copyWith(hintText: 'Tulis catatan di sini...'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Catatan tidak boleh kosong' : null,
            ),
            const SizedBox(height: 8),

            // Lampiran
            const _Label('Lampiran (opsional)'),
            _KotakLampiran(lampiran: _lampiran, onTap: _pilihLampiran),
            const SizedBox(height: 28),

            TombolUtama(label: 'Simpan Catatan', onPressed: _simpan),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: garis(AppColors.divider),
      enabledBorder: garis(AppColors.divider),
      focusedBorder: garis(AppColors.primary, 1.5),
    );
  }
}

class _Label extends StatelessWidget {
  final String teks;

  const _Label(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
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
