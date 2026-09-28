<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Compte de paiement (espèces, TMoney / Mixx by Yas, Flooz…) et son solde. */
class Compte extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'comptes';

    protected $fillable = ['nom', 'solde', 'icone', 'couleur', 'operateur'];

    protected $casts = ['solde' => 'float', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
