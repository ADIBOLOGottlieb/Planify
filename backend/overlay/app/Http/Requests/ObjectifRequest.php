<?php

namespace App\Http\Requests;

class ObjectifRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'nom' => ['required', 'string', 'max:100'],
            'montant_cible' => ['required', 'numeric', 'gt:0'],
            'montant_actuel' => ['nullable', 'numeric', 'min:0'],
            'date_echeance' => ['required', 'date'],
            'statut' => ['nullable', 'in:en_cours,atteint,abandonne'],
        ];
    }
}
