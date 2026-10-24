<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CatatanPenghubung extends Model
{
    use HasFactory;

    protected $table = 'catatan_penghubung';
    protected $primaryKey = 'id_catatan';

    /** Batas panjang isi catatan (selaras dengan batas karakter di form Flutter). */
    public const MAKS_ISI = 500;

    /** Kategori yang tersedia di form catatan; 'Umum' adalah nilai bawaan tabel. */
    public const KATEGORI = ['Akademik', 'Perilaku', 'Kesehatan', 'Kegiatan', 'Lainnya', 'Umum'];

    protected $fillable = [
        'id_siswa',
        'id_pengirim',
        'id_penerima',
        'isi_catatan',
        'tanggal',
        'status_dibaca',
        'kategori',
        'lampiran_nama',
        'lampiran_ukuran',
    ];

    protected function casts(): array
    {
        return [
            'id_catatan' => 'integer',
            'id_siswa' => 'integer',
            'id_pengirim' => 'integer',
            'id_penerima' => 'integer',
            'tanggal' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * Catatan yang boleh dibaca seorang Guru: catatan yang ia kirim/terima,
     * atau catatan siswa di kelas yang ia ampu sebagai wali kelas.
     */
    public function scopeDapatDiaksesGuru(Builder $query, User $user): Builder
    {
        return $query->where(function ($q) use ($user) {
            $q->where('id_pengirim', $user->id_user)
                ->orWhere('id_penerima', $user->id_user)
                ->orWhereHas('siswa', fn ($sq) => $sq->tanggungJawabGuru($user->guru));
        });
    }

    /**
     * Siswa yang dibahas dalam catatan
     */
    public function siswa()
    {
        return $this->belongsTo(Siswa::class, 'id_siswa', 'id_siswa');
    }

    /**
     * Pengirim catatan (Guru atau Orang Tua)
     */
    public function pengirim()
    {
        return $this->belongsTo(User::class, 'id_pengirim', 'id_user');
    }

    /**
     * Penerima catatan (Orang Tua atau Guru)
     */
    public function penerima()
    {
        return $this->belongsTo(User::class, 'id_penerima', 'id_user');
    }
}
