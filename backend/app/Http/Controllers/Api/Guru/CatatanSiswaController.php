<?php

namespace App\Http\Controllers\Api\Guru;

use App\Http\Controllers\Api\Concerns\FormatCatatan;
use App\Http\Requests\Guru\CatatanSiswaRequest;
use App\Models\CatatanPenghubung;
use App\Models\Siswa;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Riwayat & tambah catatan untuk siswa yang menjadi tanggung jawab Guru.
 */
class CatatanSiswaController extends GuruController
{
    use FormatCatatan;

    /**
     * Riwayat catatan siswa, terbaru lebih dulu.
     */
    public function index(Request $request, Siswa $siswa): JsonResponse
    {
        $this->pastikanTanggungJawab($request, $siswa);

        $paginator = CatatanPenghubung::with(self::RELASI_CATATAN)
            ->where('id_siswa', $siswa->id_siswa)
            ->dapatDiaksesGuru($request->user())
            ->orderByDesc('created_at')
            ->orderByDesc('id_catatan')
            ->paginate($this->perPage($request));

        return $this->paginatedResponse(
            $paginator,
            fn (CatatanPenghubung $c) => $this->formatCatatanItem($c),
            'Riwayat catatan berhasil dimuat',
        );
    }

    /**
     * Simpan catatan baru. Cakupan siswa dicek di CatatanSiswaRequest::authorize();
     * pengirim selalu diambil dari akun yang login, bukan dari isi request.
     */
    public function store(CatatanSiswaRequest $request, Siswa $siswa): JsonResponse
    {
        $data = $request->validated();
        $user = $request->user();

        // Penerima otomatis: orang tua/wali pertama siswa (sama dengan POST /api/catatan)
        $siswa->loadMissing('orangTua');
        $idPenerima = $siswa->orangTua->first()?->id_user ?? $user->id_user;

        $catatan = CatatanPenghubung::create([
            'id_siswa' => $siswa->id_siswa,
            'id_pengirim' => $user->id_user,
            'id_penerima' => $idPenerima,
            'kategori' => $data['kategori'] ?? 'Umum',
            'tanggal' => ! empty($data['tanggal']) ? Carbon::parse($data['tanggal']) : now(),
            'isi_catatan' => $data['isi_catatan'],
            'status_dibaca' => 'belum_dibaca',
            'lampiran_nama' => $data['lampiran_nama'] ?? null,
            'lampiran_ukuran' => $data['lampiran_ukuran'] ?? null,
        ]);

        $catatan->load(self::RELASI_CATATAN);

        return response()->json([
            'success' => true,
            'message' => "Catatan untuk {$siswa->nama} berhasil disimpan",
            'data' => $this->formatCatatanItem($catatan),
        ], 201);
    }
}
