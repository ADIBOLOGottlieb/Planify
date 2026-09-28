<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/**
 * CRUD REST des ressources synchronisées avec l'application mobile
 * (index, store, show, update, destroy).
 *
 * - Chaque utilisateur n'accède qu'à ses propres données (Policies).
 * - `store` accepte l'identifiant généré par le client : si l'élément
 *   existe déjà, il est mis à jour (écriture idempotente, utile quand une
 *   synchronisation est rejouée après une coupure réseau).
 * - `updated_at` envoyé par le client est conservé pour la résolution des
 *   conflits.
 */
abstract class RessourceController extends Controller
{
    /** @var class-string<Model> */
    protected string $modele;

    /** @var class-string<FormRequest> */
    protected string $requete;

    /** Requête de base des éléments visibles par l'utilisateur. */
    protected function visibles(Request $request): Builder
    {
        return ($this->modele)::query()->where('utilisateur_id', $request->user()->id);
    }

    public function index(Request $request): JsonResponse
    {
        return response()->json($this->visibles($request)->orderByDesc('updated_at')->get());
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $element = ($this->modele)::findOrFail($id);
        $this->authorize('view', $element);

        return response()->json($element);
    }

    public function store(Request $request): JsonResponse
    {
        $data = app($this->requete)->validated();
        $existant = ($this->modele)::find($data['id']);
        if ($existant) {
            $this->authorize('update', $existant);
        }

        $element = $existant ?? new $this->modele();
        $this->enregistrer($element, $data, $request);

        return response()->json($element->fresh(), $existant ? 200 : 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $element = ($this->modele)::findOrFail($id);
        $this->authorize('update', $element);
        $data = app($this->requete)->validated();

        $this->enregistrer($element, $data, $request);

        return response()->json($element->fresh());
    }

    public function destroy(Request $request, string $id): Response
    {
        $element = ($this->modele)::findOrFail($id);
        $this->authorize('delete', $element);
        $element->delete();

        return response()->noContent();
    }

    protected function enregistrer(Model $element, array $data, Request $request): void
    {
        $element->id = $element->exists ? $element->id : $data['id'];
        $element->fill(collect($data)->only($element->getFillable())->all());
        $element->utilisateur_id = $request->user()->id;
        // La date de modification est celle du client (résolution des conflits).
        $element->timestamps = false;
        $element->updated_at = $data['updated_at'] ?? now();
        $element->save();
    }
}
