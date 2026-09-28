<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Budget alloué pour une période, global ou par catégorie — entité BUDGET du MCD. */
class Budget extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'budgets';

    protected $fillable = ['montant_alloue', 'montant_depense', 'montant_reporte', 'periode', 'date_debut', 'date_fin', 'categorie_id', 'seuil_alerte', 'statut_alerte', 'alerte_80_envoyee', 'alerte_100_envoyee'];

    protected $casts = ['montant_alloue' => 'float', 'montant_depense' => 'float', 'montant_reporte' => 'float', 'seuil_alerte' => 'integer', 'statut_alerte' => 'integer', 'alerte_80_envoyee' => 'integer', 'alerte_100_envoyee' => 'integer', 'date_debut' => 'datetime', 'date_fin' => 'datetime', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
