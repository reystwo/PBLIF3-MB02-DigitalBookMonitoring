<?php

namespace App\Http\Requests\Admin;

use App\Models\Kelas;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * Validasi tambah / ubah data Kelas beserta wali kelas (kelas.id_wali_guru).
 */
class KelasRequest extends AdminFormRequest
{
    public function rules(): array
    {
        /** @var Kelas|null $kelas */
        $kelas = $this->route('kelas');

        return [
            // Nama kelas tidak boleh kembar dalam tahun ajaran yang sama,
            // karena daftar siswa difilter berdasarkan nama kelas.
            'nama_kelas' => [
                'required', 'string', 'max:50',
                Rule::unique('kelas', 'nama_kelas')
                    ->where('tahun_ajaran', (string) $this->input('tahun_ajaran'))
                    ->ignore($kelas?->id_kelas, 'id_kelas'),
            ],
            'tingkat' => ['required', 'string', 'max:20'],
            'tahun_ajaran' => ['required', 'string', 'max:20', 'regex:/^\d{4}\/\d{4}$/'],
            'id_wali_guru' => ['required', 'integer', Rule::exists('guru', 'id_guru')],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator) {
                $tahun = (string) $this->input('tahun_ajaran');
                if (! $validator->errors()->has('tahun_ajaran') && preg_match('/^(\d{4})\/(\d{4})$/', $tahun, $m)) {
                    if ((int) $m[2] !== (int) $m[1] + 1) {
                        $validator->errors()->add('tahun_ajaran', 'Tahun ajaran harus berurutan, contoh: 2026/2027.');
                    }
                }
            },
        ];
    }

    public function messages(): array
    {
        return [
            ...parent::messages(),
            'nama_kelas.unique' => 'Kelas dengan nama ini sudah ada pada tahun ajaran tersebut.',
            'tahun_ajaran.regex' => 'Format tahun ajaran harus YYYY/YYYY, contoh: 2026/2027.',
            'id_wali_guru.required' => 'Wali kelas wajib dipilih.',
        ];
    }

    public function attributes(): array
    {
        return [
            'nama_kelas' => 'Nama kelas',
            'tingkat' => 'Tingkat',
            'tahun_ajaran' => 'Tahun ajaran',
            'id_wali_guru' => 'Wali kelas',
        ];
    }
}
