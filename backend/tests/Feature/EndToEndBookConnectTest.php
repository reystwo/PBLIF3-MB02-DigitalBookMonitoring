<?php

namespace Tests\Feature;

use App\Models\CatatanPenghubung;
use App\Models\Siswa;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class EndToEndBookConnectTest extends TestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();

        if (config('database.default') === 'sqlite') {
            $this->artisan('migrate');
        }

        // Pastikan dataset seeder tersedia (fallback jika database testing kosong)
        if (User::count() === 0) {
            $this->seed(DatabaseSeeder::class);
        }
    }

    /**
     * Siklus Pengujian End-to-End (E2E) Lengkap:
     * 1. Guru Login & dapat token
     * 2. Guru Memilih Siswa
     * 3. Guru Mengirim Catatan Baru (status awal 'belum_dibaca', id_penerima otomatis ortu)
     * 4. Orang Tua Login & dapat token
     * 5. Orang Tua Cek Dashboard & Notifikasi
     * 6. Orang Tua Membaca Detail Catatan (status otomatis berubah jadi 'dibaca')
     * 7. Orang Tua Membalas Catatan (id_pengirim = ortu, id_penerima = guru)
     * 8. Guru Melihat Balasan
     */
    public function test_full_end_to_end_book_connect_lifecycle(): void
    {
        // -------------------------------------------------------------
        // LANGKAH 1: Guru Login
        // -------------------------------------------------------------
        $guruLoginRes = $this->postJson('/api/login', [
            'username' => 'guru',
            'password' => 'password123',
            'role' => 'guru',
        ]);

        $guruLoginRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'username' => 'guru',
                        'role' => 'guru',
                    ],
                ],
            ]);

        $guruToken = $guruLoginRes->json('data.token');
        $this->assertNotEmpty($guruToken, 'Token guru harus berhasil di-generate.');
        $guruUser = User::where('username', 'guru')->first();

        // -------------------------------------------------------------
        // LANGKAH 2: Guru Memilih Siswa (Ahmad Rizki)
        // -------------------------------------------------------------
        $siswaListRes = $this->withHeader('Authorization', 'Bearer ' . $guruToken)
            ->getJson('/api/siswa?kelas=5A');

        $siswaListRes->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $siswaList = $siswaListRes->json('data');
        $this->assertNotEmpty($siswaList, 'Daftar siswa kelas 5A tidak boleh kosong.');

        // Pilih siswa Ahmad Rizki
        $siswaAhmad = null;
        foreach ($siswaList as $s) {
            if ($s['nama'] === 'Ahmad Rizki') {
                $siswaAhmad = $s;
                break;
            }
        }
        $this->assertNotNull($siswaAhmad, 'Siswa Ahmad Rizki harus ditemukan.');
        $idSiswa = $siswaAhmad['id_siswa'];

        // -------------------------------------------------------------
        // LANGKAH 3: Guru Mengirim Catatan Baru
        // -------------------------------------------------------------
        $pesanCatatan = 'Ananda Ahmad Rizki sangat aktif berdiskusi dalam pelajaran IPA hari ini.';
        $kirimCatatanRes = $this->withHeader('Authorization', 'Bearer ' . $guruToken)
            ->postJson('/api/catatan', [
                'id_siswa' => $idSiswa,
                'kategori' => 'Akademik',
                'isi_catatan' => $pesanCatatan,
                'tanggal' => now()->toDateString(),
            ]);

        $kirimCatatanRes->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id_siswa' => $idSiswa,
                    'status_dibaca' => 'belum_dibaca',
                ],
            ]);

        $idCatatanBaru = $kirimCatatanRes->json('data.id_catatan');
        $this->assertNotNull($idCatatanBaru);

        // Verifikasi di database: status_dibaca 'belum_dibaca' dan id_penerima terhubung ke user Orang Tua
        $userOrtuAhmad = User::where('username', 'ortu')->first();
        $this->assertDatabaseHas('catatan_penghubung', [
            'id_catatan' => $idCatatanBaru,
            'id_pengirim' => $guruUser->id_user,
            'id_penerima' => $userOrtuAhmad->id_user,
            'status_dibaca' => 'belum_dibaca',
        ]);

        // -------------------------------------------------------------
        // LANGKAH 4: Orang Tua Login (Reset sesi Guru terlebih dahulu)
        // -------------------------------------------------------------
        $this->flushHeaders();
        auth()->forgetGuards();

        $ortuLoginRes = $this->postJson('/api/login', [
            'username' => 'ortu',
            'password' => 'password123',
            'role' => 'orang_tua',
        ]);

        $ortuLoginRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'username' => 'ortu',
                        'role' => 'orang_tua',
                    ],
                ],
            ]);

        $ortuToken = $ortuLoginRes->json('data.token');
        $this->assertNotEmpty($ortuToken, 'Token orang tua harus berhasil di-generate.');

        // -------------------------------------------------------------
        // LANGKAH 5: Orang Tua Cek Dashboard & Notifikasi
        // -------------------------------------------------------------
        // A. Cek Dashboard Orang Tua
        $ortuDashboardRes = $this->withHeader('Authorization', 'Bearer ' . $ortuToken)
            ->getJson('/api/dashboard');

        $ortuDashboardRes->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        // Pastikan catatan baru muncul di daftar catatan anak
        $catatanTerbaru = $ortuDashboardRes->json('data.catatan_terbaru');
        $ditemukanDiDashboard = false;
        foreach ($catatanTerbaru as $c) {
            if ($c['id_catatan'] == $idCatatanBaru) {
                $ditemukanDiDashboard = true;
                break;
            }
        }
        $this->assertTrue($ditemukanDiDashboard, 'Catatan baru harus muncul di dashboard Orang Tua.');

        // B. Cek Notifikasi Orang Tua
        $ortuNotifRes = $this->withHeader('Authorization', 'Bearer ' . $ortuToken)
            ->getJson('/api/notifikasi');

        $ortuNotifRes->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
        $notifikasiList = $ortuNotifRes->json('data');
        $ditemukanDiNotif = false;
        foreach ($notifikasiList as $n) {
            if ($n['id_catatan'] == $idCatatanBaru) {
                $ditemukanDiNotif = true;
                break;
            }
        }
        $this->assertTrue($ditemukanDiNotif, 'Catatan baru harus muncul di daftar notifikasi Orang Tua.');

        // -------------------------------------------------------------
        // LANGKAH 6: Orang Tua Membaca Detail Catatan
        // -------------------------------------------------------------
        $detailCatatanRes = $this->withHeader('Authorization', 'Bearer ' . $ortuToken)
            ->getJson("/api/catatan/{$idCatatanBaru}");

        $detailCatatanRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id_catatan' => $idCatatanBaru,
                    'status_dibaca' => 'dibaca',
                ],
            ]);

        // Verifikasi langsung di database bahwa status_dibaca sudah 'dibaca'
        $this->assertDatabaseHas('catatan_penghubung', [
            'id_catatan' => $idCatatanBaru,
            'status_dibaca' => 'dibaca',
        ]);

        // -------------------------------------------------------------
        // LANGKAH 7: Orang Tua Membalas Catatan
        // -------------------------------------------------------------
        $pesanBalasan = 'Alhamdulillah, terima kasih banyak atas bimbingannya Bapak Guru.';
        $balasRes = $this->withHeader('Authorization', 'Bearer ' . $ortuToken)
            ->postJson("/api/catatan/{$idCatatanBaru}/balas", [
                'isi_catatan' => $pesanBalasan,
            ]);

        $balasRes->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id_pengirim' => $userOrtuAhmad->id_user,
                    'id_penerima' => $guruUser->id_user,
                ],
            ]);

        $idBalasan = $balasRes->json('data.id_catatan');

        // Verifikasi di database bahwa balasan tersimpan dengan benar
        $this->assertDatabaseHas('catatan_penghubung', [
            'id_catatan' => $idBalasan,
            'id_pengirim' => $userOrtuAhmad->id_user,
            'id_penerima' => $guruUser->id_user,
            'isi_catatan' => $pesanBalasan,
        ]);

        // -------------------------------------------------------------
        // LANGKAH 8: Guru Melihat Balasan (Reset sesi Orang Tua)
        // -------------------------------------------------------------
        $this->flushHeaders();
        auth()->forgetGuards();

        $guruCatatanRes = $this->withHeader('Authorization', 'Bearer ' . $guruToken)
            ->getJson('/api/catatan');

        $guruCatatanRes->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $daftarCatatanGuru = $guruCatatanRes->json('data');
        $ditemukanBalasan = false;
        foreach ($daftarCatatanGuru as $cg) {
            if ($cg['id_catatan'] == $idBalasan) {
                $ditemukanBalasan = true;
                $this->assertEquals($userOrtuAhmad->id_user, $cg['id_pengirim']);
                $this->assertEquals($pesanBalasan, $cg['isi']);
                break;
            }
        }
        $this->assertTrue($ditemukanBalasan, 'Balasan dari Orang Tua harus dapat dilihat oleh Guru pengirim awal.');
    }
}
