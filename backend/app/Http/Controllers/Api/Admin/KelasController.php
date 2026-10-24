<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Requests\Admin\KelasRequest;
use App\Models\Kelas;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Kelola Kelas (khusus Admin): rombongan belajar dan wali kelas (kelas.id_wali_guru).
 */
class KelasController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        $query = Kelas::with('waliGuru.user')->withCount('siswa');

        $keyword = $this->kataKunci($request);
        if ($keyword !== '') {
            $query->where(function ($q) use ($keyword) {
                $q->where('nama_kelas', 'LIKE', "%{$keyword}%")
                    ->orWhere('tingkat', 'LIKE', "%{$keyword}%")
                    ->orWhere('tahun_ajaran', 'LIKE', "%{$keyword}%")
                    ->orWhereHas('waliGuru.user', function ($uq) use ($keyword) {
                        $uq->where('nama', 'LIKE', "%{$keyword}%");
                    });
            });
        }

        $paginator = $query->orderByDesc('tahun_ajaran')
            ->orderBy('nama_kelas')
            ->orderBy('id_kelas')
            ->paginate($this->perPage($request));

        return $this->paginatedResponse($paginator, fn (Kelas $k) => $this->format($k), 'Daftar kelas berhasil dimuat');
    }

    public function show(Kelas $kelas): JsonResponse
    {
        $kelas->load(['waliGuru.user', 'siswa' => fn ($q) => $q->orderBy('nama')])->loadCount('siswa');

        return response()->json([
            'success' => true,
            'message' => 'Detail kelas berhasil dimuat',
            'data' => $this->format($kelas, detail: true),
        ], 200);
    }

    public function store(KelasRequest $request): JsonResponse
    {
        $kelas = Kelas::create($request->safe()->only(['nama_kelas', 'tingkat', 'tahun_ajaran', 'id_wali_guru']));
        $kelas->load(['waliGuru.user', 'siswa'])->loadCount('siswa');

        return response()->json([
            'success' => true,
            'message' => "Kelas {$kelas->nama_kelas} berhasil ditambahkan",
            'data' => $this->format($kelas, detail: true),
        ], 201);
    }

    public function update(KelasRequest $request, Kelas $kelas): JsonResponse
    {
        $kelas->update($request->safe()->only(['nama_kelas', 'tingkat', 'tahun_ajaran', 'id_wali_guru']));
        $kelas->refresh()->load(['waliGuru.user', 'siswa' => fn ($q) => $q->orderBy('nama')])->loadCount('siswa');

        return response()->json([
            'success' => true,
            'message' => "Data kelas {$kelas->nama_kelas} berhasil diperbarui",
            'data' => $this->format($kelas, detail: true),
        ], 200);
    }

    public function destroy(Kelas $kelas): JsonResponse
    {
        $nama = $kelas->nama_kelas;
        $jumlahSiswa = $kelas->siswa()->count();

        if ($jumlahSiswa > 0) {
            return $this->conflict("Kelas {$nama} masih memiliki {$jumlahSiswa} siswa. Pindahkan siswa ke kelas lain terlebih dahulu melalui menu Kelola Siswa.");
        }

        try {
            $kelas->delete();
        } catch (QueryException) {
            return $this->conflict("Kelas {$nama} tidak dapat dihapus karena masih digunakan oleh data lain.");
        }

        return response()->json([
            'success' => true,
            'message' => "Kelas {$nama} berhasil dihapus",
        ], 200);
    }

    private function format(Kelas $k, bool $detail = false): array
    {
        $data = [
            'id_kelas' => $k->id_kelas,
            'nama_kelas' => $k->nama_kelas,
            'tingkat' => $k->tingkat,
            'tahun_ajaran' => $k->tahun_ajaran,
            'id_wali_guru' => $k->id_wali_guru,
            'wali_guru' => $k->waliGuru?->user?->nama ?? '',
            'nip_wali_guru' => $k->waliGuru?->nip ?? '',
            'total_siswa' => (int) ($k->siswa_count ?? 0),
        ];

        if ($detail) {
            $data['siswa'] = $k->siswa->map(fn ($s) => [
                'id_siswa' => $s->id_siswa,
                'nis' => $s->nis,
                'nama' => $s->nama,
                'perempuan' => $s->perempuan,
            ])->values()->all();
        }

        return $data;
    }
}
