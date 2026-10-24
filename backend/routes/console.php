<?php

use App\Models\User;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Validator;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Akun Admin hanya dibuat dari server (CLI), tidak pernah lewat API.
// Kata sandi diinput tersembunyi agar tidak tersimpan di riwayat terminal.
Artisan::command('admin:buat {username : Username akun admin} {--nama=Administrator Sekolah : Nama tampilan akun}', function (string $username) {
    $password = (string) $this->secret('Kata sandi (minimal 8 karakter)');
    $konfirmasi = (string) $this->secret('Ulangi kata sandi');

    $validator = Validator::make(
        ['username' => $username, 'nama' => $this->option('nama'), 'password' => $password, 'password_confirmation' => $konfirmasi],
        [
            'username' => ['required', 'string', 'max:100', 'alpha_dash', 'unique:users,username'],
            'nama' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', 'min:8', 'max:255', 'confirmed'],
        ],
        [
            'username.unique' => 'Username sudah digunakan.',
            'username.alpha_dash' => 'Username hanya boleh berisi huruf, angka, - dan _.',
            'password.min' => 'Kata sandi minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi kata sandi tidak cocok.',
        ],
    );

    if ($validator->fails()) {
        foreach ($validator->errors()->all() as $pesan) {
            $this->error($pesan);
        }

        return 1;
    }

    User::create([
        'nama' => $this->option('nama'),
        'username' => $username,
        'password' => $password,
        'role' => 'admin',
        'status' => 'aktif',
    ]);

    $this->info("Akun admin '{$username}' berhasil dibuat.");

    return 0;
})->purpose('Membuat akun Administrator baru secara aman (kata sandi diinput tersembunyi)');
