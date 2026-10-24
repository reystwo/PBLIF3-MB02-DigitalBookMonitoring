<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Requests\Admin\GuruRequest;
use App\Models\Guru;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Kelola Guru (khusus Admin): akun users (role 'guru') + profil tabel guru.
 */
class GuruController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        $query = Guru::with(['user', 'kelasWali']);

        $keyword = $this->kataKunci($request);
        if ($keyword !== '') {
            $query->where(function ($q) use ($keyword) {
                $q->where('nip', 'LIKE', "%{$keyword}%")
                    ->orWhere('no_hp', 'LIKE', "%{$keyword}%")
                    ->orWhereHas('user', function ($uq) use ($keyword) {
                        $uq->where('nama', 'LIKE', "%{$keyword}%")
                            ->orWhere('username', 'LIKE', "%{$keyword}%");
                    });
            });
        }

        if (in_array($request->query('status'), ['aktif', 'nonaktif'], true)) {
            $status = $request->query('status');
            $query->whereHas('user', fn ($uq) => $uq->where('status', $status));
        }

        $paginator = $query
            ->orderBy(User::select('nama')->whereColumn('users.id_user', 'guru.id_user'))
            ->orderBy('id_guru')
            ->paginate($this->perPage($request));

        return $this->paginatedResponse($paginator, fn (Guru $g) => $this->format($g), 'Daftar guru berhasil dimuat');
    }

    public function show(Guru $guru): JsonResponse
    {
        $guru->load(['user', 'kelasWali']);

        return response()->json([
            'success' => true,
            'message' => 'Detail guru berhasil dimuat',
            'data' => $this->format($guru, detail: true),
        ], 200);
    }

    public function store(GuruRequest $request): JsonResponse
    {
        $data = $request->validated();

        $guru = DB::transaction(function () use ($data) {
            $user = User::create([
                'nama' => $data['nama'],
                'username' => $data['username'],
                'password' => $data['password'],
                'role' => 'guru',
                'status' => $data['status'] ?? 'aktif',
            ]);

            return Guru::create([
                'id_user' => $user->id_user,
                'nip' => $data['nip'],
                'no_hp' => $data['no_hp'] ?? null,
            ]);
        });

        $guru->load(['user', 'kelasWali']);

        return response()->json([
            'success' => true,
            'message' => "Guru {$guru->user->nama} berhasil ditambahkan",
            'data' => $this->format($guru, detail: true),
        ], 201);
    }

    public function update(GuruRequest $request, Guru $guru): JsonResponse
    {
        $data = $request->validated();

        DB::transaction(function () use ($guru, $data) {
            $this->simpanAkun($guru->user, $data);
            $guru->update(array_intersect_key($data, array_flip(['nip', 'no_hp'])));
        });

        $guru->refresh()->load(['user', 'kelasWali']);

        return response()->json([
            'success' => true,
            'message' => "Data guru {$guru->user->nama} berhasil diperbarui",
            'data' => $this->format($guru, detail: true),
        ], 200);
    }

    public function destroy(Guru $guru): JsonResponse
    {
        $guru->load(['user', 'kelasWali']);
        $nama = $guru->user?->nama ?? 'ini';

        if ($guru->kelasWali->isNotEmpty()) {
            $daftarKelas = $guru->kelasWali->pluck('nama_kelas')->implode(', ');

            return $this->conflict("Guru {$nama} masih menjadi wali kelas {$daftarKelas}. Ganti wali kelas tersebut terlebih dahulu melalui menu Kelola Kelas.");
        }

        $jumlahCatatan = $this->jumlahCatatanUser($guru->id_user);
        if ($jumlahCatatan > 0) {
            return $this->conflict("Guru {$nama} memiliki {$jumlahCatatan} catatan penghubung. Data tidak dapat dihapus agar riwayat catatan tetap utuh; nonaktifkan akun sebagai gantinya.");
        }

        try {
            DB::transaction(function () use ($guru) {
                $user = $guru->user;
                $guru->delete();
                if ($user) {
                    $user->tokens()->delete();
                    $user->delete();
                }
            });
        } catch (QueryException) {
            return $this->conflict("Guru {$nama} tidak dapat dihapus karena masih digunakan oleh data lain.");
        }

        return response()->json([
            'success' => true,
            'message' => "Guru {$nama} berhasil dihapus",
        ], 200);
    }

    private function format(Guru $g, bool $detail = false): array
    {
        $data = [
            'id_guru' => $g->id_guru,
            'id_user' => $g->id_user,
            'nama' => $g->user?->nama ?? '',
            'username' => $g->user?->username ?? '',
            'status' => $g->user?->status ?? 'aktif',
            'nip' => $g->nip,
            'no_hp' => $g->no_hp,
            'kelas_wali' => $g->kelasWali->map(fn ($k) => [
                'id_kelas' => $k->id_kelas,
                'nama_kelas' => $k->nama_kelas,
                'tahun_ajaran' => $k->tahun_ajaran,
            ])->values()->all(),
        ];

        if ($detail) {
            $data['jumlah_catatan'] = $this->jumlahCatatanUser($g->id_user);
        }

        return $data;
    }
}
