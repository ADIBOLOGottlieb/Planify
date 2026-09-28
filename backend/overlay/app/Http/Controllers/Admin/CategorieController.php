<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Categorie;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Gestion des catégories système, proposées à tous les utilisateurs et
 * transmises aux applications à la synchronisation suivante.
 */
class CategorieController extends Controller
{
    private function regles(): array
    {
        return [
            'nom' => ['required', 'string', 'max:50'],
            'icone' => ['required', 'string', 'max:50'],
            'couleur' => ['required', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'type' => ['required', 'in:depense,revenu'],
        ];
    }

    public function index(): View
    {
        return view('admin.categories.index', [
            'categories' => Categorie::where('est_systeme', true)->orderBy('type')->orderBy('nom')->get(),
        ]);
    }

    public function create(): View
    {
        $categorie = new Categorie(['couleur' => '#546E7A', 'type' => 'depense', 'icone' => 'more_horiz']);

        return view('admin.categories.formulaire', compact('categorie'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate($this->regles());
        $categorie = new Categorie($data);
        $categorie->id = 'cat_'.Str::slug($data['nom'], '_').'_'.Str::lower(Str::random(4));
        $categorie->est_systeme = true;
        $categorie->updated_at = now();
        $categorie->save();

        return redirect()->route('admin.categories.index')->with('succes', 'Catégorie créée.');
    }

    public function edit(Categorie $categorie): View
    {
        abort_unless($categorie->est_systeme, 404);

        return view('admin.categories.formulaire', compact('categorie'));
    }

    public function update(Request $request, Categorie $categorie): RedirectResponse
    {
        abort_unless($categorie->est_systeme, 404);
        $categorie->fill($request->validate($this->regles()));
        $categorie->est_archivee = $request->boolean('est_archivee');
        $categorie->updated_at = now();
        $categorie->save();

        return redirect()->route('admin.categories.index')->with('succes', 'Catégorie mise à jour.');
    }

    /** Les catégories système sont archivées plutôt que supprimées (historique conservé). */
    public function destroy(Categorie $categorie): RedirectResponse
    {
        abort_unless($categorie->est_systeme, 404);
        $categorie->est_archivee = true;
        $categorie->updated_at = now();
        $categorie->save();

        return redirect()->route('admin.categories.index')->with('succes', 'Catégorie archivée.');
    }
}
