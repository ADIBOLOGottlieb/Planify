<?php

namespace App\Console\Commands;

use App\Models\Transaction;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Console\Command;

/**
 * Rappelle de saisir ses dépenses aux utilisateurs qui n'ont rien
 * enregistré depuis 3 jours (le rappel quotidien, lui, est programmé
 * localement dans l'application).
 */
class RelancerInactifs extends Command
{
    protected $signature = 'planify:relancer-inactifs {--jours=3}';

    protected $description = 'Notifie les utilisateurs sans saisie récente';

    public function handle(FcmService $fcm): int
    {
        $jours = (int) $this->option('jours');
        $limite = now()->subDays($jours);
        $envoyes = 0;

        User::whereNotNull('token_fcm')->where('statut', 'actif')->chunkById(200, function ($users) use ($fcm, $limite, $jours, &$envoyes) {
            foreach ($users as $user) {
                $recente = Transaction::where('utilisateur_id', $user->id)
                    ->where('updated_at', '>=', $limite)->exists();
                if ($recente) {
                    continue;
                }
                if ($fcm->envoyer($user, 'Planify', "Vous n'avez rien enregistré depuis {$jours} jours. Pensez à saisir vos dépenses !", ['type' => 'rappel'])) {
                    $envoyes++;
                }
            }
        });

        $this->info("{$envoyes} rappel(s) envoyé(s).");

        return self::SUCCESS;
    }
}
