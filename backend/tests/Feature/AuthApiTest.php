<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Seed database in-memory testing dengan dataset lengkap
        $this->seed(DatabaseSeeder::class);
    }

    /**
     * Test 1: Health check endpoint aktif.
     */
    public function test_api_health_check_returns_ok(): void
    {
        $response = $this->getJson('/api/health');

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'ok',
                'service' => 'Digital Book Connect API',
            ]);
    }

    /**
     * Test 2: Login berhasil sebagai Guru.
     */
    public function test_guru_can_login_with_valid_credentials(): void
    {
        $response = $this->postJson('/api/login', [
            'username' => 'guru',
            'password' => 'password123',
            'role' => 'guru',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil',
            ])
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'user' => [
                        'id_user',
                        'nama',
                        'username',
                        'role',
                        'status',
                        'peran_label',
                        'guru' => [
                            'id_guru',
                            'nip',
                            'kelas_wali',
                        ],
                    ],
                ],
            ]);

        $this->assertEquals('guru', $response->json('data.user.role'));
        $this->assertEquals('Wali Kelas 5A', $response->json('data.user.peran_label'));
    }

    /**
     * Test 3: Login berhasil sebagai Orang Tua.
     */
    public function test_orang_tua_can_login_with_valid_credentials(): void
    {
        $response = $this->postJson('/api/login', [
            'username' => 'ortu',
            'password' => 'password123',
            'role' => 'orang_tua',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil',
            ])
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'user' => [
                        'id_user',
                        'nama',
                        'username',
                        'role',
                        'status',
                        'orang_tua' => [
                            'id_orang_tua',
                            'siswa',
                        ],
                    ],
                ],
            ]);

        $this->assertEquals('orang_tua', $response->json('data.user.role'));
        $this->assertNotEmpty($response->json('data.user.orang_tua.siswa'));
    }

    /**
     * Test 4: Login berhasil sebagai Admin.
     */
    public function test_admin_can_login_with_valid_credentials(): void
    {
        $response = $this->postJson('/api/login', [
            'username' => 'admin',
            'password' => 'password123',
            'role' => 'admin',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil',
                'data' => [
                    'user' => [
                        'role' => 'admin',
                        'peran_label' => 'Administrator',
                    ],
                ],
            ]);
    }

    /**
     * Test 5: Login gagal saat password salah (HTTP 401).
     */
    public function test_login_fails_with_invalid_password(): void
    {
        $response = $this->postJson('/api/login', [
            'username' => 'guru',
            'password' => 'passwordsalah',
            'role' => 'guru',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Username atau kata sandi salah.',
            ]);
    }

    /**
     * Test 6: Login gagal saat memilih role yang salah (HTTP 403).
     */
    public function test_login_fails_when_selecting_wrong_role(): void
    {
        // Akun 'guru' mencoba login dengan selector 'admin'
        $response = $this->postJson('/api/login', [
            'username' => 'guru',
            'password' => 'password123',
            'role' => 'admin',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akun ini tidak terdaftar sebagai Admin.',
            ]);
    }

    /**
     * Test 7: Login gagal jika akun dinonaktifkan (HTTP 403).
     */
    public function test_login_fails_if_account_is_inactive(): void
    {
        $guru = User::where('username', 'guru')->first();
        $guru->update(['status' => 'nonaktif']);

        $response = $this->postJson('/api/login', [
            'username' => 'guru',
            'password' => 'password123',
            'role' => 'guru',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Akun Anda sedang dinonaktifkan. Silakan hubungi Administrator.',
            ]);
    }

    /**
     * Test 8: Akses GET /api/me dengan Bearer token Sanctum berhasil (HTTP 200).
     */
    public function test_authenticated_user_can_access_me_profile(): void
    {
        $user = User::where('username', 'guru')->first();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Profil berhasil dimuat',
            ])
            ->assertJsonPath('data.user.username', 'guru');
    }

    /**
     * Test 9: Akses GET /api/me tanpa token ditolak (HTTP 401).
     */
    public function test_unauthenticated_user_cannot_access_me_profile(): void
    {
        $response = $this->getJson('/api/me');

        $response->assertStatus(401);
    }

    /**
     * Test 10: POST /api/logout berhasil menghapus token (HTTP 200).
     */
    public function test_user_can_logout_and_revoke_token(): void
    {
        $user = User::where('username', 'guru')->first();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/logout');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Berhasil keluar dari sesi.',
            ]);

        $this->assertDatabaseMissing('personal_access_tokens', [
            'tokenable_id' => $user->id_user,
        ]);
    }
}
