<?php

namespace App\Http\Requests;

class AlerteRequest extends RessourceRequest
{
    protected function regles(): array
    {
        return [
            'type_alerte' => ['required', 'string', 'max:30'],
            'message' => ['required', 'string', 'max:2000'],
            'date_envoi' => ['required', 'date'],
            'est_lue' => ['nullable', 'boolean'],
            'budget_id' => ['nullable', 'string', 'max:64'],
        ];
    }
}
