import 'package:flutter_test/flutter_test.dart';

import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/screens/home/home_page.dart';
import 'package:digital_book_connect/screens/auth/login_page.dart';

void main() {
  testWidgets('Smoke Test: HomePage berhasil dirender tanpa exception', (WidgetTester tester) async {
    // 1. Render root widget aplikasi (MyApp)
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Verifikasi HomePage hadir di pohon widget
    expect(find.byType(HomePage), findsOneWidget);

    // 3. Verifikasi teks judul utama dan tombol aksi
    expect(find.text('Buku Penghubung\nDigital'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);
    expect(find.text('Pelajari selanjutnya >'), findsOneWidget);
  });

  testWidgets('Navigation Test: Navigasi dari HomePage ke LoginPage', (WidgetTester tester) async {
    // 1. Render root widget aplikasi
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Cari tombol 'Mulai Sekarang' dan pastikan terlihat di layar
    final tombolMulai = find.text('Mulai Sekarang');
    expect(tombolMulai, findsOneWidget);
    await tester.ensureVisible(tombolMulai);
    await tester.pumpAndSettle();

    // 3. Ketuk tombol 'Mulai Sekarang'
    await tester.tap(tombolMulai);
    await tester.pumpAndSettle();

    // 4. Verifikasi navigasi berhasil ke LoginPage
    expect(find.byType(LoginPage), findsOneWidget);

    // 5. Verifikasi komponen form login, teks header, dan tombol masuk
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Pilih Peran / Role'), findsOneWidget);
    expect(find.text('Guru'), findsOneWidget);
    expect(find.text('Orang Tua / Wali'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
