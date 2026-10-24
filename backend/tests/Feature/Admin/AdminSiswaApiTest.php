<?php

namespace Tests\Feature\Admin;

use App\Models\Kelas;
use App\Models\OrangTua;
use App\Models\Siswa;

class AdminSiswaApiTest extends AdminApiTestCase
{
    private function idKelas(string $nama): int
    {
        return Kelas::where('nama_kelas', $nama)->value('id_kelas');
    }

    private function idOrtu(string $username): int
    {
        return OrangTua::whereHas('user', fn ($q) => $q->where('username', $username))->value('id_orang_tua');
    }

    private function dataSiswa(array $override = []): array
    {
        return array_merge([
            'nis' => '2001',
            'nama' => 'Zahra Amalia',
            'jenis_kelamin' => 'P',
            'id_kelas' => $this->idKelas('5B'),
            'orang_tua' => [
                ['id_orang_tua' => $this->idOrtu('ortu_citra'), 'hubungan' => 'Ibu'],
            ],
        ], $override);
    }

    public function test_tambah_siswa_beserta_relasi_orang_tua(): void
    {
        $response = $this->sebagaiAdmin()->postJson('/api/admin/siswa', $this->dataSiswa());

        $response->assertCreated()
            ->assertJson([
                'success' => true,
                'message' => 'Siswa Zahra Amalia berhasil ditambahkan',
                'data' => [
                    'nis' => '2001',
                    'kelas' => '5B',
                    'perempuan' => true,
                    'wali_kelas' => 'Ibu Nurul Hidayah',
                    'orang_tua' => [['nama' => 'Ibu Dewi Lestari', 'hubungan' => 'Ibu']],
                ],
            ]);

        $idSiswa = $response->json('data.id_siswa');
        $this->assertDatabaseHas('siswa_orang_tua', [
            'id_siswa' => $idSiswa,
            'id_orang_tua' => $this->idOrtu('ortu_citra'),
            'hubungan' => 'Ibu',
        ]);

        // Relasi konsisten: orang tua kini melihat anak barunya, dan guru 5B melihat siswa barunya
        $this->sebagai('ortu_citra')->getJson('/api/siswa')
            ->assertOk()
            ->assertJsonCount(2, 'data');
        $this->sebagai('guru_nurul')->getJson('/api/siswa?kelas=5B')
            ->assertJsonFragment(['nama' => 'Zahra Amalia']);
    }

    public function test_validasi_siswa_menolak_input_tidak_valid_dan_duplikat(): void
    {
        $this->sebagaiAdmin()->postJson('/api/admin/siswa', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['nis', 'nama', 'jenis_kelamin', 'id_kelas']);

        // NIS duplikat, kelas tidak ada, jenis kelamin salah
        $this->sebagaiAdmin()->postJson('/api/admin/siswa', $this->dataSiswa([
            'nis' => '1001',
            'id_kelas' => 999999,
            'jenis_kelamin' => 'X',
        ]))
            ->assertStatus(422)
            ->assertJsonPath('errors.nis.0', 'NIS sudah digunakan.')
            ->assertJsonPath('errors.id_kelas.0', 'Kelas yang dipilih tidak ditemukan.')
            ->assertJsonPath('errors.jenis_kelamin.0', 'Jenis kelamin harus Laki-laki (L) atau Perempuan (P).');

        // Orang tua tidak ada, hubungan tidak valid, orang tua dipilih dua kali
        $idCitra = $this->idOrtu('ortu_citra');
        $this->sebagaiAdmin()->postJson('/api/admin/siswa', $this->dataSiswa([
            'orang_tua' => [
                ['id_orang_tua' => $idCitra, 'hubungan' => 'Ibu'],
                ['id_orang_tua' => $idCitra, 'hubungan' => 'Tetangga'],
                ['id_orang_tua' => 999999, 'hubungan' => 'Ayah'],
            ],
        ]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['orang_tua.0.id_orang_tua', 'orang_tua.1.hubungan', 'orang_tua.2.id_orang_tua']);

        $this->assertDatabaseMissing('siswa', ['nis' => '2001']);
    }

    public function test_ubah_siswa_pindah_kelas_dan_sinkron_orang_tua(): void
    {
        $budi = Siswa::where('nis', '1003')->first();

        $this->sebagaiAdmin()->putJson("/api/admin/siswa/{$budi->id_siswa}", [
            'nis' => '1003',
            'nama' => 'Budi Santoso Putra',
            'jenis_kelamin' => 'L',
            'id_kelas' => $this->idKelas('5B'),
            'orang_tua' => [
                ['id_orang_tua' => $this->idOrtu('ortu_budi'), 'hubungan' => 'Ayah'],
                ['id_orang_tua' => $this->idOrtu('ortu_dani'), 'hubungan' => 'Wali'],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('data.kelas', '5B')
            ->assertJsonCount(2, 'data.orang_tua');

        $this->assertDatabaseHas('siswa', ['id_siswa' => $budi->id_siswa, 'nama' => 'Budi Santoso Putra', 'id_kelas' => $this->idKelas('5B')]);
        $this->assertDatabaseHas('siswa_orang_tua', ['id_siswa' => $budi->id_siswa, 'id_orang_tua' => $this->idOrtu('ortu_dani'), 'hubungan' => 'Wali']);

        // Tanpa field orang_tua -> relasi tidak berubah
        $this->sebagaiAdmin()->putJson("/api/admin/siswa/{$budi->id_siswa}", [
            'nis' => '1003', 'nama' => 'Budi Santoso', 'jenis_kelamin' => 'L', 'id_kelas' => $this->idKelas('5A'),
        ])->assertOk()->assertJsonCount(2, 'data.orang_tua');

        // Daftar kosong -> seluruh relasi orang tua dilepas (akun orang tua tetap ada)
        $this->sebagaiAdmin()->putJson("/api/admin/siswa/{$budi->id_siswa}", [
            'nis' => '1003', 'nama' => 'Budi Santoso', 'jenis_kelamin' => 'L', 'id_kelas' => $this->idKelas('5A'), 'orang_tua' => [],
        ])->assertOk()->assertJsonCount(0, 'data.orang_tua');
        $this->assertDatabaseMissing('siswa_orang_tua', ['id_siswa' => $budi->id_siswa]);
        $this->assertDatabaseHas('orang_tua', ['id_orang_tua' => $this->idOrtu('ortu_budi')]);
    }

    public function test_pencarian_filter_kelas_dan_pagination_siswa(): void
    {
        $this->sebagaiAdmin()->getJson('/api/admin/siswa?per_page=3')
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('meta.total', 7)
            ->assertJsonPath('meta.last_page', 3)
            ->assertJsonPath('data.0.nama', 'Ahmad Rizki');

        $this->sebagaiAdmin()->getJson('/api/admin/siswa?per_page=3&page=3')
            ->assertJsonCount(1, 'data');

        $this->sebagaiAdmin()->getJson('/api/admin/siswa?search=1004')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nama', 'Citra Lestari');

        $this->sebagaiAdmin()->getJson('/api/admin/siswa?search=aisyah')
            ->assertJsonCount(2, 'data');

        $this->sebagaiAdmin()->getJson('/api/admin/siswa?id_kelas='.$this->idKelas('5B'))
            ->assertJsonPath('meta.total', 3);
    }

    public function test_hapus_siswa_dibatasi_jika_memiliki_catatan(): void
    {
        $rizki = Siswa::where('nis', '1001')->first();
        $this->sebagaiAdmin()->deleteJson("/api/admin/siswa/{$rizki->id_siswa}")
            ->assertStatus(409)
            ->assertJsonPath('message', 'Siswa Ahmad Rizki memiliki 2 catatan penghubung. Data tidak dapat dihapus agar riwayat catatan tetap utuh.');
        $this->assertDatabaseHas('siswa', ['id_siswa' => $rizki->id_siswa]);

        // Siswa tanpa catatan dapat dihapus; akun orang tua tetap ada
        $citra = Siswa::where('nis', '1004')->first();
        $idOrtuCitra = $this->idOrtu('ortu_citra');
        $this->sebagaiAdmin()->deleteJson("/api/admin/siswa/{$citra->id_siswa}")
            ->assertOk()
            ->assertJsonPath('message', 'Siswa Citra Lestari berhasil dihapus');
        $this->assertDatabaseMissing('siswa', ['id_siswa' => $citra->id_siswa]);
        $this->assertDatabaseMissing('siswa_orang_tua', ['id_siswa' => $citra->id_siswa]);
        $this->assertDatabaseHas('orang_tua', ['id_orang_tua' => $idOrtuCitra]);
    }
}
