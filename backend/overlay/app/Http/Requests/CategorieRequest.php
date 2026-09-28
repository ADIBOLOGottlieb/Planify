<?php

namespace App\Http\Requests;

class CategorieRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'nom' => ['required', 'string', 'max:50'],
            'icone' => ['required', 'string', 'max:50'],
            'couleur' => ['required', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'type' => ['required', 'in:depense,revenu'],
            'est_archivee' => ['nullable', 'boolean'],
        ];
    }
}
