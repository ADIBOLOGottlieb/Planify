<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Problème signalé par un utilisateur, traité depuis l'interface d'administration. */
class Signalement extends Model
{
    protected $fillable = ['sujet', 'message', 'est_traite'];

    protected $casts = ['est_traite' => 'boolean'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
