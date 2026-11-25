<?php

namespace Tests\Feature\OrangTua;

use App\Models\OrangTua;
use App\Models\Siswa;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Fitur Orang Tua: daftar anak yang tertaut pada akun (GET /api/orang-tua/anak).
 * Seeder: setiap orang tua memiliki tepat 1 anak (ortu = Ahmad Rizki, kelas 7A).
 */
class OrangTuaAnakApiTest extends TestCase
{
    use RefreshDatabase;

    private const ENDPOINT = '/api/orang-tua/anak';

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

    private function tautkan(string $username, string $namaSiswa, string $hubungan = 'Ibu'): void
    {
        $idOrangTua = User::where('username', $username)->firstOrFail()->orangTua->id_orang_tua;

        Siswa::where('nama', $namaSiswa)->firstOrFail()
            ->orangTua()->attach($idOrangTua, ['hubungan' => $hubungan]);
    }

    // ==================== 1 ANAK ====================

    public function test_orang_tua_dengan_satu_anak_melihat_data_anaknya(): void
    {
        $res = $this->sebagai('ortu')->getJson(self::ENDPOINT);

        $res->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [[
                    'id_siswa', 'nis', 'nama', 'jenis_kelamin', 'perempuan',
                    'id_kelas', 'kelas', 'tahun_ajaran', 'wali_kelas', 'hubungan',
                ]],
            ])
            ->assertJsonPath('data.0.nama', 'Ahmad Rizki')
            ->assertJsonPath('data.0.jenis_kelamin', 'L')
            ->assertJsonPath('data.0.perempuan', false)
            ->assertJsonPath('data.0.kelas', '7A')
            ->assertJsonPath('data.0.wali_kelas', 'Bapak Ahmad')
            ->assertJsonPath('data.0.hubungan', 'Ibu');
    }

    public function test_orang_tua_tidak_melihat_anak_milik_orang_tua_lain(): void
    {
        $res = $this->sebagai('ortu')->getJson(self::ENDPOINT);

        $this->assertSame(['Ahmad Rizki'], array_column($res->json('data'), 'nama'));

        $resAisyah = $this->sebagai('ortu_aisyah')->getJson(self::ENDPOINT);
        $this->assertSame(['Aisyah Putri'], array_column($resAisyah->json('data'), 'nama'));
        $this->assertSame('P', $resAisyah->json('data.0.jenis_kelamin'));
        $this->assertTrue($resAisyah->json('data.0.perempuan'));
    }

    // ==================== 2 ANAK ====================

    public function test_orang_tua_dengan_dua_anak_melihat_keduanya_berurut_nama(): void
    {
        // Anak kedua berada di kelas lain (7B, wali Ibu Nurul) dengan hubungan berbeda
        $this->tautkan('ortu', 'Citra Lestari', 'Wali');

        $res = $this->sebagai('ortu')->getJson(self::ENDPOINT);

        $res->assertOk()->assertJsonCount(2, 'data');
        $this->assertSame(['Ahmad Rizki', 'Citra Lestari'], array_column($res->json('data'), 'nama'));

        $res->assertJsonPath('data.0.kelas', '7A')
            ->assertJsonPath('data.0.wali_kelas', 'Bapak Ahmad')
            ->assertJsonPath('data.0.hubungan', 'Ibu')
            ->assertJsonPath('data.1.kelas', '7B')
            ->assertJsonPath('data.1.wali_kelas', 'Ibu Nurul Hidayah')
            ->assertJsonPath('data.1.hubungan', 'Wali');
    }

    public function test_siswa_yang_ditautkan_admin_langsung_muncul_di_daftar_anak(): void
    {
        $this->assertCount(1, $this->sebagai('ortu')->getJson(self::ENDPOINT)->json('data'));

        $this->tautkan('ortu', 'Budi Santoso', 'Ibu');

        $this->assertCount(2, $this->sebagai('ortu')->getJson(self::ENDPOINT)->json('data'));
    }

    // ==================== 0 ANAK ====================

    public function test_orang_tua_tanpa_anak_tertaut_mendapat_daftar_kosong(): void
    {
        $user = User::create([
            'nama' => 'Bapak Tanpa Anak',
            'username' => 'ortu_kosong',
            'password' => 'password123',
            'role' => 'orang_tua',
            'status' => 'aktif',
        ]);
        OrangTua::create(['id_user' => $user->id_user]);

        $this->sebagai('ortu_kosong')->getJson(self::ENDPOINT)
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(0, 'data');
    }

    public function test_akun_orang_tua_tanpa_profil_mendapat_daftar_kosong(): void
    {
        User::create([
            'nama' => 'Akun Tanpa Profil',
            'username' => 'ortu_tanpa_profil',
            'password' => 'password123',
            'role' => 'orang_tua',
            'status' => 'aktif',
        ]);

        $this->sebagai('ortu_tanpa_profil')->getJson(self::ENDPOINT)
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    // ==================== PROTEKSI AKSES ====================

    public function test_endpoint_wajib_login(): void
    {
        $this->getJson(self::ENDPOINT)->assertUnauthorized();
    }

    public function test_guru_dan_admin_ditolak(): void
    {
        $this->sebagai('guru')->getJson(self::ENDPOINT)->assertForbidden();
        $this->sebagai('admin')->getJson(self::ENDPOINT)->assertForbidden();
    }

    public function test_akun_orang_tua_nonaktif_ditolak(): void
    {
        User::where('username', 'ortu')->update(['status' => 'nonaktif']);

        $this->sebagai('ortu')->getJson(self::ENDPOINT)->assertForbidden();
    }
}
