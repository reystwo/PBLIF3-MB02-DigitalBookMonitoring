<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\CatatanPenghubung;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Helper bersama untuk controller kelola data Admin.
 */
abstract class AdminController extends Controller
{
    protected const PER_PAGE_DEFAULT = 10;

    protected const PER_PAGE_MAKS = 50;

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

    /**
     * Respons penolakan karena data masih dipakai oleh data lain (HTTP 409).
     */
    protected function conflict(string $message): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
        ], 409);
    }

    /**
     * Query catatan penghubung yang dikirim atau diterima oleh akun.
     */
    protected function catatanUser(int $idUser): Builder
    {
        return CatatanPenghubung::where(function (Builder $q) use ($idUser) {
            $q->where('id_pengirim', $idUser)->orWhere('id_penerima', $idUser);
        });
    }

    /**
     * Jumlah catatan penghubung yang dikirim atau diterima oleh akun.
     */
    protected function jumlahCatatanUser(int $idUser): int
    {
        return $this->catatanUser($idUser)->count();
    }

    /**
     * Penghapusan paksa data yang memiliki catatan penghubung.
     * Admin wajib mengonfirmasi lewat ?hapus_catatan=<jumlah>, dan jumlah itu harus
     * sama dengan jumlah catatan saat ini. Bila belum/tidak sesuai (mis. ada catatan
     * baru sejak halaman dibuka) -> 409 beserta jumlah terbaru untuk dikonfirmasi ulang.
     * Mengembalikan null bila penghapusan boleh dilanjutkan.
     */
    protected function tolakJikaCatatanBelumDikonfirmasi(Request $request, int $jumlahCatatan, string $label): ?JsonResponse
    {
        if ($jumlahCatatan === 0) {
            return null;
        }

        $dikonfirmasi = filter_var($request->query('hapus_catatan'), FILTER_VALIDATE_INT);
        if ($dikonfirmasi === $jumlahCatatan) {
            return null;
        }

        return response()->json([
            'success' => false,
            'message' => "{$label} memiliki {$jumlahCatatan} catatan penghubung yang akan ikut terhapus permanen. Konfirmasi penghapusan untuk melanjutkan.",
            'data' => [
                'jumlah_catatan' => $jumlahCatatan,
                'perlu_konfirmasi_catatan' => true,
            ],
        ], 409);
    }

    /**
     * Pesan sukses hapus, menyebut catatan yang ikut terhapus bila ada.
     */
    protected function pesanTerhapus(string $label, int $jumlahCatatan): string
    {
        return $jumlahCatatan > 0
            ? "{$label} berhasil dihapus beserta {$jumlahCatatan} catatan penghubung"
            : "{$label} berhasil dihapus";
    }

    /**
     * Simpan perubahan akun users (nama, username, status, kata sandi).
     * Token login dicabut bila kata sandi diganti atau akun dinonaktifkan.
     * Kolom role tidak pernah diambil dari request.
     */
    protected function simpanAkun(User $user, array $data): void
    {
        $user->fill(array_intersect_key($data, array_flip(['nama', 'username', 'status'])));

        if (! empty($data['password'])) {
            $user->password = $data['password'];
        }

        $cabutToken = $user->isDirty('password')
            || ($user->isDirty('status') && $user->status !== 'aktif');

        $user->save();

        if ($cabutToken) {
            $user->tokens()->delete();
        }
    }
}
