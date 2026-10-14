<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CatatanPenghubung;
use App\Models\Siswa;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatatanController extends Controller
{
    /**
     * Nama-nama bulan Indonesia untuk format label tanggal.
     */
    private const BULAN_ID = [
        1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun',
        7 => 'Jul', 8 => 'Agu', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
    ];

    /**
     * Dapatkan daftar catatan penghubung.
     * Menerapkan aturan privasi SEC-02 ketat untuk Orang Tua.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = CatatanPenghubung::with(['siswa.kelas', 'pengirim.guru.kelasWali', 'pengirim.orangTua', 'penerima']);

        // Proteksi Privasi Wajib SEC-02:
        if ($user->role === 'orang_tua') {
            $idOrangTua = $user->orangTua?->id_orang_tua;
            $anakIds = Siswa::whereHas('orangTua', function ($q) use ($idOrangTua) {
                $q->where('orang_tua.id_orang_tua', $idOrangTua);
            })->pluck('id_siswa');

            $query->whereIn('id_siswa', $anakIds);
        } elseif ($user->role === 'guru') {
            // Guru dapat melihat catatan yang dikirim/diterima olehnya, atau siswa di kelas yang dia ampu
            $idGuru = $user->guru?->id_guru;
            $kelasWaliIds = $user->guru?->kelasWali?->pluck('id_kelas') ?? collect();

            $query->where(function ($q) use ($user, $kelasWaliIds) {
                $q->where('id_pengirim', $user->id_user)
                    ->orWhere('id_penerima', $user->id_user)
                    ->orWhereHas('siswa', function ($sq) use ($kelasWaliIds) {
                        $sq->whereIn('id_kelas', $kelasWaliIds);
                    });
            });
        }
        // Admin: tidak dibatasi

        // Filter opsional
        if ($request->filled('id_siswa')) {
            $query->where('id_siswa', $request->query('id_siswa'));
        }

        if ($request->filled('kategori')) {
            $query->where('kategori', $request->query('kategori'));
        }

        if ($request->filled('status_dibaca')) {
            $query->where('status_dibaca', $request->query('status_dibaca'));
        }

        if ($request->filled('search')) {
            $keyword = $request->query('search');
            $query->where(function ($q) use ($keyword) {
                $q->where('isi_catatan', 'LIKE', "%{$keyword}%")
                    ->orWhere('kategori', 'LIKE', "%{$keyword}%")
                    ->orWhereHas('siswa', function ($sq) use ($keyword) {
                        $sq->where('nama', 'LIKE', "%{$keyword}%");
                    });
            });
        }

        $daftarCatatan = $query->orderBy('tanggal', 'DESC')
            ->orderBy('id_catatan', 'DESC')
            ->get();

        $data = $daftarCatatan->map(fn ($c) => $this->formatCatatanItem($c));

        return response()->json([
            'success' => true,
            'message' => 'Daftar catatan berhasil dimuat',
            'data' => $data,
        ], 200);
    }

    /**
     * Dapatkan detail satu catatan penghubung.
     * Otomatis menandai dibaca jika dibuka oleh penerima.
     */
    public function show(Request $request, int|string $id): JsonResponse
    {
        $user = $request->user();
        $catatan = CatatanPenghubung::with(['siswa.kelas', 'pengirim.guru.kelasWali', 'pengirim.orangTua', 'penerima'])
            ->find($id);

        if (! $catatan) {
            return response()->json([
                'success' => false,
                'message' => 'Catatan tidak ditemukan.',
            ], 404);
        }

        // Proteksi Privasi SEC-02:
        if ($user->role === 'orang_tua') {
            $idOrangTua = $user->orangTua?->id_orang_tua;
            $isAnakKandung = $catatan->siswa?->orangTua()
                ->where('orang_tua.id_orang_tua', $idOrangTua)
                ->exists();

            if (! $isAnakKandung) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak berhak melihat catatan siswa ini.',
                ], 403);
            }
        }

        // Tandai dibaca jika user saat ini adalah penerima catatan
        if ((int) $catatan->id_penerima === (int) $user->id_user && $catatan->status_dibaca === 'belum_dibaca') {
            $catatan->update(['status_dibaca' => 'dibaca']);
            $catatan->status_dibaca = 'dibaca';
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail catatan berhasil dimuat',
            'data' => $this->formatCatatanItem($catatan),
        ], 200);
    }

    /**
     * Tambah catatan penghubung baru (khusus Guru / Admin).
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        // Hanya Guru atau Admin yang boleh membuat catatan utama
        if (! in_array($user->role, ['guru', 'admin'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya Guru atau Administrator yang dapat membuat catatan baru.',
            ], 403);
        }

        $validated = $request->validate([
            'id_siswa' => 'required|exists:siswa,id_siswa',
            'isi_catatan' => 'nullable|string',
            'isi' => 'nullable|string',
            'kategori' => 'nullable|string|max:50',
            'tanggal' => 'nullable|date',
            'id_penerima' => 'nullable|exists:users,id_user',
            'lampiran_nama' => 'nullable|string|max:255',
            'lampiran_ukuran' => 'nullable|string|max:50',
        ]);

        $isiTeks = trim($validated['isi_catatan'] ?? $validated['isi'] ?? '');
        if (empty($isiTeks)) {
            return response()->json([
                'success' => false,
                'message' => 'Isi catatan tidak boleh kosong.',
            ], 422);
        }

        $siswa = Siswa::with('orangTua.user')->findOrFail($validated['id_siswa']);

        // Tentukan id_penerima secara otomatis jika tidak dikirim
        $idPenerima = $validated['id_penerima'] ?? null;
        if (! $idPenerima) {
            $ortuUtama = $siswa->orangTua->first();
            $idPenerima = $ortuUtama?->id_user ?? $user->id_user;
        }

        $tanggal = ! empty($validated['tanggal']) ? Carbon::parse($validated['tanggal']) : now();

        $catatan = CatatanPenghubung::create([
            'id_siswa' => $siswa->id_siswa,
            'id_pengirim' => $user->id_user,
            'id_penerima' => $idPenerima,
            'kategori' => $validated['kategori'] ?? 'Umum',
            'tanggal' => $tanggal,
            'isi_catatan' => $isiTeks,
            'status_dibaca' => 'belum_dibaca',
            'lampiran_nama' => $validated['lampiran_nama'] ?? null,
            'lampiran_ukuran' => $validated['lampiran_ukuran'] ?? null,
        ]);

        $catatan->load(['siswa.kelas', 'pengirim.guru.kelasWali', 'pengirim.orangTua', 'penerima']);

        return response()->json([
            'success' => true,
            'message' => "Catatan untuk {$siswa->nama} berhasil disimpan",
            'data' => $this->formatCatatanItem($catatan),
        ], 201);
    }

    /**
     * Balas pesan catatan penghubung (dapat dipanggil Guru maupun Orang Tua).
     */
    public function reply(Request $request, int|string $id): JsonResponse
    {
        $user = $request->user();
        $catatanAsal = CatatanPenghubung::with('siswa.orangTua.user')->find($id);

        if (! $catatanAsal) {
            return response()->json([
                'success' => false,
                'message' => 'Catatan yang dibalas tidak ditemukan.',
            ], 404);
        }

        // Proteksi Privasi SEC-02:
        if ($user->role === 'orang_tua') {
            $idOrangTua = $user->orangTua?->id_orang_tua;
            $isAnakKandung = $catatanAsal->siswa?->orangTua()
                ->where('orang_tua.id_orang_tua', $idOrangTua)
                ->exists();

            if (! $isAnakKandung) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak berhak membalas catatan siswa ini.',
                ], 403);
            }
        }

        $validated = $request->validate([
            'isi_catatan' => 'nullable|string',
            'isi' => 'nullable|string',
        ]);

        $isiTeks = trim($validated['isi_catatan'] ?? $validated['isi'] ?? '');
        if (empty($isiTeks)) {
            return response()->json([
                'success' => false,
                'message' => 'Isi balasan tidak boleh kosong.',
            ], 422);
        }

        // Tentukan id_penerima balasan
        if ($user->role === 'orang_tua') {
            // Orang tua membalas ke pengirim asal (Guru/Admin)
            $idPenerima = $catatanAsal->id_pengirim;
        } else {
            // Guru membalas ke akun orang tua siswa
            $ortu = $catatanAsal->siswa?->orangTua->first();
            $idPenerima = $ortu?->id_user ?? $catatanAsal->id_penerima;
        }

        // Tandai catatan asal sebagai sudah dibaca
        $catatanAsal->update(['status_dibaca' => 'dibaca']);

        // Buat record balasan di catatan_penghubung
        $balasan = CatatanPenghubung::create([
            'id_siswa' => $catatanAsal->id_siswa,
            'id_pengirim' => $user->id_user,
            'id_penerima' => $idPenerima,
            'kategori' => $catatanAsal->kategori,
            'tanggal' => now(),
            'isi_catatan' => $isiTeks,
            'status_dibaca' => 'belum_dibaca',
            'lampiran_nama' => null,
            'lampiran_ukuran' => null,
        ]);

        $balasan->load(['siswa.kelas', 'pengirim.guru.kelasWali', 'pengirim.orangTua', 'penerima']);

        return response()->json([
            'success' => true,
            'message' => 'Balasan berhasil dikirim',
            'data' => $this->formatCatatanItem($balasan),
        ], 201);
    }

    /**
     * Tandai catatan telah dibaca secara eksplisit.
     */
    public function markAsRead(Request $request, int|string $id): JsonResponse
    {
        $catatan = CatatanPenghubung::find($id);

        if (! $catatan) {
            return response()->json([
                'success' => false,
                'message' => 'Catatan tidak ditemukan.',
            ], 404);
        }

        $catatan->update(['status_dibaca' => 'dibaca']);

        return response()->json([
            'success' => true,
            'message' => 'Catatan berhasil ditandai telah dibaca.',
            'data' => [
                'id_catatan' => $catatan->id_catatan,
                'status_dibaca' => 'dibaca',
            ],
        ], 200);
    }

    /**
     * Helper untuk format objek Catatan yang kompatibel dengan UI Flutter.
     */
    private function formatCatatanItem(CatatanPenghubung $c): array
    {
        $pengirimUser = $c->pengirim;
        $peranPenulis = 'Pengguna';

        if ($pengirimUser) {
            if ($pengirimUser->role === 'guru') {
                $kelasWali = $pengirimUser->guru?->kelasWali?->first();
                $peranPenulis = $kelasWali ? "Guru Kelas {$kelasWali->nama_kelas}" : 'Guru';
            } elseif ($pengirimUser->role === 'orang_tua') {
                $peranPenulis = 'Orang Tua';
            } elseif ($pengirimUser->role === 'admin') {
                $peranPenulis = 'Administrator';
            }
        }

        $tanggalObj = $c->tanggal instanceof Carbon ? $c->tanggal : Carbon::parse($c->tanggal);
        $tglStr = $tanggalObj->format('Y-m-d H:i:s');
        $labelTanggal = "{$tanggalObj->day} " . (self::BULAN_ID[$tanggalObj->month] ?? '') . " {$tanggalObj->year}";

        return [
            'id_catatan' => $c->id_catatan,
            'id_siswa' => $c->id_siswa,
            'id_pengirim' => $c->id_pengirim,
            'id_penerima' => $c->id_penerima,
            'penulis' => $pengirimUser?->nama ?? 'Sistem',
            'peran_penulis' => $peranPenulis,
            'penulis_perempuan' => false,
            'kategori' => $c->kategori ?? 'Umum',
            'isi_catatan' => $c->isi_catatan,
            'isi' => $c->isi_catatan,
            'tanggal' => $tglStr,
            'tanggal_label' => $labelTanggal,
            'status_dibaca' => $c->status_dibaca,
            'siswa' => [
                'id_siswa' => $c->siswa?->id_siswa ?? $c->id_siswa,
                'nama' => $c->siswa?->nama ?? '',
                'kelas' => $c->siswa?->kelas?->nama_kelas ?? '',
                'jenis_kelamin' => $c->siswa?->jenis_kelamin ?? 'L',
                'perempuan' => $c->siswa?->perempuan ?? false,
            ],
            'lampiran' => ! empty($c->lampiran_nama) ? [
                'nama_file' => $c->lampiran_nama,
                'ukuran' => $c->lampiran_ukuran ?? '1.0 MB',
            ] : null,
        ];
    }
}
