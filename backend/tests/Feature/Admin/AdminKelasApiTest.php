<?php

namespace Tests\Feature\Admin;

use App\Models\Guru;
use App\Models\Kelas;
use App\Models\Siswa;

class AdminKelasApiTest extends AdminApiTestCase
{
    private function idGuru(string $username): int
    {
        return Guru::whereHas('user', fn ($q) => $q->where('username', $username))->value('id_guru');
    }

    private function dataKelas(array $override = []): array
    {
        return array_merge([
            'nama_kelas' => '8A',
            'tingkat' => '8',
            'tahun_ajaran' => '2026/2027',
            'id_wali_guru' => $this->idGuru('guru_nurul'),
        ], $override);
    }

    public function test_crud_kelas_lengkap(): void
    {
        $id = $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas())
            ->assertCreated()
            ->assertJsonPath('message', 'Kelas 8A berhasil ditambahkan')
            ->assertJsonPath('data.wali_guru', 'Ibu Nurul Hidayah')
            ->assertJsonPath('data.total_siswa', 0)
            ->json('data.id_kelas');

        $this->assertDatabaseHas('kelas', ['id_kelas' => $id, 'nama_kelas' => '8A', 'id_wali_guru' => $this->idGuru('guru_nurul')]);

        // Ganti wali kelas
        $this->sebagaiAdmin()->putJson("/api/admin/kelas/{$id}", $this->dataKelas(['id_wali_guru' => $this->idGuru('guru')]))
            ->assertOk()
            ->assertJsonPath('data.wali_guru', 'Bapak Ahmad');

        // Detail beserta daftar siswa
        $id7A = Kelas::where('nama_kelas', '7A')->value('id_kelas');
        $this->sebagaiAdmin()->getJson("/api/admin/kelas/{$id7A}")
            ->assertOk()
            ->assertJsonPath('data.total_siswa', 4)
            ->assertJsonCount(4, 'data.siswa')
            ->assertJsonPath('data.siswa.0.nama', 'Ahmad Rizki');

        // Hapus kelas kosong
        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$id}")
            ->assertOk()
            ->assertJsonPath('message', 'Kelas 8A berhasil dihapus');
        $this->assertDatabaseMissing('kelas', ['id_kelas' => $id]);

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$id}")
            ->assertNotFound()
            ->assertJsonPath('message', 'Data kelas tidak ditemukan.');
    }

    public function test_nama_kelas_unik_per_tahun_ajaran(): void
    {
        $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas(['nama_kelas' => '7A']))
            ->assertStatus(422)
            ->assertJsonPath('errors.nama_kelas.0', 'Kelas dengan nama ini sudah ada pada tahun ajaran tersebut.');

        // Nama sama di tahun ajaran berbeda diperbolehkan
        $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas(['nama_kelas' => '7A', 'tahun_ajaran' => '2027/2028']))
            ->assertCreated();

        // Ubah kelas dengan nama miliknya sendiri tidak dianggap duplikat
        $kelas7A = Kelas::where('nama_kelas', '7A')->where('tahun_ajaran', '2026/2027')->first();
        $this->sebagaiAdmin()->putJson("/api/admin/kelas/{$kelas7A->id_kelas}", $this->dataKelas([
            'nama_kelas' => '7A', 'tingkat' => '7', 'id_wali_guru' => $kelas7A->id_wali_guru,
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
        foreach (['8A', '8B', '9A'] as $nama) {
            $this->sebagaiAdmin()->postJson('/api/admin/kelas', $this->dataKelas([
                'nama_kelas' => $nama, 'tingkat' => substr($nama, 0, 1),
            ]))->assertCreated();
        }

        $this->sebagaiAdmin()->getJson('/api/admin/kelas?per_page=2')
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 5)
            ->assertJsonPath('meta.last_page', 3);

        $this->sebagaiAdmin()->getJson('/api/admin/kelas?search=8B')
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.nama_kelas', '8B');

        // Berdasarkan nama wali kelas: 7B + 3 kelas baru diampu Bu Nurul
        $this->sebagaiAdmin()->getJson('/api/admin/kelas?search=Nurul')
            ->assertJsonPath('meta.total', 4);
    }

    public function test_hapus_kelas_dibatasi_jika_masih_memiliki_siswa(): void
    {
        $kelas7B = Kelas::where('nama_kelas', '7B')->first();

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$kelas7B->id_kelas}")
            ->assertStatus(409)
            ->assertJsonPath('message', 'Kelas 7B masih memiliki 3 siswa. Pindahkan siswa ke kelas lain terlebih dahulu melalui menu Kelola Siswa.');

        $this->assertDatabaseHas('kelas', ['id_kelas' => $kelas7B->id_kelas]);
        $this->assertDatabaseCount('siswa', 7);
    }

    public function test_keluarkan_siswa_dari_kelas_tanpa_menghapus_data_siswa(): void
    {
        $kelas7A = Kelas::where('nama_kelas', '7A')->first();
        $siswa = Siswa::where('nama', 'Ahmad Rizki')->first();
        $jumlahOrangTua = $siswa->orangTua()->count();
        $jumlahCatatan = $siswa->catatanPenghubung()->count();
        $this->assertGreaterThan(0, $jumlahOrangTua);
        $this->assertGreaterThan(0, $jumlahCatatan);

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$kelas7A->id_kelas}/siswa/{$siswa->id_siswa}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Siswa Ahmad Rizki berhasil dikeluarkan dari kelas 7A')
            ->assertJsonPath('data.total_siswa', 3);

        // Hanya relasi kelas yang dilepas; data siswa, orang tua, dan catatan tetap utuh
        $this->assertDatabaseHas('siswa', ['id_siswa' => $siswa->id_siswa, 'nis' => '1001', 'nama' => 'Ahmad Rizki', 'id_kelas' => null]);
        $this->assertDatabaseCount('siswa', 7);
        $this->assertSame($jumlahOrangTua, $siswa->orangTua()->count());
        $this->assertSame($jumlahCatatan, $siswa->catatanPenghubung()->count());

        // Siswa tidak lagi muncul di daftar siswa kelas tersebut
        $this->sebagaiAdmin()->getJson("/api/admin/kelas/{$kelas7A->id_kelas}")
            ->assertOk()
            ->assertJsonPath('data.total_siswa', 3)
            ->assertJsonCount(3, 'data.siswa')
            ->assertJsonMissing(['nama' => 'Ahmad Rizki']);

        // Data siswa tetap dapat dibuka dan ditempatkan kembali ke kelas
        $this->sebagaiAdmin()->getJson("/api/admin/siswa/{$siswa->id_siswa}")
            ->assertOk()
            ->assertJsonPath('data.id_kelas', null)
            ->assertJsonPath('data.kelas', '');
    }

    public function test_keluarkan_siswa_yang_tidak_terdaftar_di_kelas_ditolak(): void
    {
        $kelas7A = Kelas::where('nama_kelas', '7A')->first();
        $kelas7B = Kelas::where('nama_kelas', '7B')->first();
        $siswa7B = Siswa::where('id_kelas', $kelas7B->id_kelas)->first();

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$kelas7A->id_kelas}/siswa/{$siswa7B->id_siswa}")
            ->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', "Siswa {$siswa7B->nama} tidak terdaftar di kelas 7A.");
        $this->assertDatabaseHas('siswa', ['id_siswa' => $siswa7B->id_siswa, 'id_kelas' => $kelas7B->id_kelas]);

        $this->sebagaiAdmin()->deleteJson("/api/admin/kelas/{$kelas7A->id_kelas}/siswa/999999")
            ->assertNotFound()
            ->assertJsonPath('message', 'Data kelas atau siswa tidak ditemukan.');
    }
}
