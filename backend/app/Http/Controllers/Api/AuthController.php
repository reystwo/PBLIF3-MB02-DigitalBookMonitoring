<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Login user, validasi role & status, dan buat token Sanctum.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
            'role' => 'nullable|string|in:admin,guru,orang_tua',
        ]);

        $user = User::where('username', $validated['username'])->first();

        // 1. Verifikasi kecocokan user dan password
        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Username atau kata sandi salah.',
            ], 401);
        }

        // 2. Verifikasi status akun aktif
        if ($user->status !== 'aktif') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda sedang dinonaktifkan. Silakan hubungi Administrator.',
            ], 403);
        }

        // 3. Verifikasi role yang dipilih pengguna (jika disertakan)
        if (! empty($validated['role']) && $user->role !== $validated['role']) {
            $labelPilihan = match ($validated['role']) {
                'guru' => 'Guru',
                'orang_tua' => 'Orang Tua / Wali',
                'admin' => 'Admin',
                default => $validated['role'],
            };

            return response()->json([
                'success' => false,
                'message' => "Akun ini tidak terdaftar sebagai {$labelPilihan}.",
            ], 403);
        }

        // 4. Generate token Sanctum
        $token = $user->createToken('flutter-mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                'token' => $token,
                'user' => $this->formatUserData($user),
            ],
        ], 200);
    }

    /**
     * Dapatkan data profil user yang sedang login saat ini.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil dimuat',
            'data' => [
                'user' => $this->formatUserData($user),
            ],
        ], 200);
    }

    /**
     * Logout dan hapus token akses yang sedang aktif.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Berhasil keluar dari sesi.',
        ], 200);
    }

    /**
     * Format data user lengkap dengan relasi dan label peran untuk Flutter.
     */
    private function formatUserData(User $user): array
    {
        $peranLabel = match ($user->role) {
            'admin' => 'Administrator',
            'guru' => 'Guru',
            'orang_tua' => 'Orang Tua / Wali Murid',
            default => ucfirst($user->role),
        };

        if ($user->role === 'guru') {
            $user->loadMissing(['guru.kelasWali']);
            $kelasPertama = $user->guru?->kelasWali?->first();
            if ($kelasPertama) {
                $peranLabel = "Wali Kelas {$kelasPertama->nama_kelas}";
            }
        } elseif ($user->role === 'orang_tua') {
            $user->loadMissing(['orangTua.siswa.kelas']);
        }

        $userData = $user->toArray();
        $userData['peran_label'] = $peranLabel;

        return $userData;
    }
}
