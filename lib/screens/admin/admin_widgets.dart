// =============================================================
// ADMIN - widget bersama untuk Kelola Guru, Orang Tua, Siswa, Kelas
// (daftar ber-pagination + pencarian, detail, dialog pilih data, form)
// =============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/models/admin_models.dart';
import 'package:digital_book_connect/services/api_service.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';

typedef PageFetcher<T> = Future<ApiResponse<PagedResult<T>>> Function(int page, String search);

// --- NOTIFIKASI BERHASIL / GAGAL ---
void tampilkanPesan(BuildContext context, String pesan, {bool gagal = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: gagal ? Colors.red.shade700 : AppColors.primary,
      ),
    );
}

// --- DIALOG KONFIRMASI HAPUS ---
Future<bool> konfirmasiHapus(BuildContext context, {required String judul, required String pesan}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

// --- GAYA INPUT FORM (sama dengan halaman Tambah Catatan) ---
InputDecoration adminInputDecoration({String? hint, String? errorText, String? helperText, Widget? suffixIcon}) {
  OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    helperText: helperText,
    helperMaxLines: 2,
    errorMaxLines: 3,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: garis(AppColors.divider),
    enabledBorder: garis(AppColors.divider),
    focusedBorder: garis(AppColors.primary, 1.5),
    errorBorder: garis(Colors.red.shade700),
    focusedErrorBorder: garis(Colors.red.shade700, 1.5),
  );
}

class FormLabel extends StatelessWidget {
  final String teks;
  final bool wajib;

  const FormLabel(this.teks, {super.key, this.wajib = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: teks,
          children: [
            if (wajib) TextSpan(text: ' *', style: TextStyle(color: Colors.red.shade700)),
          ],
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
    );
  }
}

/// Validasi sisi aplikasi untuk field wajib (validasi utama tetap di backend).
String? validasiWajib(String? nilai, String label) =>
    (nilai == null || nilai.trim().isEmpty) ? '$label wajib diisi' : null;

/// Ubah errors 422 dari backend menjadi {field: pesan pertama}.
Map<String, String> errorPerField(ApiResponse<dynamic> res) => {
      for (final e in res.errors.entries)
        if (e.value.isNotEmpty) e.key: e.value.first,
    };

/// Label + TextFormField dengan dukungan pesan validasi dari server.
class AdminTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool wajib;
  final String? hint;
  final String? helperText;
  final String? errorServer;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;

  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.wajib = false,
    this.hint,
    this.helperText,
    this.errorServer,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormLabel(label, wajib: wajib),
          TextFormField(
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            maxLength: maxLength,
            style: const TextStyle(fontSize: 14),
            decoration: adminInputDecoration(
              hint: hint,
              helperText: helperText,
              errorText: errorServer,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}

/// Saklar status akun (aktif / nonaktif) untuk form Guru & Orang Tua.
class SaklarStatusAkun extends StatelessWidget {
  final bool aktif;
  final ValueChanged<bool> onChanged;

  const SaklarStatusAkun({super.key, required this.aktif, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return KartuMaterial(
      child: SwitchListTile(
        value: aktif,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        title: const Text('Akun aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          aktif ? 'Pengguna dapat masuk ke aplikasi.' : 'Pengguna tidak dapat masuk dan sesi aktifnya diakhiri.',
          style: const TextStyle(fontSize: 12.5),
        ),
      ),
    );
  }
}

/// Kartu putih bergaris tipis (seperti kartuDecoration) yang juga berupa
/// Material, sehingga efek sentuh ListTile di dalamnya tetap terlihat.
class KartuMaterial extends StatelessWidget {
  final Widget child;

  const KartuMaterial({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

// --- TAMPILAN KOSONG / GAGAL ---
class PesanKosong extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String? pesan;
  final String? labelAksi;
  final VoidCallback? onAksi;

  const PesanKosong({
    super.key,
    required this.icon,
    required this.judul,
    this.pesan,
    this.labelAksi,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          if (pesan != null) ...[
            const SizedBox(height: 6),
            Text(pesan!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
          if (labelAksi != null && onAksi != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAksi,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: Text(labelAksi!),
            ),
          ],
        ],
      ),
    );
  }
}

// --- LABEL STATUS AKUN ---
class StatusAkunChip extends StatelessWidget {
  final String status;

  const StatusAkunChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final aktif = status == 'aktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: aktif ? AppColors.primaryLight : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labelStatusAkun(status),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: aktif ? AppColors.primary : Colors.red.shade700,
        ),
      ),
    );
  }
}

// --- KARTU INFO DETAIL ---
class InfoBaris {
  final String label;
  final String nilai;

  const InfoBaris(this.label, this.nilai);
}

class InfoCard extends StatelessWidget {
  final List<InfoBaris> baris;

  const InfoCard({super.key, required this.baris});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kartuDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < baris.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(baris[i].label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  ),
                  Expanded(
                    child: Text(
                      baris[i].nilai.isEmpty ? '-' : baris[i].nilai,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kepala halaman detail: ikon/avatar + judul + subjudul + status.
class DetailHeader extends StatelessWidget {
  final Widget leading;
  final String judul;
  final String subjudul;
  final Widget? trailing;

  const DetailHeader({super.key, required this.leading, required this.judul, required this.subjudul, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kartuDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subjudul, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Ikon bulat untuk entitas non-orang (mis. kelas).
class IkonBulat extends StatelessWidget {
  final IconData icon;
  final double radius;

  const IkonBulat(this.icon, {super.key, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Icon(icon, size: radius * 1.1, color: AppColors.primary),
    );
  }
}

// =============================================================
// HALAMAN DAFTAR: pencarian + pagination + tambah (opsional)
// Dipakai juga oleh daftar siswa Guru (tanpa tombol tambah).
// =============================================================
class AdminListPage<T> extends StatefulWidget {
  final String judul;
  final String hintCari;
  final String teksKosong;
  final PageFetcher<T> fetcher;
  final Widget Function(T item, VoidCallback onTap) itemBuilder;
  final Future<void> Function(BuildContext context, T item) onBukaDetail;
  // Tombol tambah hanya tampil bila keduanya diisi
  final String? labelTambah;
  final Future<bool?> Function(BuildContext context)? onTambah;
  // Keterangan saat data kosong (default: ajakan menekan tombol tambah)
  final String? pesanKosong;
  // Dipakai saat halaman ini menjadi tab (kembali ke tab Beranda)
  final VoidCallback? onBack;

  const AdminListPage({
    super.key,
    required this.judul,
    required this.hintCari,
    required this.teksKosong,
    required this.fetcher,
    required this.itemBuilder,
    required this.onBukaDetail,
    this.labelTambah,
    this.onTambah,
    this.pesanKosong,
    this.onBack,
  });

  @override
  State<AdminListPage<T>> createState() => _AdminListPageState<T>();
}

class _AdminListPageState<T> extends State<AdminListPage<T>> {
  static const _jedaCari = Duration(milliseconds: 400);

  final _cariController = TextEditingController();
  Timer? _debounce;
  String _kataKunci = '';
  int _page = 1;
  bool _loading = true;
  String? _error;
  List<T> _items = [];
  PageMeta _meta = const PageMeta();
  int _nomorRequest = 0;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _muat({int? page}) async {
    final target = page ?? _page;
    final nomor = ++_nomorRequest;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await widget.fetcher(target, _kataKunci);
    // Abaikan respons lama bila sudah ada request yang lebih baru
    if (!mounted || nomor != _nomorRequest) return;

    final hasil = res.data;
    if (res.isSuccess && hasil != null) {
      // Halaman kosong setelah data terhapus -> pindah ke halaman terakhir
      if (hasil.items.isEmpty && target > 1 && hasil.meta.lastPage < target) {
        return _muat(page: hasil.meta.lastPage);
      }
      setState(() {
        _loading = false;
        _items = hasil.items;
        _meta = hasil.meta;
        _page = hasil.meta.currentPage;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  void _onCari(String nilai) {
    _debounce?.cancel();
    _debounce = Timer(_jedaCari, () {
      _kataKunci = nilai.trim();
      _muat(page: 1);
    });
  }

  Future<void> _bukaDetail(T item) async {
    await widget.onBukaDetail(context, item);
    if (mounted) _muat();
  }

  bool get _bisaTambah => widget.onTambah != null && widget.labelTambah != null;

  Future<void> _tambah() async {
    final tersimpan = await widget.onTambah!(context);
    if (tersimpan == true && mounted) _muat(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JudulAppBar(judul: widget.judul, onBack: widget.onBack),
      floatingActionButton: _bisaTambah
          ? FloatingActionButton.extended(
              onPressed: _tambah,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(widget.labelTambah!),
            )
          : null,
      // Bar halaman diletakkan di bawah agar tidak tertutup tombol Tambah
      bottomNavigationBar: (_error == null && _items.isNotEmpty && _meta.lastPage > 1) ? _barHalaman() : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _cariController,
              onChanged: _onCari,
              textInputAction: TextInputAction.search,
              decoration: adminInputDecoration(hint: widget.hintCari).copyWith(
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(
            height: 3,
            child: (_loading && _items.isNotEmpty) ? const LinearProgressIndicator(color: AppColors.primary) : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _muat(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 4, 20, _bisaTambah ? 96 : 24),
                children: _isiDaftar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _isiDaftar() {
    if (_loading && _items.isEmpty && _error == null) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ];
    }

    if (_error != null) {
      return [
        PesanKosong(
          icon: Icons.cloud_off_rounded,
          judul: 'Gagal memuat data',
          pesan: _error,
          labelAksi: 'Coba Lagi',
          onAksi: () => _muat(),
        ),
      ];
    }

    if (_items.isEmpty) {
      return [
        PesanKosong(
          icon: _kataKunci.isEmpty ? Icons.inbox_rounded : Icons.search_off_rounded,
          judul: _kataKunci.isEmpty ? widget.teksKosong : 'Tidak ada hasil untuk "$_kataKunci"',
          pesan: _kataKunci.isNotEmpty
              ? 'Coba gunakan kata kunci lain.'
              : widget.pesanKosong ??
                  (_bisaTambah ? 'Tekan tombol "${widget.labelTambah}" untuk menambahkan data.' : null),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${_meta.total} data ditemukan',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
        ),
      ),
      ListCard(
        children: [for (final item in _items) widget.itemBuilder(item, () => _bukaDetail(item))],
      ),
    ];
  }

  Widget _barHalaman() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              _tombolHalaman(
                key: const Key('halaman-sebelumnya'),
                icon: Icons.chevron_left_rounded,
                tooltip: 'Halaman sebelumnya',
                onPressed: _meta.adaSebelumnya && !_loading ? () => _muat(page: _page - 1) : null,
              ),
              Expanded(
                child: Text(
                  'Halaman ${_meta.currentPage} dari ${_meta.lastPage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
              _tombolHalaman(
                key: const Key('halaman-berikutnya'),
                icon: Icons.chevron_right_rounded,
                tooltip: 'Halaman berikutnya',
                onPressed: _meta.adaBerikutnya && !_loading ? () => _muat(page: _page + 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tombolHalaman({required Key key, required IconData icon, required String tooltip, VoidCallback? onPressed}) {
    return IconButton.outlined(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.primary,
      style: IconButton.styleFrom(side: const BorderSide(color: AppColors.divider)),
    );
  }
}

// =============================================================
// HALAMAN DETAIL: muat data + tombol Ubah & Hapus
// =============================================================
class AdminDetailPage<T> extends StatefulWidget {
  final String judul;
  final String judulHapus;
  final Future<ApiResponse<T>> Function() muat;
  final List<Widget> Function(BuildContext context, T data) isi;
  final Future<bool?> Function(BuildContext context, T data) bukaEdit;
  final Future<ApiResponse<void>> Function(T data) hapus;
  final String Function(T data) pesanKonfirmasiHapus;

  const AdminDetailPage({
    super.key,
    required this.judul,
    required this.judulHapus,
    required this.muat,
    required this.isi,
    required this.bukaEdit,
    required this.hapus,
    required this.pesanKonfirmasiHapus,
  });

  @override
  State<AdminDetailPage<T>> createState() => _AdminDetailPageState<T>();
}

class _AdminDetailPageState<T> extends State<AdminDetailPage<T>> {
  T? _data;
  bool _loading = true;
  bool _menghapus = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.muat();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isSuccess && res.data != null) {
        _data = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _ubah(T data) async {
    final tersimpan = await widget.bukaEdit(context, data);
    if (tersimpan == true && mounted) _muat();
  }

  Future<void> _hapus(T data) async {
    final setuju = await konfirmasiHapus(context, judul: widget.judulHapus, pesan: widget.pesanKonfirmasiHapus(data));
    if (!setuju || !mounted) return;

    setState(() => _menghapus = true);
    final res = await widget.hapus(data);
    if (!mounted) return;
    setState(() => _menghapus = false);

    tampilkanPesan(context, res.message, gagal: !res.isSuccess);
    if (res.isSuccess) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    Widget body;

    if (_loading && data == null) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (data == null) {
      body = ListView(
        children: [
          PesanKosong(
            icon: Icons.cloud_off_rounded,
            judul: 'Gagal memuat data',
            pesan: _error,
            labelAksi: 'Coba Lagi',
            onAksi: _muat,
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ...widget.isi(context, data),
            const SizedBox(height: 28),
            TombolUtama(
              label: 'Ubah Data',
              icon: Icons.edit_rounded,
              onPressed: _menghapus ? null : () => _ubah(data),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _menghapus ? null : () => _hapus(data),
              icon: _menghapus
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(_menghapus ? 'Menghapus...' : 'Hapus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(appBar: JudulAppBar(judul: widget.judul), body: body);
  }
}

// =============================================================
// DIALOG PILIH DATA (mis. memilih wali kelas, kelas, orang tua)
// =============================================================
Future<T?> pilihData<T>(
  BuildContext context, {
  required String judul,
  required String hintCari,
  required Future<ApiResponse<PagedResult<T>>> Function(String search) fetcher,
  required String Function(T item) judulItem,
  String Function(T item)? subjudulItem,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (_) => _PilihDataSheet<T>(
      judul: judul,
      hintCari: hintCari,
      fetcher: fetcher,
      judulItem: judulItem,
      subjudulItem: subjudulItem,
    ),
  );
}

class _PilihDataSheet<T> extends StatefulWidget {
  final String judul;
  final String hintCari;
  final Future<ApiResponse<PagedResult<T>>> Function(String search) fetcher;
  final String Function(T item) judulItem;
  final String Function(T item)? subjudulItem;

  const _PilihDataSheet({
    required this.judul,
    required this.hintCari,
    required this.fetcher,
    required this.judulItem,
    this.subjudulItem,
  });

  @override
  State<_PilihDataSheet<T>> createState() => _PilihDataSheetState<T>();
}

class _PilihDataSheetState<T> extends State<_PilihDataSheet<T>> {
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<T> _items = [];
  PageMeta _meta = const PageMeta();
  int _nomorRequest = 0;

  @override
  void initState() {
    super.initState();
    _muat('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _muat(String search) async {
    final nomor = ++_nomorRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.fetcher(search);
    if (!mounted || nomor != _nomorRequest) return;
    setState(() {
      _loading = false;
      if (res.isSuccess && res.data != null) {
        _items = res.data!.items;
        _meta = res.data!.meta;
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.judul,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: false,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), () => _muat(v.trim()));
                },
                decoration: adminInputDecoration(hint: widget.hintCari).copyWith(
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _isi()),
              if (!_loading && _error == null && _meta.total > _items.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Menampilkan ${_items.length} dari ${_meta.total} data. Ketik untuk mempersempit pencarian.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _isi() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) {
      return SingleChildScrollView(
        child: PesanKosong(icon: Icons.cloud_off_rounded, judul: 'Gagal memuat data', pesan: _error),
      );
    }
    if (_items.isEmpty) {
      return const SingleChildScrollView(
        child: PesanKosong(icon: Icons.search_off_rounded, judul: 'Data tidak ditemukan'),
      );
    }
    return KartuMaterial(
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) {
          final item = _items[i];
          final sub = widget.subjudulItem?.call(item);
          return ListTile(
            title: Text(widget.judulItem(item), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: (sub == null || sub.isEmpty) ? null : Text(sub, style: const TextStyle(fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

/// Kotak pemilih (seperti dropdown) yang membuka dialog pilihData.
class KotakPilihan extends StatelessWidget {
  final String? nilai;
  final String hint;
  final String? errorText;
  final VoidCallback onTap;

  const KotakPilihan({super.key, required this.nilai, required this.hint, required this.onTap, this.errorText});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        isEmpty: nilai == null,
        decoration: adminInputDecoration(
          hint: hint,
          errorText: errorText,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
        ),
        child: nilai == null ? null : Text(nilai!, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
      ),
    );
  }
}
