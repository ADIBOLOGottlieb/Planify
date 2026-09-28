<?php

namespace App\Console\Commands;

use App\Models\Transaction;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Console\Command;

/**
 * Chaque lundi : envoie à chaque utilisateur (ayant un appareil enregistré)
 * le bilan de la semaine écoulée par notification push.
 */
class EnvoyerRapportsHebdomadaires extends Command
{
    protected $signature = 'planify:rapports-hebdomadaires';

    protected $description = 'Envoie le rapport hebdomadaire des dépenses par notification push';

    public function handle(FcmService $fcm): int
    {
        $debut = now()->startOfWeek()->subWeek();
        $fin = $debut->copy()->endOfWeek();
        $envoyes = 0;

        User::whereNotNull('token_fcm')->where('statut', 'actif')->chunkById(200, function ($users) use ($fcm, $debut, $fin, &$envoyes) {
            foreach ($users as $user) {
                $totaux = Transaction::where('utilisateur_id', $user->id)
                    ->whereBetween('date_transaction', [$debut, $fin])
                    ->selectRaw("SUM(CASE WHEN type = 'depense' THEN montant ELSE 0 END) as depenses")
                    ->selectRaw("SUM(CASE WHEN type = 'revenu' THEN montant ELSE 0 END) as revenus")
                    ->first();
                $depenses = (float) ($totaux->depenses ?? 0);
                $revenus = (float) ($totaux->revenus ?? 0);
                if ($depenses == 0 && $revenus == 0) {
                    continue;
                }
                $f = fn (float $v) => number_format($v, 0, ',', ' ').' '.$user->devise;
                if ($fcm->envoyer($user, 'Votre semaine avec Planify',
                    "Dépenses : {$f($depenses)} · Revenus : {$f($revenus)}. Ouvrez l'application pour le détail.",
                    ['type' => 'rapport_hebdo'])) {
                    $envoyes++;
                }
            }
        });

        $this->info("{$envoyes} rapport(s) envoyé(s).");

        return self::SUCCESS;
    }
}
