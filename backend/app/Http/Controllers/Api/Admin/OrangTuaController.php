<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Requests\Admin\OrangTuaRequest;
use App\Models\OrangTua;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Kelola Orang Tua / Wali (khusus Admin): akun users (role 'orang_tua') + profil tabel orang_tua.
 */
class OrangTuaController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        $query = OrangTua::with(['user', 'siswa.kelas']);

        $keyword = $this->kataKunci($request);
        if ($keyword !== '') {
            $query->where(function ($q) use ($keyword) {
                $q->where('no_hp', 'LIKE', "%{$keyword}%")
                    ->orWhere('alamat', 'LIKE', "%{$keyword}%")
                    ->orWhereHas('user', function ($uq) use ($keyword) {
                        $uq->where('nama', 'LIKE', "%{$keyword}%")
                            ->orWhere('username', 'LIKE', "%{$keyword}%");
                    })
                    ->orWhereHas('siswa', function ($sq) use ($keyword) {
                        $sq->where('nama', 'LIKE', "%{$keyword}%")
                            ->orWhere('nis', 'LIKE', "%{$keyword}%");
                    });
            });
        }

        if (in_array($request->query('status'), ['aktif', 'nonaktif'], true)) {
            $status = $request->query('status');
            $query->whereHas('user', fn ($uq) => $uq->where('status', $status));
        }

        $paginator = $query
            ->orderBy(User::select('nama')->whereColumn('users.id_user', 'orang_tua.id_user'))
            ->orderBy('id_orang_tua')
            ->paginate($this->perPage($request));

        return $this->paginatedResponse($paginator, fn (OrangTua $o) => $this->format($o), 'Daftar orang tua berhasil dimuat');
    }

    public function show(OrangTua $orangTua): JsonResponse
    {
        $orangTua->load(['user', 'siswa.kelas']);

        return response()->json([
            'success' => true,
            'message' => 'Detail orang tua berhasil dimuat',
            'data' => $this->format($orangTua, detail: true),
        ], 200);
    }

    public function store(OrangTuaRequest $request): JsonResponse
    {
        $data = $request->validated();

        $orangTua = DB::transaction(function () use ($data) {
            $user = User::create([
                'nama' => $data['nama'],
                'username' => $data['username'],
                'password' => $data['password'],
                'role' => 'orang_tua',
                'status' => $data['status'] ?? 'aktif',
            ]);

            return OrangTua::create([
                'id_user' => $user->id_user,
                'no_hp' => $data['no_hp'] ?? null,
                'alamat' => $data['alamat'] ?? null,
            ]);
        });

        $orangTua->load(['user', 'siswa.kelas']);

        return response()->json([
            'success' => true,
            'message' => "Orang tua {$orangTua->user->nama} berhasil ditambahkan",
            'data' => $this->format($orangTua, detail: true),
        ], 201);
    }

    public function update(OrangTuaRequest $request, OrangTua $orangTua): JsonResponse
    {
        $data = $request->validated();

        DB::transaction(function () use ($orangTua, $data) {
            $this->simpanAkun($orangTua->user, $data);
            $orangTua->update(array_intersect_key($data, array_flip(['no_hp', 'alamat'])));
        });

        $orangTua->refresh()->load(['user', 'siswa.kelas']);

        return response()->json([
            'success' => true,
            'message' => "Data orang tua {$orangTua->user->nama} berhasil diperbarui",
            'data' => $this->format($orangTua, detail: true),
        ], 200);
    }

    public function destroy(OrangTua $orangTua): JsonResponse
    {
        $orangTua->load(['user', 'siswa']);
        $nama = $orangTua->user?->nama ?? 'ini';

        if ($orangTua->siswa->isNotEmpty()) {
            $daftarAnak = $orangTua->siswa->pluck('nama')->implode(', ');

            return $this->conflict("Orang tua {$nama} masih terhubung dengan siswa: {$daftarAnak}. Lepaskan hubungan tersebut terlebih dahulu melalui menu Kelola Siswa.");
        }

        $jumlahCatatan = $this->jumlahCatatanUser($orangTua->id_user);
        if ($jumlahCatatan > 0) {
            return $this->conflict("Orang tua {$nama} memiliki {$jumlahCatatan} catatan penghubung. Data tidak dapat dihapus agar riwayat catatan tetap utuh; nonaktifkan akun sebagai gantinya.");
        }

        try {
            DB::transaction(function () use ($orangTua) {
                $user = $orangTua->user;
                $orangTua->delete();
                if ($user) {
                    $user->tokens()->delete();
                    $user->delete();
                }
            });
        } catch (QueryException) {
            return $this->conflict("Orang tua {$nama} tidak dapat dihapus karena masih digunakan oleh data lain.");
        }

        return response()->json([
            'success' => true,
            'message' => "Orang tua {$nama} berhasil dihapus",
        ], 200);
    }

    private function format(OrangTua $o, bool $detail = false): array
    {
        $data = [
            'id_orang_tua' => $o->id_orang_tua,
            'id_user' => $o->id_user,
            'nama' => $o->user?->nama ?? '',
            'username' => $o->user?->username ?? '',
            'status' => $o->user?->status ?? 'aktif',
            'no_hp' => $o->no_hp,
            'alamat' => $o->alamat,
            'anak' => $o->siswa->map(fn ($s) => [
                'id_siswa' => $s->id_siswa,
                'nis' => $s->nis,
                'nama' => $s->nama,
                'kelas' => $s->kelas?->nama_kelas ?? '',
                'perempuan' => $s->perempuan,
                'hubungan' => $s->pivot?->hubungan ?? 'Wali',
            ])->values()->all(),
        ];

        if ($detail) {
            $data['jumlah_catatan'] = $this->jumlahCatatanUser($o->id_user);
        }

        return $data;
    }
}
