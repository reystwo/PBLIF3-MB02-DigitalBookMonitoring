<?php

namespace App\Http\Requests\Admin;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * Basis Form Request untuk seluruh endpoint kelola data Admin.
 * Menyeragamkan pesan validasi berbahasa Indonesia dan format respons JSON
 * ({success, message, errors}) agar sama dengan endpoint lain di proyek.
 */
abstract class AdminFormRequest extends FormRequest
{
    /**
     * Lapisan kedua di samping middleware role:admin.
     */
    public function authorize(): bool
    {
        return $this->user()?->role === 'admin';
    }

    public function messages(): array
    {
        return [
            'required' => ':attribute wajib diisi.',
            'string' => ':attribute harus berupa teks.',
            'integer' => ':attribute harus berupa angka.',
            'array' => ':attribute harus berupa daftar.',
            'min' => [
                'string' => ':attribute minimal :min karakter.',
            ],
            'max' => [
                'string' => ':attribute maksimal :max karakter.',
            ],
            'unique' => ':attribute sudah digunakan.',
            'exists' => ':attribute yang dipilih tidak ditemukan.',
            'in' => ':attribute yang dipilih tidak valid.',
            'regex' => 'Format :attribute tidak valid.',
            'alpha_dash' => ':attribute hanya boleh berisi huruf, angka, tanda hubung (-), dan garis bawah (_).',
            'distinct' => ':attribute tidak boleh dipilih lebih dari sekali.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $validator->errors()->first(),
            'errors' => $validator->errors()->toArray(),
        ], 422));
    }

    protected function failedAuthorization(): void
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => 'Akses ditolak untuk peran Anda.',
        ], 403));
    }
}
