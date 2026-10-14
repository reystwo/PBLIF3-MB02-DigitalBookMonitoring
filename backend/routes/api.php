<?php

use App\Http\Controllers\Api\AuthController;
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

// Autentikasi Terproteksi (Bearer Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/user', [AuthController::class, 'me']); // Alias /user
    Route::post('/logout', [AuthController::class, 'logout']);
});
