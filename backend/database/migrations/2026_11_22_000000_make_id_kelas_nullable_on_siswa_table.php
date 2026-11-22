<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Siswa boleh tidak terdaftar di kelas mana pun (siswa.id_kelas = NULL).
 * Dibutuhkan fitur Admin "Keluarkan Siswa dari Kelas": hanya relasi siswa -> kelas
 * yang dilepas, sedangkan data siswa, relasi orang tua, dan catatan tetap utuh.
 * Foreign key ke kelas tetap dipertahankan (restrict on delete).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('siswa', function (Blueprint $table) {
            $table->dropForeign(['id_kelas']);
        });

        Schema::table('siswa', function (Blueprint $table) {
            $table->unsignedBigInteger('id_kelas')->nullable()->change();
            $table->foreign('id_kelas')->references('id_kelas')->on('kelas')->restrictOnDelete();
        });
    }

    /**
     * Catatan: rollback gagal bila masih ada siswa tanpa kelas.
     * Tempatkan siswa tersebut ke kelas melalui menu Kelola Siswa terlebih dahulu.
     */
    public function down(): void
    {
        Schema::table('siswa', function (Blueprint $table) {
            $table->dropForeign(['id_kelas']);
        });

        Schema::table('siswa', function (Blueprint $table) {
            $table->unsignedBigInteger('id_kelas')->nullable(false)->change();
            $table->foreign('id_kelas')->references('id_kelas')->on('kelas')->restrictOnDelete();
        });
    }
};
