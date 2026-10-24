<?php

namespace App\Http\Controllers\Api\Guru;

use App\Models\Siswa;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Daftar & detail siswa yang menjadi tanggung jawab Guru yang sedang login.
 */
class SiswaController extends GuruController
{
    public function index(Request $request): JsonResponse
    {
        $query = Siswa::with('kelas')
            ->withCount('catatanPenghubung')
            ->tanggungJawabGuru($request->user()->guru);

        $keyword = $this->kataKunci($request);
        if ($keyword !== '') {
            $query->where(function ($q) use ($keyword) {
                $q->where('nama', 'LIKE', "%{$keyword}%")
                    ->orWhere('nis', 'LIKE', "%{$keyword}%");
            });
        }

        $paginator = $query->orderBy('nama')
            ->orderBy('id_siswa')
            ->paginate($this->perPage($request));

        return $this->paginatedResponse($paginator, fn (Siswa $s) => $this->format($s), 'Daftar siswa berhasil dimuat');
    }

    public function show(Request $request, Siswa $siswa): JsonResponse
    {
        $this->pastikanTanggungJawab($request, $siswa);

        $siswa->load(['kelas.waliGuru.user', 'orangTua.user'])->loadCount('catatanPenghubung');

        return response()->json([
            'success' => true,
            'message' => 'Detail siswa berhasil dimuat',
            'data' => $this->format($siswa, detail: true),
        ], 200);
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
            'jumlah_catatan' => (int) $s->catatan_penghubung_count,
        ];

        if ($detail) {
            $data['wali_kelas'] = $s->kelas?->waliGuru?->user?->nama ?? '';
            $data['orang_tua'] = $s->orangTua->map(fn ($ot) => [
                'id_orang_tua' => $ot->id_orang_tua,
                'nama' => $ot->user?->nama ?? '',
                'no_hp' => $ot->no_hp,
                'hubungan' => $ot->pivot?->hubungan ?? 'Wali',
            ])->values()->all();
        }

        return $data;
    }
}
