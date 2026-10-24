<?php

namespace App\Http\Requests\Guru;

use App\Http\Controllers\Api\Guru\GuruController;
use App\Models\CatatanPenghubung;
use App\Models\Siswa;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * Validasi & otorisasi tambah catatan siswa oleh Guru.
 * Siswa diambil dari URL dan pengirim dari akun login; field lain di body
 * (mis. id_pengirim, id_siswa, id_guru) tidak pernah dibaca.
 */
class CatatanSiswaRequest extends FormRequest
{
    /**
     * Lapisan kedua di samping middleware role:guru: siswa wajib berada di kelas
     * yang diampu Guru. Dicek sebelum validasi agar tidak membocorkan informasi.
     */
    public function authorize(): bool
    {
        $siswa = $this->route('siswa');
        $user = $this->user();

        return $user?->role === 'guru'
            && $siswa instanceof Siswa
            && (bool) $user->guru?->bertanggungJawabAtas($siswa);
    }

    /**
     * Rapikan isi catatan (termasuk spasi unicode) agar teks berisi spasi saja ditolak.
     */
    protected function prepareForValidation(): void
    {
        $isi = $this->input('isi_catatan');

        if (is_string($isi)) {
            $this->merge(['isi_catatan' => Str::trim($isi)]);
        }
    }

    public function rules(): array
    {
        return [
            'isi_catatan' => ['required', 'string', 'max:'.CatatanPenghubung::MAKS_ISI],
            'kategori' => ['nullable', Rule::in(CatatanPenghubung::KATEGORI)],
            'tanggal' => ['nullable', 'date'],
            'lampiran_nama' => ['nullable', 'string', 'max:255'],
            'lampiran_ukuran' => ['nullable', 'string', 'max:50'],
        ];
    }

    public function messages(): array
    {
        return [
            'isi_catatan.required' => 'Isi catatan wajib diisi dan tidak boleh hanya berisi spasi.',
            'isi_catatan.string' => 'Isi catatan harus berupa teks.',
            'isi_catatan.max' => 'Isi catatan maksimal :max karakter.',
            'kategori.in' => 'Kategori harus salah satu dari: '.implode(', ', CatatanPenghubung::KATEGORI).'.',
            'tanggal.date' => 'Format tanggal tidak valid.',
            'lampiran_nama.max' => 'Nama lampiran maksimal :max karakter.',
            'lampiran_ukuran.max' => 'Ukuran lampiran maksimal :max karakter.',
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
            'message' => GuruController::PESAN_DILUAR_CAKUPAN,
        ], 403));
    }
}
