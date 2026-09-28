<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Autorisation commune : un utilisateur ne peut consulter, modifier ou
 * supprimer que ses propres données.
 */
abstract class ProprietairePolicy
{
    protected function estProprietaire(User $user, Model $element): bool
    {
        return $element->utilisateur_id === $user->id;
    }

    public function view(User $user, Model $element): bool
    {
        return $this->estProprietaire($user, $element);
    }

    public function update(User $user, Model $element): bool
    {
        return $this->estProprietaire($user, $element);
    }

    public function delete(User $user, Model $element): bool
    {
        return $this->estProprietaire($user, $element);
    }
}
