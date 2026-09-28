<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Envoi de notifications push via Firebase Cloud Messaging (API HTTP v1).
 *
 * Configuration (.env) :
 *   FCM_PROJECT_ID=identifiant-du-projet-firebase
 *   FCM_CREDENTIALS=/chemin/vers/compte-de-service.json
 * Le jeton OAuth 2.0 est obtenu en signant un JWT (RS256) avec la clé du
 * compte de service, puis mis en cache 55 minutes.
 */
class FcmService
{
    public function estConfigure(): bool
    {
        $fichier = config('services.fcm.credentials');

        return filled(config('services.fcm.project_id')) && $fichier && is_readable($fichier);
    }

    /** Envoie une notification ; renvoie false si l'appareil est invalide ou FCM non configuré. */
    public function envoyer(User $user, string $titre, string $message, array $donnees = []): bool
    {
        if (! $user->token_fcm || ! $this->estConfigure()) {
            return false;
        }

        $reponse = Http::withToken($this->jetonAcces())
            ->post(sprintf('https://fcm.googleapis.com/v1/projects/%s/messages:send', config('services.fcm.project_id')), [
                'message' => [
                    'token' => $user->token_fcm,
                    'notification' => ['title' => $titre, 'body' => $message],
                    'data' => array_map('strval', $donnees),
                    'android' => ['notification' => ['channel_id' => 'planify_push']],
                ],
            ]);

        if ($reponse->successful()) {
            return true;
        }

        // Jeton expiré ou application désinstallée : on l'oublie.
        if ($reponse->status() === 404 || str_contains($reponse->body(), 'UNREGISTERED')) {
            $user->forceFill(['token_fcm' => null])->save();
        }
        Log::warning('Échec FCM', ['statut' => $reponse->status(), 'corps' => $reponse->body()]);

        return false;
    }

    private function jetonAcces(): string
    {
        return Cache::remember('fcm_access_token', now()->addMinutes(55), function () {
            $compte = json_decode(file_get_contents(config('services.fcm.credentials')), true);
            if (! isset($compte['client_email'], $compte['private_key'])) {
                throw new RuntimeException('Fichier de compte de service FCM invalide.');
            }

            $b64 = fn (string $s) => rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
            $maintenant = time();
            $entete = $b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $contenu = $b64(json_encode([
                'iss' => $compte['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $maintenant,
                'exp' => $maintenant + 3600,
            ]));
            openssl_sign("$entete.$contenu", $signature, $compte['private_key'], OPENSSL_ALGO_SHA256);

            return Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => "$entete.$contenu.".$b64($signature),
            ])->throw()->json('access_token');
        });
    }
}
