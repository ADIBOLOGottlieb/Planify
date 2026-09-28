<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Categorie;
use App\Models\Signalement;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Facades\DB;

/**
 * Statistiques globales anonymisées : aucune donnée nominative ni aucune
 * transaction individuelle n'est affichée. Les dépenses des catégories
 * personnelles sont regroupées sous un seul libellé.
 */
class TableauDeBordController extends Controller
{
    public function __invoke(): View
    {
        $nomsSysteme = Categorie::where('est_systeme', true)->pluck('nom', 'id');

        $depensesParCategorie = Transaction::query()
            ->where('type', 'depense')
            ->where('date_transaction', '>=', now()->startOfMonth())
            ->select('categorie_id', DB::raw('SUM(montant) as total'), DB::raw('COUNT(*) as nombre'))
            ->groupBy('categorie_id')
            ->get()
            ->groupBy(fn ($ligne) => $nomsSysteme[$ligne->categorie_id] ?? 'Catégories personnelles')
            ->map(fn ($lignes, $categorie) => [
                'categorie' => $categorie,
                'total' => (float) $lignes->sum('total'),
                'nombre' => (int) $lignes->sum('nombre'),
            ])
            ->sortByDesc('total')
            ->values();

        $inscriptions = collect(range(5, 0))->mapWithKeys(function (int $i) {
            $mois = now()->startOfMonth()->subMonths($i);

            return [$mois->translatedFormat('M Y') => User::where('is_admin', false)
                ->whereBetween('created_at', [$mois, $mois->copy()->endOfMonth()])->count()];
        });

        return view('admin.tableau', [
            'utilisateurs' => User::where('is_admin', false)->count(),
            'actifs' => Transaction::where('updated_at', '>=', now()->subDays(30))
                ->distinct()->count('utilisateur_id'),
            'emailsVerifies' => User::where('is_admin', false)->whereNotNull('email_verified_at')->count(),
            'transactions' => Transaction::count(),
            'transactionsMois' => Transaction::where('date_transaction', '>=', now()->startOfMonth())->count(),
            'signalementsEnAttente' => Signalement::where('est_traite', false)->count(),
            'inscriptions' => $inscriptions,
            'depensesParCategorie' => $depensesParCategorie,
            'modesPaiement' => Transaction::select('mode_paiement', DB::raw('COUNT(*) as nombre'))
                ->groupBy('mode_paiement')->pluck('nombre', 'mode_paiement'),
        ]);
    }
}
