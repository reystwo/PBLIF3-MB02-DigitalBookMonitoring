<?php

namespace App\Http\Controllers\Api\OrangTua;

use App\Http\Controllers\Controller;
use App\Models\Siswa;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Daftar anak (siswa) milik Orang Tua / Wali yang sedang login.
 * Cakupan data hanya siswa yang tertaut pada tabel pivot siswa_orang_tua
 * ke profil orang tua akun tersebut; akun lain tidak dapat melihatnya.
 */
class AnakController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orangTua = $request->user()->orangTua;

        // Akun tanpa profil orang tua belum memiliki anak tertaut -> daftar kosong
        $anak = $orangTua
            ? $orangTua->siswa()
                ->with('kelas.waliGuru.user')
                ->orderBy('siswa.nama')
                ->orderBy('siswa.id_siswa')
                ->get()
            : collect();

        return response()->json([
            'success' => true,
            'message' => 'Daftar anak berhasil dimuat',
            'data' => $anak->map(fn (Siswa $s) => $this->format($s))->values(),
        ], 200);
    }

    private function format(Siswa $s): array
    {
        return [
            'id_siswa' => $s->id_siswa,
            'nis' => $s->nis,
            'nama' => $s->nama,
            'jenis_kelamin' => $s->jenis_kelamin,
            'perempuan' => $s->perempuan,
            'id_kelas' => $s->id_kelas,
            'kelas' => $s->kelas?->nama_kelas ?? '',
            'tahun_ajaran' => $s->kelas?->tahun_ajaran ?? '',
            'wali_kelas' => $s->kelas?->waliGuru?->user?->nama ?? '',
            'hubungan' => $s->pivot?->hubungan ?? 'Wali',
        ];
    }
}
