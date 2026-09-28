@extends('admin.layout')
@section('titre', 'Statistiques')

@section('contenu')
<h1 class="h3 mb-1">Statistiques globales</h1>
<p class="text-secondary">Données anonymisées : aucune information personnelle ni transaction individuelle n'est affichée.</p>

<div class="row g-3 mb-4">
    @foreach ([
        ['Utilisateurs inscrits', $utilisateurs, 'people', 'primary'],
        ['Actifs (30 jours)', $actifs, 'activity', 'success'],
        ['Emails vérifiés', $emailsVerifies, 'envelope-check', 'info'],
        ['Transactions', $transactions, 'receipt', 'secondary'],
        ['Transactions ce mois', $transactionsMois, 'calendar-month', 'warning'],
        ['Signalements en attente', $signalementsEnAttente, 'bug', 'danger'],
    ] as [$libelle, $valeur, $icone, $couleur])
        <div class="col-6 col-lg-4 col-xl-2">
            <div class="card carte-stat p-3 h-100">
                <i class="bi bi-{{ $icone }} text-{{ $couleur }} fs-4"></i>
                <div class="valeur">{{ number_format($valeur, 0, ',', ' ') }}</div>
                <div class="text-secondary small">{{ $libelle }}</div>
            </div>
        </div>
    @endforeach
</div>

<div class="row g-3">
    <div class="col-lg-7">
        <div class="card carte-stat p-3 h-100">
            <h2 class="h6">Dépenses du mois par catégorie (tous utilisateurs)</h2>
            @php($totalMois = $depensesParCategorie->sum('total'))
            @forelse ($depensesParCategorie as $ligne)
                <div class="mb-2">
                    <div class="d-flex justify-content-between small">
                        <span>{{ $ligne['categorie'] }} <span class="text-secondary">({{ $ligne['nombre'] }})</span></span>
                        <span>{{ number_format($ligne['total'], 0, ',', ' ') }} FCFA</span>
                    </div>
                    <div class="progress" style="height: 8px">
                        <div class="progress-bar bg-success" style="width: {{ $totalMois > 0 ? round($ligne['total'] / $totalMois * 100) : 0 }}%"></div>
                    </div>
                </div>
            @empty
                <p class="text-secondary">Aucune dépense ce mois-ci.</p>
            @endforelse
        </div>
    </div>
    <div class="col-lg-5">
        <div class="card carte-stat p-3 mb-3">
            <h2 class="h6">Inscriptions (6 derniers mois)</h2>
            @php($maxInscriptions = max(1, $inscriptions->max()))
            @foreach ($inscriptions as $mois => $nombre)
                <div class="d-flex align-items-center small mb-1">
                    <span style="width: 80px">{{ $mois }}</span>
                    <div class="progress flex-grow-1 mx-2" style="height: 8px">
                        <div class="progress-bar" style="width: {{ round($nombre / $maxInscriptions * 100) }}%"></div>
                    </div>
                    <span>{{ $nombre }}</span>
                </div>
            @endforeach
        </div>
        <div class="card carte-stat p-3">
            <h2 class="h6">Modes de paiement utilisés</h2>
            <table class="table table-sm mb-0">
                @foreach ([
                    'especes' => 'Espèces', 'mobile_money' => 'Mobile Money',
                    'virement' => 'Virement', 'carte' => 'Carte',
                ] as $cle => $libelle)
                    <tr><td>{{ $libelle }}</td><td class="text-end">{{ $modesPaiement[$cle] ?? 0 }}</td></tr>
                @endforeach
            </table>
        </div>
    </div>
</div>
@endsection
