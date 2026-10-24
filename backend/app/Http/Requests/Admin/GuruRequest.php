<?php

namespace App\Http\Requests\Admin;

use App\Models\Guru;
use Illuminate\Validation\Rule;

/**
 * Validasi tambah / ubah data Guru (akun users + profil guru).
 * Field role sengaja tidak diterima: role selalu ditetapkan 'guru' oleh server.
 */
class GuruRequest extends AdminFormRequest
{
    public function rules(): array
    {
        /** @var Guru|null $guru */
        $guru = $this->route('guru');

        return [
            'nama' => ['required', 'string', 'max:100'],
            'username' => [
                'required', 'string', 'max:100', 'alpha_dash',
                Rule::unique('users', 'username')->ignore($guru?->id_user, 'id_user'),
            ],
            // Saat ubah data, kata sandi opsional (kosong = tidak diganti)
            'password' => [$guru ? 'nullable' : 'required', 'string', 'min:8', 'max:255'],
            'nip' => [
                'required', 'string', 'max:30', 'regex:/^[0-9]+$/',
                Rule::unique('guru', 'nip')->ignore($guru?->id_guru, 'id_guru'),
            ],
            'no_hp' => ['nullable', 'string', 'max:20', 'regex:/^[0-9+\-\s]+$/'],
            'status' => ['sometimes', 'required', Rule::in(['aktif', 'nonaktif'])],
        ];
    }

    public function messages(): array
    {
        return [
            ...parent::messages(),
            'nip.regex' => 'NIP hanya boleh berisi angka.',
            'no_hp.regex' => 'Nomor HP hanya boleh berisi angka, spasi, +, atau -.',
        ];
    }

    public function attributes(): array
    {
        return [
            'nama' => 'Nama',
            'username' => 'Username',
            'password' => 'Kata sandi',
            'nip' => 'NIP',
            'no_hp' => 'Nomor HP',
            'status' => 'Status akun',
        ];
    }
}
