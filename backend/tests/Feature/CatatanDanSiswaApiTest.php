<?php

namespace Tests\Feature;

use App\Models\CatatanPenghubung;
use App\Models\Siswa;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatatanDanSiswaApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $guru;
    protected User $ortuAhmad;
    protected User $ortuSiti;
    protected string $guruToken;
    protected string $ortuAhmadToken;
    protected string $ortuSitiToken;

    protected function setUp(): void
    {
        parent::setUp();
        // Seed database in-memory testing dengan dataset lengkap
        $this->seed(DatabaseSeeder::class);

        $this->guru = User::where('username', 'guru')->first();
        $this->ortuAhmad = User::where('username', 'ortu')->first(); // Ortu Ahmad Rizki
        $this->ortuSiti = User::where('username', 'ortu_siti')->first(); // Ortu Siti Aisyah

        $this->guruToken = $this->guru->createToken('test-guru')->plainTextToken;
        $this->ortuAhmadToken = $this->ortuAhmad->createToken('test-ortu-ahmad')->plainTextToken;
        $this->ortuSitiToken = $this->ortuSiti->createToken('test-ortu-siti')->plainTextToken;
    }

    /**
     * Test 1: Guru dapat mengambil daftar seluruh siswa dan filter kelas.
     */
    public function test_guru_can_get_all_siswa_and_filter_by_kelas(): void
    {
        // 1. Ambil semua siswa
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->guruToken)
            ->getJson('/api/siswa');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonCount(7, 'data'); // Total 7 siswa

        // 2. Filter kelas 5A
        $response5A = $this->withHeader('Authorization', 'Bearer ' . $this->guruToken)
            ->getJson('/api/siswa?kelas=5A');

        $response5A->assertStatus(200);
        foreach ($response5A->json('data') as $s) {
            $this->assertEquals('5A', $s['kelas']);
        }
    }

    /**
     * Test 2: SEC-02 - Orang Tua HANYA mendapatkan daftar anak miliknya sendiri di /api/siswa.
     */
    public function test_sec_02_orang_tua_only_sees_their_own_children(): void
    {
        // Ibu Siti Nurhaliza (ortu Ahmad Rizki)
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->ortuAhmadToken)
            ->getJson('/api/siswa');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nama', 'Ahmad Rizki');
    }

    /**
     * Test 3: SEC-02 - Orang Tua HANYA mendapatkan catatan anak miliknya sendiri di /api/catatan.
     */
    public function test_sec_02_orang_tua_only_sees_their_own_children_notes(): void
    {
        // Ibu Siti Nurhaliza hanya boleh melihat catatan milik Ahmad Rizki
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->ortuAhmadToken)
            ->getJson('/api/catatan');

        $response->assertStatus(200);
        $catatanData = $response->json('data');

        $this->assertNotEmpty($catatanData);
        foreach ($catatanData as $c) {
            $this->assertEquals('Ahmad Rizki', $c['siswa']['nama']);
        }
    }

    /**
     * Test 4: SEC-02 Forbidden - Orang Tua DITOLAK saat mencoba melihat catatan anak orang lain (HTTP 403).
     */
    public function test_sec_02_orang_tua_cannot_view_other_children_notes(): void
    {
        // Catatan ID 3 adalah milik Siti Aisyah (bukan anak dari Ibu Siti Nurhaliza)
        $catatanSitiAisyah = CatatanPenghubung::whereHas('siswa', function ($q) {
            $q->where('nama', 'Siti Aisyah');
        })->first();

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->ortuAhmadToken)
            ->getJson('/api/catatan/' . $catatanSitiAisyah->id_catatan);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akses ditolak. Anda tidak berhak melihat catatan siswa ini.',
            ]);
    }

    /**
     * Test 5: SEC-02 Forbidden - Orang Tua DITOLAK saat mencoba membalas catatan anak orang lain (HTTP 403).
     */
    public function test_sec_02_orang_tua_cannot_reply_to_other_children_notes(): void
    {
        $catatanSitiAisyah = CatatanPenghubung::whereHas('siswa', function ($q) {
            $q->where('nama', 'Siti Aisyah');
        })->first();

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->ortuAhmadToken)
            ->postJson('/api/catatan/' . $catatanSitiAisyah->id_catatan . '/balas', [
                'isi_catatan' => 'Mencoba membalas catatan siswa lain',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akses ditolak. Anda tidak berhak membalas catatan siswa ini.',
            ]);
    }

    /**
     * Test 6: Guru berhasil membuat catatan penghubung baru (POST /api/catatan).
     */
    public function test_guru_can_create_new_catatan(): void
    {
        $siswaBudi = Siswa::where('nama', 'Budi Santoso')->first();

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->guruToken)
            ->postJson('/api/catatan', [
                'id_siswa' => $siswaBudi->id_siswa,
                'kategori' => 'Kesehatan',
                'isi_catatan' => 'Budi tampak kurang sehat saat jam istirahat.',
                'lampiran_nama' => 'Surat_UKS.jpg',
                'lampiran_ukuran' => '0.5 MB',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Catatan untuk Budi Santoso berhasil disimpan',
            ])
            ->assertJsonPath('data.kategori', 'Kesehatan')
            ->assertJsonPath('data.siswa.nama', 'Budi Santoso')
            ->assertJsonPath('data.lampiran.nama_file', 'Surat_UKS.jpg');

        $this->assertDatabaseHas('catatan_penghubung', [
            'id_siswa' => $siswaBudi->id_siswa,
            'kategori' => 'Kesehatan',
            'isi_catatan' => 'Budi tampak kurang sehat saat jam istirahat.',
        ]);
    }

    /**
     * Test 7: Orang Tua berhasil membalas catatan anaknya (POST /api/catatan/{id}/balas).
     */
    public function test_orang_tua_can_reply_to_their_own_child_note(): void
    {
        $catatanAhmadRizki = CatatanPenghubung::whereHas('siswa', function ($q) {
            $q->where('nama', 'Ahmad Rizki');
        })->where('id_pengirim', $this->guru->id_user)->first();

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->ortuAhmadToken)
            ->postJson('/api/catatan/' . $catatanAhmadRizki->id_catatan . '/balas', [
                'isi' => 'Baik Pak, terima kasih atas perhatiannya.',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Balasan berhasil dikirim',
            ])
            ->assertJsonPath('data.id_pengirim', $this->ortuAhmad->id_user)
            ->assertJsonPath('data.id_penerima', $this->guru->id_user);

        // Catatan asal otomatis ditandai 'dibaca'
        $this->assertEquals('dibaca', $catatanAhmadRizki->fresh()->status_dibaca);
    }

    /**
     * Test 8: Endpoint /api/dashboard untuk Guru.
     */
    public function test_dashboard_endpoint_returns_valid_data_for_guru(): void
    {
        $guruDashboard = $this->withHeader('Authorization', 'Bearer ' . $this->guruToken)
            ->getJson('/api/dashboard');

        $guruDashboard->assertStatus(200)
            ->assertJsonPath('data.role', 'guru')
            ->assertJsonStructure([
                'data' => [
                    'nama_guru',
                    'kelas_wali',
                    'statistik',
                    'catatan_terbaru',
                ],
            ]);
    }

    /**
     * Test 9: Endpoint /api/dashboard untuk Orang Tua.
     */
    public function test_dashboard_endpoint_returns_valid_data_for_orang_tua(): void
    {
        $ortuDashboard = $this->withHeader('Authorization', 'Bearer ' . $this->ortuAhmadToken)
            ->getJson('/api/dashboard');

        $ortuDashboard->assertStatus(200)
            ->assertJsonPath('data.role', 'orang_tua')
            ->assertJsonStructure([
                'data' => [
                    'nama_orang_tua',
                    'anak',
                    'statistik',
                    'catatan_terbaru',
                ],
            ]);
    }

    /**
     * Test 9: Endpoint /api/notifikasi mengembalikan list aktivitas.
     */
    public function test_notifikasi_endpoint_returns_activity_feed(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->guruToken)
            ->getJson('/api/notifikasi');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id_catatan',
                        'id_siswa',
                        'nama',
                        'keterangan',
                        'waktu',
                        'status_dibaca',
                    ],
                ],
            ]);
    }
}
