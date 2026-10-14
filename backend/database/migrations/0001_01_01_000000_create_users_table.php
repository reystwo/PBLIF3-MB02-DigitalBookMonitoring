<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Tabel users
        Schema::create('users', function (Blueprint $table) {
            $table->id('id_user');
            $table->string('nama', 100);
            $table->string('username', 100)->unique();
            $table->string('password', 255);
            $table->string('role', 20); // 'admin', 'guru', 'orang_tua'
            $table->string('status', 20)->default('aktif'); // 'aktif', 'nonaktif'
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->nullable()->useCurrentOnUpdate();
        });

        // 2. Tabel password_reset_tokens & sessions (bawaan Laravel untuk auth)
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });

        // 3. Tabel guru
        Schema::create('guru', function (Blueprint $table) {
            $table->id('id_guru');
            $table->foreignId('id_user')->unique()->constrained('users', 'id_user')->cascadeOnDelete();
            $table->string('nip', 30)->unique();
            $table->string('no_hp', 20)->nullable();
        });

        // 4. Tabel orang_tua
        Schema::create('orang_tua', function (Blueprint $table) {
            $table->id('id_orang_tua');
            $table->foreignId('id_user')->unique()->constrained('users', 'id_user')->cascadeOnDelete();
            $table->string('no_hp', 20)->nullable();
            $table->string('alamat', 255)->nullable();
        });

        // 5. Tabel kelas
        Schema::create('kelas', function (Blueprint $table) {
            $table->id('id_kelas');
            $table->string('nama_kelas', 50);
            $table->string('tingkat', 20);
            $table->string('tahun_ajaran', 20);
            $table->foreignId('id_wali_guru')->constrained('guru', 'id_guru')->restrictOnDelete();
        });

        // 6. Tabel siswa
        Schema::create('siswa', function (Blueprint $table) {
            $table->id('id_siswa');
            $table->string('nis', 30)->unique();
            $table->string('nama', 100);
            $table->string('jenis_kelamin', 1); // 'L' atau 'P'
            $table->foreignId('id_kelas')->constrained('kelas', 'id_kelas')->restrictOnDelete();
        });

        // 7. Tabel siswa_orang_tua (Pivot)
        Schema::create('siswa_orang_tua', function (Blueprint $table) {
            $table->foreignId('id_siswa')->constrained('siswa', 'id_siswa')->cascadeOnDelete();
            $table->foreignId('id_orang_tua')->constrained('orang_tua', 'id_orang_tua')->cascadeOnDelete();
            $table->string('hubungan', 20);
            $table->primary(['id_siswa', 'id_orang_tua']);
        });

        // 8. Tabel catatan_penghubung
        Schema::create('catatan_penghubung', function (Blueprint $table) {
            $table->id('id_catatan');
            $table->foreignId('id_siswa')->constrained('siswa', 'id_siswa')->cascadeOnDelete();
            $table->foreignId('id_pengirim')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->foreignId('id_penerima')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->text('isi_catatan');
            $table->timestamp('tanggal')->useCurrent();
            $table->string('status_dibaca', 20)->default('belum_dibaca'); // 'belum_dibaca', 'dibaca'
            
            // Kolom pelengkap pendukung kartu UI Flutter
            $table->string('kategori', 50)->default('Umum');
            $table->string('lampiran_nama', 255)->nullable();
            $table->string('lampiran_ukuran', 50)->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('catatan_penghubung');
        Schema::dropIfExists('siswa_orang_tua');
        Schema::dropIfExists('siswa');
        Schema::dropIfExists('kelas');
        Schema::dropIfExists('orang_tua');
        Schema::dropIfExists('guru');
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
