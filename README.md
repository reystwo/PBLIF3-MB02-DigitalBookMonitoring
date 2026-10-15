# Digital Book Connect

> **Aplikasi Buku Penghubung Digital antara Guru, Orang Tua / Wali Murid, dan Administrator Sekolah**  
> Proyek Berbasis Pembelajaran (Project-Based Learning / PBL) — Program Studi D3 Teknik Informatika Politeknik Negeri Batam.

---

## 1. Tentang Proyek

**Digital Book Connect** adalah platform komunikasi sekolah berbasis mobile dan REST API yang mendigitalisasi buku penghubung konvensional. Aplikasi ini memungkinkan:
- **Guru**: Mencatat perkembangan siswa (akademik, perilaku, kesehatan, kegiatan), melihat daftar siswa per kelas, menerima dan membalas pesan dari orang tua secara real-time.
- **Orang Tua / Wali**: Memantau perkembangan khusus anak kandung mereka secara privat (SEC-02), menerima notifikasi aktivitas, membaca catatan guru, dan mengirimkan balasan langsung.
- **Administrator**: Memantau statistik keseluruhan sistem (jumlah pengguna, guru, orang tua, kelas, dan catatan aktif).

---

## 2. Arsitektur Monorepo

Proyek ini menggunakan struktur **Monorepo** yang menampung aplikasi frontend mobile (Flutter) dan backend REST API (Laravel) dalam satu repositori Git terpadu:

```text
digital_book_connect/
├── android/                   # Konfigurasi native Android (Internet permission, cleartext HTTP)
├── assets/                    # Aset grafis & ikon aplikasi
├── backend/                   # Backend REST API (Laravel 12 + Sanctum + MySQL)
│   ├── app/
│   │   ├── Http/Controllers/Api/   # AuthController, SiswaController, CatatanController, DashboardController
│   │   ├── Http/Middleware/        # EnsureRole (RBAC Guru, Orang Tua, Admin)
│   │   └── Models/                 # User, Guru, OrangTua, Kelas, Siswa, CatatanPenghubung
│   ├── database/
│   │   ├── migrations/             # 7 Tabel ERD PBL + personal_access_tokens
│   │   └── seeders/DatabaseSeeder  # Data demo akun, siswa, kelas, dan catatan
│   ├── routes/api.php              # Definisi rute RESTful API
│   └── tests/Feature/              # AuthApiTest, CatatanDanSiswaApiTest, EndToEndBookConnectTest
├── lib/                       # Frontend Mobile (Flutter)
│   ├── config/api_config.dart      # Konfigurasi dinamis platform Base URL (10.0.2.2 vs 127.0.0.1)
│   ├── data/dummy_data.dart        # Model adapter & fallback data offline
│   ├── models/                     # UserModel, SiswaModel, KelasModel, CatatanModel
│   ├── screens/
│   │   ├── admin/                  # Dashboard & kelola Admin
│   │   ├── auth/                   # Halaman Login multi-role (Guru, Ortu, Admin)
│   │   ├── catatan/                # Tambah catatan, riwayat catatan, detail & balas catatan
│   │   ├── guru/                   # Dashboard Guru kelas & navigasi
│   │   ├── home/                   # Halaman Landing & Selamat Datang
│   │   ├── notifikasi/             # Feed aktivitas & notifikasi masuk
│   │   ├── orang_tua/              # Dashboard Orang Tua (terisolasi untuk anak kandung)
│   │   ├── profil/                 # Profil akun & tombol Logout riil
│   │   └── siswa/                  # Daftar siswa per kelas & pencarian
│   ├── services/
│   │   ├── api_service.dart        # HTTP Client wrapper (Bearer token, error handling)
│   │   ├── app_repository.dart     # Service layer pemanggilan endpoint backend
│   │   └── session_manager.dart    # Token & session persistence (SharedPreferences)
│   └── widgets/app_widgets.dart    # Desain sistem UI reusable, kartu, avatar, & navbar
├── test/
│   ├── models_and_api_test.dart    # Unit test serialisasi JSON model
│   └── widget_test.dart            # Widget smoke test, navigasi, dan validasi form login
├── analysis_options.yaml      # Konfigurasi linter Dart (mengabaikan backend/)
└── pubspec.yaml               # Dependensi Flutter (http, shared_preferences)
```

---

## 3. Skema Database MySQL (Sesuai ERD PBL)

Database MySQL (`digital_book_connect`) mengimplementasikan 7 tabel inti sesuai rancangan **Entity Relationship Diagram (ERD) PBL**:

1. **`users`**: Tabel kredensial autentikasi utama (`id_user`, `nama`, `username`, `password`, `role`, `status`). Mendukung role: `'admin'`, `'guru'`, `'orang_tua'`.
2. **`guru`**: Data profil spesifik guru (`id_guru`, `id_user` FK, `nip`, `no_hp`).
3. **`orang_tua`**: Data profil spesifik orang tua/wali (`id_orang_tua`, `id_user` FK, `no_hp`, `alamat`).
4. **`kelas`**: Data rombongan belajar (`id_kelas`, `nama_kelas`, `tingkat`, `tahun_ajaran`, `id_guru` FK wali kelas).
5. **`siswa`**: Data peserta didik (`id_siswa`, `id_kelas` FK, `nis`, `nisn`, `nama`, `jenis_kelamin`).
6. **`siswa_orang_tua`**: Tabel relasi many-to-many antara siswa dan orang tua (`id_siswa_orang_tua`, `id_siswa` FK, `id_orang_tua` FK, `hubungan`).
7. **`catatan_penghubung`**: Buku catatan penghubung digital (`id_catatan`, `id_siswa` FK, `id_pengirim` FK, `id_penerima` FK, `kategori`, `tanggal`, `isi_catatan`, `status_dibaca`, `lampiran_nama`, `lampiran_ukuran`).

---

## 4. Daftar Akun Demo (Seeder)

Seluruh akun di bawah ini telah disiapkan otomatis melalui seeder (`DatabaseSeeder.php`):

| Role | Username | Password | Nama Akun / Keterangan |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `password123` | Administrator Sekolah |
| **Guru** | `guru` | `password123` | Bapak Ahmad, S.Pd (Wali Kelas 5A) |
| **Guru** | `guru_nurul` | `password123` | Ibu Nurul Hidayah, S.Pd (Wali Kelas 5B) |
| **Orang Tua** | `ortu` | `password123` | Ibu Siti Nurhaliza (Orang Tua dari Ahmad Rizki - 5A) |
| **Orang Tua** | `ortu_aisyah` | `password123` | Ibu Rahmawati (Orang Tua dari Aisyah Putri - 5A) |
| **Orang Tua** | `ortu_budi` | `password123` | Bapak Hendra (Orang Tua dari Budi Santoso - 5A) |
| **Orang Tua** | `ortu_citra` | `password123` | Ibu Dewi Lestari (Orang Tua dari Citra Lestari - 5B) |
| **Orang Tua** | `ortu_dani` | `password123` | Bapak Bambang (Orang Tua dari Dani Pratama - 5B) |
| **Orang Tua** | `ortu_fajar` | `password123` | Bapak Joko (Orang Tua dari Fajar Ramadhan - 5B) |
| **Orang Tua** | `ortu_siti` | `password123` | Ibu Fatimah (Orang Tua dari Siti Aisyah - 5A) |

---

## 5. Panduan Instalasi & Menjalankan Proyek

### Prasyarat Sistem
- **PHP**: Versi >= 8.2 (disarankan menggunakan Laragon / XAMPP)
- **Composer**: Versi >= 2.0
- **MySQL**: Berjalan pada `127.0.0.1:3306`
- **Flutter SDK**: Versi >= 3.24 (Dart >= 3.5)

### Langkah 1: Setup Backend Laravel
1. Masuk ke folder backend:
   ```bash
   cd backend
   ```
2. Salin environment configuration dan sesuaikan koneksi database MySQL:
   ```bash
   cp .env.example .env
   ```
   *Pastikan di file `.env`:*
   ```ini
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=digital_book_connect
   DB_USERNAME=root
   DB_PASSWORD=
   ```
3. Install dependensi composer:
   ```bash
   composer install
   ```
4. Generate application key:
   ```bash
   php artisan key:generate
   ```
5. Jalankan migrasi dan seeder database:
   ```bash
   php artisan migrate:fresh --seed
   ```
6. Jalankan server backend API Laravel:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   *Server backend akan aktif di `http://127.0.0.1:8000` (atau `http://10.0.2.2:8000` untuk emulator Android).*

### Langkah 2: Setup Frontend Flutter
1. Buka terminal baru di root folder `digital_book_connect/`:
   ```bash
   flutter pub get
   ```
2. Jalankan aplikasi Flutter:
   ```bash
   flutter run
   ```
   *Pilih device target (Chrome, Windows Desktop, atau Android Emulator).*

---

## 6. Daftar Endpoint REST API Utama

Seluruh endpoint terproteksi memerlukan header `Authorization: Bearer <token>` yang diperoleh setelah login:

| Method | Endpoint | Hak Akses (Role) | Fungsi / Deskripsi |
| :---: | :--- | :---: | :--- |
| `POST` | `/api/login` | Publik | Autentikasi pengguna & generate token Sanctum |
| `GET` | `/api/me` | Semua Role | Mengambil profil user yang sedang login |
| `POST` | `/api/logout` | Semua Role | Menghapus token sesi aktif & logout |
| `GET` | `/api/dashboard` | Semua Role | Mengambil data dashboard spesifik role |
| `GET` | `/api/notifikasi` | Semua Role | Mengambil riwayat feed aktivitas & notifikasi |
| `GET` | `/api/kelas` | Guru / Admin | Mengambil daftar kelas dan wali kelas |
| `GET` | `/api/siswa` | Guru / Admin | Mengambil daftar siswa (filter `?kelas=5A`) |
| `GET` | `/api/catatan` | Guru / Ortu / Admin | Mengambil riwayat catatan penghubung |
| `GET` | `/api/catatan/{id}` | Guru / Ortu / Admin | Detail catatan & otomatis tandai `'dibaca'` |
| `POST` | `/api/catatan` | Guru / Admin | Mengirim catatan penghubung baru untuk siswa |
| `POST` | `/api/catatan/{id}/balas` | Guru / Ortu | Mengirim pesan balasan untuk suatu catatan |
| `PATCH` | `/api/catatan/{id}/baca` | Penerima Catatan | Menandai catatan secara manual sebagai `'dibaca'` |

---

## 7. Pengujian Otomatis (Testing)

Proyek ini dilengkapi dengan suite pengujian otomatis menyeluruh:

### Menjalankan Test Backend Laravel
```bash
cd backend
php artisan test
```
*Hasil:* **23 tests passed, 148 assertions (100% PASS)**  
Mencakup pengujian autentikasi (`AuthApiTest`), otorisasi catatan & isolasi privasi anak (`CatatanDanSiswaApiTest`), serta pengujian siklus penuh alur aplikasi (`EndToEndBookConnectTest`).

### Menjalankan Test Frontend Flutter
```bash
flutter analyze
flutter test
```
*Hasil:* **No issues found!** dan **All 10 tests passed!**  
Mencakup pengujian rendering widget antarmuka, navigasi antar halaman, validasi formulir input login, dan unit test serialisasi model JSON.
