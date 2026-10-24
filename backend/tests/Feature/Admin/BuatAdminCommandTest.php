<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class BuatAdminCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_perintah_admin_buat_membuat_akun_admin(): void
    {
        $this->artisan('admin:buat', ['username' => 'kepala_tu', '--nama' => 'Kepala Tata Usaha'])
            ->expectsQuestion('Kata sandi (minimal 8 karakter)', 'SandiKuat2026')
            ->expectsQuestion('Ulangi kata sandi', 'SandiKuat2026')
            ->expectsOutput("Akun admin 'kepala_tu' berhasil dibuat.")
            ->assertExitCode(0);

        $user = User::where('username', 'kepala_tu')->first();
        $this->assertSame('admin', $user->role);
        $this->assertSame('aktif', $user->status);
        $this->assertTrue(Hash::check('SandiKuat2026', $user->password));
    }

    public function test_perintah_admin_buat_menolak_sandi_lemah_atau_tidak_cocok(): void
    {
        $this->artisan('admin:buat', ['username' => 'admin2'])
            ->expectsQuestion('Kata sandi (minimal 8 karakter)', 'pendek')
            ->expectsQuestion('Ulangi kata sandi', 'beda')
            ->expectsOutput('Kata sandi minimal 8 karakter.')
            ->assertExitCode(1);

        $this->assertDatabaseMissing('users', ['username' => 'admin2']);
    }
}
