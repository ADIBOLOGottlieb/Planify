<?php

namespace App\Models\Concerns;

use App\Models\User;
use DateTimeInterface;
use Illuminate\Database\Eloquent\Builder;

/**
 * Modèle synchronisé avec l'application mobile :
 * - identifiant de type chaîne fourni par le client (UUID) ;
 * - seule la colonne `updated_at` est gérée (valeur envoyée par le client,
 *   utilisée pour résoudre les conflits) ;
 * - dates sérialisées sans fuseau horaire, au format lu par Dart
 *   (`DateTime.parse`).
 */
trait SynchroniseParClient
{
    public function initializeSynchroniseParClient(): void
    {
        $this->incrementing = false;
        $this->keyType = 'string';
        // Millisecondes conservées : indispensables pour comparer les
        // `updated_at` lors de la synchronisation.
        $this->dateFormat = 'Y-m-d H:i:s.v';
    }

    protected function serializeDate(DateTimeInterface $date): string
    {
        return $date->format('Y-m-d\TH:i:s.v');
    }

    public function scopeDe(Builder $query, User $user): Builder
    {
        return $query->where('utilisateur_id', $user->id);
    }

    /** Colonnes que le client peut écrire (hors id, propriétaire et date de modification). */
    public static function champsClient(): array
    {
        return (new static())->getFillable();
    }
}
