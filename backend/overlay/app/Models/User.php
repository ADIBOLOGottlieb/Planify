<?php

namespace App\Models;

use App\Notifications\VerificationEmail;
use DateTimeInterface;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * Utilisateur de Planify (entité UTILISATEUR du MCD). L'identifiant UUID
 * est fourni par l'application mobile à l'inscription.
 */
class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, HasUuids, Notifiable;

    protected $fillable = [
        'id',
        'nom',
        'prenom',
        'email',
        'password',
        'devise',
        'photo_profil',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'token_fcm',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed', // bcrypt
        'is_admin' => 'boolean',
    ];

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class, 'utilisateur_id');
    }

    public function signalements(): HasMany
    {
        return $this->hasMany(Signalement::class, 'utilisateur_id');
    }

    public function sendEmailVerificationNotification(): void
    {
        $this->notify(new VerificationEmail());
    }

    /** Représentation renvoyée à l'application mobile. */
    public function versApi(): array
    {
        return [
            'id' => $this->id,
            'nom' => $this->nom,
            'prenom' => $this->prenom,
            'email' => $this->email,
            'devise' => $this->devise,
            'photo_profil' => $this->photo_profil,
            'statut' => $this->statut,
            'email_verifie' => $this->hasVerifiedEmail(),
            'date_inscription' => $this->serializeDate($this->created_at),
            'updated_at' => $this->serializeDate($this->updated_at),
        ];
    }

    protected function serializeDate(DateTimeInterface $date): string
    {
        return $date->format('Y-m-d\TH:i:s.v');
    }
}
