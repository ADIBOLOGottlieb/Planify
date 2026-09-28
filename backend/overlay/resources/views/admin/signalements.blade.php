@extends('admin.layout')
@section('titre', 'Signalements')

@section('contenu')
<h1 class="h3 mb-3">Signalements d'incidents</h1>

@forelse ($signalements as $signalement)
    <div class="card carte-stat p-3 mb-2 @if($signalement->est_traite) opacity-75 @endif">
        <div class="d-flex justify-content-between align-items-start">
            <div>
                <h2 class="h6 mb-1">
                    {{ $signalement->sujet }}
                    @if ($signalement->est_traite)
                        <span class="badge bg-success ms-1">Traité</span>
                    @else
                        <span class="badge bg-warning text-dark ms-1">En attente</span>
                    @endif
                </h2>
                <div class="small text-secondary mb-2">
                    Reçu le {{ $signalement->created_at->format('d/m/Y à H:i') }}
                    — utilisateur {{ $signalement->utilisateur_id ? substr($signalement->utilisateur_id, 0, 8).'…' : 'supprimé' }}
                </div>
                <p class="mb-0" style="white-space: pre-line">{{ $signalement->message }}</p>
            </div>
            <form method="POST" action="{{ route('admin.signalements.basculer', $signalement) }}">
                @csrf @method('PATCH')
                <button class="btn btn-sm {{ $signalement->est_traite ? 'btn-outline-secondary' : 'btn-success' }}">
                    {{ $signalement->est_traite ? 'Rouvrir' : 'Marquer traité' }}
                </button>
            </form>
        </div>
    </div>
@empty
    <p class="text-secondary">Aucun signalement.</p>
@endforelse

{{ $signalements->links('pagination::bootstrap-5') }}
@endsection
