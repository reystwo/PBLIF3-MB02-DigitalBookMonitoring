<?php

namespace App\Http\Controllers\Api\Guru;

use App\Http\Controllers\Controller;
use App\Models\Siswa;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Helper bersama untuk endpoint khusus Guru (/api/guru/*).
 * Cakupan Guru = siswa di kelas yang ia ampu sebagai wali kelas (kelas.id_wali_guru).
 */
abstract class GuruController extends Controller
{
    protected const PER_PAGE_DEFAULT = 10;

    protected const PER_PAGE_MAKS = 50;

    public const PESAN_DILUAR_CAKUPAN = 'Akses ditolak. Siswa ini bukan tanggung jawab Anda.';

    /**
     * Hentikan request dengan 403 bila siswa bukan tanggung jawab Guru yang login.
     */
    protected function pastikanTanggungJawab(Request $request, Siswa $siswa): void
    {
        if (! $request->user()->guru?->bertanggungJawabAtas($siswa)) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => self::PESAN_DILUAR_CAKUPAN,
            ], 403));
        }
    }

    /**
     * Jumlah data per halaman dari query ?per_page= (dibatasi 1..50).
     */
    protected function perPage(Request $request): int
    {
        $perPage = (int) $request->query('per_page', self::PER_PAGE_DEFAULT);

        return min(max($perPage, 1), self::PER_PAGE_MAKS);
    }

    /**
     * Kata kunci pencarian dari query ?search= (hanya menerima string).
     */
    protected function kataKunci(Request $request): string
    {
        $search = $request->query('search');

        return is_string($search) ? trim($search) : '';
    }

    /**
     * Respons daftar ber-pagination dengan format standar proyek + meta halaman.
     */
    protected function paginatedResponse(LengthAwarePaginator $paginator, callable $formatter, string $message): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => collect($paginator->items())->map($formatter)->values(),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ], 200);
    }
}
