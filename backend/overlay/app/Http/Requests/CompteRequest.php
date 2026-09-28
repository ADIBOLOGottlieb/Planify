<?php

namespace App\Http\Requests;

class CompteRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'nom' => ['required', 'string', 'max:50'],
            'solde' => ['required', 'numeric'],
            'icone' => ['required', 'string', 'max:50'],
            'couleur' => ['required', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'operateur' => ['nullable', 'string', 'max:20'],
        ];
    }
}
