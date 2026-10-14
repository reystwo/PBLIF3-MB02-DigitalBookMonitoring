<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CatatanPenghubung;
use App\Models\Guru;
use App\Models\Kelas;
use App\Models\OrangTua;
use App\Models\Siswa;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Dapatkan data ringkasan dashboard sesuai role yang sedang login.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role === 'guru') {
            $user->loadMissing(['guru.kelasWali.siswa']);
            $guru = $user->guru;
            $kelasWali = $guru?->kelasWali?->first();
            $kelasWaliIds = $guru?->kelasWali?->pluck('id_kelas') ?? collect();

            $totalSiswa = Siswa::whereIn('id_kelas', $kelasWaliIds)->count();
            $totalCatatanTerkirim = CatatanPenghubung::where('id_pengirim', $user->id_user)->count();
            $catatanBelumDibaca = CatatanPenghubung::where('id_penerima', $user->id_user)
                ->where('status_dibaca', 'belum_dibaca')
                ->count();

            $catatanTerbaru = CatatanPenghubung::with(['siswa', 'pengirim', 'penerima'])
                ->where(function ($q) use ($user, $kelasWaliIds) {
                    $q->where('id_pengirim', $user->id_user)
                        ->orWhere('id_penerima', $user->id_user)
                        ->orWhereHas('siswa', function ($sq) use ($kelasWaliIds) {
                            $sq->whereIn('id_kelas', $kelasWaliIds);
                        });
                })
                ->orderBy('tanggal', 'DESC')
                ->limit(5)
                ->get()
                ->map(fn ($c) => $this->formatMiniCatatan($c));

            return response()->json([
                'success' => true,
                'message' => 'Dashboard guru berhasil dimuat',
                'data' => [
                    'role' => 'guru',
                    'nama_guru' => $user->nama,
                    'nip' => $guru?->nip ?? '',
                    'kelas_wali' => $kelasWali ? [
                        'id_kelas' => $kelasWali->id_kelas,
                        'nama_kelas' => $kelasWali->nama_kelas,
                        'tingkat' => $kelasWali->tingkat,
                        'tahun_ajaran' => $kelasWali->tahun_ajaran,
                    ] : null,
                    'statistik' => [
                        'total_siswa' => $totalSiswa,
                        'total_catatan_terkirim' => $totalCatatanTerkirim,
                        'catatan_belum_dibaca' => $catatanBelumDibaca,
                    ],
                    'catatan_terbaru' => $catatanTerbaru,
                ],
            ], 200);
        }

        if ($user->role === 'orang_tua') {
            $user->loadMissing(['orangTua.siswa.kelas']);
            $idOrangTua = $user->orangTua?->id_orang_tua;

            $anakList = Siswa::with('kelas')
                ->whereHas('orangTua', function ($q) use ($idOrangTua) {
                    $q->where('orang_tua.id_orang_tua', $idOrangTua);
                })
                ->get();

            $anakIds = $anakList->pluck('id_siswa');

            $totalCatatanAnak = CatatanPenghubung::whereIn('id_siswa', $anakIds)->count();
            $catatanBelumDibaca = CatatanPenghubung::where('id_penerima', $user->id_user)
                ->where('status_dibaca', 'belum_dibaca')
                ->count();

            $catatanTerbaru = CatatanPenghubung::with(['siswa', 'pengirim'])
                ->whereIn('id_siswa', $anakIds)
                ->orderBy('tanggal', 'DESC')
                ->limit(5)
                ->get()
                ->map(fn ($c) => $this->formatMiniCatatan($c));

            return response()->json([
                'success' => true,
                'message' => 'Dashboard orang tua berhasil dimuat',
                'data' => [
                    'role' => 'orang_tua',
                    'nama_orang_tua' => $user->nama,
                    'anak' => $anakList->map(function ($a) {
                        return [
                            'id_siswa' => $a->id_siswa,
                            'nis' => $a->nis,
                            'nama' => $a->nama,
                            'kelas' => $a->kelas?->nama_kelas ?? '',
                            'perempuan' => $a->perempuan,
                        ];
                    }),
                    'statistik' => [
                        'total_anak' => $anakList->count(),
                        'total_catatan' => $totalCatatanAnak,
                        'catatan_belum_dibaca' => $catatanBelumDibaca,
                    ],
                    'catatan_terbaru' => $catatanTerbaru,
                ],
            ], 200);
        }

        // Admin
        return response()->json([
            'success' => true,
            'message' => 'Dashboard admin berhasil dimuat',
            'data' => [
                'role' => 'admin',
                'nama' => $user->nama,
                'statistik' => [
                    'total_guru' => Guru::count(),
                    'total_orang_tua' => OrangTua::count(),
                    'total_siswa' => Siswa::count(),
                    'total_kelas' => Kelas::count(),
                    'total_catatan' => CatatanPenghubung::count(),
                ],
            ],
        ], 200);
    }

    /**
     * Dapatkan daftar aktivitas / notifikasi terbaru untuk NotifikasiPage.
     */
    public function notifikasi(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = CatatanPenghubung::with(['siswa', 'pengirim']);

        if ($user->role === 'orang_tua') {
            $idOrangTua = $user->orangTua?->id_orang_tua;
            $anakIds = Siswa::whereHas('orangTua', function ($q) use ($idOrangTua) {
                $q->where('orang_tua.id_orang_tua', $idOrangTua);
            })->pluck('id_siswa');

            $query->whereIn('id_siswa', $anakIds);
        } elseif ($user->role === 'guru') {
            $kelasWaliIds = $user->guru?->kelasWali?->pluck('id_kelas') ?? collect();
            $query->where(function ($q) use ($user, $kelasWaliIds) {
                $q->where('id_pengirim', $user->id_user)
                    ->orWhere('id_penerima', $user->id_user)
                    ->orWhereHas('siswa', function ($sq) use ($kelasWaliIds) {
                        $sq->whereIn('id_kelas', $kelasWaliIds);
                    });
            });
        }

        $daftarAktivitas = $query->orderBy('tanggal', 'DESC')
            ->limit(20)
            ->get();

        $data = $daftarAktivitas->map(function ($c) use ($user) {
            $tanggal = $c->tanggal instanceof Carbon ? $c->tanggal : Carbon::parse($c->tanggal);
            $waktuRelatif = $tanggal->diffForHumans();

            $keterangan = $c->id_pengirim === $user->id_user
                ? "Anda mengirim catatan: \"{$c->kategori}\""
                : "Menerima catatan baru dari {$c->pengirim?->nama}";

            return [
                'id_catatan' => $c->id_catatan,
                'id_siswa' => $c->id_siswa,
                'nama' => $c->siswa?->nama ?? 'Siswa',
                'keterangan' => $keterangan,
                'waktu' => $waktuRelatif,
                'perempuan' => $c->siswa?->perempuan ?? false,
                'status_dibaca' => $c->status_dibaca,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Daftar notifikasi berhasil dimuat',
            'data' => $data,
        ], 200);
    }

    /**
     * Helper mini formatter catatan
     */
    private function formatMiniCatatan(CatatanPenghubung $c): array
    {
        return [
            'id_catatan' => $c->id_catatan,
            'id_siswa' => $c->id_siswa,
            'nama_siswa' => $c->siswa?->nama ?? '',
            'penulis' => $c->pengirim?->nama ?? '',
            'kategori' => $c->kategori ?? 'Umum',
            'isi' => $c->isi_catatan,
            'tanggal' => $c->tanggal?->format('Y-m-d H:i:s'),
            'status_dibaca' => $c->status_dibaca,
        ];
    }
}
