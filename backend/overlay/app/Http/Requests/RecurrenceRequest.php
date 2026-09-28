<?php

namespace App\Http\Requests;

class RecurrenceRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'montant' => ['required', 'numeric', 'gt:0'],
            'type' => ['required', 'in:depense,revenu'],
            'date_debut' => ['required', 'date'],
            'prochaine_date' => ['required', 'date'],
            'periodicite' => ['required', 'in:hebdomadaire,mensuel,annuel'],
            'description' => ['nullable', 'string', 'max:500'],
            'mode_paiement' => ['required', 'in:especes,mobile_money,virement,carte'],
            'categorie_id' => $this->regleCategorie(),
            'compte_id' => ['nullable', 'string', 'max:64'],
            'actif' => ['nullable', 'boolean'],
        ];
    }
}
