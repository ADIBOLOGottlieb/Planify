<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validation commune des ressources synchronisées : identifiant fourni par
 * le client et date de dernière modification. Les champs `utilisateur_id`
 * ou `est_systeme` envoyés par le client sont ignorés (non validés).
 */
abstract class RessourceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // l'accès aux éléments existants est contrôlé par les Policies
    }

    /** Règles propres à la ressource. */
    abstract protected function regles(): array;

    public function rules(): array
    {
        return array_merge([
            'id' => ['required', 'string', 'max:64'],
            'updated_at' => ['nullable', 'date'],
        ], $this->regles());
    }

    public function messages(): array
    {
        return [
            'montant.gt' => 'Le montant doit être supérieur à zéro.',
            'montant_alloue.gt' => 'Le montant doit être supérieur à zéro.',
            'montant_cible.gt' => 'Le montant doit être supérieur à zéro.',
            'categorie_id.exists' => 'Catégorie inconnue.',
        ];
    }

    /** La catégorie doit être une catégorie système ou appartenir à l'utilisateur. */
    protected function regleCategorie(bool $obligatoire = true): array
    {
        return [
            $obligatoire ? 'required' : 'nullable',
            'string',
            function (string $attribut, mixed $valeur, \Closure $echec) {
                $ok = \App\Models\Categorie::whereKey($valeur)
                    ->where(fn ($q) => $q->where('est_systeme', true)
                        ->orWhere('utilisateur_id', $this->user()->id))
                    ->exists();
                if (! $ok) {
                    $echec('Catégorie inconnue.');
                }
            },
        ];
    }
}
