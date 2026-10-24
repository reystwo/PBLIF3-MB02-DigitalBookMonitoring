<?php

namespace App\Http\Requests\Admin;

use App\Models\Siswa;
use Illuminate\Validation\Rule;

/**
 * Validasi tambah / ubah data Siswa beserta relasi orang tua (siswa_orang_tua).
 * Sesuai skema, setiap siswa terdaftar di tepat satu kelas (siswa.id_kelas).
 */
class SiswaRequest extends AdminFormRequest
{
    /** Nilai hubungan yang sudah dipakai di proyek (seeder & fallback 'Wali'). */
    public const HUBUNGAN = ['Ayah', 'Ibu', 'Wali'];

    public function rules(): array
    {
        /** @var Siswa|null $siswa */
        $siswa = $this->route('siswa');

        return [
            'nis' => [
                'required', 'string', 'max:30', 'regex:/^[A-Za-z0-9.\-]+$/',
                Rule::unique('siswa', 'nis')->ignore($siswa?->id_siswa, 'id_siswa'),
            ],
            'nama' => ['required', 'string', 'max:100'],
            'jenis_kelamin' => ['required', Rule::in(['L', 'P'])],
            'id_kelas' => ['required', 'integer', Rule::exists('kelas', 'id_kelas')],
            'orang_tua' => ['nullable', 'array'],
            'orang_tua.*.id_orang_tua' => ['required', 'integer', 'distinct', Rule::exists('orang_tua', 'id_orang_tua')],
            'orang_tua.*.hubungan' => ['required', Rule::in(self::HUBUNGAN)],
        ];
    }

    public function messages(): array
    {
        return [
            ...parent::messages(),
            'nis.regex' => 'NIS hanya boleh berisi huruf, angka, titik, atau tanda hubung.',
            'jenis_kelamin.in' => 'Jenis kelamin harus Laki-laki (L) atau Perempuan (P).',
            'orang_tua.*.hubungan.in' => 'Hubungan harus salah satu dari: '.implode(', ', self::HUBUNGAN).'.',
        ];
    }

    public function attributes(): array
    {
        return [
            'nis' => 'NIS',
            'nama' => 'Nama siswa',
            'jenis_kelamin' => 'Jenis kelamin',
            'id_kelas' => 'Kelas',
            'orang_tua' => 'Orang tua',
            'orang_tua.*.id_orang_tua' => 'Orang tua',
            'orang_tua.*.hubungan' => 'Hubungan',
        ];
    }
}
