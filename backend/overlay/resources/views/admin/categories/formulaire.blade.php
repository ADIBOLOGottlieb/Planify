@extends('admin.layout')
@section('titre', $categorie->exists ? 'Modifier une catégorie' : 'Nouvelle catégorie')

@section('contenu')
<h1 class="h3 mb-3">{{ $categorie->exists ? 'Modifier « '.$categorie->nom.' »' : 'Nouvelle catégorie système' }}</h1>

<div class="card carte-stat p-4" style="max-width: 560px">
    <form method="POST" action="{{ $categorie->exists ? route('admin.categories.update', $categorie) : route('admin.categories.store') }}">
        @csrf
        @if ($categorie->exists) @method('PUT') @endif

        <div class="mb-3">
            <label class="form-label" for="nom">Nom</label>
            <input class="form-control @error('nom') is-invalid @enderror" id="nom" name="nom" value="{{ old('nom', $categorie->nom) }}" required maxlength="50">
            @error('nom')<div class="invalid-feedback">{{ $message }}</div>@enderror
        </div>
        <div class="mb-3">
            <label class="form-label" for="type">Type</label>
            <select class="form-select" id="type" name="type">
                <option value="depense" @selected(old('type', $categorie->type) === 'depense')>Dépense</option>
                <option value="revenu" @selected(old('type', $categorie->type) === 'revenu')>Revenu</option>
            </select>
        </div>
        <div class="mb-3">
            <label class="form-label" for="icone">Icône (nom Material, ex. <code>restaurant</code>, <code>two_wheeler</code>)</label>
            <input class="form-control @error('icone') is-invalid @enderror" id="icone" name="icone" value="{{ old('icone', $categorie->icone) }}" required>
            @error('icone')<div class="invalid-feedback">{{ $message }}</div>@enderror
        </div>
        <div class="mb-3">
            <label class="form-label" for="couleur">Couleur</label>
            <input class="form-control form-control-color" id="couleur" name="couleur" type="color" value="{{ old('couleur', $categorie->couleur) }}">
        </div>
        @if ($categorie->exists)
            <div class="form-check mb-3">
                <input class="form-check-input" id="est_archivee" name="est_archivee" type="checkbox" value="1" @checked(old('est_archivee', $categorie->est_archivee))>
                <label class="form-check-label" for="est_archivee">Archivée (masquée dans les nouvelles saisies)</label>
            </div>
        @endif
        <button class="btn btn-success">Enregistrer</button>
        <a class="btn btn-link" href="{{ route('admin.categories.index') }}">Annuler</a>
    </form>
</div>
@endsection
