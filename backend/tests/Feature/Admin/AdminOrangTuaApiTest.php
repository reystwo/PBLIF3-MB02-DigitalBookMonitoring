<?php

namespace Tests\Feature\Admin;

use App\Models\OrangTua;
use App\Models\User;

class AdminOrangTuaApiTest extends AdminApiTestCase
{
    private function dataOrtu(array $override = []): array
    {
        return array_merge([
            'nama' => 'Bapak Yusuf',
            'username' => 'ortu_yusuf',
            'password' => 'rahasia123',
            'no_hp' => '081277778888',
            'alamat' => 'Jl. Kenanga No. 3, Batam',
        ], $override);
    }

    private function ortu(string $username): OrangTua
    {
        return OrangTua::whereHas('user', fn ($q) => $q->where('username', $username))->firstOrFail();
    }

    public function test_crud_orang_tua_lengkap(): void
    {
        // Tambah
        $id = $this->sebagaiAdmin()->postJson('/api/admin/orang-tua', $this->dataOrtu())
            ->assertCreated()
            ->assertJsonPath('data.nama', 'Bapak Yusuf')
            ->assertJsonPath('data.anak', [])
            ->assertJsonMissingPath('data.password')
            ->json('data.id_orang_tua');

        $user = User::where('username', 'ortu_yusuf')->first();
        $this->assertSame('orang_tua', $user->role);
        $this->assertDatabaseHas('orang_tua', ['id_orang_tua' => $id, 'alamat' => 'Jl. Kenanga No. 3, Batam']);

        // Detail
        $this->sebagaiAdmin()->getJson("/api/admin/orang-tua/{$id}")
            ->assertOk()
            ->assertJsonPath('data.username', 'ortu_yusuf')
            ->assertJsonPath('data.jumlah_catatan', 0);

        // Ubah (alamat dikosongkan)
        $this->sebagaiAdmin()->putJson("/api/admin/orang-tua/{$id}", $this->dataOrtu([
            'nama' => 'Bapak Yusuf Hamdani',
            'password' => null,
            'alamat' => '',
        ]))
            ->assertOk()
            ->assertJsonPath('data.nama', 'Bapak Yusuf Hamdani')
            ->assertJsonPath('data.alamat', null);
        $this->assertDatabaseHas('users', ['id_user' => $user->id_user, 'nama' => 'Bapak Yusuf Hamdani']);

        // Hapus (tidak punya anak & catatan)
        $this->sebagaiAdmin()->deleteJson("/api/admin/orang-tua/{$id}")
            ->assertOk()
            ->assertJsonPath('message', 'Orang tua Bapak Yusuf Hamdani berhasil dihapus');
        $this->assertDatabaseMissing('orang_tua', ['id_orang_tua' => $id]);
        $this->assertDatabaseMissing('users', ['id_user' => $user->id_user]);

        $this->sebagaiAdmin()->getJson("/api/admin/orang-tua/{$id}")
            ->assertNotFound()
            ->assertJsonPath('message', 'Data orang tua tidak ditemukan.');
    }

    public function test_pencarian_dan_pagination_orang_tua(): void
    {
        // 7 orang tua dari seeder
        $this->sebagaiAdmin()->getJson('/api/admin/orang-tua?per_page=5')
            ->assertOk()
            ->assertJsonCount(5, 'data')
            ->assertJsonPath('meta.total', 7)
            ->assertJsonPath('meta.last_page', 2);

        $this->sebagaiAdmin()->getJson('/api/admin/orang-tua?per_page=5&page=2')
            ->assertJsonCount(2, 'data');

        // Berdasarkan nama orang tua
        $this->sebagaiAdmin()->getJson('/api/admin/orang-tua?search=Fatimah')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.username', 'ortu_siti');

        // Berdasarkan nama anak
        $this->sebagaiAdmin()->getJson('/api/admin/orang-tua?search=Ahmad Rizki')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.username', 'ortu')
            ->assertJsonPath('data.0.anak.0.nama', 'Ahmad Rizki')
            ->assertJsonPath('data.0.anak.0.hubungan', 'Ibu');

        // Berdasarkan alamat
        $this->sebagaiAdmin()->getJson('/api/admin/orang-tua?search=Nagoya')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.username', 'ortu_budi');
    }

    public function test_validasi_dan_duplikat_username_ditolak(): void
    {
        $this->sebagaiAdmin()->postJson('/api/admin/orang-tua', $this->dataOrtu(['username' => 'guru']))
            ->assertStatus(422)
            ->assertJsonPath('errors.username.0', 'Username sudah digunakan.');

        $this->sebagaiAdmin()->postJson('/api/admin/orang-tua', [
            'nama' => str_repeat('a', 101),
            'username' => 'ortu_x',
            'alamat' => str_repeat('b', 256),
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['nama', 'password', 'alamat'])
            ->assertJsonPath('errors.nama.0', 'Nama maksimal 100 karakter.');
    }

    public function test_hapus_orang_tua_dibatasi_jika_masih_terhubung_dengan_siswa_atau_catatan(): void
    {
        // Ibu Rahmawati terhubung dengan Aisyah Putri
        $rahmawati = $this->ortu('ortu_aisyah');
        $this->sebagaiAdmin()->deleteJson("/api/admin/orang-tua/{$rahmawati->id_orang_tua}")
            ->assertStatus(409)
            ->assertJsonPath('message', 'Orang tua Ibu Rahmawati masih terhubung dengan siswa: Aisyah Putri. Lepaskan hubungan tersebut terlebih dahulu melalui menu Kelola Siswa.');
        $this->assertDatabaseHas('siswa_orang_tua', ['id_orang_tua' => $rahmawati->id_orang_tua]);

        // Ibu Siti punya catatan; walau relasi anak dilepas tetap ditolak
        $siti = $this->ortu('ortu');
        $siti->siswa()->detach();
        $this->sebagaiAdmin()->deleteJson("/api/admin/orang-tua/{$siti->id_orang_tua}")
            ->assertStatus(409)
            ->assertJsonPath('message', 'Orang tua Ibu Siti Nurhaliza memiliki 2 catatan penghubung. Data tidak dapat dihapus agar riwayat catatan tetap utuh; nonaktifkan akun sebagai gantinya.');
        $this->assertDatabaseCount('catatan_penghubung', 3);
    }
}
