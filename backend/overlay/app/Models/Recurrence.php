<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Dépense ou revenu récurrent (loyer, abonnement, salaire…). */
class Recurrence extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'transactions_recurrentes';

    protected $fillable = ['montant', 'type', 'date_debut', 'prochaine_date', 'periodicite', 'description', 'mode_paiement', 'categorie_id', 'compte_id', 'actif'];

    protected $casts = ['montant' => 'float', 'actif' => 'integer', 'date_debut' => 'datetime', 'prochaine_date' => 'datetime', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
