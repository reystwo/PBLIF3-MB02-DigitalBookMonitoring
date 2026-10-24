<?php

namespace Tests\Feature\Admin;

use App\Models\Guru;
use App\Models\Kelas;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminGuruApiTest extends AdminApiTestCase
{
    private function dataGuru(array $override = []): array
    {
        return array_merge([
            'nama' => 'Ibu Rina Marlina, S.Pd',
            'username' => 'guru_rina',
            'password' => 'rahasia123',
            'nip' => '199203142019032001',
            'no_hp' => '081311112222',
        ], $override);
    }

    public function test_admin_dapat_menambah_guru_dan_tersimpan_di_database(): void
    {
        $response = $this->sebagaiAdmin()->postJson('/api/admin/guru', $this->dataGuru());

        $response->assertCreated()
            ->assertJson([
                'success' => true,
                'message' => 'Guru Ibu Rina Marlina, S.Pd berhasil ditambahkan',
                'data' => ['username' => 'guru_rina', 'nip' => '199203142019032001', 'status' => 'aktif'],
            ])
            ->assertJsonMissingPath('data.password');

        $user = User::where('username', 'guru_rina')->first();
        $this->assertSame('guru', $user->role);
        $this->assertTrue(Hash::check('rahasia123', $user->password));
        $this->assertDatabaseHas('guru', ['id_user' => $user->id_user, 'nip' => '199203142019032001']);

        // Guru baru dapat login
        $this->postJson('/api/login', ['username' => 'guru_rina', 'password' => 'rahasia123', 'role' => 'guru'])
            ->assertOk();
    }

    public function test_daftar_guru_mendukung_pagination_dan_pencarian(): void
    {
        for ($i = 1; $i <= 12; $i++) {
            $this->sebagaiAdmin()->postJson('/api/admin/guru', $this->dataGuru([
                'nama' => "Guru Uji {$i}",
                'username' => "guru_uji_{$i}",
                'nip' => '1990000000'.str_pad((string) $i, 4, '0', STR_PAD_LEFT),
            ]))->assertCreated();
        }

        // 2 guru seeder + 12 guru baru = 14
        $halaman1 = $this->sebagaiAdmin()->getJson('/api/admin/guru?per_page=10');
        $halaman1->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonPath('meta.total', 14)
            ->assertJsonPath('meta.last_page', 2);

        $this->sebagaiAdmin()->getJson('/api/admin/guru?per_page=10&page=2')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('meta.current_page', 2);

        // Batas maksimal per_page
        $this->sebagaiAdmin()->getJson('/api/admin/guru?per_page=1000')
            ->assertJsonPath('meta.per_page', 50);

        // Cari berdasarkan nama, username, dan NIP
        $this->sebagaiAdmin()->getJson('/api/admin/guru?search=Nurul')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.username', 'guru_nurul')
            ->assertJsonPath('data.0.kelas_wali.0.nama_kelas', '5B');

        $this->sebagaiAdmin()->getJson('/api/admin/guru?search=198501152010011002')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nama', 'Bapak Ahmad');

        $this->sebagaiAdmin()->getJson('/api/admin/guru?search=tidak-ada-yang-cocok')
            ->assertOk()
            ->assertJsonCount(0, 'data')
            ->assertJsonPath('meta.total', 0);

        // Parameter search berbentuk array tidak menyebabkan error
        $this->sebagaiAdmin()->getJson('/api/admin/guru?search[]=x')->assertOk();
    }

    public function test_detail_guru_dan_404_untuk_data_yang_tidak_ada(): void
    {
        $guru = Guru::whereHas('user', fn ($q) => $q->where('username', 'guru'))->first();

        $this->sebagaiAdmin()->getJson("/api/admin/guru/{$guru->id_guru}")
            ->assertOk()
            ->assertJsonPath('data.nama', 'Bapak Ahmad')
            ->assertJsonPath('data.kelas_wali.0.nama_kelas', '5A')
            ->assertJsonPath('data.jumlah_catatan', 3)
            ->assertJsonMissingPath('data.password');

        $this->sebagaiAdmin()->getJson('/api/admin/guru/999999')
            ->assertNotFound()
            ->assertJson(['success' => false, 'message' => 'Data guru tidak ditemukan.']);
    }

    public function test_validasi_input_dan_duplikat_ditolak(): void
    {
        // Field wajib kosong
        $this->sebagaiAdmin()->postJson('/api/admin/guru', [])
            ->assertStatus(422)
            ->assertJson(['success' => false, 'message' => 'Nama wajib diisi.'])
            ->assertJsonValidationErrors(['nama', 'username', 'password', 'nip']);

        // Username & NIP duplikat
        $this->sebagaiAdmin()->postJson('/api/admin/guru', $this->dataGuru([
            'username' => 'guru',
            'nip' => '198501152010011002',
        ]))
            ->assertStatus(422)
            ->assertJsonPath('errors.username.0', 'Username sudah digunakan.')
            ->assertJsonPath('errors.nip.0', 'NIP sudah digunakan.');

        // Format tidak valid
        $this->sebagaiAdmin()->postJson('/api/admin/guru', $this->dataGuru([
            'username' => 'ada spasi',
            'nip' => '12AB',
            'password' => 'pendek',
            'no_hp' => 'abc',
            'status' => 'superadmin',
        ]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['username', 'nip', 'password', 'no_hp', 'status'])
            ->assertJsonPath('errors.password.0', 'Kata sandi minimal 8 karakter.')
            ->assertJsonPath('errors.nip.0', 'NIP hanya boleh berisi angka.');

        $this->assertDatabaseMissing('users', ['username' => 'guru_rina']);
    }

    public function test_admin_dapat_mengubah_guru_tanpa_mengganti_kata_sandi(): void
    {
        $guru = Guru::whereHas('user', fn ($q) => $q->where('username', 'guru_nurul'))->first();
        $hashLama = $guru->user->password;

        // Mengirim username & NIP milik sendiri tidak dianggap duplikat
        $this->sebagaiAdmin()->putJson("/api/admin/guru/{$guru->id_guru}", [
            'nama' => 'Ibu Nurul Hidayah, M.Pd',
            'username' => 'guru_nurul',
            'nip' => $guru->nip,
            'no_hp' => '089900001111',
            'password' => '',
        ])
            ->assertOk()
            ->assertJsonPath('data.nama', 'Ibu Nurul Hidayah, M.Pd')
            ->assertJsonPath('data.no_hp', '089900001111');

        $guru->refresh();
        $this->assertSame('Ibu Nurul Hidayah, M.Pd', $guru->user->nama);
        $this->assertSame($hashLama, $guru->user->password);

        // Username milik guru lain tetap ditolak
        $this->sebagaiAdmin()->putJson("/api/admin/guru/{$guru->id_guru}", [
            'nama' => 'X', 'username' => 'guru', 'nip' => $guru->nip,
        ])->assertStatus(422)->assertJsonValidationErrors(['username']);
    }

    public function test_ganti_kata_sandi_atau_nonaktifkan_akun_mencabut_token_login(): void
    {
        $guru = Guru::whereHas('user', fn ($q) => $q->where('username', 'guru'))->first();
        $tokenGuru = $guru->user->createToken('hp-guru')->plainTextToken;

        $this->sebagaiAdmin()->putJson("/api/admin/guru/{$guru->id_guru}", [
            'nama' => $guru->user->nama,
            'username' => 'guru',
            'nip' => $guru->nip,
            'password' => 'sandiBaru123',
        ])->assertOk();

        $this->assertSame(0, $guru->user->tokens()->count());
        $this->denganToken($tokenGuru)->getJson('/api/me')->assertStatus(401);
        $this->postJson('/api/login', ['username' => 'guru', 'password' => 'sandiBaru123'])->assertOk();

        // Nonaktifkan akun -> token dicabut dan tidak bisa login
        $this->sebagaiAdmin()->putJson("/api/admin/guru/{$guru->id_guru}", [
            'nama' => $guru->user->nama,
            'username' => 'guru',
            'nip' => $guru->nip,
            'status' => 'nonaktif',
        ])->assertOk()->assertJsonPath('data.status', 'nonaktif');

        $this->assertSame(0, $guru->user->tokens()->count());
        $this->postJson('/api/login', ['username' => 'guru', 'password' => 'sandiBaru123'])->assertStatus(403);
    }

    public function test_hapus_guru_dibatasi_jika_masih_wali_kelas_atau_memiliki_catatan(): void
    {
        $ahmad = Guru::whereHas('user', fn ($q) => $q->where('username', 'guru'))->first();
        $nurul = Guru::whereHas('user', fn ($q) => $q->where('username', 'guru_nurul'))->first();

        // Masih wali kelas 5B
        $this->sebagaiAdmin()->deleteJson("/api/admin/guru/{$nurul->id_guru}")
            ->assertStatus(409)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Guru Ibu Nurul Hidayah masih menjadi wali kelas 5B. Ganti wali kelas tersebut terlebih dahulu melalui menu Kelola Kelas.');
        $this->assertDatabaseHas('guru', ['id_guru' => $nurul->id_guru]);

        // Setelah wali kelas 5B dipindah, Bu Nurul (tanpa catatan) dapat dihapus
        Kelas::where('nama_kelas', '5B')->update(['id_wali_guru' => $ahmad->id_guru]);
        $idUserNurul = $nurul->id_user;
        $this->sebagaiAdmin()->deleteJson("/api/admin/guru/{$nurul->id_guru}")
            ->assertOk()
            ->assertJson(['success' => true, 'message' => 'Guru Ibu Nurul Hidayah berhasil dihapus']);
        $this->assertDatabaseMissing('guru', ['id_guru' => $nurul->id_guru]);
        $this->assertDatabaseMissing('users', ['id_user' => $idUserNurul]);

        // Pak Ahmad memiliki catatan -> ditolak walau wali kelas dipindahkan
        $guruBaru = $this->sebagaiAdmin()->postJson('/api/admin/guru', $this->dataGuru())->json('data.id_guru');
        Kelas::query()->update(['id_wali_guru' => $guruBaru]);
        $this->sebagaiAdmin()->deleteJson("/api/admin/guru/{$ahmad->id_guru}")
            ->assertStatus(409)
            ->assertJsonPath('message', 'Guru Bapak Ahmad memiliki 3 catatan penghubung. Data tidak dapat dihapus agar riwayat catatan tetap utuh; nonaktifkan akun sebagai gantinya.');
        $this->assertDatabaseCount('catatan_penghubung', 3);
    }
}
