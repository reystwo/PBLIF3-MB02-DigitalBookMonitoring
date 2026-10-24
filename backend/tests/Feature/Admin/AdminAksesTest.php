<?php

namespace Tests\Feature\Admin;

use App\Models\Guru;
use App\Models\Kelas;
use App\Models\OrangTua;
use App\Models\Siswa;
use App\Models\User;

/**
 * Otorisasi endpoint Admin: hanya role admin yang aktif yang boleh mengakses.
 */
class AdminAksesTest extends AdminApiTestCase
{
    /**
     * Seluruh endpoint admin (method, uri) untuk data yang ada di seeder.
     */
    private function daftarEndpoint(): array
    {
        $guru = Guru::first()->id_guru;
        $ortu = OrangTua::first()->id_orang_tua;
        $siswa = Siswa::first()->id_siswa;
        $kelas = Kelas::first()->id_kelas;

        $endpoint = [];
        foreach (['guru' => $guru, 'orang-tua' => $ortu, 'siswa' => $siswa, 'kelas' => $kelas] as $resource => $id) {
            $endpoint[] = ['GET', "/api/admin/{$resource}"];
            $endpoint[] = ['POST', "/api/admin/{$resource}"];
            $endpoint[] = ['GET', "/api/admin/{$resource}/{$id}"];
            $endpoint[] = ['PUT', "/api/admin/{$resource}/{$id}"];
            $endpoint[] = ['DELETE', "/api/admin/{$resource}/{$id}"];
            // ID yang tidak ada tetap harus 403 (tidak membocorkan keberadaan data)
            $endpoint[] = ['GET', "/api/admin/{$resource}/999999"];
        }

        return $endpoint;
    }

    public function test_pengguna_belum_login_ditolak_401_di_semua_endpoint_admin(): void
    {
        foreach ($this->daftarEndpoint() as [$method, $uri]) {
            $this->json($method, $uri)->assertStatus(401);
        }
    }

    public function test_guru_dan_orang_tua_ditolak_403_di_semua_endpoint_admin(): void
    {
        $jumlahUserAwal = User::count();
        $jumlahSiswaAwal = Siswa::count();

        foreach (['guru', 'ortu'] as $username) {
            foreach ($this->daftarEndpoint() as [$method, $uri]) {
                $this->sebagai($username)
                    ->json($method, $uri, ['nama' => 'Coba', 'username' => 'coba_hack', 'password' => 'password123'])
                    ->assertStatus(403)
                    ->assertJson(['success' => false, 'message' => 'Akses ditolak untuk peran Anda.']);
            }
        }

        // Tidak ada data yang berubah atau terhapus
        $this->assertSame($jumlahUserAwal, User::count());
        $this->assertSame($jumlahSiswaAwal, Siswa::count());
        $this->assertDatabaseMissing('users', ['username' => 'coba_hack']);
    }

    public function test_admin_dapat_mengakses_keempat_fitur(): void
    {
        foreach (['guru', 'orang-tua', 'siswa', 'kelas'] as $resource) {
            $this->sebagaiAdmin()
                ->getJson("/api/admin/{$resource}")
                ->assertOk()
                ->assertJson(['success' => true])
                ->assertJsonStructure(['data', 'meta' => ['current_page', 'last_page', 'per_page', 'total']]);
        }
    }

    public function test_admin_nonaktif_ditolak(): void
    {
        $admin = User::where('username', 'admin')->first();
        $token = $admin->createToken('test')->plainTextToken;
        $admin->update(['status' => 'nonaktif']);

        $this->denganToken($token)->getJson('/api/admin/guru')->assertStatus(403);
    }

    public function test_role_admin_tidak_dapat_disisipkan_melalui_request(): void
    {
        $this->sebagaiAdmin()->postJson('/api/admin/guru', [
            'nama' => 'Guru Baru',
            'username' => 'guru_baru',
            'password' => 'rahasia123',
            'nip' => '199001012020011001',
            'role' => 'admin',
        ])->assertCreated();

        $this->assertSame('guru', User::where('username', 'guru_baru')->value('role'));

        $ortu = OrangTua::with('user')->first();
        $this->sebagaiAdmin()->putJson("/api/admin/orang-tua/{$ortu->id_orang_tua}", [
            'nama' => $ortu->user->nama,
            'username' => $ortu->user->username,
            'role' => 'admin',
            'id_user' => 1,
        ])->assertOk();

        $ortu->refresh();
        $this->assertSame('orang_tua', $ortu->user->role);
        $this->assertNotSame(1, $ortu->id_user);
        $this->assertSame(1, User::where('role', 'admin')->count());
    }

    public function test_login_role_lain_tetap_berfungsi(): void
    {
        foreach (['admin' => 'admin', 'guru' => 'guru', 'ortu' => 'orang_tua'] as $username => $role) {
            $this->postJson('/api/login', ['username' => $username, 'password' => 'password123', 'role' => $role])
                ->assertOk()
                ->assertJsonPath('data.user.role', $role);
        }

        // Endpoint lama milik guru tetap dapat diakses
        $this->sebagai('guru')->getJson('/api/siswa')->assertOk();
        $this->sebagai('ortu')->getJson('/api/catatan')->assertOk();
    }
}
