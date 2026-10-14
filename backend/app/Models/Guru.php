<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Guru extends Model
{
    use HasFactory;

    protected $table = 'guru';
    protected $primaryKey = 'id_guru';
    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'nip',
        'no_hp',
    ];

    /**
     * Akun user pemilik profil guru
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    /**
     * Kelas-kelas yang diampu sebagai wali guru
     */
    public function kelasWali()
    {
        return $this->hasMany(Kelas::class, 'id_wali_guru', 'id_guru');
    }
}
