// =============================================================
// PROFIL - info akun dan tombol keluar (dipakai semua role)
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/screens/home/home_page.dart';

class ProfilPage extends StatelessWidget {
  final String nama;
  final String peran;
  final VoidCallback? onBack;

  const ProfilPage({super.key, required this.nama, required this.peran, this.onBack});

  void _keluar(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JudulAppBar(judul: 'Profil', onBack: onBack),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SizedBox(height: 8),
          const Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person_rounded, size: 52, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            peran,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: kartuDecoration(),
            child: Column(
              children: [
                _item(context, Icons.person_outline_rounded, 'Ubah Profil'),
                const Divider(height: 1, color: AppColors.divider),
                _item(context, Icons.lock_outline_rounded, 'Ganti Kata Sandi'),
                const Divider(height: 1, color: AppColors.divider),
                _item(context, Icons.help_outline_rounded, 'Bantuan'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _keluar(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
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

  Widget _item(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
      onTap: () => bukaHalaman(context, SegeraHadirPage(judul: label, icon: icon)),
    );
  }
}
