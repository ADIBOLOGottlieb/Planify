<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Objectif d'épargne — entité OBJECTIF du MCD. */
class Objectif extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'objectifs';

    protected $fillable = ['nom', 'montant_cible', 'montant_actuel', 'date_echeance', 'statut'];

    protected $casts = ['montant_cible' => 'float', 'montant_actuel' => 'float', 'date_echeance' => 'datetime', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
