<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrangTua extends Model
{
    use HasFactory;

    protected $table = 'orang_tua';
    protected $primaryKey = 'id_orang_tua';
    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'no_hp',
        'alamat',
    ];

    /**
     * Akun user pemilik profil orang tua
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    /**
     * Siswa (anak-anak) yang terhubung dengan orang tua ini
     */
    public function siswa()
    {
        return $this->belongsToMany(
            Siswa::class,
            'siswa_orang_tua',
            'id_orang_tua',
            'id_siswa'
        )->withPivot('hubungan');
    }
}
