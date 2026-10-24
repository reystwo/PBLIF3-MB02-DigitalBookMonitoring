// =============================================================
// WIDGET BERSAMA - dipakai di banyak halaman
// =============================================================
import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';

// --- KARTU PUTIH DENGAN GARIS TIPIS ---
BoxDecoration kartuDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.divider),
  );
}

// --- AVATAR BULAT (pengganti foto profil) ---
class AppAvatar extends StatelessWidget {
  final double radius;
  final bool perempuan;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.radius = 22,
    this.perempuan = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primaryLight,
      child: Icon(
        perempuan ? Icons.face_3_rounded : Icons.face_rounded,
        size: radius * 1.3,
        color: AppColors.primary,
      ),
    );
  }
}

// --- HEADER SALAM DI DASHBOARD ---
class SalamHeader extends StatelessWidget {
  final String nama;
  final String peran;
  final bool tampilkanNotifikasi;
  final VoidCallback? onNotifikasi;
  final VoidCallback? onProfil;

  const SalamHeader({
    super.key,
    required this.nama,
    required this.peran,
    this.tampilkanNotifikasi = true,
    this.onNotifikasi,
    this.onProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Assalamu'alaikum,",
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 2),
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(peran, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
            ],
          ),
        ),
        if (tampilkanNotifikasi)
          IconButton(
            onPressed: onNotifikasi,
            icon: const Icon(Icons.notifications_rounded, color: AppColors.primary),
          ),
        GestureDetector(
          onTap: onProfil,
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// --- JUDUL SEKSI + LINK "Lihat Semua" ---
class SectionHeader extends StatelessWidget {
  final String judul;
  final VoidCallback? onLihatSemua;

  const SectionHeader({super.key, required this.judul, this.onLihatSemua});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            judul,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (onLihatSemua != null)
          GestureDetector(
            onTap: onLihatSemua,
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// --- KARTU MENU (ikon + label) ---
class MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const MenuCard({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Grid 2 kolom berisi MenuCard
class MenuGrid extends StatelessWidget {
  final List<MenuCard> items;

  const MenuGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: items,
    );
  }
}

// --- BARIS DAFTAR: avatar + judul + subjudul + chevron ---
class ListItemTile extends StatelessWidget {
  final Widget judul;
  final String? subjudul;
  final String? keterangan;
  final bool perempuan;
  final VoidCallback? onTap;
  // Pengganti avatar default (opsional), mis. ikon kelas
  final Widget? leading;

  const ListItemTile({
    super.key,
    required this.judul,
    this.subjudul,
    this.keterangan,
    this.perempuan = false,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            leading ?? AppAvatar(perempuan: perempuan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    child: judul,
                  ),
                  if (subjudul != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subjudul!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                    ),
                  ],
                  if (keterangan != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      keterangan!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

// Kartu yang membungkus beberapa ListItemTile dengan garis pemisah
class ListCard extends StatelessWidget {
  final List<Widget> children;

  const ListCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const Divider(height: 1, color: AppColors.divider));
      items.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: kartuDecoration(),
      child: Column(children: items),
    );
  }
}

// --- APP BAR SEDERHANA: tombol kembali + judul ---
class JudulAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String judul;
  final VoidCallback? onBack;

  const JudulAppBar({super.key, required this.judul, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bisaKembali = onBack != null || Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: bisaKembali ? 0 : 20,
      leading: bisaKembali
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        judul,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

// --- BOTTOM NAVIGATION ---
class NavItem {
  final IconData icon;
  final String label;

  const NavItem(this.icon, this.label);
}

class AppBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final aktif = i == currentIndex;
              final warna = aktif ? AppColors.primary : AppColors.textGrey.withValues(alpha: 0.6);
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon, color: warna, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          color: warna,
                          fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// --- TOMBOL UTAMA (hijau tua) ---
class TombolUtama extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool stadium;

  const TombolUtama({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.stadium = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: stadium
              ? const StadiumBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN SEMENTARA untuk fitur yang belum dibuat ---
class SegeraHadirPage extends StatelessWidget {
  final String judul;
  final IconData icon;

  const SegeraHadirPage({super.key, required this.judul, this.icon = Icons.construction_rounded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JudulAppBar(judul: judul),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Icon(icon, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fitur ini sedang dalam pengembangan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void bukaHalaman(BuildContext context, Widget halaman) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));
}
