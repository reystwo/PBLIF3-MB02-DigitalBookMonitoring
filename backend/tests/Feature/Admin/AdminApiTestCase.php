<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Basis pengujian endpoint /api/admin/* dengan dataset seeder lengkap.
 */
abstract class AdminApiTestCase extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    /**
     * Kirim request berikutnya sebagai user tertentu (Bearer token Sanctum).
     */
    protected function sebagai(string $username): static
    {
        $user = User::where('username', $username)->firstOrFail();

        return $this->denganToken($user->createToken('test')->plainTextToken);
    }

    protected function denganToken(string $token): static
    {
        // Guard di-reset agar user hasil request sebelumnya tidak ikut ter-cache
        $this->app['auth']->forgetGuards();

        return $this->withHeader('Authorization', 'Bearer '.$token);
    }

    protected function sebagaiAdmin(): static
    {
        return $this->sebagai('admin');
    }
}
