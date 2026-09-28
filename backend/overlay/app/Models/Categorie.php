<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Catégorie de transactions : système (gérée par l'administrateur) ou personnelle. */
class Categorie extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'categories';

    protected $fillable = ['nom', 'icone', 'couleur', 'type', 'est_archivee'];

    protected $casts = ['est_systeme' => 'integer', 'est_archivee' => 'integer', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
