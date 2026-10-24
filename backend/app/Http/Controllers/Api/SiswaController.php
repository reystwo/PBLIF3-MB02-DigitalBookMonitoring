<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kelas;
use App\Models\Siswa;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SiswaController extends Controller
{
    /**
     * Dapatkan daftar siswa dengan filter kelas dan pencarian (nama/nis).
     * Mematuhi aturan hak akses privasi SEC-02.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Siswa::with(['kelas', 'orangTua.user']);

        // Proteksi Privasi SEC-02: Orang Tua HANYA boleh melihat anaknya sendiri
        if ($user->role === 'orang_tua') {
            $idOrangTua = $user->orangTua?->id_orang_tua;
            if (! $idOrangTua) {
                return response()->json([
                    'success' => true,
                    'message' => 'Daftar siswa berhasil dimuat',
                    'data' => [],
                ], 200);
            }

            $query->whereHas('orangTua', function ($q) use ($idOrangTua) {
                $q->where('orang_tua.id_orang_tua', $idOrangTua);
            });
        }

        // Guru HANYA boleh melihat siswa di kelas yang ia ampu sebagai wali kelas
        if ($user->role === 'guru') {
            $query->tanggungJawabGuru($user->guru);
        }

        // Filter kelas (nama_kelas, misal: '5A', '5B')
        if ($request->filled('kelas')) {
            $namaKelas = $request->query('kelas');
            $query->whereHas('kelas', function ($q) use ($namaKelas) {
                $q->where('nama_kelas', $namaKelas);
            });
        }

        // Filter pencarian nama siswa atau NIS
        if ($request->filled('search')) {
            $keyword = $request->query('search');
            $query->where(function ($q) use ($keyword) {
                $q->where('nama', 'LIKE', "%{$keyword}%")
                    ->orWhere('nis', 'LIKE', "%{$keyword}%");
            });
        }

        $daftarSiswa = $query->orderBy('nama', 'ASC')->get();

        $data = $daftarSiswa->map(function ($s) {
            return [
                'id_siswa' => $s->id_siswa,
                'nis' => $s->nis,
                'nama' => $s->nama,
                'jenis_kelamin' => $s->jenis_kelamin,
                'perempuan' => $s->perempuan,
                'id_kelas' => $s->id_kelas,
                'kelas' => $s->kelas?->nama_kelas ?? '',
                'orang_tua' => $s->orangTua->map(function ($ot) {
                    return [
                        'id_orang_tua' => $ot->id_orang_tua,
                        'id_user' => $ot->id_user,
                        'nama' => $ot->user?->nama ?? '',
                        'hubungan' => $ot->pivot?->hubungan ?? 'Wali',
                        'no_hp' => $ot->no_hp,
                    ];
                })->values()->all(),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Daftar siswa berhasil dimuat',
            'data' => $data,
        ], 200);
    }

    /**
     * Dapatkan daftar seluruh kelas untuk filter chip di UI Flutter.
     */
    public function kelasList(): JsonResponse
    {
        $daftarKelas = Kelas::with(['waliGuru.user'])
            ->withCount('siswa')
            ->orderBy('nama_kelas', 'ASC')
            ->get();

        $data = $daftarKelas->map(function ($k) {
            return [
                'id_kelas' => $k->id_kelas,
                'nama_kelas' => $k->nama_kelas,
                'tingkat' => $k->tingkat,
                'tahun_ajaran' => $k->tahun_ajaran,
                'id_wali_guru' => $k->id_wali_guru,
                'wali_guru' => $k->waliGuru?->user?->nama ?? '',
                'total_siswa' => $k->siswa_count,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Daftar kelas berhasil dimuat',
            'data' => $data,
        ], 200);
    }
}
