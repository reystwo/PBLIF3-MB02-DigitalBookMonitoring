<?php

namespace Tests\Feature\Admin;

use App\Models\Guru;
use App\Models\Kelas;

class AdminKelasApiTest extends AdminApiTestCase
{
    private function idGuru(string $username): int
    {
        return Guru::whereHas('user', fn ($q) => $q->where('username', $username))->value('id_guru');
    }

    private function dataKelas(array $override = []): array
    {
        return array_merge([
            'nama_kelas' => '6A',
            'tingkat' => '6',
            'tahun_ajaran' => '2026/2027',
            'id_wali_guru' => $this->idGuru('guru_nurul'),
        ], $override);
    }

    public function test_crud_kelas_lengkap(): void
    {
        $id = $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas())
            ->assertCreated()
            ->assertJsonPath('message', 'Kelas 6A berhasil ditambahkan')
            ->assertJsonPath('data.wali_guru', 'Ibu Nurul Hidayah')
            ->assertJsonPath('data.total_siswa', 0)
            ->json('data.id_kelas');

        $this->assertDatabaseHas('kelas', ['id_kelas' => $id, 'nama_kelas' => '6A', 'id_wali_guru' => $this->idGuru('guru_nurul')]);

        // Ganti wali kelas
        $this->sebagaiAdmin()->putJson("/api/admin/kelas/{$id}", $this->dataKelas(['id_wali_guru' => $this->idGuru('guru')]))
            ->assertOk()
            ->assertJsonPath('data.wali_guru', 'Bapak Ahmad');

        // Detail beserta daftar siswa
        $id5A = Kelas::where('nama_kelas', '5A')->value('id_kelas');
        $this->sebagaiAdmin()->getJson("/api/admin/kelas/{$id5A}")
            ->assertOk()
            ->assertJsonPath('data.total_siswa', 4)
            ->assertJsonCount(4, 'data.siswa')
            ->assertJsonPath('data.siswa.0.nama', 'Ahmad Rizki');

        // Hapus kelas kosong
        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$id}")
            ->assertOk()
            ->assertJsonPath('message', 'Kelas 6A berhasil dihapus');
        $this->assertDatabaseMissing('kelas', ['id_kelas' => $id]);

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$id}")
            ->assertNotFound()
            ->assertJsonPath('message', 'Data kelas tidak ditemukan.');
    }

    public function test_nama_kelas_unik_per_tahun_ajaran(): void
    {
        $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas(['nama_kelas' => '5A']))
            ->assertStatus(422)
            ->assertJsonPath('errors.nama_kelas.0', 'Kelas dengan nama ini sudah ada pada tahun ajaran tersebut.');

        // Nama sama di tahun ajaran berbeda diperbolehkan
        $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas(['nama_kelas' => '5A', 'tahun_ajaran' => '2027/2028']))
            ->assertCreated();

        // Ubah kelas dengan nama miliknya sendiri tidak dianggap duplikat
        $kelas5A = Kelas::where('nama_kelas', '5A')->where('tahun_ajaran', '2026/2027')->first();
        $this->sebagaiAdmin()->putJson("/api/admin/kelas/{$kelas5A->id_kelas}", $this->dataKelas([
            'nama_kelas' => '5A', 'tingkat' => '5', 'id_wali_guru' => $kelas5A->id_wali_guru,
        ]))->assertOk();
    }

    public function test_validasi_kelas_menolak_input_tidak_valid(): void
    {
        $this->sebagaiAdmin()->postJson('/api/admin/kelas', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['nama_kelas', 'tingkat', 'tahun_ajaran', 'id_wali_guru'])
            ->assertJsonPath('errors.id_wali_guru.0', 'Wali kelas wajib dipilih.');

        $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas([
            'tahun_ajaran' => '2026-2027',
            'id_wali_guru' => 999999,
        ]))
            ->assertStatus(422)
            ->assertJsonPath('errors.tahun_ajaran.0', 'Format tahun ajaran harus YYYY/YYYY, contoh: 2026/2027.')
            ->assertJsonPath('errors.id_wali_guru.0', 'Wali kelas yang dipilih tidak ditemukan.');

        $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas(['tahun_ajaran' => '2026/2030']))
            ->assertStatus(422)
            ->assertJsonPath('errors.tahun_ajaran.0', 'Tahun ajaran harus berurutan, contoh: 2026/2027.');
    }

    public function test_pencarian_dan_pagination_kelas(): void
    {
        foreach (['6A', '6B', '4A'] as $nama) {
            $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas([
                'nama_kelas' => $nama, 'tingkat' => substr($nama, 0, 1),
            ]))->assertCreated();
        }

        $this->sebagaiAdmin()->getJson('/api/admin/kelas?per_page=2')
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 5)
            ->assertJsonPath('meta.last_page', 3);

        $this->sebagaiAdmin()->getJson('/api/admin/kelas?search=6B')
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.nama_kelas', '6B');

        // Berdasarkan nama wali kelas: 5B + 3 kelas baru diampu Bu Nurul
        $this->sebagaiAdmin()->getJson('/api/admin/kelas?search=Nurul')
            ->assertJsonPath('meta.total', 4);
    }

    public function test_hapus_kelas_dibatasi_jika_masih_memiliki_siswa(): void
    {
        $kelas5B = Kelas::where('nama_kelas', '5B')->first();

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$kelas5B->id_kelas}")
            ->assertStatus(409)
            ->assertJsonPath('message', 'Kelas 5B masih memiliki 3 siswa. Pindahkan siswa ke kelas lain terlebih dahulu melalui menu Kelola Siswa.');

        $this->assertDatabaseHas('kelas', ['id_kelas' => $kelas5B->id_kelas]);
        $this->assertDatabaseCount('siswa', 7);
    }
}
