@extends('admin.layout')
@section('titre', 'Catégories système')

@section('contenu')
<div class="d-flex justify-content-between align-items-center mb-3">
    <div>
        <h1 class="h3 mb-0">Catégories système</h1>
        <p class="text-secondary mb-0">Proposées à tous les utilisateurs ; les modifications sont transmises à la prochaine synchronisation.</p>
    </div>
    <a class="btn btn-success" href="{{ route('admin.categories.create') }}"><i class="bi bi-plus-lg"></i> Nouvelle catégorie</a>
</div>

<div class="card carte-stat">
    <table class="table align-middle mb-0">
        <thead><tr><th>Nom</th><th>Type</th><th>Icône</th><th>Identifiant</th><th>Statut</th><th></th></tr></thead>
        <tbody>
        @foreach ($categories as $categorie)
            <tr @class(['text-secondary' => $categorie->est_archivee])>
                <td><span class="pastille me-2" style="background: {{ $categorie->couleur }}"></span>{{ $categorie->nom }}</td>
                <td>{{ $categorie->type === 'depense' ? 'Dépense' : 'Revenu' }}</td>
                <td><code>{{ $categorie->icone }}</code></td>
                <td><code>{{ $categorie->id }}</code></td>
                <td>{!! $categorie->est_archivee ? '<span class="badge bg-secondary">Archivée</span>' : '<span class="badge bg-success">Active</span>' !!}</td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-primary" href="{{ route('admin.categories.edit', $categorie) }}">Modifier</a>
                    @unless ($categorie->est_archivee)
                        <form class="d-inline" method="POST" action="{{ route('admin.categories.destroy', $categorie) }}" onsubmit="return confirm('Archiver cette catégorie ?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-sm btn-outline-secondary">Archiver</button>
                        </form>
                    @endunless
                </td>
            </tr>
        @endforeach
        </tbody>
    </table>
</div>
@endsection
