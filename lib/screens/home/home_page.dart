// =============================================================
// BUKU PENGHUBUNG DIGITAL - Halaman Welcome / Onboarding
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';

// --- HALAMAN WELCOME ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hiasan lingkaran hijau di pojok kiri atas
          Positioned(top: -70, left: -90, child: _blob(220, AppColors.blob)),
          Positioned(top: -30, left: -40, child: _blob(140, AppColors.blobSoft)),
          // Hiasan lingkaran hijau di pojok kanan bawah
          Positioned(bottom: -80, right: -80, child: _blob(200, AppColors.blob)),
          Positioned(bottom: -30, right: -30, child: _blob(120, AppColors.blobSoft)),

          // Konten utama
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const _Logo(),
                  const SizedBox(height: 16),
                  const Text(
                    'Buku Penghubung\nDigital',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jembatan komunikasi antara guru dan orang tua/wali murid '
                        'untuk mendukung perkembangan belajar siswa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: AppColors.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const _Ilustrasi(),
                  const SizedBox(height: 24),
                  const _FiturRow(),
                  const SizedBox(height: 32),
                  _TombolMulai(
                    onPressed: () => _info(context, 'Menuju halaman berikutnya...'),
                  ),
                  const SizedBox(height: 16),
                  _LinkPelajari(
                    onTap: () => _info(context, 'Mengarahkan ke halaman informasi...'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lingkaran dekorasi
  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Pesan sementara sampai halaman tujuan dibuat
  void _info(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }
}

// --- LOGO: buku terbuka + daun ---
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.menu_book_rounded, size: 80, color: AppColors.primary),
        Positioned(
          top: 8,
          child: Icon(Icons.eco, size: 26, color: AppColors.accent),
        ),
      ],
    );
  }
}

// --- ILUSTRASI GURU, SISWA, DAN ORANG TUA ---
class _Ilustrasi extends StatelessWidget {
  const _Ilustrasi();

  @override
  Widget build(BuildContext context) {
    // Menggunakan Image.asset untuk memuat gambar dari URL
    return Image.asset(
      'assets/images/guru_ortu_murid.png',
      height: 220,
      fit: BoxFit.contain,
      // Menggunakan fungsi placeholder sebagai cadangan jika gambar gagal dimuat
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  // Tampilan cadangan jika file gambar gagal dimuat
  Widget _placeholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _orang(Icons.person, 110, 'Guru'),
          _orang(Icons.child_care, 80, 'Siswa'),
          _orang(Icons.person, 120, 'Orang Tua'),
        ],
      ),
    );
  }

  Widget _orang(IconData icon, double size, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: AppColors.primary),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// --- TIGA FITUR UTAMA ---
class _FiturRow extends StatelessWidget {
  const _FiturRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: const _FiturItem(
              icon: Icons.sms_outlined,
              label: 'Komunikasi\nMudah',
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
          Expanded(
            child: const _FiturItem(
              icon: Icons.edit_note_rounded,
              label: 'Catatan\nPerkembangan',
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
          Expanded(
            child: const _FiturItem(
              icon: Icons.notifications_rounded,
              label: 'Monitoring\nTumbuh Kembang',
            ),
          ),
        ],
      ),
    );
  }
}

class _FiturItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FiturItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, size: 24, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.3),
        ),
      ],
    );
  }
}

// --- TOMBOL "MULAI SEKARANG" ---
class _TombolMulai extends StatelessWidget {
  final VoidCallback onPressed;

  const _TombolMulai({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mulai Sekarang', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}

// --- TEKS "Pelajari selanjutnya >" ---
class _LinkPelajari extends StatelessWidget {
  final VoidCallback onTap;

  const _LinkPelajari({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Pelajari selanjutnya >',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
