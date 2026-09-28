<?php

namespace App\Http\Requests;

class BudgetRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'montant_alloue' => ['required', 'numeric', 'gt:0'],
            'montant_depense' => ['nullable', 'numeric', 'min:0'],
            'montant_reporte' => ['nullable', 'numeric', 'min:0'],
            'periode' => ['required', 'in:hebdomadaire,mensuel,annuel'],
            'date_debut' => ['required', 'date'],
            'date_fin' => ['required', 'date', 'after_or_equal:date_debut'],
            'categorie_id' => $this->regleCategorie(false),
            'seuil_alerte' => ['nullable', 'integer', 'between:1,100'],
            'statut_alerte' => ['nullable', 'boolean'],
            'alerte_80_envoyee' => ['nullable', 'boolean'],
            'alerte_100_envoyee' => ['nullable', 'boolean'],
        ];
    }
}
