<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\CatatanPenghubung;
use Carbon\Carbon;

/**
 * Format objek catatan penghubung yang kompatibel dengan UI Flutter (CatatanModel).
 * Dipakai bersama oleh CatatanController dan endpoint catatan siswa milik Guru.
 */
trait FormatCatatan
{
    /**
     * Relasi yang dibutuhkan formatCatatanItem() agar tidak terjadi N+1 query.
     */
    protected const RELASI_CATATAN = ['siswa.kelas', 'pengirim.guru.kelasWali', 'pengirim.orangTua', 'penerima'];

    /**
     * Nama-nama bulan Indonesia untuk format label tanggal.
     */
    private const BULAN_ID = [
        1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun',
        7 => 'Jul', 8 => 'Agu', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
    ];

    protected function formatCatatanItem(CatatanPenghubung $c): array
    {
        $pengirimUser = $c->pengirim;
        $peranPenulis = 'Pengguna';

        if ($pengirimUser) {
            if ($pengirimUser->role === 'guru') {
                $kelasWali = $pengirimUser->guru?->kelasWali?->first();
                $peranPenulis = $kelasWali ? "Guru Kelas {$kelasWali->nama_kelas}" : 'Guru';
            } elseif ($pengirimUser->role === 'orang_tua') {
                $peranPenulis = 'Orang Tua';
            } elseif ($pengirimUser->role === 'admin') {
                $peranPenulis = 'Administrator';
            }
        }

        $tanggalObj = $c->tanggal instanceof Carbon ? $c->tanggal : Carbon::parse($c->tanggal);
        $tglStr = $tanggalObj->format('Y-m-d H:i:s');
        $labelTanggal = "{$tanggalObj->day} " . (self::BULAN_ID[$tanggalObj->month] ?? '') . " {$tanggalObj->year}";

        return [
            'id_catatan' => $c->id_catatan,
            'id_siswa' => $c->id_siswa,
            'id_pengirim' => $c->id_pengirim,
            'id_penerima' => $c->id_penerima,
            'penulis' => $pengirimUser?->nama ?? 'Sistem',
            'peran_penulis' => $peranPenulis,
            'penulis_perempuan' => false,
            'kategori' => $c->kategori ?? 'Umum',
            'isi_catatan' => $c->isi_catatan,
            'isi' => $c->isi_catatan,
            'tanggal' => $tglStr,
            'tanggal_label' => $labelTanggal,
            'created_at' => ($c->created_at ?? $tanggalObj)->format('Y-m-d H:i:s'),
            'updated_at' => ($c->updated_at ?? $c->created_at ?? $tanggalObj)->format('Y-m-d H:i:s'),
            'status_dibaca' => $c->status_dibaca,
            'siswa' => [
                'id_siswa' => $c->siswa?->id_siswa ?? $c->id_siswa,
                'nama' => $c->siswa?->nama ?? '',
                'kelas' => $c->siswa?->kelas?->nama_kelas ?? '',
                'jenis_kelamin' => $c->siswa?->jenis_kelamin ?? 'L',
                'perempuan' => $c->siswa?->perempuan ?? false,
            ],
            'lampiran' => ! empty($c->lampiran_nama) ? [
                'nama_file' => $c->lampiran_nama,
                'ukuran' => $c->lampiran_ukuran ?? '1.0 MB',
            ] : null,
        ];
    }
}
