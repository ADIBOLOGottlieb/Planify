<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\CategorieRequest;
use App\Models\Categorie;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

/**
 * Catégories : catégories système (gérées depuis l'interface
 * d'administration, en lecture seule pour les utilisateurs) et catégories
 * personnelles de l'utilisateur.
 */
class CategorieController extends RessourceController
{
    protected string $modele = Categorie::class;

    protected string $requete = CategorieRequest::class;

    protected function visibles(Request $request): Builder
    {
        return Categorie::query()->where(fn ($q) => $q
            ->where('est_systeme', true)
            ->orWhere('utilisateur_id', $request->user()->id));
    }

    protected function enregistrer(Model $element, array $data, Request $request): void
    {
        $element->est_systeme = false;
        parent::enregistrer($element, $data, $request);
    }
}
