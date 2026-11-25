<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('catatan_penghubung', function (Blueprint $table) {
            $table->foreignId('parent_id')
                ->nullable()
                ->after('id_catatan')
                ->constrained('catatan_penghubung', 'id_catatan')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('catatan_penghubung', function (Blueprint $table) {
            $table->dropForeign(['parent_id']);
            $table->dropColumn('parent_id');
        });
    }
};
