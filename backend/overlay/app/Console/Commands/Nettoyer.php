<?php

namespace App\Console\Commands;

use App\Models\Alerte;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/** Supprime les données expirées : codes de réinitialisation, vieilles alertes lues. */
class Nettoyer extends Command
{
    protected $signature = 'planify:nettoyer';

    protected $description = 'Supprime les données expirées';

    public function handle(): int
    {
        $codes = DB::table('password_reset_codes')->where('expires_at', '<', now())->delete();
        $alertes = Alerte::where('est_lue', true)->where('date_envoi', '<', now()->subMonths(6))->delete();

        $this->info("{$codes} code(s) expiré(s) et {$alertes} alerte(s) ancienne(s) supprimé(s).");

        return self::SUCCESS;
    }
}
