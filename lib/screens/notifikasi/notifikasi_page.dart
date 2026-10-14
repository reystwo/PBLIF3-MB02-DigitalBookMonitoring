import 'package:flutter/material.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/data/dummy_data.dart';
import 'package:digital_book_connect/widgets/app_widgets.dart';
import 'package:digital_book_connect/services/app_repository.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<Aktivitas> _listNotifikasi = aktivitasTerbaru;

  @override
  void initState() {
    super.initState();
    _fetchNotifikasi();
  }

  Future<void> _fetchNotifikasi() async {
    try {
      final res = await AppRepository.getNotifikasi();
      if (mounted) {
        setState(() {
          if (res.isSuccess && res.data != null && res.data!.isNotEmpty) {
            _listNotifikasi = res.data!.map((m) => Aktivitas.fromModel(m)).toList();
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JudulAppBar(judul: 'Notifikasi'),
      body: RefreshIndicator(
        onRefresh: _fetchNotifikasi,
        child: _listNotifikasi.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text('Belum ada notifikasi', style: TextStyle(color: AppColors.textGrey)),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _listNotifikasi.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = _listNotifikasi[i];
                  return Container(
                    decoration: kartuDecoration(),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(Icons.notifications_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.nama,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                a.keterangan,
                                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.waktu,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
