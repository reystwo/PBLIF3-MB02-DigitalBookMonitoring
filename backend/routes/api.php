<?php

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
});
