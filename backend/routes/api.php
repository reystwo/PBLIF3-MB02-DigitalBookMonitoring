<?php

use App\Http\Controllers\Api\Admin\GuruController as AdminGuruController;
use App\Http\Controllers\Api\Admin\KelasController as AdminKelasController;
use App\Http\Controllers\Api\Admin\OrangTuaController as AdminOrangTuaController;
use App\Http\Controllers\Api\Admin\SiswaController as AdminSiswaController;
use App\Http\Controllers\Api\Guru\CatatanSiswaController as GuruCatatanSiswaController;
use App\Http\Controllers\Api\Guru\SiswaController as GuruSiswaController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatatanController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\SiswaController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - Digital Book Connect
|--------------------------------------------------------------------------
*/

// Health Check
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'Digital Book Connect API',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// Autentikasi Publik
Route::post('/login', [AuthController::class, 'login']);

// Rute Terproteksi (Bearer Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Profil & Sesi
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Dashboard & Notifikasi
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/notifikasi', [DashboardController::class, 'notifikasi']);

    // Kelas & Siswa
    Route::get('/kelas', [SiswaController::class, 'kelasList']);
    Route::get('/siswa', [SiswaController::class, 'index']);

    // Catatan Penghubung
    Route::get('/catatan', [CatatanController::class, 'index']);
    Route::get('/catatan/{id}', [CatatanController::class, 'show']);
    Route::post('/catatan', [CatatanController::class, 'store']);
    Route::post('/catatan/{id}/balas', [CatatanController::class, 'reply']);
    Route::patch('/catatan/{id}/baca', [CatatanController::class, 'markAsRead']);

    // Siswa tanggung jawab Guru (wali kelas) beserta riwayat & tambah catatan
    Route::middleware('role:guru')->prefix('guru')->name('guru.')->group(function () {
        $siswaTidakDitemukan = fn () => response()->json([
            'success' => false,
            'message' => 'Data siswa tidak ditemukan.',
        ], 404);

        Route::get('siswa', [GuruSiswaController::class, 'index'])->name('siswa.index');
        Route::get('siswa/{siswa}', [GuruSiswaController::class, 'show'])
            ->whereNumber('siswa')->name('siswa.show')->missing($siswaTidakDitemukan);
        Route::get('siswa/{siswa}/catatan', [GuruCatatanSiswaController::class, 'index'])
            ->whereNumber('siswa')->name('siswa.catatan.index')->missing($siswaTidakDitemukan);
        Route::post('siswa/{siswa}/catatan', [GuruCatatanSiswaController::class, 'store'])
            ->whereNumber('siswa')->name('siswa.catatan.store')->missing($siswaTidakDitemukan);
    });

    // Kelola Data (khusus Admin) - seluruh operasi baca/tambah/ubah/hapus
    Route::middleware('role:admin')->prefix('admin')->name('admin.')->group(function () {
        $tidakDitemukan = fn (string $label) => fn () => response()->json([
            'success' => false,
            'message' => "Data {$label} tidak ditemukan.",
        ], 404);

        Route::apiResource('guru', AdminGuruController::class)
            ->parameters(['guru' => 'guru'])
            ->missing($tidakDitemukan('guru'));

        Route::apiResource('orang-tua', AdminOrangTuaController::class)
            ->parameters(['orang-tua' => 'orangTua'])
            ->missing($tidakDitemukan('orang tua'));

        Route::apiResource('siswa', AdminSiswaController::class)
            ->parameters(['siswa' => 'siswa'])
            ->missing($tidakDitemukan('siswa'));

        Route::apiResource('kelas', AdminKelasController::class)
            ->parameters(['kelas' => 'kelas'])
            ->missing($tidakDitemukan('kelas'));
    });
});
