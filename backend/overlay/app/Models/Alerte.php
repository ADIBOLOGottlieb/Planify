<?php

namespace App\Models;

use App\Models\Concerns\SynchroniseParClient;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Notification envoyée à l'utilisateur — entité ALERTE / NOTIFICATION du MCD. */
class Alerte extends Model
{
    use SynchroniseParClient;

    public const CREATED_AT = null;

    protected $table = 'alertes';

    protected $fillable = ['type_alerte', 'message', 'date_envoi', 'est_lue', 'budget_id'];

    protected $casts = ['est_lue' => 'integer', 'date_envoi' => 'datetime', 'updated_at' => 'datetime'];

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }
}
