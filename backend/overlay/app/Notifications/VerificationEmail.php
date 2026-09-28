<?php

namespace App\Notifications;

use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Notifications\Messages\MailMessage;

/** Email de vérification envoyé après l'inscription. */
class VerificationEmail extends VerifyEmail
{
    protected function buildMailMessage($url): MailMessage
    {
        return (new MailMessage())
            ->subject('Planify — Confirmez votre adresse email')
            ->greeting('Bienvenue sur Planify !')
            ->line('Merci de vous être inscrit. Confirmez votre adresse email pour sécuriser votre compte.')
            ->action('Confirmer mon adresse', $url)
            ->line('Ce lien expire dans 60 minutes. Si vous n\'avez pas créé de compte, ignorez cet email.')
            ->salutation('L\'équipe Planify');
    }
}
