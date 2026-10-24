<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Menambahkan waktu pembuatan & pembaruan catatan.
 * Kolom `tanggal` tetap dipakai sebagai tanggal kejadian yang dipilih Guru,
 * sedangkan created_at mencatat kapan catatan benar-benar disimpan.
 * Data lama tidak diubah: created_at/updated_at diisi dari `tanggal`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('catatan_penghubung', function (Blueprint $table) {
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->index(['id_siswa', 'created_at']);
        });

        DB::table('catatan_penghubung')
            ->whereNull('created_at')
            ->update([
                'created_at' => DB::raw('tanggal'),
                'updated_at' => DB::raw('tanggal'),
            ]);
    }

    public function down(): void
    {
        Schema::table('catatan_penghubung', function (Blueprint $table) {
            $table->dropIndex(['id_siswa', 'created_at']);
            $table->dropColumn(['created_at', 'updated_at']);
        });
    }
};
