<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

/** Crée (ou promeut) le compte administrateur de l'interface web. */
class CreerAdmin extends Command
{
    protected $signature = 'planify:creer-admin {email} {--nom=Admin} {--prenom=Planify}';

    protected $description = 'Crée un compte administrateur';

    public function handle(): int
    {
        $email = Str::lower($this->argument('email'));
        $motDePasse = $this->secret('Mot de passe (8 caractères min., 1 majuscule, 1 chiffre)');

        if (strlen((string) $motDePasse) < 8 || ! preg_match('/[A-Z]/', $motDePasse) || ! preg_match('/\d/', $motDePasse)) {
            $this->error('Mot de passe trop faible.');

            return self::FAILURE;
        }

        $user = User::firstOrNew(['email' => $email]);
        $user->fill([
            'nom' => $user->nom ?? $this->option('nom'),
            'prenom' => $user->prenom ?? $this->option('prenom'),
            'password' => $motDePasse,
        ]);
        $user->is_admin = true;
        $user->email_verified_at ??= now();
        $user->save();

        $this->info("Administrateur {$email} prêt. Connexion : ".url('/admin/connexion'));

        return self::SUCCESS;
    }
}
