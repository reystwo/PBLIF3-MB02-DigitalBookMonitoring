<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class SiswaOrangTua extends Pivot
{
    protected $table = 'siswa_orang_tua';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'id_siswa',
        'id_orang_tua',
        'hubungan',
    ];
}
