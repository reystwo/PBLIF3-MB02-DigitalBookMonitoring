<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';
    protected $primaryKey = 'id_user';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'nama',
        'username',
        'password',
        'role',
        'status',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'password' => 'hashed',
        ];
    }

    /**
     * Relasi ke profil Guru (1:1)
     */
    public function guru()
    {
        return $this->hasOne(Guru::class, 'id_user', 'id_user');
    }

    /**
     * Relasi ke profil Orang Tua (1:1)
     */
    public function orangTua()
    {
        return $this->hasOne(OrangTua::class, 'id_user', 'id_user');
    }

    /**
     * Catatan yang dikirim oleh user ini
     */
    public function catatanTerkirim()
    {
        return $this->hasMany(CatatanPenghubung::class, 'id_pengirim', 'id_user');
    }

    /**
     * Catatan yang diterima oleh user ini
     */
    public function catatanDiterima()
    {
        return $this->hasMany(CatatanPenghubung::class, 'id_penerima', 'id_user');
    }
}
