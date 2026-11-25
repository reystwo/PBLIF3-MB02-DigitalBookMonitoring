// =============================================================
// DETAIL CATATAN - isi catatan, lampiran, dan balas pesan
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/models/catatan_model.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/services/app_repository.dart';
import 'package:digital_book_connect/services/session_manager.dart';

typedef MuatDetailCatatan = Future<ApiResponse<CatatanModel>> Function(int idCatatan);

typedef KirimBalasan = Future<ApiResponse<CatatanModel>> Function({
  required int idCatatan,
  required String isi,
});

class DetailCatatanPage extends StatefulWidget {
  final Catatan catatan;
  // Dapat diganti saat pengujian
  final MuatDetailCatatan? muatDetail;
  final KirimBalasan? kirimBalasan;

  const DetailCatatanPage({
    super.key,
    required this.catatan,
    this.muatDetail,
    this.kirimBalasan,
  });

  @override
  State<DetailCatatanPage> createState() => _DetailCatatanPageState();
}

class _DetailCatatanPageState extends State<DetailCatatanPage> {
  late Catatan _catatan;
  int? _idUserLogin;

  @override
  void initState() {
    super.initState();
    _catatan = widget.catatan;
    _muatUserLogin();
    _muatDetail();
  }

  Future<void> _muatUserLogin() async {
    final user = await SessionManager.getUser();
    if (user != null && mounted) {
      setState(() => _idUserLogin = user.idUser);
    }
  }

  bool get _pesanSendiri =>
      _idUserLogin != null && _catatan.idPengirim != null && _catatan.idPengirim == _idUserLogin;

  /// Panggil GET /api/catatan/{id} agar data selalu terbaru sekaligus memicu
  /// pembaruan status_dibaca -> 'dibaca' otomatis di backend bila dibuka penerima.
  Future<void> _muatDetail({bool dariRefresh = false}) async {
    final idCatatan = _catatan.idCatatan;
    if (idCatatan == null || idCatatan <= 0) return;

    final muat = widget.muatDetail ?? AppRepository.getDetailCatatan;
    final res = await muat(idCatatan);
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() => _catatan = Catatan.fromModel(res.data!));
    } else if (dariRefresh) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal memuat ulang catatan. ${res.message}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  Future<void> _balasPesan(BuildContext context) async {
    final hasil = await showModalBottomSheet<({String pesan, CatatanModel? balasan})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SheetBalasPesan(
        catatan: _catatan,
        pesanSendiri: _pesanSendiri,
        kirimBalasan: widget.kirimBalasan ?? AppRepository.replyCatatan,
      ),
    );

    if (hasil != null && mounted) {
      if (hasil.balasan != null) {
        final balasanBaru = Catatan.fromModel(hasil.balasan!);
        final daftarBaru = [..._catatan.balasan, balasanBaru];
        setState(() {
          _catatan = _catatan.copyWith(
            balasan: daftarBaru,
            jumlahBalasan: daftarBaru.length,
          );
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(hasil.pesan),
              backgroundColor: AppColors.primary,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catatan = _catatan;
    return Scaffold(
      appBar: const JudulAppBar(judul: 'Detail Catatan'),
      body: RefreshIndicator(
        onRefresh: () => _muatDetail(dariRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
          // Penulis
          Container(
            decoration: kartuDecoration(),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AppAvatar(radius: 26, perempuan: catatan.penulisPerempuan),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catatan.penulis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        catatan.peranPenulis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatTanggal(catatan.tanggal),
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kategori + isi
          Container(
            decoration: kartuDecoration(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Judul('Kategori'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    catatan.kategori,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _Judul('Isi Catatan'),
                const SizedBox(height: 8),
                Text(
                  catatan.isi,
                  style: const TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.5),
                ),
              ],
            ),
          ),

          // Lampiran
          if (catatan.lampiran != null) ...[
            const SizedBox(height: 20),
            const _Judul('Lampiran'),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Membuka ${catatan.lampiran!.namaFile}...')),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, size: 40, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catatan.lampiran!.namaFile,
                              style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catatan.lampiran!.ukuran,
                              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Thread Balasan di bawah catatan induk
          _Judul(
            catatan.balasan.isEmpty
                ? 'Balasan'
                : 'Balasan (${catatan.balasan.length})',
          ),
          const SizedBox(height: 10),
          if (catatan.balasan.isEmpty)
            Container(
              decoration: kartuDecoration(),
              padding: const EdgeInsets.all(14),
              child: const Text(
                'Belum ada balasan. Tekan tombol di bawah untuk membalas.',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < catatan.balasan.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _KartuBalasan(
                    balasan: catatan.balasan[i],
                    milikSendiri: _idUserLogin != null &&
                        catatan.balasan[i].idPengirim != null &&
                        catatan.balasan[i].idPengirim == _idUserLogin,
                  ),
                ],
              ],
            ),
          const SizedBox(height: 24),

          TombolUtama(
            label: _pesanSendiri ? 'Tulis Pesan Lanjutan' : 'Balas Pesan',
            icon: _pesanSendiri ? Icons.add_comment_rounded : Icons.reply_rounded,
            stadium: true,
            onPressed: () => _balasPesan(context),
          ),
        ],
      ),
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  final String teks;

  const _Judul(this.teks);

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }
}

class _KartuBalasan extends StatelessWidget {
  final Catatan balasan;
  final bool milikSendiri;

  const _KartuBalasan({
    required this.balasan,
    required this.milikSendiri,
  });

  String _formatWaktu(DateTime t) {
    final jam = t.hour.toString().padLeft(2, '0');
    final menit = t.minute.toString().padLeft(2, '0');
    return '${formatTanggal(t)}, $jam:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: balasan.idCatatan != null ? Key('balasan-${balasan.idCatatan}') : null,
      decoration: BoxDecoration(
        color: milikSendiri ? AppColors.primaryLight.withValues(alpha: 0.45) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: milikSendiri ? AppColors.primary.withValues(alpha: 0.35) : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                radius: 18,
                perempuan: balasan.penulisPerempuan,
                backgroundColor: milikSendiri ? Colors.white : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            balasan.penulis,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (milikSendiri) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Anda',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      balasan.peranPenulis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            balasan.isi,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textDark, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            _formatWaktu(balasan.tanggal),
            style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _SheetBalasPesan extends StatefulWidget {
  final Catatan catatan;
  final bool pesanSendiri;
  final KirimBalasan kirimBalasan;

  const _SheetBalasPesan({
    required this.catatan,
    required this.pesanSendiri,
    required this.kirimBalasan,
  });

  @override
  State<_SheetBalasPesan> createState() => _SheetBalasPesanState();
}

class _SheetBalasPesanState extends State<_SheetBalasPesan> {
  final _controller = TextEditingController();
  bool _mengirim = false;
  String? _pesanValidasi;
  String? _pesanGagal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final isiBalasan = _controller.text.trim();
    if (isiBalasan.isEmpty) {
      setState(() {
        _pesanValidasi = 'Isi balasan tidak boleh kosong.';
        _pesanGagal = null;
      });
      return;
    }

    final idCatatan = widget.catatan.idCatatan;
    if (idCatatan == null || idCatatan <= 0) {
      setState(() {
        _pesanValidasi = null;
        _pesanGagal = 'Data catatan tidak valid. Muat ulang halaman lalu coba lagi.';
      });
      return;
    }

    setState(() {
      _mengirim = true;
      _pesanValidasi = null;
      _pesanGagal = null;
    });

    final res = await widget.kirimBalasan(
      idCatatan: idCatatan,
      isi: isiBalasan,
    );

    if (!mounted) return;

    if (res.isSuccess) {
      final pesan = res.message.isNotEmpty ? res.message : 'Balasan berhasil dikirim';
      Navigator.of(context).pop((pesan: pesan, balasan: res.data));
    } else {
      setState(() {
        _mengirim = false;
        _pesanGagal = res.message.isNotEmpty
            ? 'Balasan gagal dikirim. ${res.message}'
            : 'Balasan gagal dikirim. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.pesanSendiri
                ? 'Pesan lanjutan untuk ${widget.catatan.siswa.nama}'
                : 'Balas ke ${widget.catatan.penulis}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('input-balasan'),
            controller: _controller,
            autofocus: true,
            enabled: !_mengirim,
            maxLines: 4,
            onChanged: (_) {
              if (_pesanValidasi != null || _pesanGagal != null) {
                setState(() {
                  _pesanValidasi = null;
                  _pesanGagal = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Tulis balasan...',
              errorText: _pesanValidasi,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
          if (_pesanGagal != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('pesan-gagal-balasan'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pesanGagal!,
                      style: TextStyle(fontSize: 12.5, color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TombolUtama(
            label: _mengirim ? 'Mengirim...' : 'Kirim',
            icon: _mengirim ? null : Icons.send_rounded,
            stadium: true,
            onPressed: _mengirim ? null : _kirim,
          ),
        ],
      ),
    );
  }
}
