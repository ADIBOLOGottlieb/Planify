<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\CompteRequest;
use App\Models\Compte;

/** Comptes de paiement (espèces, Mobile Money) de l'utilisateur. */
class CompteController extends RessourceController
{
    protected string $modele = Compte::class;

    protected string $requete = CompteRequest::class;
}
