<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Opération financière (dépense ou revenu) — entité TRANSACTION du MCD. */
class Transaction extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'transactions';

    protected $fillable = ['montant', 'type', 'date_transaction', 'description', 'mode_paiement', 'justificatif', 'categorie_id', 'compte_id', 'date_creation'];

    protected $casts = ['montant' => 'float', 'date_transaction' => 'datetime', 'date_creation' => 'datetime', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
