<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Guru;
use App\Models\OrangTua;
use App\Models\Kelas;
use App\Models\Siswa;
use App\Models\CatatanPenghubung;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $defaultPassword = Hash::make('password123');

        // ==========================================
        // 1. SEED USERS & PROFIL (Admin, Guru, Orang Tua)
        // ==========================================

        // A. Admin
        $userAdmin = User::create([
            'nama' => 'Administrator Sekolah',
            'username' => 'admin',
            'password' => $defaultPassword,
            'role' => 'admin',
            'status' => 'aktif',
        ]);

        // B. Guru (Bapak Ahmad - Wali Kelas 5A & Bu Nurul - Wali Kelas 5B)
        $userGuruAhmad = User::create([
            'nama' => 'Bapak Ahmad',
            'username' => 'guru',
            'password' => $defaultPassword,
            'role' => 'guru',
            'status' => 'aktif',
        ]);
        $guruAhmad = Guru::create([
            'id_user' => $userGuruAhmad->id_user,
            'nip' => '198501152010011002',
            'no_hp' => '081234567890',
        ]);

        $userGuruNurul = User::create([
            'nama' => 'Ibu Nurul Hidayah',
            'username' => 'guru_nurul',
            'password' => $defaultPassword,
            'role' => 'guru',
            'status' => 'aktif',
        ]);
        $guruNurul = Guru::create([
            'id_user' => $userGuruNurul->id_user,
            'nip' => '198804202012022003',
            'no_hp' => '081234567891',
        ]);

        // C. Orang Tua Utama (Ibu Siti Nurhaliza - Ortu Ahmad Rizki)
        $userOrtuSiti = User::create([
            'nama' => 'Ibu Siti Nurhaliza',
            'username' => 'ortu',
            'password' => $defaultPassword,
            'role' => 'orang_tua',
            'status' => 'aktif',
        ]);
        $ortuSiti = OrangTua::create([
            'id_user' => $userOrtuSiti->id_user,
            'no_hp' => '081298765432',
            'alamat' => 'Jl. Melati No. 12, Batam Centre',
        ]);

        // Orang tua untuk siswa lainnya agar setiap siswa memiliki orang tua terdaftar
        $daftarAkunOrtu = [
            'aisyah' => [
                'nama' => 'Ibu Rahmawati',
                'username' => 'ortu_aisyah',
                'no_hp' => '081298765433',
                'alamat' => 'Perum Sukajadi Blok B No. 4',
                'hubungan' => 'Ibu',
            ],
            'budi' => [
                'nama' => 'Bapak Hendra',
                'username' => 'ortu_budi',
                'no_hp' => '081298765434',
                'alamat' => 'Komp. Nagoya Permai No. 8',
                'hubungan' => 'Ayah',
            ],
            'citra' => [
                'nama' => 'Ibu Dewi Lestari',
                'username' => 'ortu_citra',
                'no_hp' => '081298765435',
                'alamat' => 'Tibancenter Blok D No. 15',
                'hubungan' => 'Ibu',
            ],
            'dani' => [
                'nama' => 'Bapak Bambang Pratama',
                'username' => 'ortu_dani',
                'no_hp' => '081298765436',
                'alamat' => 'Batuaji Asri Blok A2 No. 1',
                'hubungan' => 'Ayah',
            ],
            'fajar' => [
                'nama' => 'Bapak Joko Ramadhan',
                'username' => 'ortu_fajar',
                'no_hp' => '081298765437',
                'alamat' => 'Bengkong Harapan II No. 7',
                'hubungan' => 'Ayah',
            ],
            'siti' => [
                'nama' => 'Ibu Fatimah',
                'username' => 'ortu_siti',
                'no_hp' => '081298765438',
                'alamat' => 'Nongsa Asri Blok C No. 9',
                'hubungan' => 'Ibu',
            ],
        ];

        $ortuMap = [];
        foreach ($daftarAkunOrtu as $key => $info) {
            $userOrtu = User::create([
                'nama' => $info['nama'],
                'username' => $info['username'],
                'password' => $defaultPassword,
                'role' => 'orang_tua',
                'status' => 'aktif',
            ]);
            $ortuRecord = OrangTua::create([
                'id_user' => $userOrtu->id_user,
                'no_hp' => $info['no_hp'],
                'alamat' => $info['alamat'],
            ]);
            $ortuMap[$key] = [
                'user' => $userOrtu,
                'ortu' => $ortuRecord,
                'hubungan' => $info['hubungan'],
            ];
        }

        // ==========================================
        // 2. SEED KELAS
        // ==========================================
        $kelas5A = Kelas::create([
            'nama_kelas' => '5A',
            'tingkat' => '5',
            'tahun_ajaran' => '2026/2027',
            'id_wali_guru' => $guruAhmad->id_guru,
        ]);

        $kelas5B = Kelas::create([
            'nama_kelas' => '5B',
            'tingkat' => '5',
            'tahun_ajaran' => '2026/2027',
            'id_wali_guru' => $guruNurul->id_guru,
        ]);

        // ==========================================
        // 3. SEED SISWA & PIVOT SISWA_ORANG_TUA
        // ==========================================
        // Data selaras 100% dengan dummy_data.dart
        $dataSiswa = [
            [
                'nis' => '1001',
                'nama' => 'Ahmad Rizki',
                'kelas_id' => $kelas5A->id_kelas,
                'jenis_kelamin' => 'L',
                'ortu_record' => $ortuSiti,
                'hubungan' => 'Ibu',
            ],
            [
                'nis' => '1002',
                'nama' => 'Aisyah Putri',
                'kelas_id' => $kelas5A->id_kelas,
                'jenis_kelamin' => 'P',
                'ortu_record' => $ortuMap['aisyah']['ortu'],
                'hubungan' => $ortuMap['aisyah']['hubungan'],
            ],
            [
                'nis' => '1003',
                'nama' => 'Budi Santoso',
                'kelas_id' => $kelas5A->id_kelas,
                'jenis_kelamin' => 'L',
                'ortu_record' => $ortuMap['budi']['ortu'],
                'hubungan' => $ortuMap['budi']['hubungan'],
            ],
            [
                'nis' => '1004',
                'nama' => 'Citra Lestari',
                'kelas_id' => $kelas5B->id_kelas,
                'jenis_kelamin' => 'P',
                'ortu_record' => $ortuMap['citra']['ortu'],
                'hubungan' => $ortuMap['citra']['hubungan'],
            ],
            [
                'nis' => '1005',
                'nama' => 'Dani Pratama',
                'kelas_id' => $kelas5B->id_kelas,
                'jenis_kelamin' => 'L',
                'ortu_record' => $ortuMap['dani']['ortu'],
                'hubungan' => $ortuMap['dani']['hubungan'],
            ],
            [
                'nis' => '1006',
                'nama' => 'Fajar Ramadhan',
                'kelas_id' => $kelas5B->id_kelas,
                'jenis_kelamin' => 'L',
                'ortu_record' => $ortuMap['fajar']['ortu'],
                'hubungan' => $ortuMap['fajar']['hubungan'],
            ],
            [
                'nis' => '1007',
                'nama' => 'Siti Aisyah',
                'kelas_id' => $kelas5A->id_kelas,
                'jenis_kelamin' => 'P',
                'ortu_record' => $ortuMap['siti']['ortu'],
                'hubungan' => $ortuMap['siti']['hubungan'],
            ],
        ];

        $siswaModels = [];
        foreach ($dataSiswa as $item) {
            $siswa = Siswa::create([
                'nis' => $item['nis'],
                'nama' => $item['nama'],
                'jenis_kelamin' => $item['jenis_kelamin'],
                'id_kelas' => $item['kelas_id'],
            ]);

            // Hubungkan ke tabel pivot siswa_orang_tua
            $siswa->orangTua()->attach($item['ortu_record']->id_orang_tua, [
                'hubungan' => $item['hubungan'],
            ]);

            $siswaModels[] = $siswa;
        }

        // ==========================================
        // 4. SEED CATATAN PENGHUBUNG
        // ==========================================
        // Catatan 1: Bapak Ahmad (Guru) ke Ibu Siti (Ortu Ahmad Rizki)
        CatatanPenghubung::create([
            'id_siswa' => $siswaModels[0]->id_siswa, // Ahmad Rizki
            'id_pengirim' => $userGuruAhmad->id_user,
            'id_penerima' => $userOrtuSiti->id_user,
            'kategori' => 'Akademik',
            'tanggal' => Carbon::create(2025, 9, 12, 9, 0, 0),
            'isi_catatan' => 'Ananda Rizki menunjukkan peningkatan pada mata pelajaran Matematika. Namun, perlu lebih fokus dalam mengerjakan tugas rumah. Tetap semangat!',
            'status_dibaca' => 'dibaca',
            'lampiran_nama' => 'Foto_Tugas_Matematika.jpg',
            'lampiran_ukuran' => '1.2 MB',
        ]);

        // Catatan 2: Ibu Siti (Ortu Ahmad Rizki) membalas ke Bapak Ahmad (Guru)
        CatatanPenghubung::create([
            'id_siswa' => $siswaModels[0]->id_siswa, // Ahmad Rizki
            'id_pengirim' => $userOrtuSiti->id_user,
            'id_penerima' => $userGuruAhmad->id_user,
            'kategori' => 'Lainnya',
            'tanggal' => Carbon::create(2025, 9, 10, 16, 45, 0),
            'isi_catatan' => 'Terima kasih atas informasinya, Pak. Kami akan mendampingi Rizki belajar di rumah.',
            'status_dibaca' => 'dibaca',
            'lampiran_nama' => null,
            'lampiran_ukuran' => null,
        ]);

        // Catatan 3: Bapak Ahmad (Guru) ke Ibu Fatimah (Ortu Siti Aisyah)
        CatatanPenghubung::create([
            'id_siswa' => $siswaModels[6]->id_siswa, // Siti Aisyah
            'id_pengirim' => $userGuruAhmad->id_user,
            'id_penerima' => $ortuMap['siti']['user']->id_user,
            'kategori' => 'Perilaku',
            'tanggal' => Carbon::create(2025, 9, 8, 8, 24, 0),
            'isi_catatan' => 'Siti aktif bertanya di kelas dan membantu teman-temannya. Pertahankan!',
            'status_dibaca' => 'belum_dibaca',
            'lampiran_nama' => null,
            'lampiran_ukuran' => null,
        ]);

        // Waktu pembuatan catatan contoh disamakan dengan tanggalnya agar urutan riwayat realistis
        DB::table('catatan_penghubung')->update([
            'created_at' => DB::raw('tanggal'),
            'updated_at' => DB::raw('tanggal'),
        ]);
    }
}
