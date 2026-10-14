<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Kelas extends Model
{
    use HasFactory;

    protected $table = 'kelas';
    protected $primaryKey = 'id_kelas';
    public $timestamps = false;

    protected $fillable = [
        'nama_kelas',
        'tingkat',
        'tahun_ajaran',
        'id_wali_guru',
    ];

    /**
     * Guru wali kelas
     */
    public function waliGuru()
    {
        return $this->belongsTo(Guru::class, 'id_wali_guru', 'id_guru');
    }

    /**
     * Siswa-siswa di kelas ini
     */
    public function siswa()
    {
        return $this->hasMany(Siswa::class, 'id_kelas', 'id_kelas');
    }
}
