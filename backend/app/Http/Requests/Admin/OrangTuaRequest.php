<?php

namespace App\Http\Requests\Admin;

use App\Models\OrangTua;
use Illuminate\Validation\Rule;

/**
 * Validasi tambah / ubah data Orang Tua (akun users + profil orang_tua).
 * Field role sengaja tidak diterima: role selalu ditetapkan 'orang_tua' oleh server.
 * Hubungan dengan siswa dikelola melalui fitur Kelola Siswa (tabel siswa_orang_tua).
 */
class OrangTuaRequest extends AdminFormRequest
{
    public function rules(): array
    {
        /** @var OrangTua|null $orangTua */
        $orangTua = $this->route('orangTua');

        return [
            'nama' => ['required', 'string', 'max:100'],
            'username' => [
                'required', 'string', 'max:100', 'alpha_dash',
                Rule::unique('users', 'username')->ignore($orangTua?->id_user, 'id_user'),
            ],
            'password' => [$orangTua ? 'nullable' : 'required', 'string', 'min:8', 'max:255'],
            'no_hp' => ['nullable', 'string', 'max:20', 'regex:/^[0-9+\-\s]+$/'],
            'alamat' => ['nullable', 'string', 'max:255'],
            'status' => ['sometimes', 'required', Rule::in(['aktif', 'nonaktif'])],
        ];
    }

    public function messages(): array
    {
        return [
            ...parent::messages(),
            'no_hp.regex' => 'Nomor HP hanya boleh berisi angka, spasi, +, atau -.',
        ];
    }

    public function attributes(): array
    {
        return [
            'nama' => 'Nama',
            'username' => 'Username',
            'password' => 'Kata sandi',
            'no_hp' => 'Nomor HP',
            'alamat' => 'Alamat',
            'status' => 'Status akun',
        ];
    }
}
