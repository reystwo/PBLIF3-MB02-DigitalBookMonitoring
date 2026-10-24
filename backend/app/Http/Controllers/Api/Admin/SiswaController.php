<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Requests\Admin\SiswaRequest;
use App\Models\Siswa;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Kelola Siswa (khusus Admin): data siswa, kelas, dan relasi orang tua (siswa_orang_tua).
 */
class SiswaController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        $query = Siswa::with(['kelas', 'orangTua.user']);

        $keyword = $this->kataKunci($request);
        if ($keyword !== '') {
            $query->where(function ($q) use ($keyword) {
                $q->where('nama', 'LIKE', "%{$keyword}%")
                    ->orWhere('nis', 'LIKE', "%{$keyword}%");
            });
        }

        if ($request->filled('id_kelas')) {
            $query->where('id_kelas', (int) $request->query('id_kelas'));
        }

        $paginator = $query->orderBy('nama')
            ->orderBy('id_siswa')
            ->paginate($this->perPage($request));

        return $this->paginatedResponse($paginator, fn (Siswa $s) => $this->format($s), 'Daftar siswa berhasil dimuat');
    }

    public function show(Siswa $siswa): JsonResponse
    {
        $siswa->load(['kelas.waliGuru.user', 'orangTua.user']);

        return response()->json([
            'success' => true,
            'message' => 'Detail siswa berhasil dimuat',
            'data' => $this->format($siswa, detail: true),
        ], 200);
    }

    public function store(SiswaRequest $request): JsonResponse
    {
        $data = $request->validated();

        $siswa = DB::transaction(function () use ($data) {
            $siswa = Siswa::create([
                'nis' => $data['nis'],
                'nama' => $data['nama'],
                'jenis_kelamin' => $data['jenis_kelamin'],
                'id_kelas' => $data['id_kelas'],
            ]);

            $siswa->orangTua()->sync($this->dataPivotOrangTua($data['orang_tua'] ?? []));

            return $siswa;
        });

        $siswa->load(['kelas.waliGuru.user', 'orangTua.user']);

        return response()->json([
            'success' => true,
            'message' => "Siswa {$siswa->nama} berhasil ditambahkan",
            'data' => $this->format($siswa, detail: true),
        ], 201);
    }

    public function update(SiswaRequest $request, Siswa $siswa): JsonResponse
    {
        $data = $request->validated();

        DB::transaction(function () use ($siswa, $data) {
            $siswa->update(array_intersect_key($data, array_flip(['nis', 'nama', 'jenis_kelamin', 'id_kelas'])));

            // Relasi orang tua hanya disinkronkan bila field dikirim
            if (array_key_exists('orang_tua', $data)) {
                $siswa->orangTua()->sync($this->dataPivotOrangTua($data['orang_tua'] ?? []));
            }
        });

        $siswa->refresh()->load(['kelas.waliGuru.user', 'orangTua.user']);

        return response()->json([
            'success' => true,
            'message' => "Data siswa {$siswa->nama} berhasil diperbarui",
            'data' => $this->format($siswa, detail: true),
        ], 200);
    }

    public function destroy(Siswa $siswa): JsonResponse
    {
        $nama = $siswa->nama;
        $jumlahCatatan = $siswa->catatanPenghubung()->count();

        if ($jumlahCatatan > 0) {
            return $this->conflict("Siswa {$nama} memiliki {$jumlahCatatan} catatan penghubung. Data tidak dapat dihapus agar riwayat catatan tetap utuh.");
        }

        try {
            DB::transaction(function () use ($siswa) {
                // Hanya melepas relasi siswa_orang_tua; akun orang tua tetap ada
                $siswa->orangTua()->detach();
                $siswa->delete();
            });
        } catch (QueryException) {
            return $this->conflict("Siswa {$nama} tidak dapat dihapus karena masih digunakan oleh data lain.");
        }

        return response()->json([
            'success' => true,
            'message' => "Siswa {$nama} berhasil dihapus",
        ], 200);
    }

    /**
     * Ubah [{id_orang_tua, hubungan}] menjadi format sync() tabel pivot.
     */
    private function dataPivotOrangTua(array $daftar): array
    {
        return collect($daftar)
            ->mapWithKeys(fn ($o) => [(int) $o['id_orang_tua'] => ['hubungan' => $o['hubungan']]])
            ->all();
    }

    private function format(Siswa $s, bool $detail = false): array
    {
        $data = [
            'id_siswa' => $s->id_siswa,
            'nis' => $s->nis,
            'nama' => $s->nama,
            'jenis_kelamin' => $s->jenis_kelamin,
            'perempuan' => $s->perempuan,
            'id_kelas' => $s->id_kelas,
            'kelas' => $s->kelas?->nama_kelas ?? '',
            'tahun_ajaran' => $s->kelas?->tahun_ajaran ?? '',
            'orang_tua' => $s->orangTua->map(fn ($ot) => [
                'id_orang_tua' => $ot->id_orang_tua,
                'nama' => $ot->user?->nama ?? '',
                'no_hp' => $ot->no_hp,
                'hubungan' => $ot->pivot?->hubungan ?? 'Wali',
            ])->values()->all(),
        ];

        if ($detail) {
            $data['wali_kelas'] = $s->kelas?->waliGuru?->user?->nama ?? '';
            $data['jumlah_catatan'] = $s->catatanPenghubung()->count();
        }

        return $data;
    }
}
