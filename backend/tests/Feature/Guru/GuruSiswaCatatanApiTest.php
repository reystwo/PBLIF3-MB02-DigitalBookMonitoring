<?php

namespace Tests\Feature\Guru;

use App\Models\CatatanPenghubung;
use App\Models\Guru;
use App\Models\Siswa;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * Fitur Guru: siswa tanggung jawab (wali kelas), detail, riwayat & tambah catatan.
 * Seeder: Bapak Ahmad (guru) = wali 5A, Ibu Nurul (guru_nurul) = wali 5B.
 */
class GuruSiswaCatatanApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    private function sebagai(string $username): static
    {
        $user = User::where('username', $username)->firstOrFail();
        // Guard di-reset agar user hasil request sebelumnya tidak ikut ter-cache
        $this->app['auth']->forgetGuards();

        return $this->withHeader('Authorization', 'Bearer '.$user->createToken('test')->plainTextToken);
    }

    private function siswa(string $nama): Siswa
    {
        return Siswa::where('nama', $nama)->firstOrFail();
    }

    private function idUser(string $username): int
    {
        return User::where('username', $username)->value('id_user');
    }

    // ==================== DAFTAR SISWA ====================

    public function test_guru_hanya_melihat_siswa_di_kelas_yang_diampu(): void
    {
        $res = $this->sebagai('guru')->getJson('/api/guru/siswa');

        $res->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('meta.total', 4)
            ->assertJsonStructure([
                'data' => [['id_siswa', 'nis', 'nama', 'perempuan', 'kelas', 'tahun_ajaran', 'jumlah_catatan']],
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ]);

        $this->assertEqualsCanonicalizing(
            ['Ahmad Rizki', 'Aisyah Putri', 'Budi Santoso', 'Siti Aisyah'],
            array_column($res->json('data'), 'nama'),
        );

        $resNurul = $this->sebagai('guru_nurul')->getJson('/api/guru/siswa');
        $resNurul->assertOk()->assertJsonPath('meta.total', 3);
        $this->assertEqualsCanonicalizing(
            ['Citra Lestari', 'Dani Pratama', 'Fajar Ramadhan'],
            array_column($resNurul->json('data'), 'nama'),
        );
    }

    public function test_daftar_siswa_mendukung_pencarian_dan_pagination(): void
    {
        $this->sebagai('guru')->getJson('/api/guru/siswa?search=1003')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.nama', 'Budi Santoso');

        // Siswa kelas lain tidak muncul walau namanya cocok
        $this->sebagai('guru')->getJson('/api/guru/siswa?search=Citra')
            ->assertOk()
            ->assertJsonPath('meta.total', 0)
            ->assertJsonCount(0, 'data');

        $halaman2 = $this->sebagai('guru')->getJson('/api/guru/siswa?per_page=3&page=2');
        $halaman2->assertOk()
            ->assertJsonPath('meta.current_page', 2)
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonCount(1, 'data');
    }

    public function test_guru_tanpa_kelas_tidak_melihat_siswa_apa_pun(): void
    {
        $user = User::create([
            'nama' => 'Guru Baru', 'username' => 'guru_baru', 'password' => 'password123',
            'role' => 'guru', 'status' => 'aktif',
        ]);
        Guru::create(['id_user' => $user->id_user, 'nip' => '199001012020011001']);

        $this->sebagai('guru_baru')->getJson('/api/guru/siswa')
            ->assertOk()
            ->assertJsonPath('meta.total', 0);

        $this->sebagai('guru_baru')->getJson('/api/guru/siswa/'.$this->siswa('Ahmad Rizki')->id_siswa)
            ->assertForbidden();
    }

    // ==================== DETAIL SISWA ====================

    public function test_guru_dapat_membuka_detail_siswa_tanggung_jawabnya(): void
    {
        $siswa = $this->siswa('Ahmad Rizki');

        $this->sebagai('guru')->getJson("/api/guru/siswa/{$siswa->id_siswa}")
            ->assertOk()
            ->assertJsonPath('data.nama', 'Ahmad Rizki')
            ->assertJsonPath('data.kelas', '5A')
            ->assertJsonPath('data.wali_kelas', 'Bapak Ahmad')
            ->assertJsonPath('data.jumlah_catatan', 2)
            ->assertJsonPath('data.orang_tua.0.nama', 'Ibu Siti Nurhaliza')
            ->assertJsonPath('data.orang_tua.0.hubungan', 'Ibu');
    }

    public function test_detail_dan_riwayat_siswa_kelas_lain_ditolak_403(): void
    {
        $citra = $this->siswa('Citra Lestari'); // kelas 5B

        $this->sebagai('guru')->getJson("/api/guru/siswa/{$citra->id_siswa}")
            ->assertForbidden()
            ->assertJson(['success' => false, 'message' => 'Akses ditolak. Siswa ini bukan tanggung jawab Anda.']);

        $this->sebagai('guru')->getJson("/api/guru/siswa/{$citra->id_siswa}/catatan")
            ->assertForbidden()
            ->assertJsonMissingPath('data');
    }

    public function test_siswa_yang_tidak_ada_mengembalikan_404(): void
    {
        $this->sebagai('guru')->getJson('/api/guru/siswa/999999')
            ->assertNotFound()
            ->assertJson(['success' => false, 'message' => 'Data siswa tidak ditemukan.']);
    }

    // ==================== RIWAYAT CATATAN ====================

    public function test_riwayat_catatan_terbaru_lebih_dulu_dengan_nama_pembuat_dan_waktu(): void
    {
        $siswa = $this->siswa('Ahmad Rizki');
        $idGuru = $this->idUser('guru');
        $idOrtu = $this->idUser('ortu');

        // Tanggal kejadian dibuat lebih lama, tetapi catatan ini yang paling akhir dibuat
        Carbon::setTestNow('2030-01-15 10:00:00');
        $terbaru = CatatanPenghubung::create([
            'id_siswa' => $siswa->id_siswa, 'id_pengirim' => $idGuru, 'id_penerima' => $idOrtu,
            'kategori' => 'Kegiatan', 'tanggal' => '2025-01-01 08:00:00', 'isi_catatan' => 'Catatan paling baru',
        ]);
        Carbon::setTestNow();

        $res = $this->sebagai('guru')->getJson("/api/guru/siswa/{$siswa->id_siswa}/catatan");

        $res->assertOk()
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('data.0.id_catatan', $terbaru->id_catatan)
            ->assertJsonPath('data.0.penulis', 'Bapak Ahmad')
            ->assertJsonPath('data.0.peran_penulis', 'Guru Kelas 5A')
            ->assertJsonPath('data.0.created_at', '2030-01-15 10:00:00')
            // Catatan seeder: balasan orang tua (10 Sep) dibuat sebelum catatan guru (12 Sep)
            ->assertJsonPath('data.1.isi', 'Ananda Rizki menunjukkan peningkatan pada mata pelajaran Matematika. Namun, perlu lebih fokus dalam mengerjakan tugas rumah. Tetap semangat!')
            ->assertJsonPath('data.2.penulis', 'Ibu Siti Nurhaliza')
            ->assertJsonPath('data.2.peran_penulis', 'Orang Tua');

        $waktu = array_column($res->json('data'), 'created_at');
        $urut = $waktu;
        rsort($urut);
        $this->assertSame($urut, $waktu, 'Riwayat harus urut dari yang terbaru.');

        foreach ($res->json('data') as $c) {
            $this->assertSame($siswa->id_siswa, $c['id_siswa']);
        }
    }

    public function test_migration_mengisi_waktu_pembuatan_catatan_lama_dari_tanggal(): void
    {
        $siswa = $this->siswa('Ahmad Rizki');

        // Kembali ke skema sebelum migration timestamp, lalu simpan "data lama"
        $this->artisan('migrate:rollback', ['--step' => 1])->assertSuccessful();
        $this->assertFalse(Schema::hasColumn('catatan_penghubung', 'created_at'));
        $jumlahLama = DB::table('catatan_penghubung')->count();

        $idLama = DB::table('catatan_penghubung')->insertGetId([
            'id_siswa' => $siswa->id_siswa,
            'id_pengirim' => $this->idUser('guru'),
            'id_penerima' => $this->idUser('ortu'),
            'isi_catatan' => 'Catatan sebelum migration',
            'tanggal' => '2024-05-06 07:08:09',
        ], 'id_catatan');

        $this->artisan('migrate')->assertSuccessful();

        $baris = DB::table('catatan_penghubung')->where('id_catatan', $idLama)->first();
        $this->assertSame('Catatan sebelum migration', $baris->isi_catatan);
        $this->assertSame('2024-05-06 07:08:09', $baris->created_at);
        $this->assertSame('2024-05-06 07:08:09', $baris->updated_at);
        $this->assertSame($jumlahLama + 1, DB::table('catatan_penghubung')->count());
        $this->assertSame(0, DB::table('catatan_penghubung')->whereNull('created_at')->count());
    }

    // ==================== TAMBAH CATATAN ====================

    public function test_guru_menambah_catatan_dan_melihatnya_kembali_setelah_dimuat_ulang(): void
    {
        $siswa = $this->siswa('Budi Santoso');
        $idGuru = $this->idUser('guru');

        $res = $this->sebagai('guru')->postJson("/api/guru/siswa/{$siswa->id_siswa}/catatan", [
            'kategori' => 'Perilaku',
            'isi_catatan' => '  Budi membantu merapikan kelas hari ini.  ',
        ]);

        $res->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Catatan untuk Budi Santoso berhasil disimpan')
            ->assertJsonPath('data.isi_catatan', 'Budi membantu merapikan kelas hari ini.')
            ->assertJsonPath('data.penulis', 'Bapak Ahmad')
            ->assertJsonPath('data.id_pengirim', $idGuru)
            ->assertJsonPath('data.id_penerima', $this->idUser('ortu_budi'));

        $catatan = CatatanPenghubung::findOrFail($res->json('data.id_catatan'));
        $this->assertSame($siswa->id_siswa, $catatan->id_siswa);
        $this->assertSame($idGuru, $catatan->id_pengirim);
        $this->assertNotNull($catatan->created_at);
        $this->assertNotNull($catatan->updated_at);

        // "Muat ulang": request baru ke riwayat & detail
        $this->sebagai('guru')->getJson("/api/guru/siswa/{$siswa->id_siswa}/catatan")
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id_catatan', $catatan->id_catatan)
            ->assertJsonPath('data.0.isi', 'Budi membantu merapikan kelas hari ini.');

        $this->sebagai('guru')->getJson("/api/guru/siswa/{$siswa->id_siswa}")
            ->assertJsonPath('data.jumlah_catatan', 1);
    }

    public function test_manipulasi_identitas_pengirim_dan_siswa_pada_body_diabaikan(): void
    {
        $budi = $this->siswa('Budi Santoso');     // 5A, tanggung jawab Bapak Ahmad
        $citra = $this->siswa('Citra Lestari');   // 5B
        $idNurul = $this->idUser('guru_nurul');

        $res = $this->sebagai('guru')->postJson("/api/guru/siswa/{$budi->id_siswa}/catatan", [
            'isi_catatan' => 'Catatan dengan field palsu',
            'id_pengirim' => $idNurul,
            'id_guru' => Guru::where('id_user', $idNurul)->value('id_guru'),
            'id_siswa' => $citra->id_siswa,
            'id_penerima' => $this->idUser('admin'),
        ]);

        $res->assertCreated();
        $catatan = CatatanPenghubung::findOrFail($res->json('data.id_catatan'));
        $this->assertSame($this->idUser('guru'), $catatan->id_pengirim);
        $this->assertSame($budi->id_siswa, $catatan->id_siswa);
        $this->assertSame($this->idUser('ortu_budi'), $catatan->id_penerima);
        $this->assertSame(0, CatatanPenghubung::where('id_siswa', $citra->id_siswa)->count());
    }

    public function test_catatan_kosong_atau_tidak_valid_ditolak(): void
    {
        $siswa = $this->siswa('Ahmad Rizki');
        $url = "/api/guru/siswa/{$siswa->id_siswa}/catatan";
        $jumlahAwal = CatatanPenghubung::count();

        $kasus = [
            'tanpa isi' => [],
            'string kosong' => ['isi_catatan' => ''],
            'hanya spasi' => ['isi_catatan' => "   \t\n  "],
            'spasi unicode' => ['isi_catatan' => "\u{00A0}\u{3000}\u{2003}"],
            'bukan teks' => ['isi_catatan' => ['a', 'b']],
            'terlalu panjang' => ['isi_catatan' => str_repeat('a', CatatanPenghubung::MAKS_ISI + 1)],
        ];

        foreach ($kasus as $nama => $body) {
            $this->sebagai('guru')->postJson($url, $body)
                ->assertStatus(422)
                ->assertJsonPath('success', false)
                ->assertJsonValidationErrors('isi_catatan', 'errors');
        }

        $this->sebagai('guru')->postJson($url, ['isi_catatan' => 'Isi valid', 'kategori' => 'Rahasia'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('kategori', 'errors');

        $this->sebagai('guru')->postJson($url, ['isi_catatan' => '   '])
            ->assertJsonPath('message', 'Isi catatan wajib diisi dan tidak boleh hanya berisi spasi.');

        $this->sebagai('guru')->postJson($url, ['isi_catatan' => str_repeat('a', 501)])
            ->assertJsonPath('message', 'Isi catatan maksimal 500 karakter.');

        $this->assertSame($jumlahAwal, CatatanPenghubung::count());

        // Tepat di batas maksimal tetap diterima
        $this->sebagai('guru')->postJson($url, ['isi_catatan' => str_repeat('a', CatatanPenghubung::MAKS_ISI)])
            ->assertCreated();
    }

    public function test_isi_berupa_html_disimpan_dan_dikembalikan_sebagai_teks_apa_adanya(): void
    {
        $siswa = $this->siswa('Ahmad Rizki');
        $isi = '<script>alert("x")</script><b>tebal</b>';

        $res = $this->sebagai('guru')->postJson("/api/guru/siswa/{$siswa->id_siswa}/catatan", ['isi_catatan' => $isi]);

        $res->assertCreated()->assertJsonPath('data.isi_catatan', $isi);
        $this->assertStringStartsWith('application/json', $res->headers->get('Content-Type'));
    }

    public function test_guru_tidak_dapat_menambah_catatan_untuk_siswa_kelas_lain(): void
    {
        $citra = $this->siswa('Citra Lestari');
        $jumlahAwal = CatatanPenghubung::count();

        // Ditolak 403 (bukan 422) walau body tidak valid, agar tidak membocorkan informasi
        foreach ([['isi_catatan' => 'Mencoba menulis catatan'], []] as $body) {
            $this->sebagai('guru')->postJson("/api/guru/siswa/{$citra->id_siswa}/catatan", $body)
                ->assertForbidden()
                ->assertJson(['success' => false, 'message' => 'Akses ditolak. Siswa ini bukan tanggung jawab Anda.']);
        }

        $this->assertSame($jumlahAwal, CatatanPenghubung::count());
    }

    // ==================== HAK AKSES ROLE LAIN ====================

    private function daftarEndpointGuru(): array
    {
        $id = $this->siswa('Ahmad Rizki')->id_siswa;

        return [
            ['GET', '/api/guru/siswa'],
            ['GET', "/api/guru/siswa/{$id}"],
            ['GET', "/api/guru/siswa/{$id}/catatan"],
            ['POST', "/api/guru/siswa/{$id}/catatan"],
            // ID yang tidak ada tetap 403 bagi role lain (tidak membocorkan keberadaan data)
            ['GET', '/api/guru/siswa/999999'],
        ];
    }

    public function test_pengguna_belum_login_ditolak_401(): void
    {
        foreach ($this->daftarEndpointGuru() as [$method, $uri]) {
            $this->json($method, $uri, ['isi_catatan' => 'x'])->assertUnauthorized();
        }
    }

    public function test_admin_dan_orang_tua_ditolak_403_di_endpoint_guru(): void
    {
        $jumlahAwal = CatatanPenghubung::count();

        foreach (['admin', 'ortu'] as $username) {
            foreach ($this->daftarEndpointGuru() as [$method, $uri]) {
                $this->sebagai($username)->json($method, $uri, ['isi_catatan' => 'Coba'])
                    ->assertForbidden()
                    ->assertJson(['success' => false, 'message' => 'Akses ditolak untuk peran Anda.']);
            }
        }

        $this->assertSame($jumlahAwal, CatatanPenghubung::count());
    }

    public function test_guru_nonaktif_ditolak_403(): void
    {
        User::where('username', 'guru')->update(['status' => 'nonaktif']);

        $this->sebagai('guru')->getJson('/api/guru/siswa')
            ->assertForbidden()
            ->assertJsonPath('message', 'Akun Anda sedang dinonaktifkan. Silakan hubungi Administrator.');
    }

    // ==================== ENDPOINT LAMA (/api/siswa & /api/catatan) ====================

    private function catatanSiswa5B(): CatatanPenghubung
    {
        return CatatanPenghubung::create([
            'id_siswa' => $this->siswa('Citra Lestari')->id_siswa,
            'id_pengirim' => $this->idUser('guru_nurul'),
            'id_penerima' => $this->idUser('ortu_citra'),
            'kategori' => 'Akademik',
            'tanggal' => now(),
            'isi_catatan' => 'Catatan wali kelas 5B',
        ]);
    }

    public function test_endpoint_catatan_lama_menolak_guru_di_luar_cakupan(): void
    {
        $catatan5B = $this->catatanSiswa5B();
        $citra = $this->siswa('Citra Lestari');

        $this->sebagai('guru')->postJson('/api/catatan', ['id_siswa' => $citra->id_siswa, 'isi_catatan' => 'Lewat endpoint lama'])
            ->assertForbidden();

        $this->sebagai('guru')->getJson("/api/catatan/{$catatan5B->id_catatan}")->assertForbidden();
        $this->sebagai('guru')->postJson("/api/catatan/{$catatan5B->id_catatan}/balas", ['isi_catatan' => 'Balas'])->assertForbidden();
        $this->sebagai('guru')->patchJson("/api/catatan/{$catatan5B->id_catatan}/baca")->assertForbidden();

        $idCatatanDiDaftar = array_column($this->sebagai('guru')->getJson('/api/catatan')->json('data'), 'id_catatan');
        $this->assertNotContains($catatan5B->id_catatan, $idCatatanDiDaftar);

        $this->sebagai('guru')->getJson("/api/catatan?id_siswa={$citra->id_siswa}")
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->assertSame('belum_dibaca', $catatan5B->fresh()->status_dibaca);
        $this->assertSame(1, CatatanPenghubung::where('id_siswa', $citra->id_siswa)->count());

        // Wali kelas 5B tetap dapat membaca & membalas catatan siswanya
        $this->sebagai('guru_nurul')->getJson("/api/catatan/{$catatan5B->id_catatan}")->assertOk();
        $this->sebagai('guru_nurul')->postJson("/api/catatan/{$catatan5B->id_catatan}/balas", ['isi_catatan' => 'Tambahan'])
            ->assertCreated();
    }

    public function test_endpoint_catatan_lama_menolak_penerima_bukan_orang_tua_siswa(): void
    {
        $budi = $this->siswa('Budi Santoso');

        $this->sebagai('guru')->postJson('/api/catatan', [
            'id_siswa' => $budi->id_siswa,
            'isi_catatan' => 'Dikirim ke orang tua lain',
            'id_penerima' => $this->idUser('ortu_citra'),
        ])->assertStatus(422)->assertJsonPath('message', 'Penerima catatan harus orang tua/wali dari siswa tersebut.');

        $this->sebagai('guru')->postJson('/api/catatan', [
            'id_siswa' => $budi->id_siswa,
            'isi_catatan' => 'Dikirim ke orang tua sendiri',
            'id_penerima' => $this->idUser('ortu_budi'),
            'id_pengirim' => $this->idUser('guru_nurul'),
        ])->assertCreated()->assertJsonPath('data.id_pengirim', $this->idUser('guru'));

        $this->sebagai('guru')->postJson('/api/catatan', [
            'id_siswa' => $budi->id_siswa,
            'isi_catatan' => str_repeat('a', CatatanPenghubung::MAKS_ISI + 1),
        ])->assertStatus(422);
    }

    public function test_admin_dan_orang_tua_tetap_berfungsi_di_endpoint_lama(): void
    {
        $citra = $this->siswa('Citra Lestari');

        // Admin tidak dibatasi cakupan kelas
        $this->sebagai('admin')->postJson('/api/catatan', ['id_siswa' => $citra->id_siswa, 'isi_catatan' => 'Catatan admin'])
            ->assertCreated();
        $this->sebagai('admin')->getJson('/api/siswa')->assertOk()->assertJsonCount(7, 'data');

        // Orang tua tetap melihat & membaca catatan anaknya
        $catatan5B = $this->catatanSiswa5B();
        $this->sebagai('ortu_citra')->getJson("/api/catatan/{$catatan5B->id_catatan}")
            ->assertOk()
            ->assertJsonPath('data.status_dibaca', 'dibaca');
        $this->sebagai('ortu_citra')->patchJson("/api/catatan/{$catatan5B->id_catatan}/baca")->assertOk();
    }
}
