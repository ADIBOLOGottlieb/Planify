<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Les catégories système sont visibles par tous mais ne sont modifiables
 * que depuis l'interface d'administration.
 */
class CategoriePolicy extends ProprietairePolicy
{
    public function view(User $user, Model $element): bool
    {
        return $element->est_systeme || $this->estProprietaire($user, $element);
    }

    public function update(User $user, Model $element): bool
    {
        return ! $element->est_systeme && $this->estProprietaire($user, $element);
    }

    public function delete(User $user, Model $element): bool
    {
        return $this->update($user, $element);
    }
}
