<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Siswa extends Model
{
    use HasFactory;

    protected $table = 'siswa';
    protected $primaryKey = 'id_siswa';
    public $timestamps = false;

    protected $fillable = [
        'nis',
        'nama',
        'jenis_kelamin',
        'id_kelas',
    ];

    protected $appends = [
        'perempuan',
    ];

    /**
     * Accessor untuk kompatibilitas frontend Flutter ('perempuan' boolean)
     */
    public function getPerempuanAttribute(): bool
    {
        return $this->jenis_kelamin === 'P';
    }

    /**
     * Siswa yang menjadi tanggung jawab Guru, yaitu siswa di kelas yang ia ampu
     * sebagai wali kelas (kelas.id_wali_guru). Tanpa profil guru: tidak ada siswa.
     */
    public function scopeTanggungJawabGuru(Builder $query, ?Guru $guru): Builder
    {
        if (! $guru) {
            return $query->whereRaw('1 = 0');
        }

        return $query->whereHas('kelas', fn ($q) => $q->where('id_wali_guru', $guru->id_guru));
    }

    /**
     * Kelas tempat siswa terdaftar
     */
    public function kelas()
    {
        return $this->belongsTo(Kelas::class, 'id_kelas', 'id_kelas');
    }

    /**
     * Orang tua atau wali dari siswa
     */
    public function orangTua()
    {
        return $this->belongsToMany(
            OrangTua::class,
            'siswa_orang_tua',
            'id_siswa',
            'id_orang_tua'
        )->withPivot('hubungan');
    }

    /**
     * Seluruh catatan penghubung untuk siswa ini
     */
    public function catatanPenghubung()
    {
        return $this->hasMany(CatatanPenghubung::class, 'id_siswa', 'id_siswa');
    }
}
