<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/** Code à 6 chiffres pour réinitialiser le mot de passe depuis l'application. */
class CodeReinitialisation extends Notification
{
    use Queueable;

    public function __construct(private readonly string $code)
    {
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage())
            ->subject('Planify — Code de réinitialisation')
            ->greeting('Bonjour '.$notifiable->prenom.',')
            ->line('Voici votre code pour réinitialiser votre mot de passe :')
            ->line('**'.$this->code.'**')
            ->line('Saisissez-le dans l\'application Planify. Il est valable 15 minutes.')
            ->line('Si vous n\'êtes pas à l\'origine de cette demande, ignorez cet email : votre mot de passe reste inchangé.')
            ->salutation('L\'équipe Planify');
    }
}
