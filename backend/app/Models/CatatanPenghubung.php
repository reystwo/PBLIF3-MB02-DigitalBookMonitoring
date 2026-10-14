<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CatatanPenghubung extends Model
{
    use HasFactory;

    protected $table = 'catatan_penghubung';
    protected $primaryKey = 'id_catatan';
    public $timestamps = false;

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
        ];
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
