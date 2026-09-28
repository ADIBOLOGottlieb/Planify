<?php

namespace App\Http\Requests;

class TransactionRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'montant' => ['required', 'numeric', 'gt:0', 'max:9999999999999'],
            'type' => ['required', 'in:depense,revenu'],
            'date_transaction' => ['required', 'date'],
            'description' => ['nullable', 'string', 'max:500'],
            'mode_paiement' => ['required', 'in:especes,mobile_money,virement,carte'],
            'justificatif' => ['nullable', 'string', 'max:255'],
            'categorie_id' => $this->regleCategorie(),
            'compte_id' => ['nullable', 'string', 'max:64'],
            'date_creation' => ['nullable', 'date'],
        ];
    }
}
